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
#	links for *ksh files in ~/bin.
#	
# USAGE:
#	Run "ksh setup" to invoke this script, which invokes prep.ksh and logs all.
#
#-------------------------------------------------------------------------------
# Manifest:
#
# PS1.ksh
# alias
# exrc
# functions
# my_machine.ksh
# os.ksh
# p.ksh
# paths.ksh
# profile
# remote_tar.ksh
# scp_this.ksh
# set_shell.ksh
# ssh-copy-id.ksh
# xt.ksh
# xt.pl 

line="#---------------"
line=$line"---------------------------------------------------------------"

EoF="#-- End of File "
EoF=$EoF"----------------------------------------------------------------"

timestamp="# Last installed: $(printf "%(%Y-%m-%d %H:%M:%S)T")"

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
print "DEBUG:\n"
print "$final_lines"
print "$last_lines"
	else
		last_lines=$final_lines
	fi

	print "$last_lines"
	print "Adding last 3 comment lines to file: $file"
	print "$last_lines" >> $file
}


set_sym_links() {
	print
	print "Creating symbolic links to ksh scripts in ~/bin"
	print

	# create symbolic links
	for file in $(ls ~/bin/*.ksh)
	do
		if [ "$file" == ~/bin/ssh-copy-id.ksh ]
		then
			print "No symbolic link will be created for ${file}."
			continue
		fi
		sym="${file%.ksh}"
		rm -f ${sym}
		print ln -s ${file} ${sym}
		ln -s ${file} ${sym}
	done
}


prep_files="$(ls prep)"
cp=/bin/cp

# Backup and install dot files:
for file in $(ls dots)
do
	# backup
	print $cp ~/.${file} ~/.${file}.save
	$cp ~/.${file} ~/.${file}.save

	# install
	if [ $file == "profile" ]
	then
		print "~/.profile created/updated"
		. profile.ksh > ~/.profile
	else
		print $cp dots/${file} ~/.${file}
		$cp dots/${file} ~/.${file}
	fi

	add_last_lines ~/.${file}

	print
done
print

# Backup, install, chmod prep_files files:
for file in $(print $prep_files)
do
	# Filter out which.* files.
	print $file | grep "which" > /dev/null 2>&1
	if [ $? = 0 ]
	then
		continue
	fi

	# backup
	print cp ~/bin/${file} ~/bin/${file}.save
	cp ~/bin/${file} ~/bin/${file}.save

	# install
	print cp ${prep_dir}/${file} ~/bin/${file}
	cp ${prep_dir}/${file} ~/bin/${file}

	# Make executable
	print chmod 755 ~/bin/${file}
	chmod 755 ~/bin/${file}

	add_last_lines ~/bin/${file}

	print
done


# print "cp ${prep_dir}/xt.pl ~/bin/xt.pl"
# cp ${prep_dir}/xt.pl ~/bin/xt.pl
# print chmod 755 ~/bin/xt.pl
# chmod 755 ~/bin/xt.pl
print


print "date >> docs/README.txt"
date >> docs/README.txt
print

set_sym_links

print $line
print "Setup Complete:	$(date)"
print $line
print
