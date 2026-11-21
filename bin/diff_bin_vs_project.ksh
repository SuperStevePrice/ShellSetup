#!/bin/ksh
# diff_bin_vs_project.ksh
#
# Compares every file in ~/Projects/SS/bin against its installed
# counterpart in ~/bin, ignoring the last 3 lines of the installed
# copy (the "last installed" trailer that setup.ksh appends).

SCRIPT_NAME=${0##*/}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOGDIR="$HOME/logs"
LOGFILE="$LOGDIR/${SCRIPT_NAME}.${TIMESTAMP}.log"
mkdir -p "$LOGDIR"

SRC_DIR="$HOME/Projects/SS/bin"
BIN_DIR="$HOME/bin"
TRAILER_LINES=3

run() {
    print "Comparing files in $SRC_DIR"
    print "          against  $BIN_DIR"
    print "(ignoring the last $TRAILER_LINES lines of each installed bin file)"
    print ""

    typeset projfile base binfile trimmed total_lines keep_lines
    typeset any_diffs=0

    for projfile in "$SRC_DIR"/*; do
        [[ -f $projfile ]] || continue
        base=${projfile##*/}
        binfile="$BIN_DIR/$base"

        if [[ ! -f $binfile ]]; then
            print "=== $base: no installed copy in $BIN_DIR, skipping ==="
            print ""
            continue
        fi

        trimmed=$(mktemp "${TMPDIR:-/tmp}/${base}.trimmed.XXXXXX")
        total_lines=$(wc -l < "$binfile")
        keep_lines=$(( total_lines - TRAILER_LINES ))
        (( keep_lines < 0 )) && keep_lines=0
        head -n "$keep_lines" "$binfile" > "$trimmed"

        print "=== $base ==="
        if diff -u "$projfile" "$trimmed"; then
            print "(no differences)"
        else
            any_diffs=1
        fi
        print ""

        rm -f "$trimmed"
    done

    if (( any_diffs == 0 )); then
        print "Summary: every project file matches its installed copy (trailer excluded)."
    else
        print "Summary: differences found above - review before running your git companion script."
    fi
}

run 2>&1 | tee -a "$LOGFILE"

print "See: $LOGFILE"
