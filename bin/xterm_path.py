#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Jun  6 16:29:33 2023

@author: steve
"""

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
