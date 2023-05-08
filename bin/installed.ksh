#!/usr/bin/env ksh

#-------------------------------------------------------------------------------
#         Copyright (C) 2023    Steve Price    SuperStevePrice@gmail.com
#
#                       GNU GENERAL PUBLIC LICENSE
#                        Version 3, 29 June 2007
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# PROGRAM:
#	installed.ksh
#	
# PURPOSE:
#	Display the "Last Installed" message from a given file.
#	
# USAGE:
#	installed.ksh file
#
#-------------------------------------------------------------------------------

usage="USAGE:	$(basename $0) file"

if [ $# -ne 1 ]
then
	print $usage
	exit 1
else
	file=$1
fi

hash='#' # trick to prevent this script from finding target string in itself

print "FILE:	$file"
cat $file | grep -i "${hash} Last installed:"

if [ $? -ne 0 ]
then
	print "No installation date found for file: ${file}."
	exit 1
fi

exit 0
