#!/Users/steve/miniconda3/bin/python3
"""
threads_thread.py — Post a long text file as a reply-chained thread on Threads.

Threads uses a two-step API: first create a media container, then publish it.
Each post in the thread is published and then replied to by the next post.

Usage:
    python3 threads_thread.py <textfile>           # dry run (preview only)
    python3 threads_thread.py <textfile> --post    # actually post the thread

Credentials (~/.threads_config):
    THREADS_USER_ID=your_numeric_user_id
    THREADS_ACCESS_TOKEN=your_long_lived_access_token

Setup:
    1. Go to https://developers.facebook.com/apps/ and create a new app.
    2. Select "Access the Threads API" as the use case.
    3. Add threads_basic and threads_content_publish permissions.
    4. Use the Token Generator or OAuth flow to get a long-lived access token.
    5. Get your numeric user ID from:
       curl "https://graph.threads.net/v1.0/me?access_token=YOUR_TOKEN"
    6. Paste both into ~/.threads_config.

    Long-lived tokens last 60 days. Refresh before expiry at:
    https://graph.threads.net/refresh_access_token?grant_type=th_refresh_token&access_token=YOUR_TOKEN
"""

import argparse
import json
import re
import sys
import textwrap
import time
import urllib.request
import urllib.error
import urllib.parse
from pathlib import Path

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
MAX_CHARS   = 500
CONFIG      = Path.home() / ".threads_config"
THREADS_API = "https://graph.threads.net/v1.0"
URL_RE      = re.compile(r'https?://\S+', re.IGNORECASE)

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
def load_config():
    if not CONFIG.exists():
        sys.exit(
            f"Config file not found: {CONFIG}\n"
            "Create it with two lines:\n"
            "  THREADS_USER_ID=your_numeric_user_id\n"
            "  THREADS_ACCESS_TOKEN=your_long_lived_access_token\n"
            "See script header for setup instructions."
        )
    cfg = {}
    for line in CONFIG.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" in line:
            k, v = line.split("=", 1)
            cfg[k.strip()] = v.strip()
    user_id = cfg.get("THREADS_USER_ID", "")
    token   = cfg.get("THREADS_ACCESS_TOKEN", "")
    if not user_id or not token:
        sys.exit("~/.threads_config must contain THREADS_USER_ID and THREADS_ACCESS_TOKEN.")
    return user_id, token

# ---------------------------------------------------------------------------
# HTTP helpers
# ---------------------------------------------------------------------------
def api_post(endpoint, params, token):
    url  = f"{THREADS_API}/{endpoint}"
    params["access_token"] = token
    data = urllib.parse.urlencode(params).encode()
    req  = urllib.request.Request(url, data=data, method="POST")
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        body = e.read().decode(errors="replace")
        sys.exit(f"Threads API error {e.code} on {endpoint}:\n{body}")

# ---------------------------------------------------------------------------
# URL extraction
# ---------------------------------------------------------------------------
def extract_urls(text):
    urls    = URL_RE.findall(text)
    cleaned = URL_RE.sub('', text)
    cleaned = re.sub(r'[ \t]{2,}', ' ', cleaned)
    cleaned = re.sub(r'\n[ \t]+\n', '\n\n', cleaned)
    return cleaned.strip(), urls

# ---------------------------------------------------------------------------
# Text splitting
# ---------------------------------------------------------------------------
def split_text(text, max_chars=MAX_CHARS):
    reserve = 10   # worst-case ' (999/999)'
    limit   = max_chars - reserve

    text = re.sub(r"\n{3,}", "\n\n", text.strip())
    text = re.sub(r"[ \t]+", " ", text)

    chunks    = []
    remaining = text

    while remaining:
        remaining = remaining.strip()
        if not remaining:
            break
        if len(remaining) <= limit:
            chunks.append(remaining)
            break

        window = remaining[:limit]
        match  = None
        for m in re.finditer(r"[.!?][\"')\]]*\s", window):
            match = m
        if match:
            cut = match.end()
        else:
            space = window.rfind(" ")
            cut   = space if space > 0 else limit

        chunks.append(remaining[:cut].strip())
        remaining = remaining[cut:]

    return chunks

def add_numbering(chunks):
    total = len(chunks)
    return [chunk + f" ({i}/{total})" for i, chunk in enumerate(chunks, 1)]

# ---------------------------------------------------------------------------
# Posting
# ---------------------------------------------------------------------------
def create_container(user_id, text, reply_to_id, token):
    """Step 1: Create a media container. Returns container ID."""
    params = {
        "media_type": "TEXT",
        "text":       text,
    }
    if reply_to_id:
        params["reply_to_id"] = reply_to_id
    resp = api_post(f"{user_id}/threads", params, token)
    return resp["id"]

def publish_container(user_id, container_id, token):
    """Step 2: Publish the container. Returns post ID."""
    resp = api_post(f"{user_id}/threads_publish",
                    {"creation_id": container_id}, token)
    return resp["id"]

def post_thread(posts, user_id, token):
    reply_to_id = None
    for i, text in enumerate(posts):
        # Step 1: create container
        container_id = create_container(user_id, text, reply_to_id, token)
        # Brief pause — Meta recommends a short delay before publishing
        time.sleep(1)
        # Step 2: publish
        post_id = publish_container(user_id, container_id, token)
        print(f"  Posted ({i+1}/{len(posts)}): https://www.threads.net/t/{post_id}")
        reply_to_id = post_id

# ---------------------------------------------------------------------------
# Preview
# ---------------------------------------------------------------------------
def preview(posts):
    bar = "─" * 60
    print(f"\nDRY RUN — {len(posts)} post(s) would be sent\n{bar}")
    for i, text in enumerate(posts, 1):
        print(f"[{i}/{len(posts)}]  ({len(text)} chars)")
        print(textwrap.indent(text, "  "))
        print(bar)
    print("Re-run with --post to publish.\n")

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(
        description="Post a text file as a Threads reply-chain thread."
    )
    parser.add_argument("file",   help="Path to the text file to post")
    parser.add_argument("--post", action="store_true",
                        help="Actually publish the thread (default is dry run)")
    args = parser.parse_args()

    path = Path(args.file)
    if not path.exists():
        sys.exit(f"File not found: {path}")

    raw = path.read_text(encoding="utf-8")
    if not raw.strip():
        sys.exit("File is empty.")

    # Migrate URLs to last post
    text, urls = extract_urls(raw)
    if urls:
        print(f"Found {len(urls)} URL(s) — will append to final post:")
        for u in urls:
            print(f"  {u}")

    chunks = split_text(text)

    if urls:
        url_block = "\n" + "\n".join(urls)
        if len(chunks[-1]) + len(url_block) + 10 <= MAX_CHARS:
            chunks[-1] = chunks[-1] + url_block
        else:
            chunks.append(url_block.strip())

    posts = add_numbering(chunks)

    # Sanity check
    over = [(i+1, len(p)) for i, p in enumerate(posts) if len(p) > MAX_CHARS]
    if over:
        for n, c in over:
            print(f"WARNING: post {n} is {c} chars (limit {MAX_CHARS})", file=sys.stderr)

    if not args.post:
        preview(posts)
        return

    user_id, token = load_config()
    print(f"Posting {len(posts)}-part thread to Threads…")
    post_thread(posts, user_id, token)
    print("Done.")

if __name__ == "__main__":
    main()
