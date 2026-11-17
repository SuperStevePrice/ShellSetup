#!/bin/ksh
# myair_stats_report.ksh - wrapper around myair_stats_report.py: turns a
# downloaded myAir "Sleep therapy report" PDF into a numbers-only PDF
# (same stats myAir already computed -- usage, AHI, leak, days-used
# thresholds -- for each date window, tabled, no bar charts).
#
# Usage:
#   myair_stats_report.ksh [-s] INPUT.pdf [OUTPUT.pdf]
#     -s          print status messages in Spanish instead of English
#     INPUT.pdf   the myAir PDF you downloaded from myair.resmed.com
#     OUTPUT.pdf  where to write the numbers-only report
#                 (default: INPUT with _stats before .pdf)

SPANISH=0
while getopts "s" opt; do
    case $opt in
        s) SPANISH=1 ;;
        *) print -u2 "Usage: ${0##*/} [-s] INPUT.pdf [OUTPUT.pdf]"; exit 1 ;;
    esac
done
shift $((OPTIND - 1))

msg() {
    if [[ $SPANISH -eq 1 ]]; then
        print "$2"
    else
        print "$1"
    fi
}

if [[ -z "$1" ]]; then
    msg "Usage: ${0##*/} [-s] INPUT.pdf [OUTPUT.pdf]" \
        "Uso: ${0##*/} [-s] ENTRADA.pdf [SALIDA.pdf]"
    exit 1
fi

mkdir -p ~/logs
LOGFILE=~/logs/myair_stats_report.$(date +%Y%m%d_%H%M%S).log

{

msg "Extracting myAir stats from: $1" \
    "Extrayendo estadisticas de myAir desde: $1"

python3 ~/bin/myair_stats_report.py "$@"
rc=$?

if [[ $rc -eq 0 ]]; then
    msg "Done." "Listo."
else
    msg "Failed (see above)." "Fallo (vea arriba)."
fi

} 2>&1 | tee "$LOGFILE"

print ""
print "See: $LOGFILE"
