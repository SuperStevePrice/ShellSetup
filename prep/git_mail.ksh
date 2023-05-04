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
#	Set git user name and email
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

cmd="$git config --global user.name '"$user"'"
print $cmd
$cmd
if [ $? -eq 0 ]
then
	print "Success"
fi

cmd="$git config --global user.email '"$mail"'"
print $cmd
$cmd
if [ $? -eq 0 ]
then
	print "Success"
fi
