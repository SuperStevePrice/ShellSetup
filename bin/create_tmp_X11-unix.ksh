#!/usr/bin/env ksh
#-------------------------------------------------------------------------------
# PROGRAM:
#   create_tmp_X11-unix.ksh
#   
# PURPOSE:
#   Create /tmp/.X11-unix and set permissions
#   
# USAGE:
#   create_tmp_X11-unix.ksh
#
#   Place a call in the MacOS login scripts.
#
#-------------------------------------------------------------------------------

# Create the /tmp/.X11-unix directory if it doesn't exist
DIR=/tmp/.X11-unix
if [ ! -d "$DIR" ]; then
     /bin/mkdir -p "$DIR"
     /bin/chmod 1777 "$DIR"
else
     /bin/chmod 1777 "$DIR"
fi

# Change ownership to root:wheel
sudo /usr/sbin/chown root:wheel "$DIR"

# Testing commands, may be commented out for production:
echo "Script executed at $(date)" >> /tmp/com.steve.create_tmp_X11-unix.log
env > /tmp/create_tmp_X11-unix-env.txt

