#!/usr/bin/env python3
# safari_bookmarks_to_html.py — Convert edited Safari bookmarks JSON to
#                                Netscape bookmark HTML for Safari import.
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
#   python3 safari_bookmarks_to_html.py <bookmarks.json> [output.html]
#
#   Default output: ~/Safari-bookmarks-YYYYMMDD-HHMMSS.html
#
# After generating the HTML:
#   1. Open Safari
#   2. Delete existing bookmarks you want to replace
#   3. File → Import From → Bookmarks HTML File...
#   4. Select the generated HTML file

import json
import sys
import html
from datetime import datetime
from pathlib import Path


def render_node(node, depth=1):
    """Recursively render a JSON bookmark node as Netscape bookmark HTML."""
    indent = "    " * depth
    lines = []

    if node["type"] == "bookmark":
        title = html.escape(node.get("title", ""))
        url   = html.escape(node.get("url", ""))
        lines.append(f'{indent}<DT><A HREF="{url}">{title}</A>')

    elif node["type"] == "folder":
        title = html.escape(node.get("title", ""))
        # Skip Safari internal top-level wrapper folders — render their
        # children directly at the top level to avoid double-nesting.
        if depth == 1 and title in ("BookmarksBar", "BookmarksMenu", ""):
            for child in node.get("children", []):
                lines.extend(render_node(child, depth))
        else:
            lines.append(f'{indent}<DT><H3>{title}</H3>')
            lines.append(f'{indent}<DL><p>')
            for child in node.get("children", []):
                lines.extend(render_node(child, depth + 1))
            lines.append(f'{indent}</DL><p>')

    return lines


def main():
    if len(sys.argv) < 2:
        print("Usage: safari_bookmarks_to_html.py <bookmarks.json> [output.html]",
              file=sys.stderr)
        sys.exit(1)

    json_path = Path(sys.argv[1])
    if not json_path.exists():
        print(f"ERROR: File not found: {json_path}", file=sys.stderr)
        sys.exit(1)

    if len(sys.argv) > 2:
        out_path = Path(sys.argv[2])
    else:
        stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        out_path = Path.home() / f"Safari-bookmarks-{stamp}.html"

    with open(json_path, "r", encoding="utf-8") as f:
        root = json.load(f)

    lines = [
        "<!DOCTYPE NETSCAPE-Bookmark-file-1>",
        "<!-- This is an automatically generated file.",
        "     It will be read and overwritten.",
        "     DO NOT EDIT! -->",
        '<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">',
        "<TITLE>Bookmarks</TITLE>",
        "<H1>Bookmarks</H1>",
        "<DL><p>",
    ]

    # Render children of the root folder
    for child in root.get("children", []):
        lines.extend(render_node(child, depth=1))

    lines.append("</DL><p>")

    with open(out_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")

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

    bookmarks, folders = count(root)
    print(f"Converted {bookmarks} bookmarks in {folders} folders → {out_path}")
    print()
    print("Next steps:")
    print("  1. Open Safari")
    print("  2. Clear existing bookmarks you want to replace")
    print("  3. File → Import From → Bookmarks HTML File...")
    print(f"  4. Select: {out_path}")


if __name__ == "__main__":
    main()
