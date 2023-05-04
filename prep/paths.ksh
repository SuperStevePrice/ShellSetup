#!/usr/bin/env ksh

#-------------------------------------------------------------------------------
#         Copyright (C) 2023    Steve Price    SuperStevePrice@gmail.com
#
#                       GNU GENERAL PUBLIC LICENSE
#                        Version 3, 29 June 2007
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# PROGRAM:
#	paths.ksh
#	
# PURPOSE:
#	Print the fully qualified paths for various programs.
#	
# USAGE:
#	paths.ksh
#-------------------------------------------------------------------------------

programs="cc gcc bash sh ksh java perl python xterm"

for program in $(print $programs)
do
	full_path=$(which $program)

	# Use dirname command to get the path only
	path_only=$(dirname $full_path)

	# Use basename command to get the progam name only, sans directory information
	prog=$(basename $full_path)

	print $full_path
	print $path_only	# This will output "myprogram"
	print $prog			# This will output "myprogram"
	print 
done
