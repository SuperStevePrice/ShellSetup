#!/usr/bin/env ksh

#-------------------------------------------------------------------------------
#         Copyright (C) 2023    Steve Price    SuperStevePrice@gmail.com
#
#                       GNU GENERAL PUBLIC LICENSE
#                        Version 3, 29 June 2007
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# PROGRAM:
#	set_shell.ksh
#	
# PURPOSE:
#	Make ksh the user's login shell.
#	
# USAGE:
#	set_shell.ksh
#
#-------------------------------------------------------------------------------
chsh=$(which chsh)
usermod=$(which usermod)
ksh=$(which ksh)

if [ X$chsh != X"" ]
then
	#chsh --shell /bin/sh tecmint
	print sudo $chsh --shell $ksh $USER
else
	if [ X$usermod != X"" ]
	then
		print $usermod
		# usermod --shell /bin/bash tecmint
		print sudo $usermod --shell $ksh $USER
	fi
fi

exit 0
