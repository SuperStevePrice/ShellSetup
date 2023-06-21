#!/usr/bin/env ksh
#-------------------------------------------------------------------------------
#         Copyright (C) 2023    Steve Price    SuperStevePrice@gmail.com
#
#                       GNU GENERAL PUBLIC LICENSE
#                        Version 3, 29 June 2007
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# PROGRAM:
#   setup.ksh
#
# PURPOSE:
#   Configures files and installs them with correct permissons. Creates symbolic
#   links for *sh files in ~/bin.
#
# USAGE:
#   Run "ksh setup" to invoke this script, which invokes prep.ksh and logs all.
#
#-------------------------------------------------------------------------------
# Manifest:
#   See contents of folders dots and prep under this project's root folder.
#-------------------------------------------------------------------------------
typeset -i line_count

platform=$(uname)

# final lines of each file installed by this script
timestamp="# Last installed: $(printf "%(%Y-%m-%d %H:%M:%S)T")"
line=$(print "#$(printf -- '-%.0s' {1..79})")
EoF=$(print "#-- End of File $(printf -- '-%.0s' {1..64})")
final_lines="${line}\n${timestamp}\n${EoF}"

# full path to cat, cp, and head
cat=$(which cat)
cp=$(which cp)
head=$(which head)

# Directories bin and dots and their filenames
dots=$(ls dots)
dots_dir=dots
dots_home_dir=~

bins=$(ls bin)
bin_dir=bin
bin_home_dir=~/bin

public_home=~/Public/home
public_bin=~/Public/bin
bin_backup_dir=~/bin/backup
home_backup_dir=~/backup
mkdir -p $public_home >/dev/null 2>&1
mkdir -p $public_bin >/dev/null 2>&1
mkdir -p $bin_backup_dir >/dev/null 2>&1
mkdir -p $home_backup_dir >/dev/null 2>&1
mkdir docs >/dev/null 2>&1
mkdir templates >/dev/null 2>&1

create_xt_py() {
    #---------------------------------------------------------------------------
    # Function create_xt_py()
    # Purpose:
    #   Create a platform specific version of xt.py.
    #
    # Usage:
    #   create_xt_py
    #---------------------------------------------------------------------------
    
    print "Function create_xt_py(): Creating bin/xt.py\n"
    if [ X"$platform" == X"Darwin" ]
    then
        version=MacOSX
        shebang="#!/Users/steve/anaconda3/bin/python3.10"
        tksource="tkmacosx"
    else
        version=Linux
        shebang="#!/usr/bin/env python3"
        tksource="tkinter"
    fi

    cat templates/xt.py.template |\
        sed -e "s~XXX_SHEBANG~$shebang~" |\
        sed -e "s/XXX_VERSION/$version/"                                    |\
        sed -e "s/XXX_TKSOURCE/$tksource/" > bin/xt.py
} # create_xt_py() 

remove_final_lines() {
	#---------------------------------------------------------------------------
	# Function:
	#	remove_final_lines()
	#	
	# PURPOSE:
	#	remove_final_lines prints a file minus the last 3 
	#	lines.	The 3 lines removed are the Last installed trailing lines of 
	#	installed files. See final_lines variable.
	#	
	# USAGE:
	#	remove_final_lines file
	#---------------------------------------------------------------------------
	typeset -i line_count=0

	file="$1"

	if [ ! -f $file ]
	then
		print "Skipping remove_final_lines() for file $file.  No such file."
		return 
	fi

	base=$(basename $file)
	if [[ $base == .[^.]* ]]; then
		base=$(print $base | awk '{gsub(/^\./,"")}1')
		target_dir=$public_home
	else
		target_dir=$public_bin
	fi
	
	line_count=$(wc -l $file | awk '{print $1}')
	line_count=$((line_count - 3))

	# Don't try to reduce a file to less than 1 line.
	if [ $line_count -lt 1 ]
	then
		print "File: $file	less than 4 lines in length."
	else
		$head -n $line_count $file  > "$target_dir/$base"
	fi
}  # remove_final_lines()



