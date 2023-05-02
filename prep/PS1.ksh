#!/usr/bin/env ksh

# PS1: command line primary prompt:
host=$(uname -n)
export server_abbreviated=${host%%.*}

export PS1="$server_abbreviated <\$PWD [\!]>
$LOGNAME@$host: "
# Last modified: 2023-04-25 19:18:11
