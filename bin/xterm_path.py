#!/Users/steve/anaconda3/bin/python3.11

## Linux use: "#!/usr/bin/env python3".
## MacOS use: "#!/Users/steve/anaconda3/bin/python3.11"

#-------------------------------------------------------------------------------
#         Copyright (C) 2023    Steve Price    SuperStevePrice@gmail.com
#
#                       GNU GENERAL PUBLIC LICENSE
#                        Version 3, 29 June 2007
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# PROGRAM:
#	xterm_path.py
#	
# PURPOSE:
#	Find the full path of xterm.
#	
# USAGE:
#   xterm_path.py
#
# PLATFORM:
#   MacOSX
#-------------------------------------------------------------------------------
import os

def find_xterm():
    xterm_names = ['xterm', 'xterm-color', 'xterm-256color']

    for path in os.environ['PATH'].split(os.pathsep):
        for xterm_name in xterm_names:
            xterm_path = os.path.join(path, xterm_name)
            if os.path.isfile(xterm_path) and os.access(xterm_path, os.X_OK):
                return xterm_path
    return 'xterm'

xterm_path = find_xterm()
print(xterm_path)
