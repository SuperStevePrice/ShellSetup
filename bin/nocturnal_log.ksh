#!/bin/ksh
# nocturnal_log.ksh - "Nocturnal Voiding" log wrapper for nocturnal_log.py
# Logs nighttime urination time + amount (oz) for the sleep study.
# English output only.
#
# Called with no arguments, this finds and processes the latest pending
# nocturnal_cmds_*.ksh file in ~/Downloads (see nocturnal_log.py for the
# full logic: missing file, empty file, freshness check, and archiving
# to ~/tests/nocturnal_cmds/ once consumed).
#
# This wrapper keeps its own short log of each invocation (dispatched to
# nocturnal_log.py, with what exit status) written straight to disk, not
# shown live - nocturnal_log.py runs directly (not piped) and keeps its
# own separate, detailed log of what it actually did. Python's output is
# never piped here, since the empty-cmds-file case hands control to vi,
# which needs direct terminal access.

here=${0%/*}
[[ "$here" == "$0" ]] && here=.

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    print -u2 "Nocturnal Voiding log — usage:"
    print -u2 "  ${0##*/}                                  # process pending nocturnal_cmds_*.ksh file"
    print -u2 "  ${0##*/} HH:MM [AMOUNT_OZ] [\"notes\"] [-d YYYY-MM-DD]"
    print -u2 "  ${0##*/} -l [-n N] [--night YYYY-MM-DD]"
    print -u2 "  ${0##*/} -r"
    print -u2 ""
    print -u2 "Examples:"
    print -u2 "  ${0##*/}                               # run tonight's pasted commands"
    print -u2 "  ${0##*/} 02:15 5"
    print -u2 "  ${0##*/} 03:40 3 \"urgent, small amount\""
    print -u2 "  ${0##*/} 23:50 4 -d 2026-11-02         # log for last night, after midnight"
    print -u2 "  ${0##*/} -l                            # list recent nights"
    print -u2 "  ${0##*/} -l --night 2026-11-03          # list just one night"
    print -u2 "  ${0##*/} -r                            # write nocturnal.pdf/.xlsx to the Desktop"
    exit 1
fi

SCRIPT_NAME=$(basename "$0" .ksh)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOGDIR="$HOME/logs"
LOGFILE="$LOGDIR/${SCRIPT_NAME}_wrapper.${TIMESTAMP}.log"

mkdir -p "$LOGDIR"

{
    print "=== nocturnal_log.ksh: starting $(date) ==="
    print "Dispatching to: nocturnal_log.py $*"
} >> "$LOGFILE"

python3 "$here/nocturnal_log.py" "$@"
STATUS=$?

{
    print "nocturnal_log.py exited with status $STATUS."
    print "=== nocturnal_log.ksh: finished $(date) ==="
    print "See: $LOGFILE"
} >> "$LOGFILE"

exit $STATUS
#-------------------------------------------------------------------------------
# Last installed: 2026-11-20 07:49:26
#-- End of File ----------------------------------------------------------------
