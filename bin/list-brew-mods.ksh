#!/usr/bin/env ksh

perl=$(which perl)
ts=$(date +%Y%m%d%H%M%S)
log=~/Documents/brew-mods.log.$ts

exec 3>&1 4>&2 >>"$log" 2>&1

echo "Perl Path: $perl"
echo
"$perl" -MExtUtils::Installed -E 'my $inst = ExtUtils::Installed->new(); my @modules = $inst->modules(); say for @modules;'
echo
date

exec 1>&3 2>&4 3>&- 4>&-

echo "See log file: $log"
