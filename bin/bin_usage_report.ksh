#!/bin/ksh

#-------------------------------------------------------------------------------
# PROGRAM:
#   bin_usage_report.ksh
# 
# PURPOSE:
#   Wrapper for bin_usage_report.py
#
#   bin_usage_report.ksh - wrapper for bin_usage_report.py. Regenerates
#   ~/Documents/bin_usage.txt, the quick reference of every executable in
#   ~/bin (Description / Usage / Notes per file).
# 
# USAGE:
#   bin_usage_report or 
#
#   bin_usage_report.ksh
#-------------------------------------------------------------------------------


here=${0%/*}
[[ "$here" == "$0" ]] && here=.

exec python3 "$here/bin_usage_report.py" "$@"

print "\nSee: ~/Documents/bin_usage.txt"
