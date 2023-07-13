#!/usr/bin/env ksh

#-------------------------------------------------------------------------------
#         Copyright (C) 2023    Steve Price    SuperStevePrice@gmail.com
#
#                       GNU GENERAL PUBLIC LICENSE
#                        Version 3, 29 June 2007
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# PROGRAM:
#	parse_args.ksh
#	
# PURPOSE:
#	This ksh script provides functons parse_args() and show_usage() and sets
#   the value of $debug.
#	
# USAGE:
#   In ksh scripts that wish to use this script:
#       source ~/bin/parse_args.ksh
#       Thereafter, check $debug.
#-------------------------------------------------------------------------------

parse_args() {
    debug=false

    while [ "$#" -gt 0 ]; do
        case "$1" in
            -d|--debug)
                debug=true
                ;;
            -h|--help)
                show_usage
                return
                ;;
            *)
                # Handle unrecognized options or arguments here
                ;;
        esac
        shift
    done

    # Use the debug flag as needed in your script
    if [ "$debug" = true ]; then
        echo "Debug mode is enabled."
    fi

    # Return the value of the debug variable
    if [ "$debug" = true ]; then
        return 1  # Return non-zero status code to indicate debug mode
    else
        return 0  # Return success status code to indicate no debug mode
    fi
} # parse_args() 

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -d, --debug    Enable debug mode"
    echo "  -h, --help     Show this help message"
    exit 0
}

parse_args "$@"
