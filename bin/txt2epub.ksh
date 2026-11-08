#!/bin/ksh
#
# txt2epub.ksh - converts a plain text poem/document into a minimal,
# well-formed EPUB that preserves every line break exactly as written.
#
# This bypasses Calibre's TXT importer entirely, so there is no
# paragraph-reflow guessing to fight with. Every line of the source
# file becomes its own line in the output. Blank lines become stanza
# breaks (a bit of vertical space, nothing more).
#
# Usage:
#   ./txt2epub.ksh input.txt [output.epub]
#
# If output.epub is omitted, input.epub is written next to input.txt.
# The first non-blank line of the file is used as the book's title
# metadata (not shown twice - it's still the first line of the text).

typeset IN="$1"
typeset OUT="$2"

if [[ -z "$IN" ]]; then
    print -u2 "Usage: $0 input.txt [output.epub]"
    exit 1
fi
if [[ ! -f "$IN" ]]; then
    print -u2 "File not found: $IN"
    exit 1
fi

[[ -z "$OUT" ]] && OUT="${IN%.txt}.epub"

case "$OUT" in
    /*) OUT_ABS="$OUT" ;;
    *)  OUT_ABS="$(pwd)/$OUT" ;;
esac

# Title (for metadata only) = first non-blank line of the file.
typeset TITLE=$(awk 'NF{print; exit}' "$IN")
[[ -z "$TITLE" ]] && TITLE=$(basename "$IN" .txt)
typeset TITLE_ESC=$(print "$TITLE" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')

typeset UUID=$(uuidgen 2>/dev/null)
[[ -z "$UUID" ]] && UUID="00000000-0000-0000-0000-000000000000"

typeset WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

mkdir -p "$WORKDIR/META-INF" "$WORKDIR/OEBPS/text" "$WORKDIR/OEBPS/css"

# mimetype must be the first entry in the zip and stored uncompressed.
print -n "application/epub+zip" > "$WORKDIR/mimetype"

cat > "$WORKDIR/META-INF/container.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
EOF

cat > "$WORKDIR/OEBPS/css/style.css" <<'EOF'
body { font-family: serif; margin: 1em; }
p.line { margin: 0; padding: 0; text-align: left; white-space: pre-wrap; }
p.stanza-break { margin: 0; padding: 0; height: 1em; }
EOF

# Build the body: one <p class="line"> per source line, no reflowing.
# Blank lines become stanza breaks. & < > are XML-escaped.
{
    print '<?xml version="1.0" encoding="UTF-8"?>'
    print '<!DOCTYPE html>'
    print '<html xmlns="http://www.w3.org/1999/xhtml">'
    print '<head>'
    print "<title>${TITLE_ESC}</title>"
    print '<link rel="stylesheet" type="text/css" href="../css/style.css"/>'
    print '</head>'
    print '<body>'

    sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' "$IN" | while IFS= read -r line; do
        if [[ -z "$line" ]]; then
            print '<p class="stanza-break">&#160;</p>'
        else
            print "<p class=\"line\">${line}</p>"
        fi
    done

    print '</body>'
    print '</html>'
} > "$WORKDIR/OEBPS/text/chapter1.xhtml"

cat > "$WORKDIR/OEBPS/content.opf" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" unique-identifier="BookId" version="2.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf">
    <dc:title>${TITLE_ESC}</dc:title>
    <dc:language>und</dc:language>
    <dc:identifier id="BookId" opf:scheme="UUID">${UUID}</dc:identifier>
  </metadata>
  <manifest>
    <item id="chapter1" href="text/chapter1.xhtml" media-type="application/xhtml+xml"/>
    <item id="css" href="css/style.css" media-type="text/css"/>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
  </manifest>
  <spine toc="ncx">
    <itemref idref="chapter1"/>
  </spine>
</package>
EOF

cat > "$WORKDIR/OEBPS/toc.ncx" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="${UUID}"/>
    <meta name="dtb:depth" content="1"/>
  </head>
  <docTitle><text>${TITLE_ESC}</text></docTitle>
  <navMap>
    <navPoint id="navpoint-1" playOrder="1">
      <navLabel><text>${TITLE_ESC}</text></navLabel>
      <content src="text/chapter1.xhtml"/>
    </navPoint>
  </navMap>
</ncx>
EOF

rm -f "$OUT_ABS"
(cd "$WORKDIR" && zip -X -0 "$OUT_ABS" mimetype) >/dev/null
(cd "$WORKDIR" && zip -X -r -9 -D "$OUT_ABS" META-INF OEBPS) >/dev/null

if [[ -f "$OUT_ABS" ]]; then
    print "Wrote: $OUT_ABS"
else
    print -u2 "Something went wrong - no EPUB was produced."
    exit 1
fi
