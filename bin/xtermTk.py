#!/usr/bin/env python3

## Linux use: "#!/usr/bin/env python3".
## MacOS use: "#!/Users/steve/anaconda3/bin/python3.10"

#-------------------------------------------------------------------------------
#         Copyright (C) 2023    Steve Price    SuperStevePrice@gmail.com
#
#                       GNU GENERAL PUBLIC LICENSE
#                        Version 3, 29 June 2007
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# PROGRAM:
#	xtermTk.py
#	
# PURPOSE:
#	This Python program presents a simple widget window 
#	
# USAGE:
#   xtermTk.py
#
# PLATFORM:
#   Linux
#-------------------------------------------------------------------------------
import os
import socket
from datetime import datetime
import tkinter as tk
from tkinter import ttk
import subprocess
import locale 
import argparse

# The locale code below is commented out because it apparently prevents xterm
# windows from being visible.   The code was added to silence warnings about 
# locale settings.  As they are only warnings and do not impact the operation
# of this script, I will live with them.  I leave this code behind in case I 
# understand this locale stuff better in the future:
#
# # Get the system's default locale
# system_locale = locale.getdefaultlocale()

# # Set a fallback default locale if the system locale is None
# fallback_locale = ('en_US', 'UTF-8')
# if system_locale[0] is None:
#     system_locale = fallback_locale

#     # Set the locale based on the system's default locale
#     locale.setlocale(locale.LC_ALL, system_locale)

#     # Set the LC_ALL environment variable
#     os.environ['LC_ALL'] = system_locale[0]  # Use only language part of locale

# Create an ArgumentParser object
parser = argparse.ArgumentParser(description='Run xterm command')

# Add an argument for enabling debug mode
parser.add_argument('-d', '--debug', action='store_true',
                    help='Enable debug mode')

args = parser.parse_args()
debug = args.debug

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

# Accepted values
accepted_values = default_values.copy()

# Create the main window
root = tk.Tk()
root.title("xterm Configuration")

# Define global variables
enable_keystroke_logging_var = None
enable_command_logging_var = None

# Define functions
def update_displayed_values():
    background_color_entry.delete(0, tk.END)
    background_color_entry.insert(0, accepted_values["background_color"])

    foreground_color_entry.delete(0, tk.END)
    foreground_color_entry.insert(0, accepted_values["foreground_color"])

    font_entry.delete(0, tk.END)
    font_entry.insert(0, accepted_values["font"])

    font_size_entry.delete(0, tk.END)
    font_size_entry.insert(0, accepted_values["font_size"])

    columns_entry.delete(0, tk.END)
    columns_entry.insert(0, accepted_values["columns"])

    rows_entry.delete(0, tk.END)
    rows_entry.insert(0, accepted_values["rows"])

    scrollback_lines_entry.delete(0, tk.END)
    scrollback_lines_entry.insert(0, accepted_values["scrollback_lines"])

    enable_keystroke_logging_var.set(accepted_values["enable_keystroke_logging"])
    enable_command_logging_var.set(accepted_values["enable_command_logging"])

def accept_defaults():
    update_displayed_values()

def accept_changes():
    accepted_values["background_color"] = background_color_entry.get()
    accepted_values["foreground_color"] = foreground_color_entry.get()
    accepted_values["font"] = font_entry.get()
    accepted_values["font_size"] = font_size_entry.get()
    accepted_values["columns"] = columns_entry.get()
    accepted_values["rows"] = rows_entry.get()
    accepted_values["scrollback_lines"] = scrollback_lines_entry.get()
    accepted_values["enable_keystroke_logging"] = enable_keystroke_logging_var.get()
    accepted_values["enable_command_logging"] = enable_command_logging_var.get()

def log_command(cmd):
    log_file = os.path.expanduser("~/Documents/xterm.log")
    with open(log_file, "a") as f:
        f.write("\n" + cmd + "\n")

