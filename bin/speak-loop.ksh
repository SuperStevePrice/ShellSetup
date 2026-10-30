#!/usr/bin/env ksh
#
# speak-loop.ksh - run `speak` in a loop with whatever arguments you'd
# normally give it, replaying the same text file until you quit.
#
# All arguments are passed straight through to speak, except the last
# one, which is taken to be the text file -- and except speak-loop's
# own options below, which must come first, before any speak options.
#
# Usage:
#   speak-loop.ksh [-L] [-o output-file] [-s] [speak-options...] textfile.txt
#
# speak-loop's own options:
#   -L            Loop forever: replay automatically with no prompt,
#                 until you hit Ctrl-C. (Without -L, you're prompted
#                 after each playback to repeat, switch files, or quit,
#                 same as before.)
#   -o outfile    Save the translated text to outfile. Only valid when
#                 -x (translation) is also among the speak options --
#                 without translation the saved text would just
#                 duplicate the input file, so speak-loop refuses and
#                 exits rather than passing it through. Forwarded to
#                 speak as `-o outfile`.
#   -s            Spanish prompts/messages from speak-loop itself
#                 (match lists, picker prompts, error text). Does not
#                 affect speak's own output language -- pass speak's
#                 own language flags separately, as always.
#
# Example:
#   speak-loop.ksh -p -g laura li_fold.txt
#   (runs: speak -p -g laura li_fold.txt, then offers to repeat)
#
#   speak-loop.ksh -L -o freude_de.txt -x de freude.txt
#   (loops forever; each pass translates to German via speak -x de
#   and (re)saves the translation to freude_de.txt)
#
# If textfile.txt is not a fully qualified path (i.e. doesn't start
# with /), the CURRENT DIRECTORY is checked first -- same precedence
# 'speak' itself uses -- and only if nothing matches there does it fall
# back to the base name in ~/Documents. So "laura li_fold.txt" above
# resolves to ./laura li_fold.txt if that exists here, else
# ~/Documents/laura li_fold.txt.
#
# Wildcards are allowed in the base name (e.g. freude*.txt), whether
# the shell expands them for you (because you ran from a directory
# where they matched something -- that directory is honored, not
# silently swapped for ~/Documents) or they reach the script unexpanded
# (quoted, or no match in the current directory, in which case
# ~/Documents is tried next). Either way, if more than one file
# matches, you're shown a numbered list to pick from -- and (unless
# -L is given) that same list comes back up after every playback, so
# you can jump straight from one match to another (e.g. the 1st
# Schiller verse to the 5th) without re-running the whole command.

typeset -a args
typeset -a speak_args
typeset textfile
integer n

integer forever=0
integer spanish=0
typeset outfile=""

args=("$@")

