#!/Users/steve/anaconda3/bin/python3.10

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
#	font_selector.py
#	
# PURPOSE:
#	Present a scrollable pick list of all xlsfonts. User may Select, Submit, or
#   Cancel.  Submit returns selected font; Cancel returns None. Both buttons
#   close this app.   The current font will be illustrated by "Sample Text" in
#   the current font.
#	
# USAGE:
#   font_selector.py        At the CLI as a stand alone app.
#   import font_selector    As an imported component of anothe Python script.
#                           The importer should use this line: 
#                           selected_font = font_selector.run_font_selector()
#
# PLATFORM:
#   MacOSX
#-------------------------------------------------------------------------------



import subprocess
import tkinter as tk
import xtrc as xt



class FontSelectorDialog:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("Font Selector")
        self.selected_font = None

        available_fonts = self.get_available_fonts()

        list_frame = tk.Frame(self.root)
        list_frame.pack(padx=10, pady=10)

        self.listbox = tk.Listbox(list_frame, width=60, height=10)
        scrollbar = tk.Scrollbar(list_frame, command=self.listbox.yview)
        self.listbox.config(yscrollcommand=scrollbar.set)
        self.listbox.pack(side=tk.LEFT)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        for font in available_fonts:
            self.listbox.insert(tk.END, font)

        self.font_entry = tk.Entry(self.root, width=60, justify=tk.CENTER)
        default_font = available_fonts[0]
        self.font_entry.insert(tk.END, default_font)
        self.font_entry.pack(padx=10, pady=(0, 10))

        button_frame = tk.Frame(self.root)
        button_frame.pack(padx=10, pady=10)

        select_button = tk.Button(button_frame, text="Select", width=10, command=self.select_font)
        select_button.pack(side=tk.LEFT, padx=5)

        submit_button = tk.Button(button_frame, text="Submit", width=10, command=self.submit_selection)
        submit_button.pack(side=tk.LEFT, padx=5)

        self.font_label = tk.Label(self.root, text="Preview Text", font=(default_font, 12), fg="DarkRed")
        self.font_label.pack(pady=10)

        cancel_button = tk.Button(button_frame, text="Cancel", width=10, command=self.cancel_selection)
        cancel_button.pack(side=tk.LEFT, padx=5)

        self.listbox.bind('<<ListboxSelect>>', self.select_font)

    def get_available_fonts(self):
        xtrc = xt.set_xtrc()
        xlsfonts = xtrc['x_path'] + "/xlsfonts"
        process = subprocess.Popen([xlsfonts], 
            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
        output, _ = process.communicate()
        available_fonts = output.decode('utf-8').splitlines()
        return available_fonts

    def select_font(self, event=None):
        selected_index = self.listbox.curselection()
        if selected_index:
            index = int(selected_index[0])
            font_name = self.listbox.get(index)
            self.font_entry.delete(0, tk.END)
            self.font_entry.insert(tk.END, font_name)
            self.font_label.config(font=(font_name, 12))

    def submit_selection(self):
        self.selected_font = self.font_entry.get()
        self.root.quit()

    def cancel_selection(self):
        self.selected_font = None
        self.root.quit()

def run_font_selector():
    dialog = FontSelectorDialog()
    dialog.root.mainloop()
    selected_font = dialog.selected_font
    dialog.root.withdraw()  # Withdraw the root window instead of destroying it
    return selected_font

# Check if the script is executed as a standalone test script
if __name__ == "__main__":
    selected_font = run_font_selector()
    print("Selected font:", selected_font)
