#!/usr/bin/env ksh
#-------------------------------------------------------------------------------
# PROGRAM:
#	git_clone.ksh	
#	
# PURPOSE:
#	Use git clone to pull a repository to a local machine.
#	
# USAGE:
#	$0 repository
#	
#-------------------------------------------------------------------------------

# NOTE:
# If this script is used by multiple users, make git_user an input.
git_user="SuperStevePrice"

usage="Usage: $0 repository branch_name"
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
projects_dir=~/Projects
target="${projects_dir}/${repository}"

print "ls -ld $projects_dir"
ls -ld $projects_dir
print
print "cd $projects_dir"
cd $projects_dir

if [ -d "$HOME/${projects_dir}/${repository}" ]
then
	print "mv $HOME/${projects_dir}/${repository} $HOME/${projects_dir}/${repository}.backup"
	mv $HOME/${projects_dir}/${repository} $HOME/${projects_dir}/${repository}.backup
fi

print "git clone git@github.com:$git_user/$repository.git $target"
git clone git@github.com:$git_user/$repository.git $target

exit $?
