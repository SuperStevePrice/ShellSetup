#!/bin/ksh
#
# german_vocabulary.ksh — launch script for the vocabulary workbook.
#
# On macOS, prefers the native .numbers file if one exists: it opens
# instantly, with no "may look different" warning and no compatibility
# side panel. Falls back to the .xlsx if no .numbers copy exists yet
# -- that still works, just with Numbers' usual import warning, since
# there's no way to tell Numbers to treat an .xlsx as native.
#
# The .numbers file is a manual snapshot you create yourself in Numbers
# (File > Save As..., format: Numbers) -- it is NOT auto-generated,
# because openpyxl (the tool that builds the .xlsx) can only write
# Excel format, not Apple's native package format.
#
# On Linux (no Numbers app), always uses the .xlsx via xdg-open.
#
# Usage:
#   german_vocabulary.ksh                 # picks the right default per platform
#   german_vocabulary.ksh /path/to/file   # explicit override

typeset BUILD_SCRIPT="$HOME/bin/german-vocab.ksh"
typeset XLSX_FILE="$HOME/Documents/german_vocabulary_by_domain.xlsx"
typeset NUMBERS_FILE="$HOME/Documents/german_vocabulary_by_domain.numbers"

platform=$(uname)

if [[ -n "$1" ]]; then
    typeset FILE="$1"
elif [[ "${platform}" == "Darwin" && -e "${NUMBERS_FILE}" ]]; then
    typeset FILE="${NUMBERS_FILE}"
else
    typeset FILE="${XLSX_FILE}"
fi

if [[ ! -e "${FILE}" ]]; then
    if [[ "${FILE}" == *.numbers ]]; then
        print -u2 "german_vocabulary.ksh: ${FILE} not found."
        print -u2 "The .numbers file is a manual copy -- open ${XLSX_FILE}"
        print -u2 "in Numbers and use File > Save As... (format: Numbers)."
        exit 1
    fi

    print "german_vocabulary.ksh: ${FILE} not found; building it..."

    if [[ ! -x "${BUILD_SCRIPT}" ]]; then
        print -u2 "german_vocabulary.ksh: cannot find or execute ${BUILD_SCRIPT}"
        exit 1
    fi

    "${BUILD_SCRIPT}" "${FILE}" || {
        print -u2 "german_vocabulary.ksh: build failed"
        exit 1
    }
fi

case $platform in
    Darwin) open "${FILE}" ;;
    Linux)  xdg-open "${FILE}" >/dev/null 2>&1 & ;;
    *)      print -u2 "german_vocabulary.ksh: unsupported platform: ${platform}"
            exit 1 ;;
esac
