#!/usr/bin/env ksh

#-------------------------------------------------------------------------------
# PROGRAM:
#	xtermTk.ksh
#	
# PURPOSE:
#	Set .profile environment, which includes ~/.locale, call ~/bin/xtermTk.py.
#	
# USAGE:
#	xtermTk[.ksh]
#-------------------------------------------------------------------------------
. ~/.profile
. ~/.locale
nohup /usr/bin/env python ~/bin/xtermTk.py  &
