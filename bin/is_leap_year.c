#-------------------------------------------------------------------------------
#         Copyright (C) 2023    Steve Price    SuperStevePrice@gmail.com
#
#                       GNU GENERAL PUBLIC LICENSE
#                        Version 3, 29 June 2007
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# PROGRAM:
#	C language subroutine that takes an interger year input and returns boolean.
#	
# PURPOSE:
#	Link to any C program that rquires leap year validation.
#	
# USAGE:
#	Input:	integer year
#	Return:	boolean
#-------------------------------------------------------------------------------

int is_leap_year(int year) {
  return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
}
