#!/usr/bin/env ksh

#-------------------------------------------------------------------------------
#         Copyright (C) 2023    Steve Price    SuperStevePrice@gmail.com
#
#                       GNU GENERAL PUBLIC LICENSE
#                        Version 3, 29 June 2007
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# PROGRAM:
#	prep.ksh
#	
# PURPOSE:
#	This script is part of the installation suite for the ShellSetup project.
#	It creates the appropriate shebang lines for ksh and perl scripts.
#	
# USAGE:
#	prep.ksh
#
#-------------------------------------------------------------------------------

line="#------------------------------------------"
line="${line}-------------------------------------"

print $line
print "Preparing files:	$(date)"
print $line

make_shebang() {
	app=$1
	file="prep/$2"

	# ksh,  perl
	shebang="#!/usr/bin/env $app"

	if [ "$file" = "prep/xt.pl" ]
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

	if [ "$file" != "prep/xtrc" ]
	then
		ls -l $file
		head -1 $file
	fi
} # make_shebang()


make_prep_dir () {
	prep_dir=prep

	if [ ! -e $prep_dir ]
	then
		mkdir $prep_dir
	else
		print "See contents of $prep_dir:\n"
	fi
} # make_prep_dir()


make_prep_dir

# Informative only?
which perl > $prep_dir/which.perl
which xterm > $prep_dir/which.xterm
which ksh > $prep_dir/which.ksh

# Shell shebang lines for ksh and perl and relative path for xterm
make_shebang ksh xt.ksh
make_shebang ksh PS1.ksh
make_shebang perl xt.pl

print "ls -l $prep_dir"
ls -l $prep_dir

print
print $line
print "Preparations done:	$(date)"
print $line
print
print
