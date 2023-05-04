#!/usr/bin/env ksh

#-------------------------------------------------------------------------------
#         Copyright (C) 2023    Steve Price    SuperStevePrice@gmail.com
#
#                       GNU GENERAL PUBLIC LICENSE
#                        Version 3, 29 June 2007
#-------------------------------------------------------------------------------
# PROGRAM:
#	PS1.ksh
#	
# PURPOSE:
#	Set up $PS1 which controls command line prompt string.
#	
# USAGE:
#	source ~/bin/PS1.ksh
#-------------------------------------------------------------------------------
# PS1: command line primary prompt:
host=$(uname -n)
export server_abbreviated=${host%%.*}

export PS1="$server_abbreviated <\$PWD [\!]>
$LOGNAME@$host: "
