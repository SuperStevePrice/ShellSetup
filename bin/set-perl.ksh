#!/usr/bin/env ksh

#-------------------------------------------------------------------------------
#         Copyright (C) 2023    Steve Price    SuperStevePrice@gmail.com
#
#                       GNU GENERAL PUBLIC LICENSE
#                        Version 3, 29 June 2007
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# PROGRAM:
#	set-perl.ksh
#	
# PURPOSE:
#	Offer the user a selection of installed perl versions. Set a sym link.
#	
# USAGE:
#	set-perl.ksh
#
# Author:
#	Steve Price
#-------------------------------------------------------------------------------

# Global string of all folders that might have perl executables:
dirs="/usr/bin"
dirs="$dirs /usr/local/bin"
dirs="$dirs /usr/local/share"
dirs="$dirs $HOME/perl*/bin"
dirs="$dirs /opt/perl*/bin"
dirs="$dirs /opt/homebrew/bin"

# Variable to store the Perl version selection
selected_perl=""

# Function to show current version of Perl used by the shell:
display_current_perl() {
	# Display the current Perl
	print
	print "Current Perl:"
	perl=$(which perl)
	print $perl
	if [ $1 == "full" ]; then
		perl --version
	fi
	print
}

display_current_perl brief

# Function to check if a given file path is a Perl executable
is_perl_executable() {
    file="$1"
    if [[ -x "$file" && -f "$file" && $(file -b "$file") == *Perl* ]]; then
        return 1
    else
        return 0
    fi
}

# Function to list Perl versions target directory
list_perl_versions() {
	target_dir=$1
	print "Perl versions in $target_dir:"
	ls ${target_dir}/perl* 2>/dev/null | while read -r perl; do
		if is_perl_executable "$perl" && ! print "$perl" |\
			grep -qE 'perlbug|perlivp|perltidy|perldoc|perlthanks'; then
			print "\t$perl"
			((index++))
		fi
	done
}

# Function to add choice from target directory
add_choice_from() {
	target_dir=$1
	ls ${target_dir}/perl* 2>/dev/null | while read -r perl; do
		if is_perl_executable "$perl" && ! print "$perl" |\
			grep -qE 'perlbug|perlivp|perltidy|perldoc|perlthanks'; then
			choices+=("$perl")
			print "$index) $perl"
			((index++))
		fi
	done
}

index=1
# Loop over directories and invoke list_perl_versions function
for dir in $dirs; do
  list_perl_versions "$dir"
done

# Prompt for Perl version selection
while true; do
	print "Select a Perl version (or 0 to cancel):"
	choices=()

	index=1
	for dir in $dirs; do
		add_choice_from  "$dir"
	done

	# Prompt for selection
	print -n "#? "
	read -r selection
	print

	# Handle the selection
	if [[ "$selection" == "0" ]]; then
		print "No changes made to Perl."
		exit 0
	elif ((selection >= 1 && selection <= index-1)); then
		selected_perl="${choices[selection]}"
		sudo ln -sf "$selected_perl" /usr/local/bin/perl
		print "Perl successfully set to: $selected_perl"
		break  # Exit the loop after a valid selection
	else
		print "Invalid selection. Please try again."
	fi
done

display_current_perl full
