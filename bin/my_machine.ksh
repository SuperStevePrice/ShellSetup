#!/usr/bin/env ksh

#-------------------------------------------------------------------------------
#         Copyright (C) 2023    Steve Price    SuperStevePrice@gmail.com
#
#                       GNU GENERAL PUBLIC LICENSE
#                        Version 3, 29 June 2007
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# PROGRAM:
#	my_machine.ksh
#	
# PURPOSE:
#	Print the machine name.
#	
# USAGE:
#	my_machone.ksh
#-------------------------------------------------------------------------------
MACHINE_NAME=$(hostname)
echo "The machine name is $MACHINE_NAME"
