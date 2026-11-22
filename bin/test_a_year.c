#-------------------------------------------------------------------------------
#         Copyright (C) 2023    Steve Price    SuperStevePrice@gmail.com
#
#                       GNU GENERAL PUBLIC LICENSE
#                        Version 3, 29 June 2007
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# PROGRAM:
#	test_a_year.c
#	
# PURPOSE:
#	A C language to determined leap years.
#	
# USAGE:
#	Compile and link with is_leap_year.o
#
#-------------------------------------------------------------------------------

#include <stdlib.h>
#include <stdio.h>

extern int is_leap_year(int year);

int main() {
  int year;
  char input[10];
  while (1) {
    printf("Enter a year: ");
    fgets(input, sizeof(input), stdin);
    if (sscanf(input, "%d", &year) == 1 && year >= 0) {
      break;
    }
    printf("Invalid input. Please enter a positive integer.\n");
  }
  if (is_leap_year(year)) {
    printf("%d is a leap year.\n", year);
  } else {
    printf("%d is not a leap year.\n", year);
  }
  return 0;
}
