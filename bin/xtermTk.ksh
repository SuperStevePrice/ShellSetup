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
nohup perl ~/bin/xtermTk.py  &
