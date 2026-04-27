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

repo_dir="${projects_dir}/${repository}"

if [ -d "${repo_dir}/.git" ]; then
	# Already a git repo — just pull
	cd "${repo_dir}" || error_check $?
elif [ -d "${repo_dir}" ]; then
	# Directory exists but no .git — warn and bail
	print "${repo_dir} exists but is not a git repository. Aborting."
	exit 1
else
	# No directory at all — can't pull, need to clone first
	print "${repo_dir} not found. Use git_clone to clone the repository first."
	exit 1
fi

# Pull
$git pull || error_check $?

# Check the repository status
print
print "git status"
$git status || error_check $?
print
print "Done."
#-------------------------------------------------------------------------------
#-- End of File ----------------------------------------------------------------
