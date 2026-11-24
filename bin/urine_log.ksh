#!/bin/ksh
# urine_log.ksh - Urine Log wrapper for urine_log.py
# Logs every urination, day and night: time + amount (oz).
# English output only.
#
# Called with no arguments, this finds and processes the latest pending
# urine_cmds_*.ksh file in ~/Downloads (see urine_log.py for the
# full logic: missing file, empty file, freshness check, and archiving
# to ~/tests/urine_cmds/ once consumed).
#
# This wrapper keeps its own short log of each invocation (dispatched to
# urine_log.py, with what exit status) written straight to disk, not
# shown live - urine_log.py runs directly (not piped) and keeps its
# own separate, detailed log of what it actually did. Python's output is
# never piped here, since the empty-cmds-file case hands control to vi,
# which needs direct terminal access.

here=${0%/*}
[[ "$here" == "$0" ]] && here=.

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    print -u2 "Urine Log — usage:"
    print -u2 "  ${0##*/}                                  # process pending urine_cmds_*.ksh file"
    print -u2 "  ${0##*/} HH:MM [AMOUNT_OZ] [\"notes\"] [-d YYYY-MM-DD] [--day | --as-night]"
    print -u2 "  ${0##*/} -l [-n N] [--on YYYY-MM-DD | --night YYYY-MM-DD]"
    print -u2 "  ${0##*/} -r"
    print -u2 ""
    print -u2 "Examples:"
    print -u2 "  ${0##*/}                               # run the pasted commands"
    print -u2 "  ${0##*/} 02:15 5"
    print -u2 "  ${0##*/} 03:40 3 \"urgent, small amount\""
    print -u2 "  ${0##*/} 23:50 4 -d 2026-11-02         # event on a given calendar date"
    print -u2 "  ${0##*/} -l                            # list recent 24-hour periods"
    print -u2 "  ${0##*/} -l --on 2026-11-03             # list one 24-hour period"
    print -u2 "  ${0##*/} -r                            # write urine_log.pdf/.xlsx to the Desktop"
    exit 1
fi

SCRIPT_NAME=$(basename "$0" .ksh)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOGDIR="$HOME/logs"
LOGFILE="$LOGDIR/${SCRIPT_NAME}_wrapper.${TIMESTAMP}.log"

mkdir -p "$LOGDIR"

{
    print "=== urine_log.ksh: starting $(date) ==="
    print "Dispatching to: urine_log.py $*"
} >> "$LOGFILE"

python3 "$here/urine_log.py" "$@"
STATUS=$?

{
    print "urine_log.py exited with status $STATUS."
    print "=== urine_log.ksh: finished $(date) ==="
    print "See: $LOGFILE"
} >> "$LOGFILE"

exit $STATUS
#-------------------------------------------------------------------------------
# Last installed: 2026-11-20 07:49:26
#-- End of File ----------------------------------------------------------------
