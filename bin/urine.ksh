#!/bin/ksh
#-------------------------------------------------------------------------------
# File:
#   urine.ksh
#
# PURPOSE:
#   Opens a fresh, empty, timestamped file in vi so Steve can paste in
#   (Cmd-V) the "urine_log" command lines copied from the Urine
#   Log app on his iPhone, then save and quit. Does not run or otherwise
#   process the file afterward - that is urine_log.ksh's job.
#
# USAGE:
#   urine.ksh          (deployed as alias "nk", and as "nocturnal" for the old name)
#-------------------------------------------------------------------------------

SCRIPT_NAME=$(basename "$0" .ksh)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOGDIR="$HOME/logs"
LOGFILE="$LOGDIR/${SCRIPT_NAME}.${TIMESTAMP}.log"

mkdir -p "$LOGDIR"

cd ~/Downloads || exit 1

CMDFILE="urine_cmds_${TIMESTAMP}.ksh"

{
    print "=== urine.ksh: starting $(date) ==="
    print "Opening $CMDFILE in vi."
    print "Paste (Cmd-V) the urine_log commands copied from the"
    print "Urine Log app on your iPhone, then save and quit."
} 2>&1 | tee -a "$LOGFILE"

# vi needs direct terminal access for its screen drawing, so it is run
# outside the logging pipe - piping it through tee would break its
# interactive display. When urine.ksh is itself run inside a pipe (e.g.
# all_sleep tees its output to a log), stdout is that pipe, so vi is
# pointed straight at the terminal to avoid "Output is not to a terminal".
vi "$CMDFILE" </dev/tty >/dev/tty

{
    print "$CMDFILE saved. urine.ksh takes no further action -"
    print "urine_log.ksh handles the file from here."
    print ""
    print "=== urine.ksh: finished $(date) ==="
    print "See: $LOGFILE"
} 2>&1 | tee -a "$LOGFILE"
#-------------------------------------------------------------------------------
# Last installed: 2026-11-20 21:10:08
#-- End of File ----------------------------------------------------------------
