#!/usr/bin/env ksh
#-------------------------------------------------------------------------------
# PROGRAM:
#       get_ip.ksh
#
# PURPOSE:
#       Display OS, Server, and non-loopback IP address(es).
# USAGE:
#       get_ip.ksh
#-------------------------------------------------------------------------------

os=$(uname -s)

case $os in
	Linux)
		ip=$(ip addr show | awk '/inet / && !/127.0.0.1/ {print $2}'| head -n 1)
		;;
	Darwin)
		ip=$(ifconfig | awk '/inet / && !/127.0.0.1/ {print $2}' | head -n 1)
		;;
	*)
		echo "Unsupported OS: $os"
		exit 1
		;;
esac

echo -e "OS:\t$os"
echo -e "Name:\t$(uname -n)"
echo -e "Server:\t$ip"
echo
