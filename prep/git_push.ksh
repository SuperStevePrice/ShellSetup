#!/usr/bin/env ksh

#-------------------------------------------------------------------------------
# Copyright (C) 2023  Steve Price	SuperStevePrice@gmail.com
#
#                  GNU GENERAL PUBLIC LICENSE
#                     Version 3, 29 June 2007
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# PROGRAM:
#	git_push.ksh
#	
# PURPOSE:
#	Use git to add, commit, and push a project
#	
# USAGE:
#	git_push.ksh 
#	
#	The user will be queried for the repository basename and commit message.
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

# Prompt for commit message
while true; do
	print -n "Enter commit message: "
	read -r message
	if [ -z "$message" ]; then
		print "Commit message cannot be empty. Please try again."
	else
		break
	fi
done

# Change to repository directory
cd ~/Projects/$repository || error_check $?

# Check the repository status
$git status || error_check $?

# Add all files to staging area
$git add . || error_check $?
print "Files added to staging area."

# Commit changes
$git commit -m "$message" || error_check $?
print "Changes committed."

# Push changes to remote repository
$git push || error_check $?
print "Changes pushed to remote repository."

print "Done."

print
print "git status"
$git status
print
