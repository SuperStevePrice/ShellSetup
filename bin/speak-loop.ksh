#!/usr/bin/env ksh
#
# speak-loop.ksh - run `speak` in a loop with whatever arguments you'd
# normally give it, replaying the same text file until you quit.
#
# All arguments are passed straight through to speak, except the last
# one, which is taken to be the text file.
#
# Usage:
#   speak-loop.ksh [speak-options...] textfile.txt
#
# Example:
#   speak-loop.ksh -p -g laura li_fold.txt
#   (runs: speak -p -g laura li_fold.txt, then offers to repeat)
#
# If textfile.txt is not a fully qualified path (i.e. doesn't start
# with /), its base name is used and looked up in ~/Documents by
# default. So "laura li_fold.txt" above resolves to
# ~/Documents/laura li_fold.txt.
#
# Wildcards are allowed in the base name (e.g. freude*.txt). If more
# than one file matches, you're shown a numbered list to pick from --
# and that same list comes back up after every playback, so you can
# jump straight from one match to another (e.g. the 1st Schiller verse
# to the 5th) without re-running the whole command.

typeset -a args
typeset -a speak_args
typeset textfile
integer n

args=("$@")
n=${#args[@]}

if (( n < 1 )); then
    print -u2 "Usage: speak-loop.ksh [speak-options...] textfile.txt"
    exit 1
fi

textfile=${args[n-1]}

if (( n > 1 )); then
    speak_args=("${args[@]:0:n-1}")
fi

# If not a fully qualified path, default to ~/Documents using just
# the base name (any directory part given on the command line is
# dropped).
if [[ $textfile != /* ]]; then
    textfile="$HOME/Documents/${textfile##*/}"
fi

# Allow wildcards in the base name (e.g. freude_3_f*.txt). The glob
# itself isn't expanded by the shell at invocation time because it
# didn't match anything in the current directory, so expand it here
# against the resolved path instead. IFS is blanked first so that any
# literal spaces in the filename (e.g. "laura li_fold.txt") aren't
# mistaken for word breaks during the expansion.
typeset -a matches
typeset old_ifs=$IFS
IFS=
matches=( $textfile )
IFS=$old_ifs

if (( ${#matches[@]} == 0 )) || [[ ! -f ${matches[0]} ]]; then
    print -u2 "Error: file '$textfile' not found"
    exit 1
fi

integer current=0

# Print the numbered match list, marking the currently selected file.
function print_matches {
    integer i=1
    typeset m
    for m in "${matches[@]}"; do
        if (( i - 1 == current )); then
            print "  $i) $m  (current)"
        else
            print "  $i) $m"
        fi
        (( i += 1 ))
    done
}

if (( ${#matches[@]} > 1 )); then
    print "'$textfile' matches more than one file:"
    print_matches

    while true; do
        print -n "Pick a number (1-${#matches[@]}), or 'q' to quit: "
        read choice

        case $choice in
            q|Q) exit 0 ;;
            +([0-9]))
                if (( choice >= 1 && choice <= ${#matches[@]} )); then
                    current=$((choice - 1))
                    break
                fi
                ;;
        esac

        print "Invalid selection."
    done
fi

while true; do
    speak "${speak_args[@]}" "${matches[current]}"

    if (( ${#matches[@]} > 1 )); then
        print_matches
        print -n "Press Enter to repeat, type a number to switch files, or 'q' to quit: "
    else
        print -n "Press Enter to repeat, or 'q' to quit: "
    fi

    read answer

    case $answer in
        q|Q) break ;;
        +([0-9]))
            if (( ${#matches[@]} > 1 )) && (( answer >= 1 && answer <= ${#matches[@]} )); then
                current=$((answer - 1))
            elif (( ${#matches[@]} > 1 )); then
                print "Invalid selection -- repeating current file."
            fi
            ;;
        *) ;;
    esac
done
