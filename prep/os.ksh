#!/usr/bin/env ksh

os_version() {
    if [[ $(uname -s) == "Darwin" ]]; then
        os=$(sw_vers -productName)
        os+=" $(sw_vers -productVersion)"
    elif [[ $(uname -s) == "Linux" ]]; then
        os=$(lsb_release -sd)
    fi
    echo "$os"
}

echo "OS version: $(os_version)"
