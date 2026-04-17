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
#	Use git commands to merge a branch into the main repository.
#	
# USAGE:
#	$0 git_repository branch_name
#	
#-------------------------------------------------------------------------------
usage="Usage: $0 git_repository branch_name"
git=$(which git)

if [ ! -x "$git" ]
then
	print "The 'git' executable is not found or is not executable."
	exit 1
fi

if [ "$#" == 2 ]
then
	git_repository="$1"
	branch_name="$2"
else
	print "$usage"
	exit 1
fi

if [ ! -d "$git_repository" ]
then
	print "$usage"
	print "$git_repository not found, or is not a directory."
	exit 1
fi

print "cd $git_repository"
cd "$git_repository"

# Detect the main branch (main or master)
main=$($git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
if [ -z "$main" ]
then
	print "Could not detect main branch. Run: git remote set-head origin --auto"
	exit 1
fi

# Switch to main branch
print "$git checkout $main"
$git checkout "$main"

# Merge branch_name into main
print "$git merge $branch_name"
$git merge "$branch_name"

# Commit the merge changes with a message
print "$git commit -m 'Merged $branch_name into $main'"
$git commit -m "Merged $branch_name into $main"

# Push the changes to the remote repository
print "$git push"
$git push
#-------------------------------------------------------------------------------
#-- End of File ----------------------------------------------------------------