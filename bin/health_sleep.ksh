#!/bin/ksh
# health_sleep.ksh - wrapper for health_sleep.py
# English output only.
# Logs each run to ~/logs/sleep_TIMESTAMP.log, then echoes that log to stdout.

here=${0%/*}
[[ "$here" == "$0" ]] && here=.

if [[ $# -lt 1 ]]; then
    print -u2 "Usage: ${0##*/} export.xml|export.zip [-n nights] [-d YYYY-MM-DD] [-c out.csv] [--since YYYY-MM-DD] [--include-naps] [--night-start H] [--night-end H]"
    exit 1
fi

logdir=~/logs
mkdir -p "$logdir"
ts=$(date +%Y%m%d_%H%M%S)
logfile="$logdir/sleep_${ts}.log"

python3 "$here/health_sleep.py" "$@" > "$logfile" 2>&1
cat "$logfile"
print "See: $logfile"
