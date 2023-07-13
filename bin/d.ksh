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
        # Perform additional debug-related actions
        # ...
    fi
} # parse_args() 

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -d, --debug    Enable debug mode"
    echo "  -h, --help     Show this help message"
}

parse_args "$@"
