#!/bin/ksh
# find_it.ksh - find wrapper with path, match pattern, exclude pattern(s), and output file.
#
# Usage:
#   find_it.ksh -p path -f pattern [-e exclude-pattern ...] [-o outfile]
#
# -p   starting directory to search from (required)
# -f   filename pattern to match, wildcards allowed (required)
# -e   filename pattern to exclude, wildcards allowed; repeatable
#      (e.g. -e Library -e Container excludes both)
# -o   write results to this file instead of stdout (optional)
#
# Any -f or -e pattern without its own '*' is auto-wrapped as *pattern*
# so a bare word still matches anywhere in the filename. Exclusion is
# done by find itself (-not -iname), not by piping through grep.
# Standard error (e.g. "Permission denied") is always discarded.
#
# Examples:
#   find_it.ksh -p ~ -f "*xxsls*"
#   find_it.ksh -p ~ -f xxsls -e Library -e Container
#   find_it.ksh -p ~ -f xxsls -e Library -e Container -o ~/Desktop/hits.txt

typeset path=""
typeset pattern=""
typeset outfile=""
typeset -a excludes

wrap() {
    # $1: pattern, auto-wraps in *...* if it has no wildcard of its own.
    case $1 in
        *\**) print -- "$1" ;;
        *)    print -- "*${1}*" ;;
    esac
}

while getopts "p:f:e:o:" opt; do
    case $opt in
        p) path=$OPTARG ;;
        f) pattern=$OPTARG ;;
        e) excludes+=( "$(wrap "$OPTARG")" ) ;;
        o) outfile=$OPTARG ;;
        *) print -u2 "Usage: ${0##*/} -p path -f pattern [-e exclude ...] [-o outfile]"; exit 1 ;;
    esac
done

if [[ -z $path || -z $pattern ]]; then
    print -u2 "Usage: ${0##*/} -p path -f pattern [-e exclude ...] [-o outfile]"
    print -u2 "  -p  starting directory to search from"
    print -u2 "  -f  filename pattern to match (wildcards allowed)"
    print -u2 "  -e  filename pattern to exclude (wildcards allowed, repeatable)"
    print -u2 "  -o  write results to this file (default: stdout)"
    exit 1
fi

pattern=$(wrap "$pattern")

typeset -a cmd
cmd=(find "$path" -iname "$pattern")
typeset ex
for ex in "${excludes[@]}"; do
    cmd+=(-not -iname "$ex")
done
cmd+=(-ls)

if [[ -n $outfile ]]; then
    "${cmd[@]}" 2>/dev/null > "$outfile"
else
    "${cmd[@]}" 2>/dev/null
fi
