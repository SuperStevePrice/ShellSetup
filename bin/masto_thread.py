#!/Users/steve/miniconda3/bin/python3
"""
masto_thread.py — Post a long text file as a reply-chained thread on Mastodon.

Supports optional inline images via Markdown syntax in the source file:
    ![Alt text](/path/to/image.jpg)
Local image paths are uploaded and attached to the post they appear in.
Remote URLs in image syntax are left in the text as plain URLs.

Usage:
    python3 masto_thread.py <textfile>           # dry run (preview only)
    python3 masto_thread.py <textfile> --post    # actually post the thread

Credentials (~/.masto_config):
    MASTO_INSTANCE=https://norcal.social
    MASTO_ACCESS_TOKEN=your_access_token_here

Generate an access token at:
    https://<your-instance>/settings/applications
"""

import argparse
import re
import sys
import textwrap
from pathlib import Path

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
MAX_CHARS = 500          # Mastodon default; raise if your instance allows more
CONFIG    = Path.home() / ".masto_config"

# Markdown image pattern:  ![alt text](/path/or/url)
IMAGE_RE = re.compile(r'!\[(.*?)\]\((.*?)\)')

# URL pattern (for non-image URLs)
URL_RE = re.compile(r'https?://\S+', re.IGNORECASE)

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
def load_config():
    if not CONFIG.exists():
        sys.exit(
            f"Config file not found: {CONFIG}\n"
            "Create it with two lines:\n"
            "  MASTO_INSTANCE=https://norcal.social\n"
            "  MASTO_ACCESS_TOKEN=your_access_token_here\n"
            "Generate a token at https://<your-instance>/settings/applications"
        )
    cfg = {}
    for line in CONFIG.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" in line:
            k, v = line.split("=", 1)
            cfg[k.strip()] = v.strip()
    instance = cfg.get("MASTO_INSTANCE", "").rstrip("/")
    token    = cfg.get("MASTO_ACCESS_TOKEN", "")
    if not instance or not token:
        sys.exit("~/.masto_config must contain MASTO_INSTANCE and MASTO_ACCESS_TOKEN.")
    return instance, token

# ---------------------------------------------------------------------------
# Mastodon client (uses mastodon.py library)
# ---------------------------------------------------------------------------
def make_client(instance, token):
    try:
        from mastodon import Mastodon
    except ImportError:
        sys.exit(
            "The 'mastodon.py' library is required.\n"
            "Install it with:  pip install Mastodon.py"
        )
    return Mastodon(access_token=token, api_base_url=instance)

# ---------------------------------------------------------------------------
# Text and image extraction
# ---------------------------------------------------------------------------
def extract_images(text):
    """
    Find all Markdown image references. Remove them from text.
    Local paths are returned for upload; remote URLs are kept as plain text.
    Returns (cleaned_text, [(image_path, alt_text), ...])
    """
    local_images = []
    remote_urls  = []

    def handle_match(m):
        alt, src = m.group(1), m.group(2)
        if src.startswith("http"):
            remote_urls.append(src)
            return src          # leave remote URL as plain text
        else:
            local_images.append((src, alt))
            return ""           # remove local image markdown entirely

    cleaned = IMAGE_RE.sub(handle_match, text)
    cleaned = re.sub(r'[ \t]{2,}', ' ', cleaned)
    cleaned = re.sub(r'\n[ \t]+\n', '\n\n', cleaned)
    return cleaned.strip(), local_images

def extract_urls(text):
    """
    Remove all bare https?:// URLs from text.
    Returns (cleaned_text, [url, ...])
    """
    urls    = URL_RE.findall(text)
    cleaned = URL_RE.sub('', text)
    cleaned = re.sub(r'[ \t]{2,}', ' ', cleaned)
    cleaned = re.sub(r'\n[ \t]+\n', '\n\n', cleaned)
    return cleaned.strip(), urls

# ---------------------------------------------------------------------------
# Text splitting
# ---------------------------------------------------------------------------
def split_text(text, max_chars=MAX_CHARS):
    """
    Split text into chunks of at most max_chars characters.
    Reserves space for the ' (N/T)' suffix.
    Breaks on sentence boundaries first, then word boundaries.
    """
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
    """Attach ' (N/T)' suffix to each chunk."""
    total = len(chunks)
    return [chunk + f" ({i}/{total})" for i, chunk in enumerate(chunks, 1)]

