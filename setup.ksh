#!/usr/bin/env ksh

#-------------------------------------------------------------------------------
#         Copyright (C) 2023    Steve Price    SuperStevePrice@gmail.com
#
#                       GNU GENERAL PUBLIC LICENSE
#                        Version 3, 29 June 2007
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# PROGRAM:
#	setup.ksh
#	
# PURPOSE:
#	Configures files and installs them with correct permissons. Creates symbolic
#	links for *sh files in ~/bin.
#	
# USAGE:
#	Run "ksh setup" to invoke this script, which invokes prep.ksh and logs all.
#
#-------------------------------------------------------------------------------
# Manifest:
#	See contents of folders dots and prep under this project's root folder.
#-------------------------------------------------------------------------------
typeset -i line_count

timestamp="# Last installed: $(printf "%(%Y-%m-%d %H:%M:%S)T")"
line=$(print "#$(printf -- '-%.0s' {1..79})")
EoF=$(print "#-- End of File $(printf -- '-%.0s' {1..64})")
final_lines="${line}\n${timestamp}\n${EoF}"

# preparations:
. ./prep.ksh

print $line
print "Setup Commenced:	$(date)"
print $line
print

prep_dir=prep

add_last_lines() {
	file=$1

	if [ "$file" ==  ~/.exrc ]
	then
		# .exrc and vi don't tolerate normal comment marker. Use ".
		last_lines=$(print $final_lines | sed -e 's/#/"/g')
	else
		last_lines=$final_lines
	fi

	print "$last_lines"
	print "Adding last 3 comment lines to file: $file"
	print "$last_lines" >> $file
}


set_sym_links() {
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
}


make_backup_dir () {

	for backup_dir in $(print "$HOME/backup $HOME/bin/backup")
	do
		if [ ! -e $backup_dir ]
		then
			mkdir $backup_dir
		fi
	done

	# mv any *save files to backup folders
	mv ~/.*.save ~/backup/  > /dev/null 2>&1
	mv ~/bin/*.save ~/bin/backup  > /dev/null 2>&1

} # make_backup_dir()

prep_files="$(ls prep)"
cp=/bin/cp
make_backup_dir

# Backup and install dot files:
for file in $(ls dots)
do
    home_file=~/.$file

	# backup
	ts=$(date +%Y_%m_%d-%H:%M:%S)
	dot_file=~/.${file}
	backup_file=~/backup/.${file}.$ts

	print $cp $dot_file $backup_file
	$cp $dot_file $backup_file

	# install
    
    line_count=$(wc -l $dot_file | awk '{print $1}')
    if [ "$file" == "profile" ]
    then
        line_count+=2
        head -n $line_count $home_file | grep -v Mlocal::lib | grep -v shellenv > /tmp/$file
    else
        # Create a tmp file to be used by diff
        head -n $line_count $home_file > /tmp/$file
    fi

	diff -w $dot_file /tmp/$file
	if [ $? -eq 1 ]
	then
		print "Installing $dot_file"
		if [ $file == "profile" ]
		then
			print "~/.profile created/updated"
			. profile.ksh > ~/.profile
		else
			print $cp dots/${file} ~/.${file}
			$cp dots/${file} ~/.${file}
		fi
	fi

	add_last_lines ~/.${file}
	chmod 755 ~/.${file} > /dev/null 2>&1

	print
done
print

# Backup, install, chmod prep_files files:
for file in $(print $prep_files)
do
	# Filter out which.* files.
	if [ "${file%.*}" == "which" ]
    then
        continue
    fi

	# backup
	ts=$(date +%Y_%m_%d-%H:%M:%S)
	preped_file=~/bin/$file
	backup_file=~/bin/backup/${file}.$ts

	print $cp $preped_file $backup_file
	$cp $preped_file $backup_file


    prep_file=$prep_dir/$file
    bin_file=~/bin/$file

    line_count=$(wc -l $bin_file | awk '{print $1}')
    line_count=$((line_count - 3))

    # Create a tmp file to be used by diff
    head -n $line_count $bin_file > /tmp/$file
        
    diff -w /tmp/$file $prep_file
    if [ $? -eq 1 ]
    then
		# install
        print "Installing $bin_file"
		print $cp $prep_file $bin_file
		$cp $prep_file $bin_file
    else
        print "File: $bin_file is the latest version."
    fi

    rm -rf /tmp/$file > /dev/null 2>&1

	add_last_lines ~/bin/${file}

	# Make executable
	print chmod 755 ~/bin/${file}
	chmod 755 ~/bin/${file}


	print
done




print "date >> docs/README.txt"
date >> docs/README.txt
print

set_sym_links

print $line
print "Setup Complete:	$(date)"
print $line
print
