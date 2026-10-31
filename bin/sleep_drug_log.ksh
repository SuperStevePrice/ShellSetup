#!/bin/ksh
# sleep_drug_log.ksh - append or show sleep-drug experiment entries.
# Log file: ~/logs/sleep_drug_log.csv  (date,drug,notes)
#
# Usage:
#   sleep_drug_log.ksh 2026-10-31 Lunesta
#   sleep_drug_log.ksh 2026-10-31 Lunesta "fast onset, 8 wakings, felt rested"
#   sleep_drug_log.ksh -l              # list all entries
#   sleep_drug_log.ksh -l -n 7         # list last 7 entries
#   sleep_drug_log.ksh -s ...          # Spanish messages

LOG=~/logs/sleep_drug_log.csv
SPANISH=0
LIST=0
NLINES=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s) SPANISH=1; shift ;;
        -l) LIST=1; shift ;;
        -n) NLINES=$2; shift 2 ;;
        *) break ;;
    esac
done

mkdir -p ~/logs
[[ -f "$LOG" ]] || print "date,drug,notes" > "$LOG"

if [[ $LIST -eq 1 ]]; then
    if [[ $NLINES -gt 0 ]]; then
        { head -1 "$LOG"; tail -n "$NLINES" "$LOG" | grep -v '^date,drug,notes$'; } | column -t -s,
    else
        column -t -s, "$LOG"
    fi
    exit 0
fi

if [[ $# -lt 2 ]]; then
    if [[ $SPANISH -eq 1 ]]; then
        print -u2 "Uso: ${0##*/} FECHA MEDICAMENTO [notas]   o   ${0##*/} -l [-n N]"
    else
        print -u2 "Usage: ${0##*/} DATE DRUG [notes]   or   ${0##*/} -l [-n N]"
    fi
    exit 1
fi

DATE=$1
DRUG=$2
NOTES=$3

# simple CSV-safe: strip any commas from notes
NOTES=$(print "$NOTES" | tr ',' ';')

print "$DATE,$DRUG,$NOTES" >> "$LOG"

if [[ $SPANISH -eq 1 ]]; then
    print "Registrado: $DATE -> $DRUG"
else
    print "Logged: $DATE -> $DRUG"
fi
