#!/usr/bin/env ksh

path=/home/user/folder/file.txt
filename=$(basename "$path")
dirname=$(dirname "$path")
echo "Filename: $filename"
echo "Directory: $dirname"
