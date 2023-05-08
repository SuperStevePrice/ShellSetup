#!/usr/bin/env ksh

#-------------------------------------------------------------------------------
#         Copyright (C) 2023    Steve Price    SuperStevePrice@gmail.com
#
#                       GNU GENERAL PUBLIC LICENSE
#                        Version 3, 29 June 2007
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# PROGRAM:
#	bin.ksh
#	
# PURPOSE:
#	This script is part of the installation suite for the ShellSetup project.
#	It creates the appropriate shebang lines for ksh and perl scripts.
#	
# USAGE:
#	bin.ksh
#
#-------------------------------------------------------------------------------

line=$(print "#$(printf -- '-%.0s' {1..79})")

print $line
print "Preparing files:	$(date)"
print $line

make_shebang() {
	app=$1
	file="bin/$2"

	# ksh,  perl
	shebang="#!/usr/bin/env $app"

	if [ "$file" = "bin/xt.pl" ]
	then
		# Relative path of xterm is stored in xterm not xt.pl.
		file="dots/xtrc"
		x=$(dirname $(which xterm))
		sed -e "s|^xpath=.*|xpath=${x}|g" $file > /tmp/$2
		print
		print $file
		print "xpath=$x"
		print
	else
		old_shebang=$(head -1 $file)
		new_shebang="$shebang"
		sed -e "s|${old_shebang}|${new_shebang}|g" $file > /tmp/$2
	fi
	mv /tmp/$2 $file

	if [ "$file" != "bin/xtrc" ]
	then
		ls -l $file
		head -1 $file
	fi
} # make_shebang()


make_bin_dir () {
	bin_dir=bin

	if [ ! -e $bin_dir ]
	then
		mkdir $bin_dir
	else
		print "See contents of $bin_dir:\n"
	fi
} # make_bin_dir()


make_bin_dir


# Shell shebang lines for ksh and perl and relative path for xterm
make_shebang ksh xt.ksh
make_shebang ksh PS1.ksh
make_shebang perl xt.pl

print "ls -l $bin_dir"
ls -l $bin_dir

print
print $line
print "Preparations done:	$(date)"
print $line
print
print