make_installation_list() {
	installation_list=docs/installation_list.txt
	> $installation_list

    print "\nHandling dot files:\n"
	# Loop over all candidate dot files:
	for file in $(print $dots)
	do
		#print "$0: $dots_dir/$file"

		# check tha target file exists
		if [ ! -f $dots_home_dir/.${file} -o \
			! -s $dots_home_dir/.${file} ]
        then
            install="y"
            echo "Not found $bin_home_dir/.${file}"
        else
            install=n
            echo "Found $bin_home_dir/.${file}"
        fi

		# Strip the Last installed markers from the target.
		# print "$0: remove_final_lines $dots_home_dir/.$file"
		remove_final_lines $dots_home_dir/.$file

		public=$(basename $file)
		bn=$(print $public | awk '{gsub(/^\./,"")}1')
		installer=dots/$bn
		public=$public_home/$bn
		#if diff "$public" "$installer" > /dev/null 2>&1; then
		if cmp "$public" "$installer"; then
			echo "No differences between $public and $installer"
		else
			install=y
			echo "Differences found between $public and $installer"
		fi

		file=$(basename $file)
		file=$(print $file | awk '{gsub(/^\./,"")}1')
		if [ $install == "y" ] 
		then
			print "dots/$file" >> $installation_list
		fi
		print "install=$install $dots_dir/$file"
		print
	done

    print "\nHandling bin files:\n"
	# Loop over all candidate bin files:
	for file in $(print $bins)
	do
		#print "$0: $bin_dir/$file"

		folder=$(dirname $file)
		file=$(basename $file)

		#print "Loop over bin files: $folder $file"

		# Handle only "bin" files here, which are installed to ~/bin
		if [ $folder == "dots" ]
		then
			continue
		fi
		
		# check tha target file exists
		if [ ! -f $bin_home_dir/${file} -o ! -s $bin_home_dir/${file} ]
        then
            install="y"
            echo "Not found $bin_home_dir/${file}"
        else
            install=n
            echo "Found $bin_home_dir/${file}"
        fi

		# Strip the Last installed markers from the target.
		# print "$0: remove_final_lines $bin_home_dir/$file"
		remove_final_lines $bin_home_dir/$file

		public=$(basename $file)
		bn=$(print $public | awk '{gsub(/^\./,"")}1')
		installer=bin/$bn
		public=$public_bin/$bn
		# if diff "$public" "$installer" > /dev/null 2>&1; then
		if cmp "$public" "$installer"; then
			echo "No differences between $public and $installer"
		else
			install=y
			echo "Differences found between $public and $installer"
		fi

		file=$(basename $file)
		file=$(print $file | awk '{gsub(/^\./,"")}1')
		if [ $install == "y" ] 
		then
			print "bin/$file" >> $installation_list
		fi
		print "install=$install $bin_dir/$file"
		print
	done

	print
	print $line
	print "$cat $installation_list"
	$cat $installation_list
	print $line
} # make_installation_list() 

add_last_lines() {
	file=$1

	if [ "$file" ==  ~/.exrc ]
	then
		# .exrc and vi don't tolerate normal comment marker '#'. Use '"'.
		last_lines=$(print $final_lines | awk '{gsub(/^#/,"\"")}1')
	else
		last_lines=$final_lines
	fi

	# print "last_line:	$last_lines"
	print "Adding last 3 comment lines to file: $file"
	print "$last_lines" >> $file
} # add_last_lines() {

