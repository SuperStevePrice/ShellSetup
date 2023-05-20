#!/usr/bin/env python

import os
from datetime import datetime

xterm_path = "/opt/X11/bin/xterm"
xterm_path = "/usr/bin/xterm"

# Define and initialize parameters dictionary
params = {
    "bg": "CadetBlue",
    "fg": "Black",
    "fn": "9x15bold",
    "cols": "80",
    "rows": "45",
    "sl": "200",
    "log": 'N',
    "dbg": 'N'
}

# Function to prompt user and return input


def prompt_user(prompt, default=None):
    default_text = f"[{default}]" if default else ""
    return input(f"{prompt:<30s} {default_text}: ") or default

# Function to launch xterm


def Xterm(params):
    # Format the title
    title = f"steve@ {datetime.now()}"

    # Determine the font parameter
    font_param = "-fa" if " " in params["fn"] else "-fn"
    font_value = f'"{params["fn"]}"' if font_param == "-fn" else params["fn"]

    # Format the xterm command
    cmd = f"{xterm_path} -sb -sl {params['sl']} {font_param} {font_value} "
    cmd += f"-geometry {params['cols']}x{params['rows']} -fg \"{params['fg']}\" "
    cmd += f"-bg \"{params['bg']}\" -title \"{title}\""
    cmd += " -l" if params['log'].lower() == 'y' else ""

    # Execute the xterm command in a separate process
    pid = os.fork()

    if pid == 0:
        # Child process
        os.system(cmd)
        exit(0)
    elif pid > 0:
        # Parent process
        print("xterm launched in the background.")
        write_debug_file(cmd, params['dbg'])
    else:
        # Forking failed
        raise RuntimeError("Failed to fork a child process")

# Prompt user for parameter values


def get_user_inputs():
    print()
    params['bg'] = prompt_user(
        "Pick a background color", params['bg'])
    params['fg'] = prompt_user(
        "Pick a foreground color", params['fg'])
    params['fn'] = prompt_user(
        "Enter the font", params['fn'])
    params['cols'] = prompt_user(
        "Enter the number of columns", params['cols'])
    params['rows'] = prompt_user(
        "Enter the number of rows", params['rows'])
    params['sl'] = prompt_user(
        "Enter the memory buffer size", params['sl'])
    params['log'] = prompt_user(
        "Enable logging? (Y/N)", params['log'])
    params['dbg'] = prompt_user(
        "Enable debugging? (Y/N)", params['dbg'])
    print()

# Function to write to the debug file
def write_debug_file(cmd, dbg):
    debug_file = os.path.expanduser("~/Documents/xterm.debug")
    print("See debug file:", debug_file)

    try:
        with open(debug_file, 'a') as fh:
            fh.write(cmd + "\n")
    except Exception as e:
        print(f"Failed to write to debug file: {str(e)}")
        print(f"Current directory: {os.getcwd()}")

        return debug_file


# Launch xterm
get_user_inputs()
Xterm(params)
