#!/usr/bin/env ksh

#-------------------------------------------------------------------------------
#         Copyright (C) 2023    Steve Price    SuperStevePrice@gmail.com
#
#                       GNU GENERAL PUBLIC LICENSE
#                        Version 3, 29 June 2007
#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
# PROGRAM:
#	diff_projs.ksh
#	
# PURPOSE:
#	Run diff against all files in project1 and project2 folders
#	
# USAGE:
#    diff_projs.sh /path/to/old_project /path/to/new_project
#-------------------------------------------------------------------------------

# Check the number of arguments
if [ "$#" -lt 2 ]; then
	echo "Usage: $0 <old_project_directory> <new_project_directory>"
	exit 1
fi

# Get the old and new project directories from the arguments
old_project="$1"
new_project="$2"

# Validate the old project directory
if [ ! -d "$old_project" ]; then
	echo "Old project directory not found: $old_project"
	read -p "Enter the path to the old project directory: " old_project
	if [ ! -d "$old_project" ]; then
		echo "Invalid old project directory. Exiting."
		exit 1
	fi
fi

# Validate the new project directory
if [ ! -d "$new_project" ]; then
	echo "New project directory not found: $new_project"
	read -p "Enter the path to the new project directory: " new_project
	if [ ! -d "$new_project" ]; then
		echo "Invalid new project directory. Exiting."
		exit 1
	fi
fi

# Run diff recursively on all files in the folders, excluding specified folders
diff -r --exclude=".git" --exclude="logs" "$old_folder" "$new_folder"
