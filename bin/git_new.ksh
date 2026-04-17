#!/usr/bin/env ksh
#-------------------------------------------------------------------------------
# Copyright (C) 2023  Steve Price	SuperStevePrice@gmail.com
#
#                  GNU GENERAL PUBLIC LICENSE
#                     Version 3, 29 June 2007
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
# PROGRAM:
#	git_new.ksh
#	
# USAGE:
#	git_new.ksh repository
#	
# PURPOSE:
#	Create a new repository in GitHub
#-------------------------------------------------------------------------------
# NOTE:
# If this script is used by multiple users, make git_user an input.
git_user="SuperStevePrice"
usage="Usage: $0 repository"
git=$(which git)

if [ ! -x "$git" ]
then
	print "The 'git' executable is not found or is not executable."
	exit 1
fi

if [ "$#" == 1 ]
then
	repository="$1"
else
	print "$usage"
	exit 1
fi

# Derive the repository name from the repository
repository=$(basename "$repository")
projects_dir="$HOME/Projects"
target="${projects_dir}/${repository}"

if [ ! -d "$target" ]
then
	print "$target not found, or is not a directory."
	exit 1
fi

print "cd $target"
cd "$target"

print "$git init"
$git init

print "$git add ."
$git add .

print "$git commit -m 'Initial commit of $repository'"
$git commit -m "Initial commit of $repository"

print "$git remote add origin git@github.com:$git_user/$repository.git"
$git remote add origin git@github.com:$git_user/$repository.git

print "$git push -u origin main"
$git push -u origin main
#-------------------------------------------------------------------------------
#-- End of File ----------------------------------------------------------------