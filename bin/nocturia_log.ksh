#!/bin/ksh
# nocturia_log.ksh - "Pissy Night" log wrapper for nocturia_log.py
# Logs nighttime urination time + amount (oz) for the sleep study.
# English output only.

here=${0%/*}
[[ "$here" == "$0" ]] && here=.

if [[ $# -lt 1 ]]; then
    print -u2 "Pissy Night log — usage:"
    print -u2 "  ${0##*/} HH:MM [AMOUNT_OZ] [\"notes\"] [-d YYYY-MM-DD]"
    print -u2 "  ${0##*/} -l [-n N] [--night YYYY-MM-DD]"
    print -u2 ""
    print -u2 "Examples:"
    print -u2 "  ${0##*/} 02:15 5"
    print -u2 "  ${0##*/} 03:40 3 \"urgent, small amount\""
    print -u2 "  ${0##*/} 23:50 4 -d 2026-11-02         # log for last night, after midnight"
    print -u2 "  ${0##*/} -l                            # list recent nights"
    print -u2 "  ${0##*/} -l --night 2026-11-03          # list just one night"
    exit 1
fi

exec python3 "$here/nocturia_log.py" "$@"
