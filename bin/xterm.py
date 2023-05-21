#!/usr/bin/env python

import subprocess
import os
import socket
import shutil
from datetime import datetime

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
    background_color = input("Pick a background color [CadetBlue]: ") or "CadetBlue"
    foreground_color = input("Pick a foreground color [Black]: ") or "Black"
    font = input("Enter the font [9x15bold]: ") or "9x15bold"
    columns = input("Enter the number of columns [80]: ") or "80"
    rows = input("Enter the number of rows [45]: ") or "45"
    buffer_size = input("Enter the memory buffer size [200]: ") or "200"
    enable_keystroke_logging = input("Enable keystroke logging? (Y/N) [N]: ") == "Y"
    enable_command_logging = input("Enable command logging? (Y/N) [N]: ") == "Y"

    # Build the xterm command
    cmd = [
        xterm_executable,
        "-sb",
        "-sl",
        buffer_size,
        "-fn",
        font,
        "-geometry",
        f"{columns}x{rows}",
        "-fg",
        foreground_color,
        "-bg",
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
        print("xterm launched in the background.")
        write_command_log_file(cmd)
        if enable_command_logging:
            try:
                write_command_log_file(cmd)
            except Exception as e:
                print(f"Error writing to log file: {str(e)}")
    else:
        # Forking failed
        raise RuntimeError("Failed to fork a child process")

# Call the Xterm function
Xterm({})

