#!/usr/bin/env ksh
#-------------------------------------------------------------------------------
# PROGRAM:
#	ssh-copy-id.ksh
#	
# PURPOSE:
#	Copy the ~/.ssh/id_rsa.pub key to each machine in /etc/hosts.
#	
#-------------------------------------------------------------------------------
user=$USER

# Read the IP addresses and machine names from /etc/hosts
hosts=($(grep -E "^10\.0\.0\.[0-9]+\s+" /etc/hosts |\
    awk '{print $1, $2, $3, $4}'))

let idx=0
# Loop through the hosts array and run ssh-copy-id on each machine
for host in "${hosts[@]}"; do
    # Extract the IP address and machine names from the current host
    read ip_addr machine_names <<< "$host"

    print "ssh-copy-id  $user@$host"
	ssh-copy-id  "$user@$host"
    
	idx=$((idx + 1))
    if [ $idx -eq 4 ]
    then
		print
		idx=0
	fi 
done
#-------------------------------------------------------------------------------
# Last installed: 2023-04-30 15:18:44
