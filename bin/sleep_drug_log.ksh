#!/bin/ksh
# sleep_drug_log.ksh - append or show sleep-drug experiment entries.
# Log file: ~/logs/sleep_drug_log.csv  (date,drug,melatonin,notes)
#
# Usage:
#   sleep_drug_log.ksh 2026-11-01 Lunesta Y
#   sleep_drug_log.ksh 2026-11-01 Lunesta N "no melatonin, pure Lunesta test"
#   sleep_drug_log.ksh -l              # list all entries
#   sleep_drug_log.ksh -l -n 7         # list last 7 entries
#   sleep_drug_log.ksh -s ...          # Spanish messages
#
# MELATONIN is Y or N - whether melatonin was taken that night, tracked
# separately from the main sleep agent so combinations can be compared.

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

# One-time migration: old 3-column file (date,drug,notes) -> 4-column
# (date,drug,melatonin,notes). Existing rows get melatonin=Y backfilled,
# since melatonin was present on all logged nights so far.
if [[ -f "$LOG" ]] && head -1 "$LOG" | grep -q '^date,drug,notes$'; then
    cp "$LOG" "$LOG.pre-melatonin.bak"
    { 
        print "date,drug,melatonin,notes"
        tail -n +2 "$LOG.pre-melatonin.bak" | awk -F',' 'BEGIN{OFS=","} {
            notes=$3
            for(i=4;i<=NF;i++) notes=notes","$i
            print $1,$2,"Y",notes
        }'
    } > "$LOG"
    print "Migrated $LOG to add melatonin column (old version saved as $LOG.pre-melatonin.bak)"
fi

[[ -f "$LOG" ]] || print "date,drug,melatonin,notes" > "$LOG"

if [[ $LIST -eq 1 ]]; then
    if [[ $NLINES -gt 0 ]]; then
        { head -1 "$LOG"; tail -n "$NLINES" "$LOG" | grep -v '^date,drug,melatonin,notes$'; } | column -t -s,
    else
        column -t -s, "$LOG"
    fi
    exit 0
fi

if [[ $# -lt 3 ]]; then
    if [[ $SPANISH -eq 1 ]]; then
        print -u2 "Uso: ${0##*/} FECHA MEDICAMENTO MELATONINA(S/N) [notas]   o   ${0##*/} -l [-n N]"
    else
        print -u2 "Usage: ${0##*/} DATE DRUG MELATONIN(Y/N) [notes]   or   ${0##*/} -l [-n N]"
    fi
    exit 1
fi

DATE=$1
DRUG=$2
MEL=$3
NOTES=$4

# simple CSV-safe: strip any commas from notes
NOTES=$(print "$NOTES" | tr ',' ';')

print "$DATE,$DRUG,$MEL,$NOTES" >> "$LOG"

if [[ $SPANISH -eq 1 ]]; then
    print "Registrado: $DATE -> $DRUG (melatonina: $MEL)"
else
    print "Logged: $DATE -> $DRUG (melatonin: $MEL)"
fi
