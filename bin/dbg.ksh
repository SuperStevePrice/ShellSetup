#!/usr/bin/env ksh

#-------------------------------------------------------------------------------
#         Copyright (C) 2023    Steve Price    SuperStevePrice@gmail.com
#
#                       GNU GENERAL PUBLIC LICENSE
#                        Version 3, 29 June 2007
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# PROGRAM:
#	dbg.ksh
#	
# PURPOSE:
#   This ksh script provides a ksh function, dbg() to print and log DEBUG 
#   messages.
#	
# USAGE:
#   source dbg.ksh  # from another ksh that wishes to use dbg.ksh
#   dbg $msg        # invoking dbg with a message to print and log
#
#   dbg will prepend "DEBUG: line:" to $msg.
#-------------------------------------------------------------------------------
dbg() {
    log_dir=~/logs
    if [ ! -d "$log_dir" ]; then
        echo "mkdir -p $log_dir > /dev/null 2>&1"
        mkdir -p "$log_dir" > /dev/null 2>&1
    fi

    debug_file=$log_dir/$0.debug.$$

    if [ ! -f "$debug_file" ]; then
        echo "Script: $0" >> "$debug_file"
    fi

    msg="DEBUG: line:$1"
    echo "$msg"
    echo "$msg" >> "$debug_file"
}
