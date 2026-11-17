#!/bin/ksh
#
# bin_usage_report.ksh - wrapper for bin_usage_report.py. Regenerates
# ~/Documents/bin usage.txt, the quick reference of every executable in
# ~/bin (Description / Usage / Notes per file).
#
# Usage:
#   bin_usage_report

here=${0%/*}
[[ "$here" == "$0" ]] && here=.

exec python3 "$here/bin_usage_report.py" "$@"
