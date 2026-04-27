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
projects_dir="$HOME/Projects"

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

# Verify repository directory exists
if [ ! -d "${projects_dir}/${repository}" ]
then
	print "${projects_dir}/${repository} not found. Cannot push."
	exit 1
fi

# Change to repository directory
cd "${projects_dir}/${repository}" || error_check $?

# Show files to be staged and prompt for confirmation
print
print "Files to be staged:"
$git status --short
print
print -n "Proceed with git add .? [y/N]: "
read -r confirm
[[ "$confirm" != [yY] ]] && { print "Aborted."; exit 0; }

# Add all files to staging area
$git add . || error_check $?
print "Files added to staging area."

# Commit changes — exit code 1 means nothing to commit, not a fatal error
$git commit -m "$message"
commit_status=$?
if [ $commit_status -eq 0 ]
then
	print "Changes committed."
elif [ $commit_status -eq 1 ]
then
	print "Nothing to commit, continuing to push."
else
	print "Fatal Error on commit!"
	exit $commit_status
fi

# Push changes to remote repository
$git push || error_check $?
print "Changes pushed to remote repository."
print "Done."
print

print "git status"
$git status
print
#-------------------------------------------------------------------------------
#-- End of File ----------------------------------------------------------------
