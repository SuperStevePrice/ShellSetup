#!/usr/bin/env python

#-------------------------------------------------------------------------------
#         Copyright (C) 2023    Steve Price    SuperStevePrice@gmail.com
#
#                       GNU GENERAL PUBLIC LICENSE
#                        Version 3, 29 June 2007
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# PROGRAM:
#   xt.pl
#   
# PURPOSE:
#   This Python script presents a tkinter dashboard to launch xterm windows.
#   
# USAGE:
#   xt.py
#-------------------------------------------------------------------------------

import tkinter as tk
import subprocess
import sys
import os

# Get the absolute path of the current directory
current_dir = os.path.abspath(os.path.dirname(__file__))

# Add the ~/bin directory to the module search path
bin_dir = os.path.expanduser('~/bin')
sys.path.insert(0, bin_dir)

# Import the module from the ~/bin directory
import set_globals

xtrc = set_globals.set_globals()
#print("DEBUG: xtrc:", xtrc)

colors = [
    ("grey", "black"),
    ("LightSteelBlue", "navy"),
    ("CadetBlue", "white"),
    ("CadetBlue", "black"),
    ("blue", "white"),
    ("navy", "white"),
    ("navy", "orange"),
    ("navy", "yellow"),
    ("DarkGreen", "white"),
    ("DarkSeaGreen", "black"),
    ("DarkRed", "white"),
    ("salmon", "black"),
    ("SaddleBrown", "white"),
    ("tan", "black"),
    ("LightYellow", "black"),
    ("black", "lightSteelBlue")
]

# Calculate the number of rows needed for centering
num_rows = (len(colors) + 1) // 2

root = tk.Tk()
root.geometry('500x600')
root.title('Button color demo !!')

# Set the background color of the root window to black
root.configure(bg='black')

def on_button_press(button):
    button.config(bg=button.color_pair[0],
                  fg=button.color_pair[1],
                  highlightbackground=button.color_pair[0],
                  highlightcolor=button.color_pair[0])

    # Get the color values for xterm command
    bg_color, fg_color = button.color_pair

    xterm_path = xtrc['x_path'] + "/xterm"
    #print("DEBUG: ", xterm_path)
    cmd = f"{xtrc['x_path']}/xterm -sl {xtrc['x_sl']} " \
        f"-geometry {xtrc['x_cols']}x{xtrc['x_rows']} " \
        f"-fa {xtrc['x_fa']} -fs {xtrc['x_fs']} " \
        f"-title \"Steve\'s Term Window\" -fg {fg_color} " \
        f"-bg {bg_color}"

    #print(cmd)

    if xterm_path is not None:
        # xterm executable found
        # Launch xterm with the specified colors and parameters
        subprocess.Popen(cmd, shell=True)

    else:
        # xterm not found
        print("xterm is not installed or cannot be found in system PATH.")

# Set the grid column weights to center the buttons
root.grid_columnconfigure(0, weight=1)
root.grid_columnconfigure(1, weight=1)

for i, color_pair in enumerate(colors):
    button = \
       tk.Button(root, text=f'Xterm Window {str(i + 1).zfill(2)}',
       width=10, height=1, relief=tk.RAISED)
    button.color_pair = color_pair
    button.bind('<ButtonPress-1>', lambda event,
                button=button: on_button_press(button))

    # Calculate the row and column indices
    row = i // 2
    column = i % 2

    button.grid(row=row, column=column, padx=5, pady=10,
                sticky='nsew')

    # Set button colors
    button.configure(bg=color_pair[0], fg=color_pair[1],
                     highlightbackground=color_pair[0],
                     highlightcolor=color_pair[0])

# Add a Quit button centered at the bottom of the root window
quit_button = tk.Button(root, text='Quit', width=15, height=2,
                        relief=tk.RAISED,
                        command=root.destroy)
quit_button.grid(row=num_rows, columnspan=2, pady=10)

root.mainloop()
