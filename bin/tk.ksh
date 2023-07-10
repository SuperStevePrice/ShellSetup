#!/usr/bin/env ksh

#-------------------------------------------------------------------------------
#         Copyright (C) 2023    Steve Price    SuperStevePrice@gmail.com
#
#                       GNU GENERAL PUBLIC LICENSE
#                        Version 3, 29 June 2007
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# PROGRAM:
#	tk.ksh
#	
# PURPOSE:
#	Given a file containing a list of fully qualified perl paths, this ksh will
#   return a legal shebang line for any of the perls that support Tk. To see 
#   all the results for all of the perl paths, used one of the command line args
#   for debugging, -d or --debug.
#	
# FILE:
#   ~Documents/perls.txt is the default list of perl executable to be tested.
#   "-f filename" can be used to test a differnt file containing perl paths.
#
# USAGE:
#   Options:
#     -d, --debug     Enable debug mode
#     -f perls_list   Use a custom Perl list file
#     -h, --help      Print this usage message
#
#-------------------------------------------------------------------------------
perl_list=~/Documents/perls.txt
debug_mode=false
perl_list_file=""

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--debug)
                debug_mode=true
                shift
                ;;
            -f|--file)
                perl_list_file=$2
                if [ ! -f "$perl_list_file" ]; then
                    echo "No such file or directory: $perl_list_file"
                    exit 1
                fi
                shift 2
                ;;
            -h|--help)
                echo "Usage: $0 [options]"
                echo "Options:"
                echo "  -d, --debug        Enable debug mode"
                echo "  -f, --file FILE    Use a custom Perl list file"
                echo "  -h, --help         Print this usage message"
                exit 0
                ;;
            *)
                echo "Invalid option: $1"
                echo "Usage: $0 [options]"
                echo "Run '$0 --help' for help."
                exit 1
                ;;
        esac
    done
}

parse_args "$@"

if [ "$perl_list_file" != "" ]; then
    if [ ! -f "$perl_list_file" ]; then
        echo "No such file or directory: $perl_list_file"
        exit 1
    fi
    perl_list=$perl_list_file
fi

check_tk_support() {
    perl_path=$1
    output=$($perl_path -e 'use Tk; my $top = MainWindow->new(); exit 0' 2>&1)
    if [ $? -eq 0 ]; then
        shebang="#!$perl_path"
        if [ "$debug_mode" = true ]; then
            echo "$shebang supports Tk"
        else
            echo "$shebang"
        fi
        return 0
    else
        if [ "$debug_mode" = true ]; then
            echo "$perl_path does not support Tk"
            echo "Error output: $output"
        fi
        return 1
    fi
}

for perl_path in $(cat $perl_list)
do
    if [ -x "$perl_path" ]; then
        check_tk_support $perl_path
    else
        if [ "$debug_mode" = true ]; then
            echo "$perl_path not found"
        fi
    fi
done
