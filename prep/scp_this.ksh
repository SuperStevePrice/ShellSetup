#!/usr/bin/env ksh

# Modify by adding -r for transferring folders.
scp=$(which scp)
print "DEBUG0: $scp"

# Validate command line parameters:
if [ $# -ne 2 ]
then
	print "Usage: $0 source target"
	exit 1
else
	source=$1
fi

if [ -d "$source" ]
then
	scp="$scp -r"
elif [ ! -f "$source" ]
then
	print "Source folder does not exist: $source"
	exit 1
fi

if [ ! -f "$source" ]
then
	print "Source does not exist or is not a regular file: $source"
	exit 1
fi

user=$USER

# Copy to remote servers.  Don't scp to local server.
scp_source() {
	source=$1
	target=$2

	print "DEBUG1: $scp"
	for server in $(cat /etc/hosts | grep "^10.0.0" | awk '{print $3}')
	do
		simple_server=$(hostname | sed 's/\.local//g')

		if [ "$server" != "$simple_server" ]
		then
			print "$scp $source $user@$server:$target"
			$scp $source $user@$server:$source
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
scp_source $1 $2
print "Transfer Complete"
#-------------------------------------------------------------------------------
