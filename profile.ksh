#!/usr/bin/env ksh

#-------------------------------------------------------------------------------
#         Copyright (C) 2023    Steve Price    SuperStevePrice@gmail.com
#
#                       GNU GENERAL PUBLIC LICENSE
#                        Version 3, 29 June 2007
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# PROGRAM:
#	profile.ksh
#	
# PURPOSE:
#	Create ~/.profile including environment values for brew and perl via eval.
#	
# USAGE:
#	Invoked by setup.ksh
#
#-------------------------------------------------------------------------------

filename=dots/profile

perl_v=$(which perl)
brew_path=$(which brew)

if [[ $perl_v == "/usr/bin/perl" || $perl_v == "/bin/perl" ]]; then
    perl_installed="bin"
else
    perl_installed="brew"
fi

while read -r line; do
    print $line
	if [[ $line == "set"* ]]; then
		print 'eval $(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib)'
		if [[ $perl_installed = "brew" ]]; then
			print 'eval $('${brew_path}' shellenv)'
		fi
	fi
done < "$filename"

