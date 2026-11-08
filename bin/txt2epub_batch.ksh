#!/bin/ksh
#
# txt2epub_batch.ksh - runs txt2epub.ksh over a list of text files.
#
# Usage:
#   ./txt2epub_batch.ksh file1.txt file2.txt ...
#   ./txt2epub_batch.ksh *voll*.txt *full*.txt
#   ./txt2epub_batch.ksh -l list.txt                # filenames read from ~/Documents by default
#   ./txt2epub_batch.ksh -l list.txt extra_one.txt   # list file plus extra names, mixed is fine
#   ./txt2epub_batch.ksh -d ~/Desktop/drafts -l list.txt  # override the default directory
#   ./txt2epub_batch.ksh -y file1.txt file2.txt     # overwrite existing EPUBs, no prompt
#   ./txt2epub_batch.ksh -n file1.txt file2.txt     # skip existing EPUBs, no prompt
#
# -l list.txt reads filenames from list.txt, one per line. Blank lines and
# lines starting with # are ignored, so you can comment a list out freely.
#
# -d DIR looks for every filename inside DIR instead of the default,
# ~/Documents. A filename that's already an absolute path (starts with /)
# is left alone regardless of -d. Each EPUB is written next to its
# source .txt file, so it lands in DIR (or ~/Documents) too.
#
# With no -y or -n, you're asked before any existing .epub is overwritten.
#
# Expects txt2epub.ksh to be in the same directory as this script.

typeset SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
typeset CONVERTER="$SCRIPT_DIR/txt2epub.ksh"

if [[ ! -f "$CONVERTER" ]]; then
    print -u2 "Can't find txt2epub.ksh next to this script in $SCRIPT_DIR"
    exit 1
fi

typeset OVERWRITE="ask"
typeset DIR="$HOME/Documents"
typeset -a FILES=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -y) OVERWRITE="yes"; shift ;;
        -n) OVERWRITE="no"; shift ;;
        -d)
            shift
            DIR="$1"
            if [[ -z "$DIR" ]]; then
                print -u2 "-d requires a directory"
                exit 1
            fi
            if [[ ! -d "$DIR" ]]; then
                print -u2 "Directory not found: $DIR"
                exit 1
            fi
            shift
            ;;
        -l)
            shift
            typeset LISTFILE="$1"
            if [[ -z "$LISTFILE" ]]; then
                print -u2 "-l requires a filename"
                exit 1
            fi
            if [[ ! -f "$LISTFILE" ]]; then
                print -u2 "List file not found: $LISTFILE"
                exit 1
            fi
            while IFS= read -r line || [[ -n "$line" ]]; do
                [[ -z "$line" ]] && continue
                case "$line" in
                    \#*) continue ;;
                esac
                FILES+=("$line")
            done < "$LISTFILE"
            shift
            ;;
        *) FILES+=("$1"); shift ;;
    esac
done

if [[ ${#FILES[@]} -eq 0 ]]; then
    print -u2 "Usage: $0 [-y|-n] [-d directory] [-l listfile] file1.txt file2.txt ..."
    exit 1
fi

# Resolve each filename against -d, unless it's already an absolute path.
if [[ -n "$DIR" ]]; then
    typeset -a RESOLVED=()
    for f in "${FILES[@]}"; do
        case "$f" in
            /*) RESOLVED+=("$f") ;;
            *)  RESOLVED+=("$DIR/$f") ;;
        esac
    done
    FILES=("${RESOLVED[@]}")
fi

typeset -i converted=0
typeset -i skipped=0
typeset -i failed=0
typeset -i notfound=0

for f in "${FILES[@]}"; do
    if [[ ! -f "$f" ]]; then
        print "NOT FOUND:  $f"
        notfound=$((notfound+1))
        continue
    fi
    case "$f" in
        *.txt) ;;
        *) print "SKIP (not .txt):  $f"; skipped=$((skipped+1)); continue ;;
    esac

    typeset out="${f%.txt}.epub"

    if [[ -f "$out" ]]; then
        case "$OVERWRITE" in
            yes) : ;;
            no)  print "SKIP (exists):  $out"; skipped=$((skipped+1)); continue ;;
            *)
                print -n "EPUB already exists: $out - overwrite? [y/N] "
                read ans
                case "$ans" in
                    y|Y) : ;;
                    *) print "SKIP:  $out"; skipped=$((skipped+1)); continue ;;
                esac
                ;;
        esac
    fi

    if "$CONVERTER" "$f" "$out" >/dev/null 2>&1; then
        print "OK:  $f -> $out"
        converted=$((converted+1))
    else
        print "FAILED:  $f"
        failed=$((failed+1))
    fi
done

print "----------------------------------------------------------------------"
print "Converted: $converted   Skipped: $skipped   Not found: $notfound   Failed: $failed"
