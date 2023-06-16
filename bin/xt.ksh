#!/usr/bin/env ksh
if [ X"$(uname)" == X"Darwin" ]
then
    perl=/opt/homebrew/bin/perl
else
    perl=/usr/bin/perl5.34-x86_64-linux-gnu
fi
$perl ~/bin/xt.pl &