def launch_xterm():
    # Build the xterm command
    scrollback_lines = accepted_values["scrollback_lines"]
    font = accepted_values["font"]
    font_size = accepted_values["font_size"]
    geometry = f'{accepted_values["columns"]}x{accepted_values["rows"]}'
    foreground_color = accepted_values["foreground_color"]
    background_color = accepted_values["background_color"]

    # NOTE: font and title values must be enclosed in quotation marks.
    title = f'{os.environ["USER"]}@{socket.gethostname()} {datetime.now()}'
    cmd = [
        "/usr/bin/env", "xterm",
        "-sb",
        "-sl", scrollback_lines,
        "-fa", f'"{font}"',
        "-fs", font_size,
        "-geometry", geometry,
        "-fg", foreground_color,
        "-bg", background_color,
        "-title", f'"{title}"'
    ]

    if enable_keystroke_logging_var.get():
        cmd.append("-l")

    try:
        if debug:
            print("DEBUG: cmd: ", cmd)
        process = subprocess.Popen(cmd)

        if accepted_values["enable_command_logging"]:
            log_command(" ".join(cmd))  # Log the command

        process.communicate()  # Wait for the process to finish

    except subprocess.CalledProcessError as e:
        print(f"Command execution failed with return code: {e.returncode}")
        print(f"Error output: {e.output}")
    except Exception as e:
        print(f"Command execution failed with exception: {str(e)}")

def quit_app():
    root.quit()

# Create the user interface elements
style = ttk.Style()
style.configure(
    "CustomEntry.TEntry",
    fieldbackground="light grey",
    foreground="navy",
    font=("Courier New", 12, "bold")
)

background_color_label = tk.Label(root, text="Background Color:")
background_color_label.grid(row=0, column=0, sticky=tk.E)

background_color_entry = ttk.Entry(root, style="CustomEntry.TEntry")
background_color_entry.grid(row=0, column=1)

foreground_color_label = tk.Label(root, text="Foreground Color:")
foreground_color_label.grid(row=1, column=0, sticky=tk.E)

foreground_color_entry = ttk.Entry(root, style="CustomEntry.TEntry")
foreground_color_entry.grid(row=1, column=1)

font_label = tk.Label(root, text="Font:")
font_label.grid(row=2, column=0, sticky=tk.E)

font_entry = ttk.Entry(root, style="CustomEntry.TEntry")
font_entry.grid(row=2, column=1)

font_size_label = tk.Label(root, text="Font Size:")
font_size_label.grid(row=3, column=0, sticky=tk.E)

font_size_entry = ttk.Entry(root, style="CustomEntry.TEntry")
font_size_entry.grid(row=3, column=1)

columns_label = tk.Label(root, text="Columns:")
columns_label.grid(row=4, column=0, sticky=tk.E)

columns_entry = ttk.Entry(root, style="CustomEntry.TEntry")
columns_entry.grid(row=4, column=1)

rows_label = tk.Label(root, text="Rows:")
rows_label.grid(row=5, column=0, sticky=tk.E)

rows_entry = ttk.Entry(root, style="CustomEntry.TEntry")
rows_entry.grid(row=5, column=1)

scrollback_lines_label = tk.Label(root, text="Buffer Size:")
scrollback_lines_label.grid(row=6, column=0, sticky=tk.E)

scrollback_lines_entry = ttk.Entry(root, style="CustomEntry.TEntry")
scrollback_lines_entry.grid(row=6, column=1)

enable_keystroke_logging_var = tk.BooleanVar()
enable_keystroke_logging_var.set(accepted_values["enable_keystroke_logging"])

enable_keystroke_logging_checkbox = tk.Checkbutton(
    root, text="Enable Keystroke Logging", variable=enable_keystroke_logging_var)
enable_keystroke_logging_checkbox.grid(row=7, column=0, columnspan=2)

enable_command_logging_var = tk.BooleanVar()
enable_command_logging_var.set(accepted_values["enable_command_logging"])

enable_command_logging_checkbox = tk.Checkbutton(
    root, text="Enable Command Logging", variable=enable_command_logging_var)
enable_command_logging_checkbox.grid(row=8, column=0, columnspan=2)

accept_defaults_button = tk.Button(root, text="Accept Defaults", command=accept_defaults)
accept_defaults_button.grid(row=9, column=0)

accept_changes_button = tk.Button(root, text="Accept Changes", command=accept_changes)
accept_changes_button.grid(row=9, column=1)

launch_xterm_button = tk.Button(root, text="Launch xterm", command=launch_xterm)
launch_xterm_button.grid(row=10, column=0, columnspan=2)

quit_button = tk.Button(root, text="Quit", command=quit_app)
quit_button.grid(row=11, column=0, columnspan=2)

# Update displayed values
update_displayed_values()

# Start the Tkinter event loop
root.mainloop()
