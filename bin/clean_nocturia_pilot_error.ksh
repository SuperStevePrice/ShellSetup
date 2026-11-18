#!/bin/ksh
# clean_nocturia_pilot_error.ksh - one-off, NOT a general-purpose tool:
# removes exactly the two pilot-error rows from the night of 2026-11-17
# (02:08 and 03:23, both logged with no amount -- test entries, not
# real events, per Steve's own account) from ~/.nocturia_log.csv.
#
# This is hardcoded to those two specific rows on purpose: an
# amount-less row isn't always a mistake (it can mean "woke up, didn't
# measure"), so this does NOT delete every empty-amount row -- only
# the two you identified as not being real events.
#
# Usage:
#   clean_nocturia_pilot_error.ksh

LOGFILE=~/.nocturia_log.csv

if [[ ! -f "$LOGFILE" ]]; then
    print -u2 "No such file: $LOGFILE"
    exit 1
fi

print "=== Current content ==="
cat -A "$LOGFILE" | sed 's/\$$//'
print ""

BACKUP="${LOGFILE}.before_pilot_error_cleanup.$(date +%Y%m%d_%H%M%S)"
cp "$LOGFILE" "$BACKUP"
print "Backed up to: $BACKUP"
print ""

TMP=$(mktemp)
grep -vF "2026-11-17,02:08,," "$LOGFILE" | grep -vF "2026-11-17,03:23,," > "$TMP"

BEFORE=$(wc -l < "$LOGFILE" | tr -d ' ')
AFTER=$(wc -l < "$TMP" | tr -d ' ')
REMOVED=$((BEFORE - AFTER))

if [[ $REMOVED -ne 2 ]]; then
    print -u2 "Expected to remove exactly 2 rows, but removed $REMOVED instead."
    print -u2 "Nothing written -- the file is unchanged. Check the content above"
    print -u2 "and the exact row text before proceeding."
    rm -f "$TMP"
    exit 1
fi

mv "$TMP" "$LOGFILE"

print "Removed $REMOVED row(s)."
print ""
print "=== Content after cleanup ==="
cat -A "$LOGFILE" | sed 's/\$$//'
