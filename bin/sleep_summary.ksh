#!/bin/ksh
#-------------------------------------------------------------------------------
# File:
#   sleep_summary.ksh
#
# PURPOSE:
#   One-page overview of the sleep study: urine (urine_log), Apple Watch
#   sleep (sleep_study.db) and ResMed myAir figures, with averages, medians
#   and totals. Prints it and writes sleep_summary.pdf/.xlsx to the Desktop.
#   Last step of all_sleep.ksh, so it sees that morning's fresh data.
#
# USAGE:
#   sleep_summary.ksh [--since YYYY-MM-DD] [--no-files] [--no-prompt]
#-------------------------------------------------------------------------------
here=${0%/*}
[[ "$here" == "$0" ]] && here=.

LOGDIR="$HOME/logs"
mkdir -p "$LOGDIR"
LOGFILE="$LOGDIR/sleep_summary.$(date +%Y%m%d_%H%M%S).log"

set -o pipefail
python3 "$here/sleep_summary.py" "$@" 2>&1 | tee -a "$LOGFILE"
STATUS=$?
print "See: $LOGFILE" | tee -a "$LOGFILE"
exit $STATUS
