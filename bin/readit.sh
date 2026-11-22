#!/bin/bash

# Prompt for voice
read -p "Enter the voice name (e.g., Anna, Alex, Samantha): " VOICE

# Prompt for text file
read -p "Enter the path to your text file: " FILE

# Expand ~ to $HOME if used
FILE="${FILE/#\~/$HOME}"

# Check if file exists
if [[ ! -f "$FILE" ]]; then
    echo "File not found: $FILE"
    exit 1
fi

# Read file line by line and speak
while IFS= read -r line; do
    say -v "$VOICE" "$line"
done < "$FILE"

echo "Done reading $FILE with voice $VOICE."
