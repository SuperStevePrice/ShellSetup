#!/bin/ksh
# Run this ON THE MAC. It copies nopasswd-apt-update.ksh to each
# Linux host and executes it there (you'll be prompted for that
# host's sudo password once, interactively, during setup only).

for ip in $(tss | grep -i linux | awk '{print $1}')
do
    print "== $ip =="
    scp nopasswd-apt-update.ksh "$ip:/tmp/nopasswd-apt-update.ksh"
    ssh -t "$ip" "ksh /tmp/nopasswd-apt-update.ksh && rm /tmp/nopasswd-apt-update.ksh"
    print ""
done
