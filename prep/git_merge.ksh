#!/usr/bin/env ksh

#-------------------------------------------------------------------------------
# Copyright (C) 2023  Steve Price	SuperStevePrice@gmail.com
#
#                  GNU GENERAL PUBLIC LICENSE
#                     Version 3, 29 June 2007
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# PROGRAM:
#	git_merge.ksh	
#	
# PURPOSE:
#	Use git commands to merge a branch into the the master repository.
#	
# USAGE:
#	$0 git_repository branch_name
#	
#-------------------------------------------------------------------------------
usage="Usage: $0 git_repository branch_name"
git=$(which git)

if [ ! -x "$git" ]
then
	echo "The 'git' executable is not found or is not executable."
	exit 1
fi

if [ "$#" == 2 ]
then
	git_repository="$1"
	branch_name="$2"
else
	echo "$usage"
	exit 1
fi

if [ ! -d "$git_repository" ]
then
	echo "$usage"
	echo "$git_repository not found, or is not a directory."
	exit 1
fi

# Derive the master name from the git_repository
master=$(basename "$git_repository")

echo "cd $git_repository"
cd "$git_repository"

# switch to master branch
echo "$git checkout $master"
$git checkout "$master"

# merge branch_name into master
echo "$git merge $branch_name"
$git merge "$branch_name"

# resolve conflicts if any

# commit the merge changes with a message
echo "$git commit -m 'Merged $branch_name into $master'"
$git commit -m "Merged $branch_name into $master"

# push the changes to the remote repository
echo "$git push"
$git push
