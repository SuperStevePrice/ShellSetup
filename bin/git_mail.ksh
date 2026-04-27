#!/usr/bin/env ksh
#-------------------------------------------------------------------------------
#         Copyright (C) 2023    Steve Price    SuperStevePrice@gmail.com
#
#                       GNU GENERAL PUBLIC LICENSE
#                        Version 3, 29 June 2007
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
# PROGRAM:
#	git_mail.ksh
#	
# PURPOSE:
#	Set git user name and email and editor.
#	
# USAGE:
#	git_mail.ksh
#
#-------------------------------------------------------------------------------
if [ $# -eq 2 ]
then
	user=$1
	mail=$2
else
	user=SuperStevePrice
	mail=SuperStevePrice@gmail.com
fi

git=$(which git)

print "$git config --global user.name \"$user\""
$git config --global user.name "$user"
if [ $? -eq 0 ]
then
	print "Success"
fi

print "$git config --global user.email \"$mail\""
$git config --global user.email "$mail"
if [ $? -eq 0 ]
then
	print "Success"
fi

print "$git config --global core.editor 'vim'"
$git config --global core.editor "vim"
if [ $? -eq 0 ]
then
	print "Success"
fi
#-------------------------------------------------------------------------------
#-- End of File ----------------------------------------------------------------
