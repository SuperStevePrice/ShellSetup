#!/usr/bin/env ksh
if [ X"$(uname)" == X"Darwin" ]
then
    perl=/usr/local/bin/perl5.36.1
else
    perl=/usr/bin/perl5.34-x86_64-linux-gnu
fi
$perl ~/bin/xt.pl &
