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
#	xterm.py
#	
# PURPOSE:
#	A simple Python script that questions the user at the command line for 
#   attributes of an xterm window, which are used to spawn said window.
#	
# USAGE:
#   xterm.py
#
# PLATFORM:
#   MacOSX
#-------------------------------------------------------------------------------
import os
import socket
import shutil
import sys
from datetime import datetime

# Default values
default_values = {
    "background_color": "CadetBlue",
    "foreground_color": "Black",
    "font": "Courier New Bold",
    "font_size": "16",
    "columns": "80",
    "rows": "45",
    "scrollback_lines": "200",
    "enable_keystroke_logging": False,
    "enable_command_logging": False
}


def write_command_log_file(cmd):
    cmd_log_file = os.path.expanduser('~/Documents/xterm.log')
    print("See xterm commands in the cmd_log file:", cmd_log_file)

    os.makedirs(os.path.dirname(cmd_log_file), exist_ok=True)

    with open(cmd_log_file, 'a') as file:
        if file.tell() != 0:
            file.write('\n\n')
        if isinstance(cmd, str):
            file.write(cmd + '\n')
        elif isinstance(cmd, list):
            file.write(' '.join(cmd) + '\n')
        else:
            raise ValueError("Invalid cmd type")
        if isinstance(cmd, str):
            file.write('\n')


def prompt_user(question, default):
    default_prompt = f" [{default}]" if default else ""
    padding = " " * (40 - len(question) - len(default_prompt))
    #print("DEBUG: ", len(padding), "\n")
    print(f"{question}{padding}{default_prompt}: ", end="")
    user_input = input()
    return user_input if user_input else default


def Xterm(params):
    success = 0
    xterm_path = "/opt/X11/bin/xterm"

    if os.path.exists(xterm_path):
        xterm_executable = xterm_path
        success = 1
    else:
        xterm_executable = shutil.which("xterm")
        if xterm_executable:
            success = 1
        else:
            print("xterm executable not found.")
            sys.exit(1)

    # Gather user preferences
    background_color = prompt_user(
        "Pick a background color", default_values["background_color"])
    foreground_color = prompt_user(
        "Pick a foreground color", default_values["foreground_color"])
    font = prompt_user("Enter the font", default_values["font"])
    font_size = prompt_user("Enter the font size", default_values["font_size"])
    columns = prompt_user("Enter the number of columns", default_values["columns"])
    rows = prompt_user("Enter the number of rows", default_values["rows"])
    scrollback_lines = prompt_user("Enter the scrollback lines size",
                              default_values["scrollback_lines"])

    enable_keystroke_logging = prompt_user(
        "Enable keystroke logging? (Y/N)", "Y" if default_values["enable_keystroke_logging"] else "N") == "Y"
    enable_command_logging = prompt_user(
        "Enable command logging? (Y/N)", "Y" if default_values["enable_command_logging"] else "N") == "Y"

    if enable_keystroke_logging:
        log = " -l "
    else:
        log = ""

    # Build the xterm command
    cmd = [
        xterm_executable,
        "-sb",
        "-sl",
        scrollback_lines,
        "-fa",
        f"'{font}'",
        "-fs",
        font_size,
        "-geometry",
        f"{columns}x{rows}",
        "-fg",
        foreground_color,
        "-bg",
        log,
        background_color,
        "-title",
        f"'{os.environ['USER']}@{socket.gethostname()} {datetime.now()}'"
    ]

    # Execute the xterm command
    pid = os.fork()

    if pid == 0:
        # Child process
        os.system(" ".join(cmd))
        exit(0)
    elif pid > 0:
        # Parent process
        print("\nxterm launched in the background.\n")
        write_command_log_file(cmd)
        if enable_command_logging:
            try:
                write_command_log_file(cmd)
                print("The xterm command has been written to the xterm.log.")
            except Exception as e:
                print(f"Error writing to log file: {str(e)}")
    else:
        # Forking failed
        raise RuntimeError("Failed to fork a child process")

# Call the Xterm function
Xterm({})
