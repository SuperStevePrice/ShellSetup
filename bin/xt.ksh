#!/usr/bin/env ksh
if [ X"$(uname)" == X"Darwin" ]
then
        perl=/opt/homebrew/bin/perl
        if [ ! -f $perl ]
        then
            perl=/usr/local/Cellar/perl/5.36.1/bin/perl5.36.1
        fi
else
    perl=/usr/bin/perl5.34-x86_64-linux-gnu
fi

if [ ! -f $perl ]
then
    print "Perl not found.  No such file: $perl"
    exit 1
else
    $perl ~/bin/xt.pl &
    exit 0
fi
