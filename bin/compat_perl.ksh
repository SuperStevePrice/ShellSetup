#!/usr/bin/env ksh

#-------------------------------------------------------------------------------
#         Copyright (C) 2023    Steve Price    SuperStevePrice@gmail.com
#
#                       GNU GENERAL PUBLIC LICENSE
#                        Version 3, 29 June 2007
#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
# PROGRAM:
#	compat_perl.ksh
#	
# PURPOSE:
#	Look for a perl installtion compatable with perl Tk used in xt.pl. Run
#   xt.pl with that version as a test of compatiblity.
#	
# USAGE:
#   compat_perl.ksh
#-------------------------------------------------------------------------------

perl_executables=$(find / -name "perl*" -type f -executable 2>/dev/null)

for perl_executable in $perl_executables; do
    perl_lib_path=$(dirname $(dirname $perl_executable))/lib

    perl_tk_version=$($perl_executable -I$perl_lib_path -e 'use Tk; print $Tk::VERSION;')

    if [[ $perl_tk_version ]]; then
        echo "Compatible Perl version found: $perl_executable"
        # Invoke xt.pl with the compatible Perl version
        $perl_executable ~/bin/xt.pl &
        break
    fi
done

