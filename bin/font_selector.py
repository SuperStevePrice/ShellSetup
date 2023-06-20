#!/usr/bin/env python

#-------------------------------------------------------------------------------
#         Copyright (C) 2023    Steve Price    SuperStevePrice@gmail.com
#
#                       GNU GENERAL PUBLIC LICENSE
#                        Version 3, 29 June 2007
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# PROGRAM:
#	font_selector.py
#	
# PURPOSE:
#	This Python program provides methods to select and return a font name taken
#   from xlsfonts executable.
#	
# USAGE:
#   font_selector.py        When run as a stand-alone program.
#   import font_selector    When imported into anothey Python program.
#-------------------------------------------------------------------------------

import tkinter as tk
import subprocess

selected_font = None  # Global variable to store the selected font

def cancel_selection():
    global selected_font
    selected_font = None
    font_selector_window.destroy()

def get_available_fonts():
    process = subprocess.Popen(['/opt/X11/bin/xlsfonts'], 
    stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    output, _ = process.communicate()
    available_fonts = output.decode('utf-8').splitlines()
    return available_fonts

def submit_selection():
    global selected_font
    selected_font = font_entry.get()
    font_selector_window.destroy()

def select_font(event):
    widget = event.widget
    index = int(widget.curselection()[0])
    font_name = widget.get(index)
    font_entry.delete(0, tk.END)
    font_entry.insert(tk.END, font_name)

def run_font_selector():
    global font_selector_window, selected_font, font_entry

    font_selector_window = tk.Tk()
    font_selector_window.title("Font Selector")

    available_fonts = get_available_fonts()

    list_frame = tk.Frame(font_selector_window)
    list_frame.pack(padx=10, pady=10)

    listbox = tk.Listbox(list_frame, width=60, height=10)
    scrollbar = tk.Scrollbar(list_frame, command=listbox.yview)
    listbox.config(yscrollcommand=scrollbar.set)
    listbox.pack(side=tk.LEFT)
    scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

    for font in available_fonts:
        listbox.insert(tk.END, font)

    font_entry = tk.Entry(font_selector_window, width=60, justify=tk.CENTER)
    default_font = available_fonts[0]
    font_entry.insert(tk.END, default_font)
    font_entry.pack(padx=10, pady=(0, 10))

    button_frame = tk.Frame(font_selector_window)
    button_frame.pack(padx=10, pady=10)

    select_button = tk.Button(button_frame, text="Select",
        width=10, command=submit_selection)
    select_button.pack(side=tk.LEFT, padx=5)

    cancel_button = tk.Button(button_frame, text="Cancel", width=10, 
        command=cancel_selection)
    cancel_button.pack(side=tk.LEFT, padx=5)

    listbox.bind('<Double-Button-1>', select_font)

    font_selector_window.mainloop()

    return selected_font

# Check if the script is executed as a standalone test script
if __name__ == "__main__":
    selected_font = run_font_selector()
    print("Selected font:", selected_font)
