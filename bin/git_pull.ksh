#!/usr/bin/env ksh

#-------------------------------------------------------------------------------
# Copyright (C) 2023  Steve Price	SuperStevePrice@gmail.com
#
#                  GNU GENERAL PUBLIC LICENSE
#                     Version 3, 29 June 2007
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# PROGRAM:
#	git_pull.ksh
#	
# PURPOSE:
#	Use git to pull changes to a local Project
#	
# USAGE:
#	git_pull.ksh 
#	
#	The user will be queried for the repository basename
#
#-------------------------------------------------------------------------------
git=$(which git)

# Function to check for errors
error_check() {
	if [ $1 -ne 0 ]
	then
		print "Fatal Error!"
		exit $1
	fi
}

# Prompt for repository name
while true; do
	print -n "Enter repository name: "
	read -r repository
	if [ -z "$repository" ]; then
		print "Repository name cannot be empty. Please try again."
	else
		break
	fi
done

# Change to repository directory
if [ ! -d ~/Projects/$repository ]; then
	mkdir ~/Projects/$repository || error_check $?
fi
cd ~/Projects/$repository || error_check $?

# Pull
$git pull || error_check $?

# Check the repository status
print
print "git status"
$git status || error_check $?
print
print "Done."
