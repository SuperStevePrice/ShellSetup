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
    #---------------------------------------------------------------------------
    # Function dbg()
    #
    # Purpose:
    #   Given a string message, log it in $debug_file and print the message.
    #
    # Usage:
    #   dbg message
    #---------------------------------------------------------------------------
    debug_file=~/Documents/$0.debug.$$

    if [ ! -f "$debug_file" ]; then
        echo "Script: $0" >> "$debug_file"
    fi

    msg="DEBUG: line:$1"
    echo "$msg"
    echo "$msg" >> "$debug_file"
} # dbg()
