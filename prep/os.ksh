#!/usr/bin/env ksh

#-------------------------------------------------------------------------------
# Copyright (C) 2023  Steve Price	SuperStevePrice@gmail.com
#
#                  GNU GENERAL PUBLIC LICENSE
#                     Version 3, 29 June 2007
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# PROGRAM:
#	os.ksh
#	
# PURPOSE:
#	Print the operating system and version number.
#	
# USAGE:
#	os.ksh
#
#-------------------------------------------------------------------------------

os_version() {
    if [[ $(uname -s) == "Darwin" ]]; then
        os=$(sw_vers -productName)
        os+=" $(sw_vers -productVersion)"
    elif [[ $(uname -s) == "Linux" ]]; then
        os=$(lsb_release -sd)
    fi
    echo "$os"
}

echo "OS version: $(os_version)"
