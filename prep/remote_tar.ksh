#!/usr/bin/env ksh
#-------------------------------------------------------------------------------
# PROGRAM:
#	remote_tar.ksh	
#	
# PURPOSE:
#	Use tar to create a tarball, ie a *.tar.gz file, from a folder 
#	or to extract from a tarball to a folder.
#	Use scp to push the tarball file to remote servers.
#	Note:  scp will not be run on the local machine which executes this script.
#
# Usage:
#	 remote_tar.ksh -c|-x <tarball_fullpath>
#	
#-------------------------------------------------------------------------------
prog=$(basename "$0")

usage="USAGE:	$prog -c|-x <tarball_full_path>"

# Check for valid arguments
if [ "$#" -ne 2 ]
then
	print "$usage"
	exit 1
fi


# Check for compression or extraction action
action=$(echo "$1" | tr '[:upper:]' '[:lower:]')
if [ "$action" = "-c" ]
then
	action="compress"
elif [ "$action" = "-x" ]
then
	action="extract"
else
	print "Invalid action: $action"
	print "$usage"
	exit 1
fi

# Check if tarball has .tar.gz extension, if not, add it
normalize_tarball() {
	tarball=$1

	relative_path=${tarball%$file_name}			# extract relative path
	relative_path=${relative_path%/} 			# remove trailing slash
	relative_path=$(dirname ${relative_path})	# remove trailing slash

	ls "$tarball" | grep "tar.gz" > /dev/null 2>&1
	if [ $? != 0 ]
	then
		tarball="${tarball}.tar.gz"
		target=$(basename $1)
		#print "DEBUG0: $tarball\t$target"
	else
		file_name=$(basename "$tarball")    # extract file name with extension
		target=${file_name%.tar.gz}         # remove extension
		target=${target##*/}                # remove path
		#print "DEBUG1: $tarball\t$target"
	fi
	#print "DEBUG2: target=[$target]"
	#print "DEBUG3: tarball=[$tarball]"
	#print "DEBUG4: relative_path=[$relative_path]"
}

normalize_tarball $2
#print "DEBUG: tarball=[$tarball]"

print
print cd $relative_path
cd $relative_path
#print "DEBUG target=[$target]"


# Check for source file existence and regularity
if [ "$action" = "compress" ]
then
	if [ ! -d "$target" ]
	then
		print "Source folder does not exist: $target"
		exit 1
	fi
else
	if [ ! -f "$tarball" ]
	then
		print "The tarball does not exist or is not a regular file: $tarball"
		exit 1
	fi
fi

# Check for target tarball or folder.
# If action is extract normalize_tarball.
if [ "$action" == "extract" ]
then
	normalize_tarball $2
fi

# Perform the action
if [ "$action" = "compress" ]
then
	print "tar -czvf " "tarball: $tarball" "target: $target"
	tar -czvf "$tarball" "$target"
else
	print "tar -xzvf " "$tarball" "$target"
	tar -xzvf "$tarball" "$target"
fi

# Check for successful action
if [ "$?" -eq 0 ]
then
	print "\nSuccess: $action\n"
else
	print "\nFailed: $action\n"
fi

scp_tarball() {
	# Copy to remote servers.  Don't scp to local server.

	user=$USER
	for server in $(cat /etc/hosts | grep "^10.0.0" | awk '{print $3}')
	do
		simple_server=$(hostname | sed 's/\.local//g')

		if [ "$server" != "$simple_server" ]
		then
			target=$(dirname $tarball)
			print "scp " "$tarball" "$user@$server:$target"
			scp "$tarball" "$user@$server:$target"
			# Check for successful scp
			if [ "$?" -eq 0 ]
			then
				print "File copied successfully to $user@$server:$target"
			else
				print "Failed to copy file to $user@$server:$target"
			fi
		else
			print "No scp performed for local server, $server"
			print "See $tarball."
		fi
		print
	done
}

if [ "$action" == "compress" ]
then
	scp_tarball
fi

print
#-------------------------------------------------------------------------------
# EOF
#-------------------------------------------------------------------------------
