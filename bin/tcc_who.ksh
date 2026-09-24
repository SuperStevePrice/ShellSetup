#!/usr/bin/env ksh

#-------------------------------------------------------------------------------
# PROGRAM:
#   ~/bin/tcc_who.ksh
#
#
# PURPOSE:
#   Find out which program macOS holds responsible for Full Disk Access (FDA)
#   in the current terminal. It triggers an FDA check, then reads the TCC
#   (privacy) entries from the unified log and prints the responsible and
#   requesting binary paths. The "responsible_path" is what needs to be added
#   in System Settings > Privacy & Security > Full Disk Access.
#
# USAGE:
#   ~/bin/tcc_who.ksh
#   Run it in the terminal window you want to diagnose (e.g. an xterm).
#
#-------------------------------------------------------------------------------

LOG=~/logs/tcc_who.log
mkdir -p ~/logs

start=$(date '+%Y-%m-%d %H:%M:%S')
sleep 1

print "Triggering Full Disk Access checks..."
ls ~/Library/Mail >/dev/null 2>&1 && print "  ~/Library/Mail: allowed" \
                                  || print "  ~/Library/Mail: DENIED"
tmutil latestbackup >/dev/null 2>&1 && print "  tmutil latestbackup: allowed" \
                                    || print "  tmutil latestbackup: DENIED"

sleep 3
print "\nReading TCC log entries since $start ..."

log show --start "$start" --info --debug \
    --predicate 'subsystem == "com.apple.TCC"' > $LOG 2>&1

print "  $(wc -l < $LOG | tr -d ' ') log lines saved to $LOG"

print "\n------------------------------------------------------------"
print "Responsible programs (add THESE to Full Disk Access)"
print "------------------------------------------------------------"
grep -o 'responsible_path=[^,}]*' $LOG | sort -u \
    || print "  (none found)"

print "\n------------------------------------------------------------"
print "Requesting programs"
print "------------------------------------------------------------"
grep -o 'binary_path=[^,}]*' $LOG | sort -u \
    || print "  (none found)"

print "\n------------------------------------------------------------"
print "Full Disk Access results (authValue=0 means denied)"
print "------------------------------------------------------------"
grep -E 'AUTHREQ_RESULT' $LOG | grep -i 'AllFiles' | tail -5 \
    || print "  (none found)"

print "\nIf the sections above are empty, send the last 40 lines of $LOG:"
print "  tail -40 $LOG | pbcopy"

#-------------------------------------------------------------------------------
