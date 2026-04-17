#!/usr/bin/env ksh

# xterm*font: DejaVuSansMono-Bold:pixelsize=18
# xterm*font: SourceCodePro-Bold:pixelsize=18
# xterm*font: Consolas-Bold:pixelsize=18

fonts="DejaVuSansMono-Bold:pixelsize=18 SourceCodePro-Bold:pixelsize=18"
fonts="$fonts Consolas-Bold:pixelsize=18"
geo="80x45"

for font in $(print $fonts) 
do
	for bg in $(print "DarkGreen Tan")
	do
		if [ "$bg" == "DarkGreen" ]; then
			fg="White"
		else
			fg="Black"
		fi

		xterm -fa "$font" -fg "$fg" -bg "$bg" -geometry "$geo" &
	done
done
