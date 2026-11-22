#!/Users/steve/miniconda3/bin/python3
"""
threads_manual.py — Format a text file as a Threads thread for manual copy-paste.

Splits text into 500-character chunks with N/T numbering and URL migration,
then prints each post clearly so you can paste them into Threads one by one.

No API credentials required.

Usage:
    python3 threads_manual.py <textfile>
"""

import argparse
import re
import sys
import textwrap
from pathlib import Path

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
MAX_CHARS = 500
URL_RE    = re.compile(r'https?://\S+', re.IGNORECASE)

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
    reserve = 10
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
# Display
# ---------------------------------------------------------------------------
def display(posts):
    bar     = "═" * 60
    divider = "─" * 60
    print(f"\n{bar}")
    print(f"  THREADS — {len(posts)} post(s) to paste manually")
    print(f"{bar}")
    for i, text in enumerate(posts, 1):
        print(f"\n  [{i}/{len(posts)}]  ({len(text)} chars)")
        print(f"{divider}")
        print(textwrap.indent(text, "  "))
        print(f"{divider}")
        if i < len(posts):
            print("  ^ Paste above, post it, then reply with the next one.")
    print(f"\n{bar}")
    print(f"  Start a new post with [1/{len(posts)}], then reply to each")
    print(f"  with the next post to build the thread.")
    print(f"{bar}\n")

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(
        description="Format a text file as a Threads thread for manual copy-paste."
    )
    parser.add_argument("file", help="Path to the text file to post")
    args = parser.parse_args()

    path = Path(args.file)
    if not path.exists():
        sys.exit(f"File not found: {path}")

    raw = path.read_text(encoding="utf-8")
    if not raw.strip():
        sys.exit("File is empty.")

    text, urls = extract_urls(raw)
    if urls:
        print(f"Found {len(urls)} URL(s) — appended to final post:")
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

    over = [(i+1, len(p)) for i, p in enumerate(posts) if len(p) > MAX_CHARS]
    if over:
        for n, c in over:
            print(f"WARNING: post {n} is {c} chars (limit {MAX_CHARS})", file=sys.stderr)

    display(posts)

if __name__ == "__main__":
    main()
