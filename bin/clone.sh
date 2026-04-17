#!/usr/bin/env bash

#-------------------------------------------------------------------------------
# PROGRAM:
#	clone.ksh
#	
# PURPOSE:
#	This ksh script was developed with the assistance of ChatGPT to use to 
#	clone the SATA HD from a 2011 MacBook Pro 15" laptop running Elementary OS
#	Horus 7.
#	
# USAGE:
#	clone.ksh
#
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# # Install gddrrescue to use as the cloning app:
# sudo apt-get install gddrescue
#
# # Use lsblk to find the source_HD and destination_SSD drives:
# MacBook-Linux </home/steve [644]>
# steve@MacBook-Linux: lsblk
# NAME            MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINTS
# loop0             7:0    0     4K  1 loop  /snap/bare/5
# loop1             7:1    0  63.3M  1 loop  /snap/core20/1879
# loop2             7:2    0  91.7M  1 loop  /snap/gtk-common-themes/1535
# loop3             7:3    0 349.7M  1 loop  /snap/gnome-3-38-2004/137
# loop4             7:4    0  49.8M  1 loop  /snap/snapd/18596
# loop5             7:5    0 349.7M  1 loop  /snap/gnome-3-38-2004/140
# loop6             7:6    0  53.2M  1 loop  /snap/snapd/18933
# loop7             7:7    0 101.9M  1 loop  /snap/thunderbird/319
# loop8             7:8    0  63.3M  1 loop  /snap/core20/1852
# loop9             7:9    0 101.9M  1 loop  /snap/thunderbird/315
# sda               8:0    0 465.8G  0 disk  
# ├─sda1            8:1    0 263.1M  0 part  /boot/efi
# └─sda2            8:2    0 465.5G  0 part  
#   ├─data-root   253:0    0 461.7G  0 lvm   /
#     └─data-swap   253:1    0   3.8G  0 lvm   
# 	    └─cryptswap 253:2    0   3.8G  0 crypt [SWAP]
# 		sdb               8:16   0 953.9G  0 disk  
# 		sr0              11:0    1  1024M  0 rom   
# 
# # use fdisk to confirm that /dev/sdb is the destination_SSD
# MacBook-Linux </home/steve [645]>
# steve@MacBook-Linux: sudo fdisk -l /dev/sdb
# [sudo] password for steve:       
# Disk /dev/sdb: 953.87 GiB, 1024209543168 bytes, 2000409264 sectors
# Disk model:                 
# Units: sectors of 1 * 512 = 512 bytes
# Sector size (logical/physical): 512 bytes / 4096 bytes
# I/O size (minimum/optimal): 4096 bytes / 4096 bytes
# MacBook-Linux </home/steve [646]>
# steve@MacBook-Linux: 
#
#-------------------------------------------------------------------------------

# Command format and example:
# sudo ddrescue -f /dev/<source_HD> /dev/<destination_SSD> log.txt
# sudo ddrescue -f /dev/sda /dev/sdb clone.log

#-------------------------------------------------------------------------------
#
# MacBook-Linux </home/steve/Projects/SS [809]>
# steve@MacBook-Linux: clone.sh
# Enter the source HD [/dev/sda]: 
# Enter the destination SSD [/dev/sdb]: 
# Enter the log file [clone.log]: 
# 
# This script will clone the source HD '/dev/sda'
# to the destination SSD '/dev/sdb'.
# Do you want to continue? (y/n): y
# sudo ddrescue -f /dev/sda /dev/sdb clone.log
# GNU ddrescue 1.23
# Press Ctrl-C to interrupt
# ipos:  500107 MB, non-trimmed:        0 B,  current rate:  32464 kB/s
# opos:  500107 MB, non-scraped:        0 B,  average rate:  19193 kB/s
# non-tried:        0 B,  bad-sector:        0 B,    error rate:       0 B/s
# rescued:  500107 MB,   bad areas:        0,        run time:  7h 14m 15s
# pct rescued:  100.00%, read errors:        0,  remaining time:         n/a
# time since last successful read:         n/a
# Finished                                     
# Cloning completed successfully.
#-------------------------------------------------------------------------------

# Default values
default_source_HD="/dev/sda"
default_destination_SSD="/dev/sdb"
default_log="clone.log"

# Prompt for source HD
read -p "Enter the source HD [$default_source_HD]: " source_HD
source_HD=${source_HD:-$default_source_HD}

# Prompt for destination SSD
read -p "Enter the destination SSD [$default_destination_SSD]: " destination_SSD
destination_SSD=${destination_SSD:-$default_destination_SSD}

# Prompt for log file
read -p "Enter the log file [$default_log]: " log
log=${log:-$default_log}

# Confirmation prompt
cp1="\nThis script will clone the source HD '%s'\n"
cp2="to the destination SSD '%s'.\n"
cp3="Do you want to continue? (y/n): "
prompt=$(printf "${cp1}${cp2}${cp3}" "$source_HD" "$destination_SSD" )


read -p "$prompt" choice
if [ "$choice" != "y" ]; then
    echo "Cloning canceled."
    exit 0
fi

# Cloning command
echo "sudo ddrescue -f $source_HD $destination_SSD $log"
sudo ddrescue -f $source_HD $destination_SSD $log

# Check the exit status of ddrescue
if [ $? -eq 0 ]; then
    echo "Cloning completed successfully."
else
    echo "Cloning failed. Please check the log, $log, for more information."
fi

