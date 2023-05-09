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
# NOTE:  The source_HD and destination_HD are hard coded in this verion. I will
# make them variables that are set by guerying the user for future use.
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
# # use fdisk to confirm that /dev/sdb is the destination_HD
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
# sudo ddrescue -f /dev/sda /dev/sdb clonelog.txt

#-------------------------------------------------------------------------------
source_HD="/dev/sda"
destination_HD="/dev/sdb"
log="clone.log"

prompt="This script will clone the source HD to the destination SSD."
prompt+=$'\nDo you want to continue? (y/n): '

# Confirmation prompt
read -p "$prompt" choice
if [ "$choice" != "y" ]; then
	echo "Cloning canceled."
	exit 0
fi

# Cloning command
# sudo ddrescue -f /dev/sda /dev/sdb clonelog.txt
echo
echo "sudo ddrescue -f $source_HD $destineation_HD $log"
sudo ddrescue -f $source_HD $destineation_HD $log

# Check the exit status of ddrescue
if [ $? -eq 0 ]; then
	echo "Cloning completed successfully."
else
	echo "Cloning failed. Please check the logs for more information."
fi
