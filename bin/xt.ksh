#!/usr/bin/env ksh
if [ X"$(uname)" == X"Darwin" ]
then
    perl=/opt/homebrew/bin/perl
else
    perl=/usr/bin/perl5.34-x86_64-linux-gnu
fi
$perl ~/bin/xt.pl &
#-------------------------------------------------------------------------------
# Last installed: 2023-06-16 10:31:37
#-- End of File ----------------------------------------------------------------
