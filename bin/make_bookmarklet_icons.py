#!/usr/bin/env python3
"""
make_bookmarklet_icons.py

Builds a tiny Netscape-format bookmarks.html file that attaches custom
icons to the BS (Bluesky) and FB (Facebook) posting bookmarklets, using
the ICON="data:image/png;base64,..." attribute. Chromium-based browsers
(Chrome, Edge, Opera) honor this attribute on import and will permanently
cache the icon against the bookmarklet's exact URL.

NOTE: This trick is Chromium-specific. Safari does not support attaching
custom icons to javascript: bookmarklets by any known method -- its
favicons are only ever fetched live from an actual site visit, and
bookmarklets have no site to visit. This file is for Chrome/Edge/Opera
only.

USAGE
    python3 make_bookmarklet_icons.py bluesky_icon.png facebook_icon.png
    (writes bookmarklet_icons.html next to this script, or pass --out)

WHAT TO DO WITH THE OUTPUT
    1. In your browser's bookmark manager, Import Bookmarks from File,
       choose the generated bookmarklet_icons.html
    2. It'll land in a new "Imported" folder with BS and FB now showing
       your custom icons
    3. Drag those two into place on your Bookmarks Bar
    4. Delete the old plain-icon BS/FB entries and the "Imported" folder
"""

import sys
import base64
import argparse
from pathlib import Path
from io import BytesIO

try:
    from PIL import Image
except ImportError:
    print("ERROR: Pillow is required (pip install Pillow --break-system-packages)", file=sys.stderr)
    sys.exit(1)

# The exact bookmarklet code from Steve's Safari export -- preserved
# verbatim so functionality doesn't change, only the icon.
BS_HREF = (
    "javascript:(function()%7B%20%20%20%20var%20text%20=%20document.title%20"
    "+%20%22%5Cn%22%20+%20document.location.href%20+%20%22%20%23bluesky%22;"
    "%20%20%20%20var%20encoded%20=%20encodeURIComponent(text);%20%20%20%20"
    "window.open(%22https://bsky.app/intent/compose?text=%22%20+%20encoded)"
    ";%7D)();"
)
FB_HREF = (
    "javascript:(function(){window.open('https://www.facebook.com/sharer/"
    "sharer.php?u='+encodeURIComponent(location.href));})();"
)

ICON_SIZE = 32  # px -- standard favicon-ish size, keeps the file small


def image_to_data_uri(path: Path) -> str:
    """Load an image, pad it to a square, resize to ICON_SIZE, and return
    a data:image/png;base64,... URI."""
    img = Image.open(path).convert("RGBA")

    # Pad to square (centered) so non-square crops don't look squashed.
    w, h = img.size
    side = max(w, h)
    square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    square.paste(img, ((side - w) // 2, (side - h) // 2))

    square = square.resize((ICON_SIZE, ICON_SIZE), Image.LANCZOS)

    buf = BytesIO()
    square.save(buf, format="PNG")
    b64 = base64.b64encode(buf.getvalue()).decode("ascii")
    return f"data:image/png;base64,{b64}"


def render(bs_icon_uri: str, fb_icon_uri: str) -> str:
    return "\n".join([
        "<!DOCTYPE NETSCAPE-Bookmark-file-1>",
        "<HTML>",
        '<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">',
        "<TITLE>Bookmarks</TITLE>",
        "<H1>Bookmarks</H1>",
        "<DL><p>",
        f'\t<DT><A HREF="{BS_HREF}" ICON="{bs_icon_uri}">BS</A>',
        f'\t<DT><A HREF="{FB_HREF}" ICON="{fb_icon_uri}">FB</A>',
        "</DL><p>",
        "</HTML>",
    ])


def main():
    parser = argparse.ArgumentParser(description="Build a bookmark HTML file with custom BS/FB icons.")
    parser.add_argument("bluesky_icon", help="Path to the Bluesky butterfly icon image")
    parser.add_argument("facebook_icon", help="Path to the Facebook icon image")
    parser.add_argument("--out", default=None, help="Output path (default: bookmarklet_icons.html)")
    args = parser.parse_args()

    bs_path = Path(args.bluesky_icon)
    fb_path = Path(args.facebook_icon)

    for p in (bs_path, fb_path):
        if not p.exists():
            print(f"ERROR: file not found: {p}", file=sys.stderr)
            sys.exit(1)

    bs_uri = image_to_data_uri(bs_path)
    fb_uri = image_to_data_uri(fb_path)

    html = render(bs_uri, fb_uri)

    out_path = Path(args.out) if args.out else Path("bookmarklet_icons.html")
    out_path.write_text(html, encoding="utf-8")

    print(f"Wrote: {out_path}")
    print(f"BS icon: {len(bs_uri)} bytes encoded")
    print(f"FB icon: {len(fb_uri)} bytes encoded")
    print("\nImport this file into Chrome/Edge/Opera's bookmark manager")
    print("(Import Bookmarks from File). It'll land in a new 'Imported'")
    print("folder with BS and FB now carrying your custom icons.")
    print("Not supported in Safari -- see the note at the top of this script.")


if __name__ == "__main__":
    main()
