#!/usr/bin/env perl 

#-------------------------------------------------------------------------------
#         Copyright (C) 2023    Steve Price    SuperStevePrice@gmail.com
#
#                       GNU GENERAL PUBLIC LICENSE
#                        Version 3, 29 June 2007
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# PROGRAM:
#	test.pl
#	
# PURPOSE:
#	Test perl Tk.
#	
# USAGE:
#	test.pl
#
#-------------------------------------------------------------------------------

use Tk;

my $mw = MainWindow->new;
$mw->Label(-text => "Hello, Tk!")->pack;
$mw->Button(-text => "Quit", -command => sub { exit })->pack;
MainLoop;
