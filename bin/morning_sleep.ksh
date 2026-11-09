#!/bin/ksh
# morning_sleep.ksh - one-stop morning sleep-study routine.
# Prompts for last night's medication, melatonin, and notes, logs them,
# runs health_sleep on the Watch export, then shows the consolidated
# database report (sleep + drug + nocturia, joined by night).
#
# Usage:
#   morning_sleep.ksh [-f export.zip|export.xml]
#     -f FILE   path to the Health export (default: looks for export.zip
#               in the current directory, then ~/Downloads/export.zip)

EXPORT_FILE=""

while getopts "f:" opt; do
    case $opt in
        f) EXPORT_FILE=$OPTARG ;;
        *) print -u2 "Usage: ${0##*/} [-f export.zip|export.xml]"; exit 1 ;;
    esac
done

# --- find the export file if not given with -f ---------------------
if [[ -z "$EXPORT_FILE" ]]; then
    if [[ -f "./export.zip" ]]; then
        EXPORT_FILE="./export.zip"
    elif [[ -f "$HOME/Downloads/export.zip" ]]; then
        EXPORT_FILE="$HOME/Downloads/export.zip"
    fi
fi

if [[ -z "$EXPORT_FILE" || ! -f "$EXPORT_FILE" ]]; then
    print -n "Path to Health export file: "
    read EXPORT_FILE
fi

if [[ ! -f "$EXPORT_FILE" ]]; then
    print -u2 "Export file not found at '$EXPORT_FILE'"
    exit 1
fi

# --- unzip export.zip if needed, reusing an existing extract if one's
#     already there (health_sleep can read a .zip directly, but a
#     plain .xml is faster on repeat runs and this was asked for
#     explicitly) --------------------------------------------------
if [[ "$EXPORT_FILE" == *.zip ]]; then
    ZIP_DIR=$(dirname "$EXPORT_FILE")
    XML_CANDIDATE="$ZIP_DIR/apple_health_export/export.xml"
    if [[ -f "$XML_CANDIDATE" ]]; then
        print "Already-unzipped copy found; using that."
        EXPORT_FILE="$XML_CANDIDATE"
    else
        print "Unzipping export.zip..."
        if ( cd "$ZIP_DIR" && unzip -oq "$EXPORT_FILE" ) 2>/dev/null && [[ -f "$XML_CANDIDATE" ]]; then
            EXPORT_FILE="$XML_CANDIDATE"
        else
            print -u2 "Could not unzip export.zip; will use the .zip directly instead."
        fi
    fi
fi

# --- prompt for the night's date (default: today) -------------------
DEFAULT_DATE=$(date +%Y-%m-%d)
print -n "Night's date (YYYY-MM-DD) [$DEFAULT_DATE]: "
read NIGHT_DATE
[[ -z "$NIGHT_DATE" ]] && NIGHT_DATE="$DEFAULT_DATE"

# --- prompt for drug (single letter), melatonin, notes --------------
DRUG=""
while [[ -z "$DRUG" ]]; do
    print -n "Sleep medication: Z=ZzzQuil, L=Lunesta, T=Trazodone: "
    read DRUG_LETTER
    DRUG_LETTER=$(print "$DRUG_LETTER" | tr '[:lower:]' '[:upper:]')
    case "$DRUG_LETTER" in
        Z) DRUG="ZzzQuil" ;;
        L) DRUG="Lunesta" ;;
        T) DRUG="Trazodone" ;;
        *) print "Please enter Z, L, or T." ;;
    esac
done

MEL=""
while [[ "$MEL" != "Y" && "$MEL" != "N" ]]; do
    print -n "Melatonin taken? (Y/N): "
    read MEL
    MEL=$(print "$MEL" | tr '[:lower:]' '[:upper:]')
done

print -n "Notes (optional, Enter to skip): "
read NOTES

# --- log the drug entry ---------------------------------------------
print ""
print "Logging last night's medication..."
if [[ -n "$NOTES" ]]; then
    sleep_drug_log "$NIGHT_DATE" "$DRUG" "$MEL" "$NOTES"
else
    sleep_drug_log "$NIGHT_DATE" "$DRUG" "$MEL"
fi

# --- run health_sleep -------------------------------------------------
print ""
print "Running health_sleep on the export file..."
health_sleep "$EXPORT_FILE"

# --- run the consolidated SQLite report ------------------------------
print ""
print "Generating the consolidated report..."
setup_sleep_db.ksh --import-drug-log ~/logs/sleep_drug_log.csv --report
