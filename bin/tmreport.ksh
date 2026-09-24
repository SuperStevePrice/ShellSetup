#!/usr/bin/env ksh

#-------------------------------------------------------------------------------
# PROGRAM:
#   ~/bin/tmreport.ksh
#
#
# PURPOSE:
#   Run a set of tmutil (Time Machine utilities) commands and display results
#   to STDOUT. Named tmreport so it never shadows Apple's /usr/bin/tmutil.
#   Results are also written to ~/logs/<HD Name> and copied to the clipboard.
#
# USAGE:
#   ~/bin/tmreport.ksh [HD Name]
#   If no HD Name is given, the first Time Machine destination reported by
#   "tmutil destinationinfo" is used (e.g. UnionSine on the MacBook Pro,
#   easystore on the iMac).
#
# NOTES:
#   Terminal must have Full Disk Access (System Settings > Privacy & Security
#   > Full Disk Access) or tmutil latestbackup/listbackups will fail.
#   The HD Name only names the log file and is checked for being mounted;
#   tmutil itself reports on all configured Time Machine destinations.
#
#-------------------------------------------------------------------------------

if [[ $(uname -s) != Darwin ]]; then
    print -u2 "Error: $(basename $0) runs on macOS only."
    exit 1
fi

if [[ -n "$1" ]]; then
    HD_name="$1"
else
    HD_name=$(tmutil destinationinfo 2>/dev/null \
        | awk -F' : ' '/^Name/ { sub(/[ \t]+$/, "", $2); print $2; exit }')
    if [[ -z "$HD_name" ]]; then
        print -u2 "Error: no Time Machine destination is configured on this Mac."
        exit 1
    fi
fi

if [[ ! -d "/Volumes/$HD_name" ]]; then
    print -u2 "Error: /Volumes/$HD_name is not mounted."
    exit 1
fi

mkdir -p ~/logs
LOG="$HOME/logs/$HD_name"

{ tmutil status; tmutil latestbackup; tmutil listbackups; tmutil destinationinfo; } > "$LOG" 2>&1
pbcopy < "$LOG"
cat "$LOG"

#-------------------------------------------------------------------------------
