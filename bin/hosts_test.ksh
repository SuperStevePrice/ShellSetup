#!/usr/bin/env ksh

#-------------------------------------------------------------------------------
# PROGRAM:
#	hosts_test.ksh
#	
# PURPOSE:
#	Run ssh on each IP in /etc/hosts
#	
# USAGE:
#	hosts_test.ksh
#
#-------------------------------------------------------------------------------
#
# Host Database
# localhost is used to configure the loopback interface
# when the system is booting.  Do not change this entry.
##
# `127.0.0.1    localhost
# `255.255.255.255    broadcasthost
# `::1             localhost
# `10.0.0.147    Steves-iMac.localdomain    Steves-iMac iMac
# `10.0.0.212    MacBook-Linux.localdomain MacBook-Linux StevesMacBook-Linux
# `10.0.0.198    iMac-Linux.localdomain    iMac-Linux StevesiMac-Linux
# `10.0.0.245    StevesMacBook-Pro.local    StevesMacBook-Pro MacBook
#-------------------------------------------------------------------------------
ips=" 10.0.0.147    10.0.0.212    10.0.0.198    10.0.0.245"
for ip in $(print $ips)
do
	print "ssh $ip"
	ssh $ip
done

