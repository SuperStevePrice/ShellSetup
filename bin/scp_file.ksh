#!/usr/bin/env ksh
#-------------------------------------------------------------------------------
# PROGRAM:
#   scp_file.ksh
#
# PURPOSE:
#   Copy a given file to a series of IP addresses
#
# USAGE:
#   scp_file.ksh file_to_copy
#
#-------------------------------------------------------------------------------

REMOTE_USER=steve
HOSTS="100.73.104.80 100.112.55.50 100.77.201.99 100.113.102.87"

file=$1

if [[ -z $file ]]
then
    print -u2 "Usage: ${0##*/} file_to_copy"
    exit 1
fi

if [[ ! -f $file ]]
then
    print -u2 "${0##*/}: cannot read file: $file"
    exit 1
fi

for IP in $HOSTS
do
    echo "scp $file $REMOTE_USER@$IP:~"
    if scp "$file" "$REMOTE_USER@$IP:~"
    then
        echo "  OK:     $IP"
    else
        echo "  FAILED: $IP"
    fi
    echo
done
