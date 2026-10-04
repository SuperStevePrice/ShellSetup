#!/bin/ksh
#
# pbp.ksh - write clipboard content to stdout or to a file (wraps pbpaste)
#
# Usage:
#   pbp.ksh               print clipboard contents to stdout
#                          (so 'pbp.ksh > file' still works unchanged)
#   pbp.ksh file           write clipboard contents directly to 'file'
#   pbp.ksh -s [file]      show messages in Spanish
#   pbp.ksh -h             show this help
#
# Mirrors pbc.ksh: a filename argument or old-habit redirection both work.

typeset SPANISH=0

usage() {
    if [[ $SPANISH -eq 1 ]]; then
        print "Uso: pbp.ksh [-s] [archivo]"
        print "  Imprime el contenido del portapapeles, o lo escribe en 'archivo'."
        print "  -s  Mensajes en espanol"
        print "  -h  Muestra esta ayuda"
    else
        print "Usage: pbp.ksh [-s] [file]"
        print "  Prints the clipboard contents, or writes them to 'file'."
        print "  -s  Spanish-language messages"
        print "  -h  Show this help"
    fi
}

while getopts "sh" opt; do
    case $opt in
        s) SPANISH=1 ;;
        h) usage; exit 0 ;;
        *) usage; exit 1 ;;
    esac
done
shift $((OPTIND - 1))

if [[ $# -eq 0 ]]; then
    # No filename given: behave exactly like pbpaste itself, writing stdout.
    # This is what preserves "pbp.ksh > outfile" for old habits.
    pbpaste
elif [[ $# -eq 1 ]]; then
    typeset file="$1"
    if ! pbpaste > "$file"; then
        if [[ $SPANISH -eq 1 ]]; then
            print -u2 "pbp.ksh: no se puede escribir en '$file'"
        else
            print -u2 "pbp.ksh: cannot write to '$file'"
        fi
        exit 1
    fi
else
    usage
    exit 1
fi