handle_dots() {
	folder=$1
	file=$2
	folder=$(basename $folder)

	print "handle_dots"
	print "Folder: $folder	File: $file"
	# Backup and install dot files:
	for file in $(cat $installation_list)
	do
		folder=$(dirname $file)
		file=$(basename $file)

		# print "DEBUG handle_dots() folder=$folder	file=$file"

		# Handle only "dots" files here, which are installed to ~
		if [ $folder == "bin" ]
		then
			continue
		fi
		# print "DEBUG handle_dots() folder=$folder	file=$file"

		# print "Loop over dot files: $folder $file"

		# backup
		if [ -s  ~/.${file} ]
		then
			print "backup .$file"
			ts=$(date +%Y_%m_%d-%H:%M:%S)
			print $cp ~/.${file} $home_backup_dir/.${file}.$ts
			$cp ~/.${file} $home_backup_dir/.${file}.$ts
		fi

		# install 
		print $cp dots/${file} ~/.${file}
		if [ "$file" == "xtrc" ]
		then
			x_path=$(which xterm)
			x_path=$(dirname $x_path)
			sed "s!^x_path=.*!x_path=$x_path!" dots/xtrc > ~/.${file}
		else
			$cp dots/${file} ~/.${file}
		fi

		print "add_last_lines ~/.${file}"
		add_last_lines ~/.${file}

		print   
	done
} # handle_dots


handle_bins() {
	folder=$1
	file=$2
	folder=$(basename $folder)

	print "handle_bins"
	print "Folder: $folder	File: $file"


	# Backup, install, chmod bin_files files:
	for file in $(cat $installation_list)
	do
		folder=$(dirname $file)
		file=$(basename $file)

		# print "DEBUG handle_bins() folder=$folder	file=$file"

		# Handle only "bin" files here, which are installed to ~
		if [ $folder == "dots" ]
		then
			continue
		fi
		# print "DEBUG handle_bins() folder=$folder	file=$file"

		# print "Loop over bin files: $folder $file"

		# backup
		if [ -s /bin/${file} ]
		then
			print "backup ~/bin/${file}"
			ts=$(date +%Y_%m_%d-%H:%M:%S)
			print cp ~/bin/${file} $bin_backup_dir/${file}.$ts
			cp ~/bin/${file} $bin_backup_dir/${file}.$ts
		fi

		# install
		print cp ${bin_dir}/${file} ~/bin/${file}
		cp ${bin_dir}/${file} ~/bin/${file}

		# Make executable
		print chmod 755 ~/bin/${file}
		chmod 755 ~/bin/${file}

		print "add_last_lines ~/bin/${file}"
		add_last_lines ~/bin/${file}

		print
	done

}	# handle_bins() {


set_symbolic_links() {
	print
	print "Creating symbolic links to sh scripts in ~/bin"
	print

	# create symbolic links
	for file in $(ls ~/bin/*.*sh)
	do
		if [ "$file" == ~/bin/ssh-copy-id.ksh ]
		then
			print "No symbolic link will be created for ${file}."
			continue
		fi
		sym="${file%.*sh}"
		if [ ! -f "$sym" -o ! -h "$sym" ]; then
			print "ln -s ${file} ${sym}"
			ln -s ${file} ${sym}
		fi
	done
} # set_symbolic_links() {

# Make shebang lines for ksh and perl
source shebang.ksh

# Create bin/xt.py:
create_xt_py

# Create bin/xt.ksh:
create_xt_ksh

# Make a list of artifacts to be installed as a new or a new version.
make_installation_list

# Main Loop:
for file in $($cat $installation_list)
do
	folder=$(dirname $file)
	file=$(basename $file)

	print $folder | grep "dots" > /dev/null 2>&1
	if [ $? -eq 1 ]
	then
		print "handle_bins folder: $folder	file: $file"
		handle_bins $folder	$file
	else
		print "handle_dots folder: $folder	file: $file"
		handle_dots $folder	$file
	fi
	print
done

# Always set symbolic links
set_symbolic_links

print
print "date >> docs/README.txt"
date >> docs/README.txt
print


print $line
print "Setup Complete:	$(date)"
print $line
print
