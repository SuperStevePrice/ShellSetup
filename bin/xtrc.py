#!/usr/bin/env python3

#-------------------------------------------------------------------------------
#         Copyright (C) 2023    Steve Price    SuperStevePrice@gmail.com
#
#                       GNU GENERAL PUBLIC LICENSE
#                        Version 3, 29 June 2007
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# PROGRAM:
#   xtrc.py
#   
# PURPOSE:
#   Python subroutines to be used by xt.py and any Python scripts that use the
#   .xtrc environmental variables.
#   
# USAGE:
#   import xtrc
#-------------------------------------------------------------------------------
import datetime as dt
import os

def set_cmd(xtrc):
    """
    set_cmd builds a legal xterm command using xtrc dictionary elements.

    Parameters
    ----------
    xtrc : TYPE
        DESCRIPTION.

    Returns
    -------
    cmd : TYPE
        DESCRIPTION.

    """
    xterm_executable = f"{xtrc['x_path']}/xterm"

    # Build the xterm command
    cmd =  \
        xterm_executable + \
        " -sb " + \
        " -sl " + \
        xtrc['x_sl'] + \
        " -fa " + \
        f"'{xtrc['x_fa']}'" + \
        " -fs " + \
        xtrc['x_fs'] + \
        " -geometry " + \
        f"{xtrc['x_cols']}x{xtrc['x_rows']}" + \
        " -fg " + \
        xtrc['x_fg'] + \
        " -bg " + \
        xtrc['x_bg'] + \
        " -title " + \
        f"'{os.environ['USER']}@{os.environ['HOME']} {dt.datetime.now()}'"

    #print("DEBUG: set_cmd: Pre: ", cmd)

    if xtrc['x_log'] == 1:
        cmd += " -l"
    #print("DEBUG: set_cmd: Post: ", cmd)

    return cmd


def set_colors():
    """
    set_colors defines background and foreground color pairs for xterm buttons.

    Returns
    -------
    colors : TYPE
        DESCRIPTION.

    """
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
    return colors


def set_xtrc():
    """
    set_xtrc defines xtrc values by parsing the .xtrc file.

    Returns
    -------
    xtrc : TYPE
        DESCRIPTION.

    """
    # set defaults:
    xtrc = {
        'x_rows': "24",
        'x_cols': "80",
        'x_fg': "black",
        'x_bg': "grey",
        'x_fa': "9x15bold",
        'x_fs': "16",
        'x_log': 'None',
        'x_sl': 200,
        'x_path': ""
    }

    # Read the .xtrc or ~/.xtrc file
    try:
        with open('.xtrc', 'r') as file:
            config_lines = file.readlines()
    except FileNotFoundError:
        try:
            with open(os.path.expanduser('~/.xtrc'), 'r') as file:
                config_lines = file.readlines()
        except FileNotFoundError:
            print("No .xtrc or ~/.xtrc file found.")
            return

    # Parse the configuration lines
    # and update the xtrc dictionary
    for line in config_lines:
        line = line.strip()
        if line.startswith('#'):
            continue

        if line.startswith('x_cols'):
            xtrc['x_cols'] = line.split('=')[1].strip()
        elif line.startswith('x_rows'):
            xtrc['x_rows'] = line.split('=')[1].strip()
        elif line.startswith('x_sl'):
            xtrc['x_sl'] = line.split('=')[1].strip()
        elif line.startswith('x_fa'):
            xtrc['x_fa'] = line.split('=')[1].strip().replace(' ', '')
        elif line.startswith('x_fs'):
            xtrc['x_fs'] = line.split('=')[1].strip()
        elif line.startswith('x_bg'):
            xtrc['x_bg'] = line.split('=')[1].strip()
        elif line.startswith('x_fg'):
            xtrc['x_fg'] = line.split('=')[1].strip()
        elif line.startswith('x_path'):
            xtrc['x_path'] = line.split('=')[1].strip()
        elif line.startswith('x_log'):
            xtrc['x_log'] = int(line.split('=')[1].strip())
            xtrc['x_log'] = 0      # default: no logging

    return xtrc


def xtrc_values(xtrc):
    """
    xtrc_values is a debugging report for the xtrc dictionary.

    Parameters
    ----------
    xtrc : TYPE
        DESCRIPTION.

    Returns
    -------
    None.

    """
    print("\nxtrc:")
    for key, value in xtrc.items():
        print(f"{key}:\t{value}")


def colors_values(colors):
    """
    colors_values is a debugging report for the colors data structure.

    Parameters
    ----------
    colors : TYPE
        DESCRIPTION.

    Returns
    -------
    None.

    """
    print("\nColors:")
    for idx, val in enumerate(colors):
        print(f"{idx + 1}. {val}")


if __name__ == "__main__":
    colors = set_colors()
    colors_values(colors)
    xtrc = set_xtrc()
    xtrc_values(xtrc)
    print("\n", set_cmd(set_xtrc()))
