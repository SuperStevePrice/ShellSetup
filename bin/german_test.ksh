#!/bin/ksh
#
# german_test.ksh — launch script for the German vocabulary drill/quiz app
# (the "Prüfung"). Opens german_vocab_drill.html in your default
# browser, building it (along with the xlsx workbook, in the same
# pass) via german-vocab.ksh if it doesn't exist yet.
#
# Usage:
#   german_test.ksh                 # opens ~/Documents/german_vocab_drill.html
#   german_test.ksh /path/to/file   # explicit override

typeset BUILD_SCRIPT="$HOME/bin/german-vocab.ksh"
typeset HTML_FILE="$HOME/Documents/german_vocab_drill.html"

platform=$(uname)

if [[ -n "$1" ]]; then
    typeset FILE="$1"
else
    typeset FILE="${HTML_FILE}"
fi

if [[ ! -e "${FILE}" ]]; then
    print "german_test.ksh: ${FILE} not found; building it..."

    if [[ ! -x "${BUILD_SCRIPT}" ]]; then
        print -u2 "german_test.ksh: cannot find or execute ${BUILD_SCRIPT}"
        exit 1
    fi

    # german-vocab.ksh takes (xlsx_path html_path); pass through the
    # default xlsx location so it doesn't get overridden, and place
    # our target html path second.
    "${BUILD_SCRIPT}" "$HOME/Documents/german_vocabulary_by_domain.xlsx" "${FILE}" || {
        print -u2 "german_test.ksh: build failed"
        exit 1
    }
fi

case $platform in
    Darwin)
        # Explicitly named, rather than a bare 'open', because a local
        # .html file opens via macOS's per-file-type default app -- if
        # that's ever been set to a text editor instead of a browser
        # (easy to do by accident), 'open' alone would open it there.
        # Naming the app sidesteps that regardless of the current
        # system-wide association. Override with:
        #   GERMAN_VOCAB_BROWSER="Google Chrome" german_test.ksh
        typeset BROWSER_APP="${GERMAN_VOCAB_BROWSER:-Safari}"
        open -a "${BROWSER_APP}" "${FILE}"
        ;;
    Linux)  xdg-open "${FILE}" >/dev/null 2>&1 & ;;
    *)      print -u2 "german_test.ksh: unsupported platform: ${platform}"
            exit 1 ;;
esac
