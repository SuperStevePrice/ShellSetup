#!/bin/ksh
# setup_sleep_db.ksh - wrapper for setup_sleep_db.py
# Creates/updates the sleep study SQLite database and imports existing logs.

here=${0%/*}
[[ "$here" == "$0" ]] && here=.

if [[ $# -lt 1 ]]; then
    print "Usage:"
    print "  ${0##*/} --import-prescriptions-sql prescriptions_insert.sql"
    print "  ${0##*/} --import-drug-log PATH_TO_SLEEP_DRUG_LOG_FILE"
    print "  ${0##*/} --report [-n N]"
    print ""
    print "Run with no useful flags still creates/updates the database and imports"
    print "the nocturia log automatically (default path ~/.nocturia_log.csv)."
fi

exec python3 "$here/setup_sleep_db.py" "$@"
