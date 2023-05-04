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
#	git_push.ksh repository
#
#-------------------------------------------------------------------------------
usage="Usage: $0 repository"
git=$(which git)

if [ ! -x "$git" ]
then
	echo "The 'git' executable is not found or is not executable."
	exit 1
fi

if [ "$#" == 1 ]
then
	repository="$1"
else
	echo "$usage"
	exit 1
fi

projects_dir=~/Projects
repository_dir="$projects_dir/$repository"

if [ ! -d "$repository_dir" ]
then
	echo "$usage"
	echo "$repository_dir not found, or is not a directory."
	exit 1
fi

echo "cd $projects_dir/$repository"
cd $projects_dir/$repository

# add
print $git add .
$git add .

# commit the merge changes with a message
echo "$git commit -m 'Commit project $repository'"
$git commit -m 'Commit project $repository'

# push the changes to the remote repository
echo "$git push"
$git push
