#!/usr/bin/env python3
# safari_bookmarks_import.py — Import an edited JSON bookmark file back into Safari
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
#   python3 safari_bookmarks_import.py bookmarks.json
#
#   Run safari_backup.ksh before this script. A preflight check will
#   confirm you have done so before anything is overwritten.
#   Safari must be CLOSED before running.

import plistlib
import json
import sys
import uuid
from pathlib import Path


PLIST_PATH    = Path.home() / "Library" / "Safari" / "Bookmarks.plist"
BACKUP_SCRIPT = Path.home() / "bin" / "safari_backup.ksh"

# Safari's fixed UUIDs for the two top-level special folders.
# We preserve these so Safari doesn't get confused on first launch.
BOOKMARKS_BAR_UUID  = "BookmarksBar"
BOOKMARKS_MENU_UUID = "BookmarksMenu"


def make_uuid():
    return str(uuid.uuid4()).upper()


def build_leaf(node):
    """Build a Safari plist leaf (bookmark) from a JSON bookmark node."""
    return {
        "WebBookmarkType": "WebBookmarkTypeLeaf",
        "URLString": node.get("url", ""),
        "URIDictionary": {"title": node.get("title", node.get("url", ""))},
        "WebBookmarkUUID": make_uuid(),
    }


def build_list(node, fixed_uuid=None):
    """Build a Safari plist list (folder) from a JSON folder node."""
    children = []
    for child in node.get("children", []):
        if child["type"] == "bookmark":
            children.append(build_leaf(child))
        elif child["type"] == "folder":
            children.append(build_list(child))

    folder = {
        "WebBookmarkType": "WebBookmarkTypeList",
        "Title": node.get("title", ""),
        "WebBookmarkUUID": fixed_uuid if fixed_uuid else make_uuid(),
        "Children": children,
    }
    return folder


def build_plist_root(json_root):
    """
    Reconstruct the Safari plist root from the JSON tree.
    The JSON root is a folder whose children are the top-level Safari groups
    (BookmarksBar, BookmarksMenu, and any others).
    We assign stable UUIDs to the two well-known top-level folders.
    """
    children = []
    for child in json_root.get("children", []):
        if child["type"] == "folder":
            title = child.get("title", "")
            if title == "BookmarksBar":
                children.append(build_list(child, fixed_uuid=BOOKMARKS_BAR_UUID))
            elif title == "BookmarksMenu":
                children.append(build_list(child, fixed_uuid=BOOKMARKS_MENU_UUID))
            else:
                children.append(build_list(child))
        elif child["type"] == "bookmark":
            children.append(build_leaf(child))

    root = {
        "WebBookmarkType": "WebBookmarkTypeList",
        "Title": "",
        "WebBookmarkUUID": "Root",
        "Children": children,
    }
    return root


def main():
    if len(sys.argv) < 2:
        print("Usage: safari_bookmarks_import.py <bookmarks.json>", file=sys.stderr)
        sys.exit(1)

    json_path = Path(sys.argv[1])
    if not json_path.exists():
        print(f"ERROR: File not found: {json_path}", file=sys.stderr)
        sys.exit(1)

    if not PLIST_PATH.exists():
        print(f"ERROR: Cannot find Safari bookmarks at {PLIST_PATH}", file=sys.stderr)
        sys.exit(1)

    # Preflight: confirm safari_backup.ksh has been run
    if BACKUP_SCRIPT.exists():
        print(f"REMINDER: {BACKUP_SCRIPT} should be run before proceeding.")
    else:
        print("REMINDER: Back up your Safari configuration before proceeding.")
    print("Have you done so? (y/N) ", end="", flush=True)
    reply = input().strip().lower()
    if reply != "y":
        print("Aborted. Run safari_backup.ksh first, then retry.")
        sys.exit(0)
    print()

    # Load edited JSON
    with open(json_path, "r", encoding="utf-8") as f:
        json_root = json.load(f)

    # Build plist structure
    plist_root = build_plist_root(json_root)

    # Write binary plist
    with open(PLIST_PATH, "wb") as f:
        plistlib.dump(plist_root, f, fmt=plistlib.FMT_BINARY)

    print(f"Bookmarks written: {PLIST_PATH}")
    print("Launch Safari — your reorganized bookmarks should appear.")
    print()
    print("If anything looks wrong, run:  safari_restore.ksh")


if __name__ == "__main__":
    main()
