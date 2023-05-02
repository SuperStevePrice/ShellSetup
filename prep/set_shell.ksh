#!/usr/bin/env ksh
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
