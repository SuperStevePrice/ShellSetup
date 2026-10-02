#!/bin/ksh
#
# git_stat_all.ksh
# Checks `git status` for ~/Projects/SS on each of Steve's machines.
#
# Each iteration builds the ssh command into a variable, prints it
# (diagnostic/info for the user at runtime), then executes that exact
# same string via eval — so there's one source of truth instead of
# keeping the printed form and the executed form in sync by hand.
#
# Note: eval re-parses the string, so quoting still matters. Here the
# remote command is embedded with escaped double quotes so ssh receives
# it as ONE argument: cd ~/Projects/SS && git status

for server in stevesmacbook-pro imac-linux macbookpro-linux steves-imac
do
    print "Server: $server"

    cmd="ssh \"steve@${server}\" \"cd ~/Projects/SS && git status\""

    print "$cmd"
    eval "$cmd"
    print
done
