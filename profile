#-------------------------------------------------------------------------------
# $Id$
# PROGRAM:
#	.profile	
#	
# PURPOSE:
#	ksh profile
#	
#-------------------------------------------------------------------------------
export PATH=$PATH:$HOME/bin:/usr/local/bin:.

# PS1: command line primary prompt:
. ~/bin/PS1.ksh

# load my aliases
. ~/.alias

# load my functions
. ~/.functions

export HOST=$(uname -n)
export FCEDIT=vi
set -o vi
#-------------------------------------------------------------------------------
