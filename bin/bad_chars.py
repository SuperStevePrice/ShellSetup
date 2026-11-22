#!/usr/bin/env python3
"""
bad_chars.py - Report non-ASCII and control characters in a text file.
Usage: python3 bad_chars.py <inputfile>
"""

import sys

def check_file(path):
    try:
        with open(path, 'r', encoding='utf-8') as f:
            text = f.read()
    except FileNotFoundError:
        print(f"Error: File not found: {path}", file=sys.stderr)
        sys.exit(1)
    except UnicodeDecodeError as e:
        print(f"Error: Could not decode file as UTF-8: {e}", file=sys.stderr)
        sys.exit(1)

    found = False
    for i, c in enumerate(text):
        code = ord(c)
        if code > 127 or (code < 32 and code not in (9, 10, 13)):
            print(f"pos {i}: U+{code:04X} ({repr(c)})")
            found = True

    if not found:
        print("No suspicious characters found.")

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <inputfile>", file=sys.stderr)
        sys.exit(1)
    check_file(sys.argv[1])
