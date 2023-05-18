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
#-------------------------------------------------------------------------------`
# Variable to store the Perl version selection
selected_perl=""

# Function to check if a given file path is a Perl executable
is_perl_executable() {
    file="$1"
    if [[ -x "$file" && -f "$file" && $(file -b "$file") == *Perl* ]]; then
        return 1
    else
        return 0
    fi
}

# List Perl versions in /usr/bin
print
print "Perl versions in /usr/bin:"
print
ls /usr/bin/perl* 2>/dev/null | while read -r perl; do
    if is_perl_executable "$perl" && ! print "$perl" |\
        grep -qE 'perlbug|perldoc|perlthanks'; then
        print "$perl"
    fi
done

# List Perl versions in $HOME
print
print "Perl versions in $HOME:"
print 
ls "$HOME"/perl*/bin/perl 2>/dev/null | while read -r perl; do
    if is_perl_executable "$perl" && ! print "$perl" |\
        grep -qE 'perlbug|perldoc|perlthanks'; then
    print "$perl"
    fi
done

# Prompt for Perl version selection
print
print "Select a Perl version (or 0 to cancel):"
choices=()
index=1

# Add choices from /usr/bin
ls /usr/bin/perl* 2>/dev/null | while read -r perl; do
    if is_perl_executable "$perl" && ! print "$perl" |\
        grep -qE 'perlbug|perldoc|perlthanks'; then
        choices+=("$perl")
        print "$index) $perl"
        ((index++))
    fi
done

# Add choices from $HOME
ls "$HOME"/perl*/bin/perl 2>/dev/null | while read -r perl; do
    if is_perl_executable "$perl" && ! print "$perl" |\
        grep -qE 'perlbug|perldoc|perlthanks'; then
        choices+=("$perl")
        print "$index) $perl"
        ((index++))
    fi
done

# Add cancel option
print "$index) Cancel"

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
else
    print "Invalid selection. Please try again."
    exit 1
fi

# Display the current Perl
print
print "Current Perl:"
perl=$(which perl)
print $perl
perl --version