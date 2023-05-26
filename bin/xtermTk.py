#!/usr/bin/env python

import os
import socket
import shutil
import sys
from datetime import datetime
import tkinter as tk
import getpass
import shlex

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
#root.configure(background="CadetBlue")  # Set the background color


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

def launch_xterm():
    # Build the xterm command
    scrollback_lines = accepted_values["scrollback_lines"]
    font = accepted_values["font"]
    font_size = accepted_values["font_size"]
    geometry = f'{accepted_values["columns"]}x{accepted_values["rows"]}'
    foreground_color = accepted_values["foreground_color"]
    background_color = accepted_values["background_color"]

    title = f'{os.environ["USER"]}@{socket.gethostname()} {datetime.now()}'
    cmd = (
        f'/usr/bin/env xterm '
        f'-sb -sl {scrollback_lines} '
        f'-fa "{font}" -fs {font_size} '
        f'-geometry {geometry} '
        f'-fg {foreground_color} -bg {background_color} '
        f'-title "{title}"'
    )

 
    # Uncomment the following line to debug:
    #print(f"DEBUG: 'cmd=' [{cmd}]")

    try:
        return_code = os.system(cmd)
        if return_code != 0:
            print(f"Command execution failed with return code: {return_code}")
    except Exception as e:
        print(f"Command execution failed with exception: {str(e)}")


def quit_app():
    root.quit()

# Create the user interface elements
background_color_label = tk.Label(root, text="Background Color:")
background_color_label.grid(row=0, column=0, sticky=tk.E)

background_color_entry = tk.Entry(root)
background_color_entry.grid(row=0, column=1)

foreground_color_label = tk.Label(root, text="Foreground Color:")
foreground_color_label.grid(row=1, column=0, sticky=tk.E)

foreground_color_entry = tk.Entry(root)
foreground_color_entry.grid(row=1, column=1)

font_label = tk.Label(root, text="Font:")
font_label.grid(row=2, column=0, sticky=tk.E)

font_entry = tk.Entry(root)
font_entry.grid(row=2, column=1)

font_size_label = tk.Label(root, text="Font Size:")
font_size_label.grid(row=3, column=0, sticky=tk.E)

font_size_entry = tk.Entry(root)
font_size_entry.grid(row=3, column=1)

columns_label = tk.Label(root, text="Columns:")
columns_label.grid(row=4, column=0, sticky=tk.E)

columns_entry = tk.Entry(root)
columns_entry.grid(row=4, column=1)

rows_label = tk.Label(root, text="Rows:")
rows_label.grid(row=5, column=0, sticky=tk.E)

rows_entry = tk.Entry(root)
rows_entry.grid(row=5, column=1)

scrollback_lines_label = tk.Label(root, text="Buffer Size:")
scrollback_lines_label.grid(row=6, column=0, sticky=tk.E)

scrollback_lines_entry = tk.Entry(root)
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
