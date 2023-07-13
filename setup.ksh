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
x_path=$(which xterm)
x_path=$(dirname $x_path)

log="logs/installation_list.log"

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

docs=$(ls docs)
docs_dir=docs
docs_home_dir=~/Documents 
docs_backup_dir=~/Documents/backup

local_docs=local_docs

public_home=~/Public/home
public_bin=~/Public/bin
public_docs=~/Public/docs
bin_backup_dir=~/bin/backup
home_backup_dir=~/backup

mkdir -p $public_home >/dev/null 2>&1
mkdir -p $public_bin >/dev/null 2>&1
mkdir -p $public_docs >/dev/null 2>&1
mkdir -p $bin_backup_dir >/dev/null 2>&1
mkdir -p $home_backup_dir >/dev/null 2>&1
mkdir -p docs >/dev/null 2>&1
mkdir -p templates >/dev/null 2>&1
mkdir -p $docs_dir >/dev/null 2>&1
mkdir -p $docs_home_dir >/dev/null 2>&1
mkdir -p $docs_backup_dir >/dev/null 2>&1
mkdir -p $local_docs >/dev/null 2>&1

print "#-----------------------------------------------------------------------"
date
print "#-----------------------------------------------------------------------"
print

print "> logs/installation_list.log"
> logs/installation_list.log

# Parse the command line:
source ~/bin/parse_args.ksh

# Include the debugging script:
source ~/bin/dbg.ksh
if [ $debug == true ]; then
    dbg "$LINENO    dbg.ksh sourced by setup.ksh"
fi

create_python_script() {
    #---------------------------------------------------------------------------
    # Function create_python_script()
    #
    # Purpose:
    #   Create a platform specific version of all python scripts referenced in
    #   ~Projects/*/templates
    #
    # Usage:
    #   create_python_script
    #---------------------------------------------------------------------------
    template=$1
    python_script=$2

    print "\t$template -> $python_script"

    if [ X"$platform" == X"Darwin" ]
    then
        this_platform=MacOSX
        shebang="#!/Users/steve/anaconda3/bin/python3.10"
        tksource="tkmacosx"
    else
        this_platform=Linux
        shebang="#!/usr/bin/env python3"
        tksource="tkinter"
    fi

    $cat $template |\
        sed -e "s~XXX_SHEBANG~$shebang~" |\
        sed -e "s/XXX_PLATFORM/$this_platform/" |\
        sed -e "s/XXX_TKSOURCE/$tksource/" > $python_script

    print $python_script >> logs/installation_list.log
    print "Installed python_script: $python_script"
} # create_python_script() 

add_last_lines() {
    #---------------------------------------------------------------------------
    # Function:
    #   add_last_lines()
    # 
    # Purpose:
    #   Add 3 lines to the end of each installed file. This will include the
    #   date on line 2.  Lines 1 and 3 are just comment lines # + 79 "-"s.
    #
    # Usage:
    #   add_last_file installed_file
    #---------------------------------------------------------------------------
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
} # add_last_lines() 

prepare_public_file() {
	#---------------------------------------------------------------------------
	# Function:
	#	prepare_public_file()
	#	
	# PURPOSE:
	#	prepare_public_file prints a file minus the last 3 
	#	lines.	The 3 lines removed are the Last installed trailing lines of 
	#	installed files. See final_lines variable.
	#	
	#	The file minus the final_lines is copied to a Public folder and used
    #   subsequently in a comparison with a candidate file to determine if it
    #   requires installation or not.
	#	
	# USAGE:
	#	prepare_public_file file full_path
	#---------------------------------------------------------------------------
	typeset -i line_count=0

	file="$1"
    file_path=$(dirname $file)

	if [ ! -f $file ]
	then
		print -n "Skipping prepare_public_file() for file $file."        
        print "  No such file."
		return 
	fi

	base=$(basename $file)
	if [[ $base == .[^.]* ]]; then
		base=$(print $base | awk '{gsub(/^\./,"")}1')
		target_dir=$public_home
	else
		target_dir=$public_bin
	fi
	
    if [ X"$file_path" == X"$docs_home_dir" ]
    then
		target_dir=$public_docs
    fi

	line_count=$(wc -l $file | awk '{print $1}')
	line_count=$((line_count - 3))

	# Don't try to reduce a file to less than 1 line.
	if [ $line_count -lt 1 ]
	then
		print "File: $file	less than 4 lines in length."
	else
        print "prepare_public_file() $target_dir/$base"
        if [ $debug == true ]; then
            dbg "$LINENO base:$base target:$target_dir/$base file:$file"
        fi
        if [ X"$base" != X"xtrc" ]; then
            if [ $debug == true ]; then
                dbg "$LINENO base:$base target:$target_dir/$base file:$file"
            fi
            $head -n $line_count $file  > "$target_dir/$base"
        else
            line_count=$((line_count - 1))
            $head -n $line_count $file  > "$target_dir/$base"
            print "x_path=TBD" >> "$target_dir/$base"
            if [ $debug == true ]; then
                msg="$LINENO base:$base target:$target_dir/$base file:$file "
                msg="$msg x_path=TBD"
                dbg "$msg"
            fi
        fi
	fi
}  # prepare_public_file()

