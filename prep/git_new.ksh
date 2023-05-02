#-------------------------------------------------------------------------------
#!/usr/bin/env ksh
# $Id$
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
projects_dir=~/Projects
target="${projects_dir}/${repository}"

print "cd $target"
cd $target

#if [ -d "$HOME/${projects_dir}/${repository}" ]
#then
#	print "$HOME/${projects_dir}/${repository} exists."
#	exit 1
#fi

# Use SSH for no password login to GitHub:
print "$git remote set-url $repository git@github.com:$git_user/$repository.git"
$git remote set-url $repository git@github.com:$git_user/$repository.git

print "$git init"
$git init

print "$git add ."
$git add .

print "$git commit -m 'Initial commit of $repository'"
$git commit -m "Initial commit of $repository"

print "$git remote add $repository git@github.com:$git_user/$repository.git"
$git remote add $repository git@github.com:$git_user/$repository.git 

#print "$git remote add $repository https://github.com/$git_user/$repository.git"
#$git remote add $repository https://github.com/$git_user/$repository.git

print "$git push -u $repository main"
$git push -u $repository main
# EOF --------------------------------------------------------------------------
