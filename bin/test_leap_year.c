
#-------------------------------------------------------------------------------
#         Copyright (C) 2023    Steve Price    SuperStevePrice@gmail.com
#
#                       GNU GENERAL PUBLIC LICENSE
#                        Version 3, 29 June 2007
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# PROGRAM:
#	test_leap_year.c
#	
# PURPOSE:
#	C module to link with is_leap_year.o to test a year for leap year status.
#	
# USAGE:
#	Link with is_leap_year.o.
#
#-------------------------------------------------------------------------------

#include <stdio.h>
extern int is_leap_year(int year);

int main() {
  int year = 2024;
  if (is_leap_year(year)) {
    printf("%d is a leap year.\n", year);
  } else {
    printf("%d is not a leap year.\n", year);
  }
  return 0;
}
