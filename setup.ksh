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

# final lines of each file installed by this script
timestamp="# Last installed: $(printf "%(%Y-%m-%d %H:%M:%S)T")"
line=$(print "#$(printf -- '-%.0s' {1..79})")
EoF=$(print "#-- End of File $(printf -- '-%.0s' {1..64})")
final_lines="${line}\n${timestamp}\n${EoF}"

# full path to cp and head
cp=$(which cp)
head=$(which head)

# Directories bin and dots and their filenames
dots=$(ls dots)
dots_dir=dots
dots_home_dir=~

bins=$(ls bin)
bin_dir=bin
bin_home_dir=~/bin


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
	#	
	# USAGE:
	#	remove_final_lines file
	#
	#---------------------------------------------------------------------------
	typeset -i line_count=0
	public_home=~/Public/home
	public_bin=~/Public/bin

	file="$1"

	if [ ! -f $file ]
	then
		print "Skipping remove_final_lines for file $flie"
		return 
	fi

	base=$(basename $file)
	if [[ $base == .[^.]* ]]; then
		base=$(print $base | sed -e 's/^\.//')
		target_dir=$public_home
	else
		target_dir=$public_bin
	fi
	
	line_count=$(wc -l $file | awk '{print $1}')
	line_count=$((line_count - 3))


	$head -n $line_count $file | grep -v 'eval'  > "$target_dir/$base"

}  #remove_final_lines()



make_installation_list() {
	installation_list=docs/installation_list.txt
	> $installation_list


	public_home=~/Public/home
	public_bin=~/Public/bin

	# Loop over all candidate dot files:
	for file in $(print $dots)
	do
		#print "$0: $dots_dir/$file"

		# check tha target file exists
		if [ ! -f $dots_home_dir/.${file} -o \
			! -s $dots_home_dir/.${file} ]
		then
			install="y"
		else
			install=n
		fi

		# Strip the Last installed markers from the target.
		#print "$0: remove_final_lines $dots_home_dir/.$file"
		remove_final_lines $dots_home_dir/.$file
		if [ -f $dots_home_dir/.${file} ]
		then
			diff -w  "$dots_dir/$file" "$file" > /dev/null 2>&1
			if [ $? -eq 1 ]
			then
				install=y
			fi
		fi
		file=$(basename $file)
		file=$(print $file | sed -e 's/^\.//')
		if [ $install == "y" ] 
		then
			print "dots/$file" >> $installation_list
		fi
		print "install=$install $dots_dir/$file"

	done

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
		else
			install=n
		fi

		# Strip the Last installed markers from the target.
		#print "$0: remove_final_lines $bin_home_dir/$file"
		remove_final_lines $bin_home_dir/$file
		if [ -f $bin_home_dir/${file} ]
		then
			diff -w  "$bin_dir/$file" "$file" > /dev/null 2>&1
			if [ $? -eq 1 ]
			then
				install=y
			fi
		fi

		file=$(basename $file)
		file=$(print $file | sed -e 's/^\.//')
		if [  $install == "y" ] 
		then
			print "bin/$file" >> $installation_list
		fi
		print "install=$install $bin_dir/$file"

	done

	print
	print $line
	print "cat $installation_list"
	cat $installation_list
	print $line
} # make_installation_list() 

add_last_lines() {
	file=$1

	if [ "$file" ==  ~/.exrc ]
	then
		# .exrc and vi don't tolerate normal comment marker. Use ".
		last_lines=$(print $final_lines | sed -e 's/#/"/g')
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
			print $cp ~/.${file} ~/backup/.${file}.$ts
			$cp ~/.${file} ~/backup/.${file}.$ts
		fi

		# install 
		print $cp dots/${file} ~/.${file}
		$cp dots/${file} ~/.${file}

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
			print cp ~/bin/${file} ~/bin/backup/${file}.$ts
			cp ~/bin/${file} ~/bin/backup/${file}.$ts
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
		rm -f ${sym}
		print ln -s ${file} ${sym}
		ln -s ${file} ${sym}
	done
} # set_symbolic_links() {

# Make shebang lines for ksh and perl
source shebang.ksh

# Make a list of artifacts to be installed as a new or a new version.
make_installation_list
#
# Main Loop:
for file in $(cat $installation_list)
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

