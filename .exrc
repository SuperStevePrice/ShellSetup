"-------------------------------------------------------------------------------
"         Copyright (C) 2023    Steve Price    SuperStevePrice@gmail.com
"
"                       GNU GENERAL PUBLIC LICENSE
"                        Version 3, 29 June 2007
"-------------------------------------------------------------------------------

"-------------------------------------------------------------------------------
" PROGRAM:
"	~/.profile
"	
" PURPOSE:
"	Sets runtime ksh environment.
"	
" USAGE:
"	Invoked at runtime by the operating system as users login.
"
"-------------------------------------------------------------------------------
ab #D # PROGRAM:#	#	# PURPOSE:#	#	# USAGE:##
ab #E #-- End of File ---------------------------------------------------------------
ab #a #include <assert.h>
ab #c #include <ctype.h>
ab #d #define 
ab #i #include <stdio.h>
ab #b #!/usr/bin/env bash
ab #k #!/usr/bin/env ksh
ab #l #-------------------------------------------------------------------------------
ab #m public static void main(String[] args) {} // end of main()
ab #n #include 
ab #p #!/usr/bin/env perl 
ab #y #!/usr/bin/env python
ab #s #include <stdio.h>
ab *l * ------------------------------------------------------------------------------
ab *l System.out.println("");
ab *p System.out.print("");
ab /f } /* end of function */
ab /l //------------------------------------------------------------------------------
ab /m } /* end of main */
map ^ :r ~/Projects/ShellSetup/docs/copyright
map ] :r ~/Projects/ShellSetup/docs/header
map * :! chmod u+x %; %
map + :w! %.save
map , :w
map - :!perl -c %
map ; :w
map = :wq!
map [ :f
map \ :n
set ai
set autoindent
set noignorecase
set redraw
set showmatch
set showmode
set sw=4
set tabstop=4
set ts=4
"-------------------------------------------------------------------------------
" Last installed: 2023-05-18 15:52:57
"-- End of File ----------------------------------------------------------------
