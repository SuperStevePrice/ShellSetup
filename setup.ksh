#!/usr/bin/env ksh
#-------------------------------------------------------------------------------
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
# xtrc
#-------------------------------------------------------------------------------

# preparations:
. ./prep.ksh

print $line
print "Setup Commenced:	$(date)"
print $line
print

timestamp="# Last installed: $(printf "%(%Y-%m-%d %H:%M:%S)T")"

prep_dir=prep

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

	if [ "$file" == "exrc" ]
	then
		# .exrc and vi don't tolerate normal comment marker. Use ".
		ts=$(print $timestamp | sed -e 's/^#/"/')
		print $ts >> ~/.${file}
	else
		print $timestamp >> ~/.${file}
	fi
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

	print $timestamp >> ~/bin/${file}

	print
done


print cp ${prep_dir}/xt.pl
cp ${prep_dir}/xt.pl ~/bin/xt.pl
print chmod 755 ~/bin/xt.pl
chmod 755 ~/bin/xt.pl
print


print "date >> docs/README.txt"
date >> docs/README.txt
print

set_sym_links

print $line
print "Setup Complete:	$(date)"
print $line
print
#-------------------------------------------------------------------------------