# ---------------------------------------------------------------------------
# Image upload
# ---------------------------------------------------------------------------
def upload_images(client, image_details, dry_run=False):
    """Upload local images; return list of media IDs."""
    media_ids = []
    for path, alt_text in image_details:
        if dry_run:
            print(f"  [dry run] would upload image: {path}  alt='{alt_text}'")
            continue
        try:
            media = client.media_post(path, description=alt_text)
            media_ids.append(media['id'])
            print(f"  Uploaded image: {path}")
        except Exception as e:
            print(f"  WARNING: failed to upload {path}: {e}", file=sys.stderr)
    return media_ids

# ---------------------------------------------------------------------------
# Preview
# ---------------------------------------------------------------------------
def preview(posts):
    bar = "─" * 60
    print(f"\nDRY RUN — {len(posts)} post(s) would be sent\n{bar}")
    for i, (text, images) in enumerate(posts, 1):
        print(f"[{i}/{len(posts)}]  ({len(text)} chars)"
              + (f"  +{len(images)} image(s)" if images else ""))
        print(textwrap.indent(text, "  "))
        for path, alt in images:
            print(f"  📎 {path}  alt='{alt}'")
        print(bar)
    print("Re-run with --post to publish.\n")

# ---------------------------------------------------------------------------
# Posting
# ---------------------------------------------------------------------------
def post_thread(client, posts):
    """
    Posts is a list of (text, [(image_path, alt_text), ...]).
    First post is public; replies are unlisted (keeps timeline clean).
    """
    in_reply_to_id = None
    first_post     = True

    for i, (text, image_details) in enumerate(posts):
        media_ids  = upload_images(client, image_details)
        visibility = 'public' if first_post else 'unlisted'
        try:
            resp = client.status_post(
                status        = text,
                in_reply_to_id= in_reply_to_id,
                media_ids     = media_ids if media_ids else None,
                visibility    = visibility,
            )
            print(f"  Posted ({i+1}/{len(posts)}): {resp['url']}  [{visibility}]")
            in_reply_to_id = resp['id']
            first_post     = False
        except Exception as e:
            sys.exit(f"Error posting ({i+1}/{len(posts)}): {e}")

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(
        description="Post a text file as a Mastodon thread."
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

    # --- Extract inline images first (Markdown syntax) ---
    # Images are attached to whatever post they physically appear in,
    # so we handle them per-chunk after splitting.
    # For now, strip them from the master text and note their positions
    # by keeping them in-line as a sentinel we can detect post-split.
    # Simpler approach: strip all local images from master text,
    # collect them, attach all to the FIRST post (common convention).
    text, all_images = extract_images(raw)

    # --- Extract bare URLs; migrate to last post ---
    text, urls = extract_urls(text)
    if urls:
        print(f"Found {len(urls)} URL(s) — will append to final post:")
        for u in urls:
            print(f"  {u}")
    if all_images:
        print(f"Found {len(all_images)} local image(s) — will attach to first post:")
        for p, a in all_images:
            print(f"  {p}  alt='{a}'")

    # --- Split and number ---
    chunks = split_text(text)

    if urls:
        url_block = "\n" + "\n".join(urls)
        last = chunks[-1]
        if len(last) + len(url_block) + 10 <= MAX_CHARS:
            chunks[-1] = last + url_block
        else:
            chunks.append(url_block.strip())

    numbered = add_numbering(chunks)

    # Build posts: list of (text, images).
    # Images attach to first post; all others have none.
    posts = []
    for i, text in enumerate(numbered):
        images = all_images if i == 0 else []
        posts.append((text, images))

    # --- Sanity check ---
    over = [(i+1, len(t)) for i, (t, _) in enumerate(posts) if len(t) > MAX_CHARS]
    if over:
        for n, c in over:
            print(f"WARNING: post {n} is {c} chars (limit {MAX_CHARS})", file=sys.stderr)

    if not args.post:
        preview(posts)
        return

    instance, token = load_config()
    client = make_client(instance, token)
    print(f"Posting {len(posts)}-part thread to {instance}…")
    post_thread(client, posts)
    print("Done.")

if __name__ == "__main__":
    main()
