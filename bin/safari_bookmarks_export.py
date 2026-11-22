#!/usr/bin/env python3
# safari_bookmarks_export.py — Export Safari bookmarks to an editable JSON file
#
# Copyright (C) 2026  Steve
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# Usage:
#   python3 safari_bookmarks_export.py [output.json]
#
#   Default output: ~/Safari-bookmarks-YYYYMMDD-HHMMSS.json
#   Safari must be CLOSED before running.

import plistlib
import json
import sys
import os
from datetime import datetime
from pathlib import Path


PLIST_PATH = Path.home() / "Library" / "Safari" / "Bookmarks.plist"

# Safari internal folder WebBookmarkUUIDs to skip (Reading List, etc.)
SKIP_TITLES = {"com.apple.ReadingList"}


def parse_node(node):
    """
    Recursively parse a Safari bookmark plist node into a plain dict.
    Returns a bookmark dict, a folder dict, or None if the node should be skipped.
    """
    kind = node.get("WebBookmarkType", "")

    if kind == "WebBookmarkTypeLeaf":
        url = node.get("URLString", "")
        title = node.get("URIDictionary", {}).get("title", url)
        return {
            "type": "bookmark",
            "title": title,
            "url": url,
        }

    elif kind == "WebBookmarkTypeList":
        title = node.get("Title", "")
        if title in SKIP_TITLES:
            return None

        children_raw = node.get("Children", [])
        children = []
        for child in children_raw:
            parsed = parse_node(child)
            if parsed is not None:
                children.append(parsed)

        return {
            "type": "folder",
            "title": title,
            "children": children,
        }

    elif kind == "WebBookmarkTypeProxy":
        # History / smart folders — skip
        return None

    return None


def main():
    if not PLIST_PATH.exists():
        print(f"ERROR: Cannot find Safari bookmarks at {PLIST_PATH}", file=sys.stderr)
        print("Make sure Safari is closed and try again.", file=sys.stderr)
        sys.exit(1)

    # Determine output path
    if len(sys.argv) > 1:
        out_path = Path(sys.argv[1])
    else:
        stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        out_path = Path.home() / f"Safari-bookmarks-{stamp}.json"

    print(f"Reading: {PLIST_PATH}")

    with open(PLIST_PATH, "rb") as f:
        plist = plistlib.load(f)

    # The top-level plist is itself a WebBookmarkTypeList
    parsed = parse_node(plist)
    if parsed is None:
        print("ERROR: Could not parse bookmark root.", file=sys.stderr)
        sys.exit(1)

    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(parsed, f, indent=2, ensure_ascii=False)

    # Count totals
    def count(node):
        if node["type"] == "bookmark":
            return 1, 0
        total_b, total_f = 0, 1
        for child in node.get("children", []):
            b, fo = count(child)
            total_b += b
            total_f += fo
        return total_b, total_f

    bookmarks, folders = count(parsed)
    print(f"Exported {bookmarks} bookmarks in {folders} folders → {out_path}")
    print()
    print("Edit the JSON freely — reorganize, rename, delete, nest folders.")
    print(f"When done, run:  safari_bookmarks_import.py {out_path}")


if __name__ == "__main__":
    main()
