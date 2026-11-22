#!/usr/bin/env python3
"""
clean_text.py - Replace U+2028 (Line Separator) and other problem characters
                in a text file with safe equivalents.
Usage: python3 clean_text.py <inputfile> <outputfile>
"""

import sys

# Characters to replace: { U+XXXX: replacement }
REPLACEMENTS = {
    '\u2028': '\n',   # Line Separator -> newline
    '\u2029': '\n',   # Paragraph Separator -> newline
}

def clean_file(inpath, outpath):
    try:
        with open(inpath, 'r', encoding='utf-8') as f:
            text = f.read()
    except FileNotFoundError:
        print(f"Error: Input file not found: {inpath}", file=sys.stderr)
        sys.exit(1)
    except UnicodeDecodeError as e:
        print(f"Error: Could not decode file as UTF-8: {e}", file=sys.stderr)
        sys.exit(1)

    count = 0
    for bad, good in REPLACEMENTS.items():
        occurrences = text.count(bad)
        if occurrences:
            print(f"Replacing {occurrences} occurrence(s) of U+{ord(bad):04X} ({repr(bad)})")
            text = text.replace(bad, good)
            count += occurrences

    try:
        with open(outpath, 'w', encoding='utf-8') as f:
            f.write(text)
    except IOError as e:
        print(f"Error: Could not write output file: {e}", file=sys.stderr)
        sys.exit(1)

    if count:
        print(f"Done. {count} replacement(s) written to {outpath}")
    else:
        print("No problematic characters found. Clean copy written.")

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <inputfile> <outputfile>", file=sys.stderr)
        sys.exit(1)
    clean_file(sys.argv[1], sys.argv[2])
