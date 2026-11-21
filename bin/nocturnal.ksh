#!/bin/ksh
#-------------------------------------------------------------------------------
# File:
#   nocturnal.ksh
#
# PURPOSE:
#   Opens a fresh, empty, timestamped file in vi so Steve can paste in
#   (Cmd-V) the "nocturnal_log" command lines copied from the Nocturnal
#   Log app on his iPhone, then save and quit. Does not run or otherwise
#   process the file afterward - that is nocturnal_log.ksh's job.
#
# USAGE:
#   nocturnal.ksh          (deployed as alias "nk")
#-------------------------------------------------------------------------------

SCRIPT_NAME=$(basename "$0" .ksh)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOGDIR="$HOME/logs"
LOGFILE="$LOGDIR/${SCRIPT_NAME}.${TIMESTAMP}.log"

mkdir -p "$LOGDIR"

cd ~/Downloads || exit 1

CMDFILE="nocturnal_cmds_${TIMESTAMP}.ksh"

{
    print "=== nocturnal.ksh: starting $(date) ==="
    print "Opening $CMDFILE in vi."
    print "Paste (Cmd-V) the nocturnal_log commands copied from the"
    print "Nocturnal Log app on your iPhone, then save and quit."
} 2>&1 | tee -a "$LOGFILE"

# vi needs direct terminal access for its screen drawing, so it is run
# outside the logging pipe - piping it through tee would break its
# interactive display.
vi "$CMDFILE"

{
    print "$CMDFILE saved. nocturnal.ksh takes no further action -"
    print "nocturnal_log.ksh handles the file from here."
    print ""
    print "=== nocturnal.ksh: finished $(date) ==="
    print "See: $LOGFILE"
} 2>&1 | tee -a "$LOGFILE"
