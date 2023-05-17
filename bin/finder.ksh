#!/usr/bin/env ksh

line=$(print "#$(printf -- '-%.0s' {1..79})")

finder() {
	print "find / -name $1"
	find / -name $1
}

for target in $(print Tk.pm perl perl.h)
do
	print 
	finder $target
	print $line
done
