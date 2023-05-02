#!/usr/bin/env ksh
# Set git user name and email

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
# EOF --------------------------------------------------------------------------
