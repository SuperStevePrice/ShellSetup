#!/bin/ksh
#
# pbc.ksh - copy a file's content to the clipboard (wraps pbcopy)
#
# Usage:
#   pbc.ksh file          copy contents of 'file' to the clipboard
#   pbc.ksh               read from stdin (so 'pbc.ksh < file' still works)
#   pbc.ksh -s [file]     show messages in Spanish
#   pbc.ksh -h            show this help
#
# Rationale: pbcopy is a stdin filter, so historically you had to write
# "pbcopy < file". This wrapper lets you just name the file; redirection
# still works unchanged for anyone who types it that way out of habit.

typeset SPANISH=0

usage() {
    if [[ $SPANISH -eq 1 ]]; then
        print "Uso: pbc.ksh [-s] [archivo]"
        print "  Copia el contenido de 'archivo' (o la entrada estandar) al portapapeles."
        print "  -s  Mensajes en espanol"
        print "  -h  Muestra esta ayuda"
    else
        print "Usage: pbc.ksh [-s] [file]"
        print "  Copies the contents of 'file' (or stdin) to the clipboard."
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
    # No filename given: behave exactly like pbcopy itself, reading stdin.
    # This is what preserves "pbc.ksh < setup.ksh" for old habits.
    pbcopy
elif [[ $# -eq 1 ]]; then
    typeset file="$1"
    if [[ ! -r "$file" ]]; then
        if [[ $SPANISH -eq 1 ]]; then
            print -u2 "pbc.ksh: no se puede leer '$file'"
        else
            print -u2 "pbc.ksh: cannot read '$file'"
        fi
        exit 1
    fi
    pbcopy < "$file"
else
    usage
    exit 1
fi
