#!/usr/bin/env ksh
#-------------------------------------------------------------------------------
#         Copyright (C) 2023    Steve Price    SuperStevePrice@gmail.com
#
#                       GNU GENERAL PUBLIC LICENSE
#                        Version 3, 29 June 2007
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# PROGRAM:
#	xterms.ksh
#	
# PURPOSE:
#	Generate 3 pairs of xterm windows, each pair sharing a font. All six xterm
#	windows will have unique colors.
#	
# USAGE:
#	xterms.ksh
#-------------------------------------------------------------------------------

# Define the color pairs
colors=(
"CadetBlue        black"
"tan              black"
"SaddleBrown      white"
"LightYellow      black"
"DarkGreen        white"
"DarkSeaGreen     black"
"grey             black"
"blue             white"
"LightSteelBlue   navy"
"black            lightSteelBlue"
"navy             yellow"
"salmon           black"
)

# Define the fonts
fonts="DejaVuSansMono-Bold:pixelsize=18 SourceCodePro-Bold:pixelsize=18 Consolas-Bold:pixelsize=18"

# Define the xterm geometry
geo="80x45"

# Calculate the total number of color pairs and fonts
num_colors=${#colors[@]}
num_fonts=$(echo $fonts | wc -w)

# Loop over the fonts and color pairs
index=0
for font in $fonts
do
	for i in 1 2
	do
	# Calculate the color pair index
	color_index=$((index % num_colors))
	color_pair=${colors[$color_index]}
	bg=$(echo $color_pair | awk '{print $1}')
	fg=$(echo $color_pair | awk '{print $2}')

	# Launch xterm with specified font, foreground, and background colors
	xterm			\
		-fa "$font" \
		-fg "$fg"	\
		-bg "$bg"	\
		-geometry "$geo" > /dev/null 2>&1 &

	# Increment the color pair index
	index=$((index + 1))
	done
done
