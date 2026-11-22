#!/bin/ksh

#-------------------------------------------------------------------------------
# Copyright (C) 2026 Steve Price SuperStevePrice@gmail.com
#
# GNU GENERAL PUBLIC LICENSE
# Version 3, 29 June 2007
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# PROGRAM:
#	safari_start.ksh
#
# PURPOSE:
#   ksh script to start Safari with a nature slideshow.
#
# USAGE:
#	safari_start.ksh
#-------------------------------------------------------------------------------

URL="file:///Users/steve/Pictures/ChangingImages/start.html"

# Start Safari if it's not already running
if ! pgrep -x Safari >/dev/null 2>&1 ; then
    open -a Safari
    sleep 1
fi

# Open the desired page
open -a safari "$URL"

exit 0