backup_install() {
    #---------------------------------------------------------------------------
    # Function:
    #   backup_install()
    #
    # Purpose:
    #   Backup every file that was installed by this script. Then install any
    #   that are missing or that are different than the master source file.
    #
    # Usage:
    #   backup_install path    where $path in ['bin', 'docs', 'dots']
    #---------------------------------------------------------------------------
    path="$1"

    if [ X"$path" == X"bin" ]; then
        installed_path=~/bin
        backup_path=${installed_path}/backup
        public_path=~/Public/bin
    elif [ X"$path" = X"dots" ]; then
        installed_path=~
        backup_path=${installed_path}/backup
        public_path=~/Public/home
    elif [ X"$path" = X"docs" ]; then
        installed_path=~/Documents
        backup_path=${installed_path}/backup
        public_path=~/Public/docs
    else
        print "Unknown path, [$path]"
        exit 1
    fi

    for file in ${path}/*; do
        ts=$(date +%Y_%m_%d-%H:%M:%S)

        if [ $debug == true ]; then
            dbg "$LINENO  path: [$path] file: [$file]"
        fi
        if [ X"$path" = X"dots" ]; then
            dot="."
        else
            dot=""
        fi

        src=$path/$file
        print
        bn=$(basename $file)
        # Backup:
        if [ $debug == true ]; then
            msg="$LINENO: $cp $installed_path/${dot}$bn "
            msg="$msg ${backup_path}/${dot}${bn}.$ts"
            dbg "$msg"
        fi
        $cp ${installed_path}/${dot}${bn} ${backup_path}/${dot}${bn}.$ts

        base=$(basename $file)
        print "prepare_public_file() ${installed_path}/${dot}${base}"
        prepare_public_file ${installed_path}/${dot}${base}

        file=$(print $file | awk '{gsub(/^\./,"")}1')
        base=$(basename $file)
		base=$(print $base | awk '{gsub(/^\./,"")}1')

        print "diff $path/$base $public_path"
        diff $path/$base $public_path > /dev/null 2>&1
        return_code=$?
        if [ $debug == true ]; then
            dbg "$LINENO   return_code: $return_code"
        fi

        # Install if $src and $public_path differ:
        if [ $return_code -ne 0  ]; then
            if [ $debug == true ]; then
                dbg "$LINENO   file: $file path: $path base: $base"
            fi
            if [ X"$path" == X"dots" ]; then
                if [ $debug == true ]; then
                    dbg "$LINENO file $file path: $path base: $base"
                    print "$cp ${path}/${base} ~/.${base}"
                fi
                if [ "${base}" == "xtrc" ]
                then
                    if [ $debug == true ]; then
                        dbg "$LINENO file:$file path:$path base:$base"
                    fi
                    sed "s!^x_path=.*!x_path=$x_path!" dots/xtrc > ~/.xtrc
                else
                    $cp ${path}/${base} ~/.${base}
                fi
            else
                print "$cp ${path}/${base} ${installed_path}/${base}"
                $cp ${path}/${base} ${installed_path}/${base}
            fi

            print "add_last_lines ${file}"
            add_last_lines ${file}

            if [ $path == "docs" ]; then
                print "chmod 644 $file"
                chmod 644 $file
            else
                print "chmod 755 $file"
                chmod 755 $file
            fi

            print ${file} >> logs/installation_list.log
            print "Installed file: $file"
        fi

        # Remove public_path file to present false positive.
        rm $public_path/$base > /dev/null 2>&1
    done
    print
} # backup_install()

set_symbolic_links() {
    #---------------------------------------------------------------------------
    # Function:
    #   set_symbolic_links()
    #
    # Purpose:
    #   Creating symbolic links to sh scripts in ~/bin
    #
    # Usage:
    #   set_symbolic_links
    #---------------------------------------------------------------------------
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
} # set_symbolic_links() 

# Handle backup and installation file for each file that is not present or that
# has changed since the master source code has changed:
backup_install bin
backup_install docs
backup_install dots

# Create platform specific Python scripts from templates:
print "Create_python_script():"
for template in $(ls templates/*.py.template)
do
    # Remove ".template":
    py_file=$(print $template |\
        sed -e 's!templates/!!' |\
        sed -e 's/.template//')

    prepare_public_file ~/bin/$py_file

    diff bin/$py_file ~/Public/bin/ > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        if [ $debug == true ]; then
            dbg "$LINENO create_python_script $template bin/$py_file"
        fi
        create_python_script $template bin/$py_file
    fi
    # Remove public_path file to present false positive.
    rm ~/Public/bin/$py_file > /dev/null 2>&1
done

print

# Make shebang lines for ksh and perl
print source shebang.ksh
source shebang.ksh

# Always set symbolic links
set_symbolic_links

print
print $line
print "Installation Report"
if [ ! -s $log ]; then
    print -n "Based on the inspection of all target files, "
    print "nothing required installation."
else
    cat $log
fi
print $line

print
print $line
date
print $line
print
print "debug:$debug"
if [ $debug == true ]; then
    dbg "$LINENO    $0 completed"
fi
