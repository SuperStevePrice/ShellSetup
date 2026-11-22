#!/usr/bin/env perl

#-------------------------------------------------------------------------------
#         Copyright (C) 2023    Steve Price    SuperStevePrice@gmail.com
#
#                       GNU GENERAL PUBLIC LICENSE
#                        Version 3, 29 June 2007
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# PROGRAM:
#	paths.pl
#	
# PURPOSE:
#	Print the full path of various common shells or languages.
#	
# USAGE:
#	paths.pl
#
#-------------------------------------------------------------------------------

use strict;
use warnings;

my $programs = "ksh perl python xterm";

foreach my $program (split(' ', $programs)) {
    my $full_path = `which $program`;

    # Use chomp to remove the trailing newline from $full_path
    chomp($full_path);

    # Use File::Basename to get the path and program name
    use File::Basename;
    my $path_only = dirname($full_path);
    my $prog = basename($full_path);

    print "Full Path:	$full_path\n";	# output fully qualified path
    print "Path Only:	$path_only\n";	# output the program's path
    print "Prog:		$prog\n\n";		# output the name of the program only
}

