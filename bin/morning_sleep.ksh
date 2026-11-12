#!/bin/ksh
# morning_sleep.ksh - one-stop morning sleep-study routine.
# Confirms the four standing nightly meds (default yes), lets you add
# any extra one-off drugs, asks melatonin + notes, logs it, runs
# health_sleep on the Watch export, then shows the consolidated
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

# --- own timestamped log, per standing instruction -------------------
# Written as a brace-group piped to tee, not `exec > >(tee ...)`:
# that process-substitution form hit an "Illegal byte sequence" error
# on Steve's Mac (locale/parsing quirk in that ksh build), so this
# avoids it entirely -- same end result (everything shown on screen
# also lands in the log file), just without that syntax.
mkdir -p ~/logs
LOGFILE=~/logs/morning_sleep.$(date +%Y%m%d_%H%M%S).log

{

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
#     already there ---------------------------------------------------
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

# --- the four standing nightly meds, default yes --------------------
typeset -a STANDING_DRUGS
STANDING_DRUGS=("Lisinopril (blood pressure)" "Trazodone (sleep)" "Prilosec (heartburn)" "Flomax (prostate/bladder)")
typeset DRUG_LIST=""
typeset SKIPPED=""

for entry in "${STANDING_DRUGS[@]}"; do
    name="${entry%% \(*}"
    print -n "${entry} - taken? [Y/n]: "
    read ans
    ans=$(print "$ans" | tr '[:lower:]' '[:upper:]')
    if [[ "$ans" == "N" ]]; then
        SKIPPED="${SKIPPED:+$SKIPPED; }$name"
    else
        DRUG_LIST="${DRUG_LIST:+$DRUG_LIST; }$name"
    fi
done

# --- open-ended loop for any additional, one-off drugs ---------------
while true; do
    print -n "Additional drug not listed above (Enter to finish): "
    read EXTRA
    [[ -z "$EXTRA" ]] && break
    DRUG_LIST="${DRUG_LIST:+$DRUG_LIST; }$EXTRA"
    print -n "Any more to add? [y/N]: "
    read more
    more=$(print "$more" | tr '[:lower:]' '[:upper:]')
    [[ "$more" != "Y" ]] && break
done

# --- notes -------------------------------------------------------------
# Melatonin is no longer part of the regimen going forward (Steve has
# stopped taking it), so there's no prompt for it anymore -- the
# sleep_drug_log column still exists for the historical ZzzQuil/
# Lunesta/Trazodone experiment data, it's just always logged as N now.
MEL="N"

print -n "Notes (optional, Enter to skip): "
read NOTES

if [[ -n "$SKIPPED" ]]; then
    NOTES="${NOTES:+$NOTES; }(skipped: $SKIPPED)"
fi

# --- log the drug entry ---------------------------------------------
print ""
print "Logging last night's medications..."
if [[ -n "$NOTES" ]]; then
    sleep_drug_log "$NIGHT_DATE" "$DRUG_LIST" "$MEL" "$NOTES"
else
    sleep_drug_log "$NIGHT_DATE" "$DRUG_LIST" "$MEL"
fi

# --- run health_sleep -------------------------------------------------
print ""
print "Running health_sleep on the export file..."
health_sleep "$EXPORT_FILE"

# --- run the consolidated SQLite report ------------------------------
print ""
print "Generating the consolidated report..."
setup_sleep_db.ksh --import-drug-log ~/logs/sleep_drug_log.csv --report

} 2>&1 | tee "$LOGFILE"

print ""
print "See: $LOGFILE"
