#!/usr/bin/env ksh
#-------------------------------------------------------------------------------
# PROGRAM:
#	AddToShellSetup.ksh
#	
# PURPOSE:
#	Find programs in ~/bin that should be added to ~/Projects/ShellSetup.ksh.
#	
# USAGE:
#	AddToShellSetup.ksh
#-------------------------------------------------------------------------------

bin=~/bin
prep=~/Projects/ShellSetup/prep

for file in $(ls $bin)
do
	if [ -h "$file" ]
	then
		continue
	else
		if [ ! -f "$prep/$file" ]
		then
			print "Add: $file"
		fi
	fi
done
