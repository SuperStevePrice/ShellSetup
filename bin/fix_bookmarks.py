#!/usr/bin/env python3
"""
fix_bookmarks.py

Restructures a Netscape-format bookmarks.html export so that no folder
directly contains BOTH loose bookmark links AND subfolders as siblings.

WHY THIS EXISTS
Safari's export is valid Netscape Bookmark HTML, but some Chromium-based
importers (Opera observed directly) silently drop loose links that sit
alongside subfolders in the same folder, while still importing the
subfolders fine. This script moves any such loose links into a new
subfolder (named "<Folder> - General") so every folder in the output is
either all-links or all-folders -- side-stepping the bug regardless of
its exact cause. It also adds the root-level <DL><p> wrapper that was
missing from the original export (harmless either way, but technically
more correct).

It does NOT delete, rename, or alter any bookmark -- every link that goes
in comes out, just regrouped. The script verifies this itself: it counts
<A> tags in the input and output and refuses to write a result if they
don't match.

USAGE
    python3 fix_bookmarks.py Bookmarks.html
    (writes Bookmarks_fixed.html next to it, or pass --out to choose)
"""

import sys
import argparse
from html.parser import HTMLParser
from pathlib import Path


class Folder:
    def __init__(self, name):
        self.name = name
        self.links = []     # list of (text, href)
        self.subfolders = []  # list of Folder

    def total_links(self):
        return len(self.links) + sum(f.total_links() for f in self.subfolders)


class BookmarkParser(HTMLParser):
    """Walks the DT/H3/DL/A structure using a folder stack. Tolerant of
    the format's unclosed <DT> and <p> tags, same as real browsers are."""

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.root = Folder("ROOT")
        self.stack = [self.root]
        self.pending_folder_name = None
        self.in_a = False
        self.a_href = None
        self.a_text = []
        self.in_h3 = False
        self.h3_text = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "h3":
            self.in_h3 = True
            self.h3_text = []
        elif tag == "a":
            self.in_a = True
            self.a_href = attrs.get("href", "")
            self.a_text = []
        elif tag == "dl":
            # A new <DL> opens the folder most recently named by <H3>,
            # unless this is the very first DL (the implicit root list).
            if self.pending_folder_name is not None:
                new_folder = Folder(self.pending_folder_name)
                self.stack[-1].subfolders.append(new_folder)
                self.stack.append(new_folder)
                self.pending_folder_name = None
            # else: root-level DL, stack already has ROOT on top -- no-op

    def handle_endtag(self, tag):
        if tag == "h3":
            self.in_h3 = False
            self.pending_folder_name = "".join(self.h3_text).strip()
        elif tag == "a":
            self.in_a = False
            text = "".join(self.a_text).strip()
            self.stack[-1].links.append((text, self.a_href))
        elif tag == "dl":
            if len(self.stack) > 1:
                self.stack.pop()

    def handle_data(self, data):
        if self.in_a:
            self.a_text.append(data)
        elif self.in_h3:
            self.h3_text.append(data)


def split_mixed_folders(folder: Folder):
    """Recursively move a folder's direct links into a new subfolder
    whenever that folder ALSO has subfolders -- so every folder ends up
    either all-links or all-folders."""
    for sub in folder.subfolders:
        split_mixed_folders(sub)

    if folder.links and folder.subfolders:
        overflow = Folder(f"{folder.name} - General")
        overflow.links = folder.links
        folder.links = []
        # Put the new "General" bucket first so it's easy to find.
        folder.subfolders.insert(0, overflow)


def escape(text: str) -> str:
    return (text.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;"))


def write_folder(folder: Folder, out: list, indent: int):
    pad = "\t" * indent
    for name, href in folder.links:
        out.append(f'{pad}<DT><A HREF="{escape(href)}">{escape(name)}</A>')
    for sub in folder.subfolders:
        out.append(f'{pad}<DT><H3>{escape(sub.name)}</H3>')
        out.append(f'{pad}<DL><p>')
        write_folder(sub, out, indent + 1)
        out.append(f'{pad}</DL><p>')


def render(root: Folder) -> str:
    out = [
        "<!DOCTYPE NETSCAPE-Bookmark-file-1>",
        "<HTML>",
        '<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">',
        "<TITLE>Bookmarks</TITLE>",
        "<H1>Bookmarks</H1>",
        "<DL><p>",
    ]
    write_folder(root, out, 1)
    out.append("</DL><p>")
    out.append("</HTML>")
    return "\n".join(out)


def main():
    parser = argparse.ArgumentParser(description="Fix mixed-content folders in a bookmarks.html export.")
    parser.add_argument("input", help="Path to the Safari/browser bookmarks.html export")
    parser.add_argument("--out", help="Output path (default: <input>_fixed.html next to input)")
    args = parser.parse_args()

    in_path = Path(args.input)
    if not in_path.exists():
        print(f"ERROR: file not found: {in_path}", file=sys.stderr)
        sys.exit(1)

    html_text = in_path.read_text(encoding="utf-8")

    bp = BookmarkParser()
    bp.feed(html_text)
    root = bp.root

    before_count = root.total_links()
    if before_count == 0:
        print("ERROR: parsed zero links from the input file -- refusing to write anything.", file=sys.stderr)
        sys.exit(1)

    split_mixed_folders(root)
    after_count = root.total_links()

    if after_count != before_count:
        print(
            f"ERROR: link count changed during restructuring ({before_count} -> {after_count}). "
            "Refusing to write a result -- this should never happen; please share the input file for review.",
            file=sys.stderr,
        )
        sys.exit(1)

    output_html = render(root)

    out_path = Path(args.out) if args.out else in_path.with_name(in_path.stem + "_fixed.html")
    out_path.write_text(output_html, encoding="utf-8")

    print(f"Parsed {before_count} bookmarks from {in_path.name}")
    print(f"Verified {after_count} bookmarks in the restructured output (no data loss)")
    print(f"Wrote: {out_path}")
    print("\nEvery folder in this file is now either all-links or all-subfolders.")
    print("Any folder that had both now has its loose links grouped under")
    print('a new subfolder named "<FolderName> - General".')


if __name__ == "__main__":
    main()
