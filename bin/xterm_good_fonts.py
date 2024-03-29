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
#    xterm_good_fonts.py
#    
# PURPOSE:
#    Given an output file of good_fonts.ksh, ~/Documents/good_fonts.txt, create
#    xterm windows with those fonts and an array of colors.
#    
# USAGE:
#    xterm_good_fonts.py 
#
#    ~/Documents/good_fonts.txt is hard coded here.  This script takes no args.
#
# PLATFORM:
#   MacOSX
#-------------------------------------------------------------------------------
import os
import subprocess

def execute_xterms_from_file():
    file_path = os.path.expanduser("~/Documents/good_fonts.txt")
    counter = 0
    colors = [
        ("CadetBlue", "black"),
        ("tan", "black"),
        ("SaddleBrown", "white"),
        ("LightYellow", "black"),
        ("DarkGreen", "white"),
        ("DarkSeaGreen", "black"),
        ("grey", "black"),
        ("blue", "white"),
        ("LightSteelBlue", "navy")
    ]

    with open(file_path, 'r') as file:
        for line in file:
            line = line.strip()
            if line:
                counter += 1
                font_family, font_size = line.rsplit(maxsplit=1)
                background_color, foreground_color = colors[(
                    counter - 1) % len(colors)]
                cmd = [
                    "xterm",
                    "-fa",
                    font_family,
                    "-fs",
                    font_size,
                    "-bg",
                    background_color,
                    "-fg",
                    foreground_color,
#                     "-e", f"echo Font Family: {font_family}, Font Size: {font_size}; sleep 99999",
                ]
                subprocess.Popen(cmd, start_new_session=True)
                print(f"Launched xterm ({counter}) with font family: {font_family}, font size: {font_size},"
                      f" background color: {background_color}, foreground color: {foreground_color}")

    print(f"Total number of xterms launched: {counter}")


# Call the function to execute xterms
execute_xterms_from_file()
