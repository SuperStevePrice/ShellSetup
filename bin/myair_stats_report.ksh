#!/bin/ksh
# myair_stats_report.ksh - wrapper around myair_stats_report.py: turns a
# downloaded myAir "Sleep therapy report" PDF into a numbers-only PDF
# (same stats myAir already computed -- usage, AHI, leak, days-used
# thresholds -- for each date window, tabled, no bar charts).
#
# Before anything else, this also fixes ResMed's own download naming:
# myAir's "Download my report" saves the file as "myAir-Steve Price.pdf"
# (a literal space before the surname), which is awkward to reference
# from a shell. If that bad name is found sitting in ~/Downloads, it's
# renamed to myAir-Steve-Price.pdf first, every run, whether or not
# INPUT.pdf is given.
#
# Usage:
#   myair_stats_report.ksh [-s] [INPUT.pdf [OUTPUT.pdf]]
#     -s          print status messages in Spanish instead of English
#     INPUT.pdf   the myAir PDF you downloaded from myair.resmed.com
#                 (default: ~/Downloads/myAir-Steve-Price.pdf, after
#                 the rename above)
#     OUTPUT.pdf  where to write the numbers-only report
#                 (default: ~/Desktop/<INPUT base name>_stats.pdf --
#                 same place the rest of the Sleep Study Suite lands
#                 its PDFs)
#
# After a successful run, offers to open the finished PDF (default no),
# same as morning_sleep.ksh does for sleep_report.pdf.

SPANISH=0
while getopts "s" opt; do
    case $opt in
        s) SPANISH=1 ;;
        *) print -u2 "Usage: ${0##*/} [-s] [INPUT.pdf [OUTPUT.pdf]]"; exit 1 ;;
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

# --- fix ResMed's space-in-filename download, if it's sitting there ---
BAD_NAME=~/Downloads/"myAir-Steve Price.pdf"
GOOD_NAME=~/Downloads/myAir-Steve-Price.pdf
if [[ -f "$BAD_NAME" ]]; then
    msg "Renaming ResMed's download: 'myAir-Steve Price.pdf' -> 'myAir-Steve-Price.pdf'" \
        "Renombrando la descarga de ResMed: 'myAir-Steve Price.pdf' -> 'myAir-Steve-Price.pdf'"
    mv "$BAD_NAME" "$GOOD_NAME"
fi

# --- default INPUT.pdf to the (now correctly named) latest download ---
if [[ -z "$1" ]]; then
    if [[ -f "$GOOD_NAME" ]]; then
        set -- "$GOOD_NAME"
    else
        msg "Usage: ${0##*/} [-s] [INPUT.pdf [OUTPUT.pdf]]" \
            "Uso: ${0##*/} [-s] [ENTRADA.pdf [SALIDA.pdf]]"
        exit 1
    fi
fi

INPUT="$1"

# --- default OUTPUT.pdf to the Desktop, same as the rest of the Sleep
#     Study Suite (sleep_report.pdf etc.) rather than next to INPUT ---
if [[ -n "$2" ]]; then
    OUTPUT="$2"
else
    base=$(basename "${INPUT%.*}")
    OUTPUT="$HOME/Desktop/${base}_stats.pdf"
fi

mkdir -p ~/logs
LOGFILE=~/logs/myair_stats_report.$(date +%Y%m%d_%H%M%S).log

{

msg "Extracting myAir stats from: $INPUT" \
    "Extrayendo estadisticas de myAir desde: $INPUT"

python3 ~/bin/myair_stats_report.py "$INPUT" "$OUTPUT"
rc=$?

if [[ $rc -eq 0 ]]; then
    msg "Done." "Listo."

    if [[ -f "$OUTPUT" ]]; then
        if [[ $SPANISH -eq 1 ]]; then
            print -n "¿Desea abrir el informe en PDF? [y/N]: "
        else
            print -n "Would you like to open the PDF report? [y/N]: "
        fi
        read OPEN_PDF
        OPEN_PDF=$(print "$OPEN_PDF" | tr '[:lower:]' '[:upper:]')
        [[ "$OPEN_PDF" == "Y" ]] && open "$OUTPUT"
    fi
else
    msg "Failed (see above)." "Fallo (vea arriba)."
fi

} 2>&1 | tee "$LOGFILE"

print ""
print "See: $LOGFILE"
