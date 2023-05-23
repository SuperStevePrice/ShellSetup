#!/usr/bin/env ksh

#-------------------------------------------------------------------------------
#         Copyright (C) 2023    Steve Price    SuperStevePrice@gmail.com
#
#                       GNU GENERAL PUBLIC LICENSE
#                        Version 3, 29 June 2007
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# PROGRAM:
#	.profile	
#	
# PURPOSE:
#	ksh profile
#	
# USAGE:
#	Invoked by the operating system at login.
#-------------------------------------------------------------------------------

# PS1: command line primary prompt:
. ~/bin/PS1.ksh

# load my aliases
. ~/.aliases

# load my functions
. ~/.functions

export HOST=$(uname -n)
export FCEDIT=vi

# Setting the terminal type for xterm and Terminal windows. 
# term=xterm does not work for xterm vi sessions; vt100 does.
export TERM=vt100

# Enable CLI editting of previous commands in history:
set -o vi


# Detect the operating system and set environment to run perl Tk modules.
if [ "$(uname)" == "Darwin" ]; then
	# macOS specific configurations. Not required for Linux.

	# If Homebrew Perl is installed, set up the environment
	if command -v brew >/dev/null 2>&1 && brew list perl >/dev/null 2>&1; then
		# Determine the path to Homebrew Perl
		brew_prefix=$(brew --prefix)
		perl_path="${brew_prefix}/bin/perl"

		# Set up eval statement with the correct path
		eval $(perl -I"${brew_prefix}/lib/perl5" \
		  -Mlocal::lib="${brew_prefix}") || \
			echo "Failed to set up Homebrew Perl environment"


		# If you want to capture the path separately:
		export HOMEBREW_PERL_PATH="${perl_path}"
		# Uncomment the following line if you want to override 
		# the default Perl path
		export PATH="$(dirname "${perl_path}"):${PATH}"
	else
		echo "Homebrew Perl is not installed"
	fi
fi

# Add to $PATH
export PATH="${PATH}s:/bin:/usr/bin:/usr/local/bin:/usr/sbin:/opt/X11/bin:/opt/homebrew/bin:$HOME/bin:/usr/local/bin:$HOME/anaconda3/bin:."

# Remove duplicates from $PATH
export PATH=$(echo $PATH | awk -v RS=':' '!a[$0]++ {if (NR>1) printf(":"); printf("%s", $0)}')

#-------------------------------------------------------------------------------
# Last installed: 2023-05-21 14:13:09
#-- End of File ----------------------------------------------------------------