# Pull speak-loop's own options off the FRONT of the argument list.
# These must come before any speak options / the text file, since
# everything below treats "all args but the trailing file(s)" as
# belonging to speak.
while (( ${#args[@]} > 0 )); do
    case ${args[0]} in
        -L)
            forever=1
            args=("${args[@]:1}")
            ;;
        -s)
            spanish=1
            args=("${args[@]:1}")
            ;;
        -o)
            if (( ${#args[@]} < 2 )); then
                if (( spanish )); then
                    print -u2 "Error: -o requiere un nombre de archivo"
                else
                    print -u2 "Error: -o requires a filename argument"
                fi
                exit 1
            fi
            outfile=${args[1]}
            args=("${args[@]:2}")
            ;;
        *)
            break
            ;;
    esac
done

n=${#args[@]}

if (( n < 1 )); then
    if (( spanish )); then
        print -u2 "Uso: speak-loop.ksh [-L] [-o archivo-salida] [-s] [opciones-de-speak...] archivo.txt"
    else
        print -u2 "Usage: speak-loop.ksh [-L] [-o output-file] [-s] [speak-options...] textfile.txt"
    fi
    exit 1
fi

# If you run a wildcard (e.g. freude*.txt) from a directory where it
# happens to match something -- most commonly ~/Documents itself --
# the shell expands it before this script ever sees it, handing us
# several separate filename arguments instead of one argument
# containing a "*". Scan backward from the end of the argument list
# and pull in every trailing argument that resolves to a real file;
# if two or more do, that's the match list, full stop -- this must
# run before any wildcard pattern-matching below, or those extra
# filenames get mistaken for speak options.
typeset -a matches
typeset -a trailing_resolved
integer trailing_count=0
integer idx=n-1
typeset cand cand_resolved
integer saw_dir=0

# speak-loop (and speak) read text files, never directories. Keep only
# regular files in $matches; note (via saw_dir) whether a directory
# turned up along the way, purely so a later all-directories-no-files
# failure can say so plainly instead of a bare "not found".
function filter_to_files {
    typeset -a kept
    typeset m
    for m in "${matches[@]}"; do
        if [[ -f $m ]]; then
            kept+=("$m")
        elif [[ -d $m ]]; then
            saw_dir=1
        fi
    done
    matches=("${kept[@]}")
}

while (( idx >= 0 )); do
    cand=${args[idx]}
    if [[ $cand == /* ]]; then
        cand_resolved=$cand
    elif [[ -f $cand ]]; then
        # Found right here in the current directory -- this is exactly
        # the case where the shell already expanded a wildcard for us
        # because it matched something in THIS directory, so that's
        # where the match actually lives; don't reach into ~/Documents
        # instead.
        cand_resolved=$cand
    else
        cand_resolved="$HOME/Documents/${cand##*/}"
    fi
    if [[ -f $cand_resolved ]]; then
        trailing_resolved=("$cand_resolved" "${trailing_resolved[@]}")
        (( trailing_count += 1 ))
        (( idx -= 1 ))
    else
        break
    fi
done

if (( trailing_count >= 2 )); then
    matches=("${trailing_resolved[@]}")
    speak_args=("${args[@]:0:n-trailing_count}")
    textfile=${matches[0]}
else
    textfile=${args[n-1]}

    if (( n > 1 )); then
        speak_args=("${args[@]:0:n-1}")
    fi

    # Allow wildcards in the base name (e.g. freude_3_f*.txt). This
    # covers the case where the pattern reached us unexpanded --
    # typically because you quoted it, or ran it from a directory
    # where it didn't match anything so the shell left it alone.
    # IFS is blanked first so that any literal spaces in the filename
    # (e.g. "laura li_fold.txt") aren't mistaken for word breaks
    # during the expansion.
    typeset old_ifs=$IFS
    typeset orig_pattern=$textfile

    if [[ $textfile == /* ]]; then
        IFS=
        matches=( $textfile )
        IFS=$old_ifs
        filter_to_files
    else
        # Try the pattern as given, relative to the CURRENT DIRECTORY
        # first -- same precedence 'speak' itself uses -- so running
        # speak-loop from inside a project directory finds a file
        # sitting right there instead of silently reaching into
        # ~/Documents.
        IFS=
        matches=( $textfile )
        IFS=$old_ifs
        filter_to_files

        # Nothing usable here (no match, or the only match was a
        # directory -- e.g. *pro* catching a "project_docs" folder) --
        # fall back to ~/Documents using just the base name (any
        # directory part given on the command line is dropped for this
        # fallback).
        if (( ${#matches[@]} == 0 )); then
            textfile="$HOME/Documents/${textfile##*/}"
            IFS=
            matches=( $textfile )
            IFS=$old_ifs
            filter_to_files
        fi
    fi

    if (( ${#matches[@]} == 0 )); then
        if (( saw_dir )); then
            if (( spanish )); then
                print -u2 "Error: '$orig_pattern' coincide con un directorio, no un archivo -- la entrada debe ser un archivo de texto."
            else
                print -u2 "Error: '$orig_pattern' matches a directory, not a file -- input must be a text file."
            fi
        else
            if (( spanish )); then
                print -u2 "Error: archivo '$textfile' no encontrado"
            else
                print -u2 "Error: file '$textfile' not found"
            fi
        fi
        exit 1
    fi
fi

# -o is only meaningful alongside translation; otherwise the saved
# text would just duplicate the input file. Require -x somewhere in
# the options being forwarded to speak, then forward -o itself.
if [[ -n $outfile ]]; then
    typeset has_x=0
    typeset sa
    for sa in "${speak_args[@]}"; do
        if [[ $sa == -x* ]]; then
            has_x=1
            break
        fi
    done
    if (( ! has_x )); then
        if (( spanish )); then
            print -u2 "Error: -o requiere que -x (traduccion) tambien este activado"
        else
            print -u2 "Error: -o requires -x (translation) to also be given"
        fi
        exit 1
    fi
    speak_args+=(-o "$outfile")
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
    if (( spanish )); then
        print "'$textfile' coincide con mas de un archivo:"
    else
        print "'$textfile' matches more than one file:"
    fi
    print_matches

    while true; do
        if (( spanish )); then
            print -n "Elija un numero (1-${#matches[@]}), o 'q' para salir: "
        else
            print -n "Pick a number (1-${#matches[@]}), or 'q' to quit: "
        fi
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

        if (( spanish )); then
            print "Seleccion invalida."
        else
            print "Invalid selection."
        fi
    done
fi

if (( forever )); then
    if (( spanish )); then
        print "Repitiendo sin parar -- presione Ctrl-C para detener."
    else
        print "Looping forever -- press Ctrl-C to stop."
    fi
    while true; do
        speak "${speak_args[@]}" "${matches[current]}"
    done
else
    while true; do
        speak "${speak_args[@]}" "${matches[current]}"

        if (( ${#matches[@]} > 1 )); then
            print_matches
            if (( spanish )); then
                print -n "Presione Enter para repetir, escriba un numero para cambiar de archivo, o 'q' para salir: "
            else
                print -n "Press Enter to repeat, type a number to switch files, or 'q' to quit: "
            fi
        else
            if (( spanish )); then
                print -n "Presione Enter para repetir, o 'q' para salir: "
            else
                print -n "Press Enter to repeat, or 'q' to quit: "
            fi
        fi

        read answer

        case $answer in
            q|Q) break ;;
            +([0-9]))
                if (( ${#matches[@]} > 1 )) && (( answer >= 1 && answer <= ${#matches[@]} )); then
                    current=$((answer - 1))
                elif (( ${#matches[@]} > 1 )); then
                    if (( spanish )); then
                        print "Seleccion invalida -- repitiendo el archivo actual."
                    else
                        print "Invalid selection -- repeating current file."
                    fi
                fi
                ;;
            *) ;;
        esac
    done
fi
#-------------------------------------------------------------------------------
# Last installed: (set by setup.ksh)
#-- End of File ----------------------------------------------------------------
