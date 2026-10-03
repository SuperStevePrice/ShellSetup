#!/bin/ksh
#
# extract_emails.ksh - Extract email addresses from a string of
#                      "Name <email@domain>" entries and print them
#                      to STDOUT, one line, space-separated, by default.
#
# Usage:
#   extract_emails.ksh [-s] [-m] "string"
#   echo "string" | extract_emails.ksh [-s] [-m]
#
# Options:
#   -s    Print messages in Spanish instead of English
#   -m    Print one address per line (multi-line) instead of the
#         default single space-separated line
#   -h    Show this help message
#
# IMPORTANT: Always quote the string argument. It normally contains
# '<' and '>' characters (e.g. Name <email@domain>), and if left
# unquoted the SHELL (not this script) will treat them as input/output
# redirection operators, producing errors like:
#     -ksh: syntax error: `newline' unexpected
# Use double or single quotes around the whole string, e.g.:
#     ksh extract_emails.ksh "Name <a@b.com>, Name <c@d.com>"
#

typeset SPANISH=0
typeset MULTILINE=0

usage() {
    if [ "$SPANISH" -eq 1 ]; then
        print "Uso: $(basename "$0") [-s] [-m] [-h] \"cadena\""
        print "  Extrae direcciones de correo de una cadena con el formato:"
        print "  Nombre <correo@dominio.com>, Nombre <correo@dominio.com>, ..."
        print "  -s    Salida en espanol"
        print "  -m    Una direccion por linea (por defecto: una sola"
        print "        linea, separadas por un espacio)"
        print "  -h    Muestra esta ayuda"
        print "  NOTA: encierre siempre la cadena entre comillas; los"
        print "  caracteres '<' y '>' son interpretados por el shell"
        print "  como redireccion de E/S si no se citan."
    else
        print "Usage: $(basename "$0") [-s] [-m] [-h] \"string\""
        print "  Extracts email addresses from a string formatted as:"
        print "  Name <email@domain.com>, Name <email@domain.com>, ..."
        print "  -s    Output messages in Spanish"
        print "  -m    One address per line (multi-line) instead of the"
        print "        default single space-separated line"
        print "  -h    Show this help"
        print "  NOTE: always quote the string; '<' and '>' are treated"
        print "  as shell I/O redirection if left unquoted."
    fi
}

# Parse options
while getopts "smh" opt; do
    case $opt in
        s) SPANISH=1 ;;
        m) MULTILINE=1 ;;
        h) usage; exit 0 ;;
        *) usage; exit 1 ;;
    esac
done
shift $((OPTIND - 1))

# Get input: command-line argument(s) take priority, else read STDIN
if [ $# -ge 1 ]; then
    INPUT="$*"

    # Sanity check: more than one argument almost always means the
    # string was NOT quoted (the shell split it on whitespace instead
    # of passing it through as one piece). We still reconstruct it with
    # $* below, but warn, since word-splitting can quietly drop commas,
    # collapse repeated spaces, or - if the string contains '<'/'>' that
    # happened to resolve to a real file - silently vanish a whole email.
    if [ $# -gt 1 ]; then
        if [ "$SPANISH" -eq 1 ]; then
            print -u2 "Aviso: se recibieron varios argumentos separados, lo cual sugiere que la cadena no estaba entre comillas dobles. Encierre toda la cadena entre comillas, por ejemplo:"
            print -u2 "  $(basename "$0") \"Nombre <correo@dominio.com>, ...\""
        else
            print -u2 "Warning: multiple separate arguments were received, which suggests the string was not enclosed in double quotes. Wrap the whole string in quotes, e.g.:"
            print -u2 "  $(basename "$0") \"Name <email@domain.com>, ...\""
        fi
    fi

    # Sanity check: an unequal count of '<' and '>' suggests the shell
    # consumed one as a redirection operator (quietly, with no error)
    # rather than passing it through as literal text.
    typeset lt_count=$(print "$INPUT" | tr -cd '<' | wc -c)
    typeset gt_count=$(print "$INPUT" | tr -cd '>' | wc -c)
    if [ "$lt_count" -ne "$gt_count" ]; then
        if [ "$SPANISH" -eq 1 ]; then
            print -u2 "Aviso: el numero de '<' y '>' no coincide; es posible que el shell haya interpretado uno de ellos como redireccion de E/S y haya eliminado parte de la cadena en silencio. Encierre toda la cadena entre comillas dobles."
        else
            print -u2 "Warning: the '<' and '>' counts don't match; the shell may have silently interpreted one as I/O redirection and dropped part of the string. Wrap the whole string in double quotes."
        fi
    fi
elif [ ! -t 0 ]; then
    INPUT=$(cat)
else
    if [ "$SPANISH" -eq 1 ]; then
        print -u2 "Error: no se proporciono ninguna cadena de entrada."
    else
        print -u2 "Error: no input string provided."
    fi
    usage
    exit 1
fi

if [ -z "$INPUT" ]; then
    if [ "$SPANISH" -eq 1 ]; then
        print -u2 "Error: la cadena de entrada esta vacia."
    else
        print -u2 "Error: input string is empty."
    fi
    exit 1
fi

# Extract substrings matching a basic email pattern
EMAILS=$(print "$INPUT" | grep -oE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}')

if [ -z "$EMAILS" ]; then
    if [ "$SPANISH" -eq 1 ]; then
        print -u2 "Error: no se encontraron direcciones de correo validas en la entrada."
    else
        print -u2 "Error: no valid email addresses found in the input."
    fi
    exit 1
fi

if [ "$MULTILINE" -eq 1 ]; then
    print "$EMAILS"
else
    print "$EMAILS" | tr '\n' ' ' | sed 's/ $//'
    print
fi

exit 0
