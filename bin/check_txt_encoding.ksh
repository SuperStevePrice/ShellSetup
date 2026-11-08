#!/bin/ksh
#
# check_txt_encoding.ksh
#
# Scans .txt files (the ones used by speak/speak-loop) for non-UTF-8
# encoding. This is the most likely reason Calibre imports a file as
# blank/graphic-only while TextEdit, vi, and speak/speak-loop show it
# fine — those tools are forgiving about encoding; Calibre's TXT
# importer is not. Text pulled from a web page and pasted into vi
# often carries Windows-1252/Latin-1 bytes (smart quotes, dashes,
# non-breaking spaces) even when the rest of the file looks like
# plain ASCII.
#
# Usage:
#   ./check_txt_encoding.ksh [directory]        # report only
#   ./check_txt_encoding.ksh [directory] -fix   # report AND convert
#
#   Directory defaults to ~/Documents if omitted.
#   -fix can go before or after the directory argument.
#
# Converted files are backed up first as <name>.txt.bak before being
# overwritten with a UTF-8 version. Nothing is deleted.

typeset DIR="$HOME/Documents"
typeset FIX="no"

for arg in "$@"; do
    case "$arg" in
        -fix) FIX="yes" ;;
        *)    DIR="$arg" ;;
    esac
done

if [[ ! -d "$DIR" ]]; then
    print -u2 "Directory not found: $DIR"
    exit 1
fi

print "Scanning: $DIR"
if [[ "$FIX" == "yes" ]]; then
    print "Mode: report + fix (backups saved as <file>.bak)"
else
    print "Mode: report only (re-run with -fix to convert)"
fi
print "----------------------------------------------------------------------"
printf "%-40s %-18s %s\n" "FILE" "ENCODING" "ACTION"
print "----------------------------------------------------------------------"

find "$DIR" -maxdepth 1 -type f -name "*.txt" -print | sort | while IFS= read -r f; do
    base=$(basename "$f")
    enc=$(file -b --mime-encoding "$f" 2>/dev/null)

    case "$enc" in
        utf-8|us-ascii)
            action="OK"
            ;;
        binary)
            action="SKIP (not text)"
            ;;
        *)
            if [[ "$FIX" == "yes" ]]; then
                cp "$f" "${f}.bak"
                if iconv -f "$enc" -t UTF-8 "${f}.bak" > "$f" 2>/dev/null; then
                    action="CONVERTED (backup: ${base}.bak)"
                else
                    action="FAILED - try manually: iconv -f WINDOWS-1252 -t UTF-8"
                fi
            else
                action="NEEDS CONVERSION (run with -fix)"
            fi
            ;;
    esac

    printf "%-40s %-18s %s\n" "$base" "$enc" "$action"
done

print "----------------------------------------------------------------------"
print "Done. Any file not marked OK is a likely cause of Calibre's"
print "blank/graphic-only conversions. After fixing, re-add/re-convert"
print "the file in Calibre with TXT Input encoding set to utf-8."
