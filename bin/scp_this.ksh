#!/usr/bin/env ksh

#-------------------------------------------------------------------------------
# Copyright (C) 2023  Steve Price	SuperStevePrice@gmail.com
#
#                  GNU GENERAL PUBLIC LICENSE
#                     Version 3, 29 June 2007
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# PROGRAM:
#	scp_this.ksh
#	
# PURPOSE:
#	scp a source file or directory to the same path, or to a given target
#	path, on every other machine in the Tailscale network (via tss).
#	
# USAGE:
#	scp_this.ksh source target
#
#	target is the destination path on each remote machine. Use a bare
#	relative filename (e.g. "notes.txt") to land in the remote user's
#	home directory regardless of OS — this matters because your Mac and
#	Linux home directories live at different absolute paths
#	(/Users/steve vs /home/steve), so an absolute source path won't
#	necessarily exist as a valid destination on every machine.
#
#-------------------------------------------------------------------------------

typeset scp
scp=$(which scp)

# Validate command line parameters:
if [ $# -ne 2 ]
then
	print "Usage: $0 source target"
	exit 1
fi

source=$1
target=$2

if [ -d "$source" ]
then
	scp="$scp -r"
elif [ ! -f "$source" ]
then
	print "Source does not exist or is not a regular file or directory: $source"
	exit 1
fi

user=$USER

# Copy to every other machine in the Tailscale network. Don't scp to the
# local machine. Host discovery uses tss (Tailscale status), same
# convention as update-linux-hosts.ksh — NOT /etc/hosts, since not every
# machine is necessarily listed there.
scp_source() {
	source=$1
	target=$2

	# Tailscale lowercases hostnames in its status output, but the
	# system's own `hostname` command may not — compare case-insensitively
	# so the local machine is correctly recognized and skipped.
	typeset -l local_host
	local_host=$(hostname | sed 's/\.local//g')

	tss | awk '{print $2}' | while read -r server
	do
		typeset -l server_lc
		server_lc="$server"

		if [ "$server_lc" != "$local_host" ]
		then
			print "$scp $source $user@$server:$target"
			$scp $source $user@$server:$target
			# Check for successful scp
			if [ "$?" -eq 0 ]
			then
				print "File copied successfully to $user@$server:$target"
			else
				print "Failed to copy file to $user@$server:$target"
			fi
		else
			print "No scp performed for local server, $server"
		fi
		print
	done
}

#-------------------------------------------------------------------------------
# MAIN:
#-------------------------------------------------------------------------------
print "Transfer Beginning"
scp_source "$source" "$target"
print "Transfer Complete"
#-------------------------------------------------------------------------------
# Last installed: 2023-07-07 00:12:49
#-- End of File ----------------------------------------------------------------
