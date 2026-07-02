#!/bin/ksh
# stmt_redact.ksh -- Wells Fargo statement -> redacted 80-col text + CSV
# usage: stmt_redact.ksh [input.pdf]
#
# Requires: pdftotext (poppler)  --  brew install poppler | apt install poppler-utils
#
# Produces two files from one pass:
#   <name>_redacted.txt  -- human-readable, 80 columns, descriptions wrapped
#   <name>_redacted.csv  -- Date,Description,Credits,Debits,Balance
#                           full MM/DD/YYYY dates, one row per transaction;
#                           opens directly in Numbers / Excel / LibreOffice
#
# Year handling: the statement date ("June 30, 2026") printed at the top
# of page 1 supplies the year. If a statement spans a year boundary
# (Dec-Jan), December transactions are assigned the prior year.

in=${1:-~/Downloads/statement.pdf}

if [[ ! -f $in ]]; then
    print -u2 "stmt_redact.ksh: no such file: $in"
    exit 1
fi

base=${in%.pdf}
base=$(print -r -- "$base" | sed 's/ *$//')
out=${base}_redacted.txt
csv=${base}_redacted.csv

pdftotext -layout "$in" - |
sed -E \
    -e 's/(^|[^A-Za-z0-9])[0-9]{10,17}([^0-9]|$)/\1[ACCT REDACTED]\2/g' \
    -e 's/[0-9]{3}-[0-9]{7,10}/[ACCT REDACTED]/g' \
    -e 's/([Aa]ccount[[:space:]]*([Nn]umber|#)?:?[[:space:]]*)[X0-9*-]{4,}/\1[REDACTED]/g' \
    -e 's/(ending in|[Xx]{4,})[[:space:]]*[0-9]{4}/\1 [REDACTED]/g' \
    -e 's/[Rr]outing[[:space:]]*([Nn]umber)?[[:space:]]*(\(RTN\))?:?[[:space:]]*[0-9]{9}/Routing [REDACTED]/g' \
|
awk -v CSV="$csv" '
# ---- 80-column reformatter + CSV writer for the WF transaction table ----
# Text layout: date(5) desc(43, wrapped) credits(9) debits(9) balance(11)
# CSV: one row per transaction, full MM/DD/YYYY dates, description
# unwrapped, commas stripped from amounts so Numbers sees real numbers.

function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }

function csvq(s) { gsub(/"/, "\"\"", s); return "\"" s "\"" }

function num(s)  { gsub(/,/, "", s); return s }

# Expand "6/18" to "06/18/2026" using the statement year found on page 1.
# If the statement spans Dec-Jan, a month later than the statement month
# must belong to the prior year.
function fulldate(d,    a, m, dd, y) {
    if (stY == 0 || d !~ /^[0-9]{1,2}\/[0-9]{1,2}$/) return d
    split(d, a, "/"); m = a[1] + 0; dd = a[2] + 0
    y = stY
    if (m > stM) y = stY - 1
    return sprintf("%02d/%02d/%04d", m, dd, y)
}

function emit(date, desc, cr, db, bal,    first, chunk) {
    first = 1
    if (desc == "") desc = " "
    while (length(desc) > 0 || first) {
        chunk = substr(desc, 1, 43)
        desc  = substr(desc, 44)
        if (first) {
            printf "%-5.5s %-43.43s %9.9s %9.9s %10.10s\n", \
                   date, chunk, cr, db, bal
            first = 0
        } else {
            printf "      %-43.43s\n", chunk
        }
    }
}

function csvflush() {                       # write the pending CSV row
    if (cDate != "")
        print fulldate(cDate) "," csvq(cDesc) "," num(cCr) "," num(cDb) "," num(cBal) > CSV
    cDate = cDesc = cCr = cDb = cBal = ""
}

BEGIN {
    print "Date,Description,Credits,Debits,Balance" > CSV
    split("January February March April May June July August September " \
          "October November December", MN, " ")
    for (i = 1; i <= 12; i++) mnum[MN[i]] = i
    stY = 0                                 # statement year (0 = not found)
}

# Statement date: first full date on the page, e.g. "June 30, 2026"
# or "06/30/2026". Scanned only until found, only outside the table.
!intable && stY == 0 {
    if (match($0, /(January|February|March|April|May|June|July|August|September|October|November|December)[ \t]+[0-9]{1,2},[ \t]*[0-9]{4}/)) {
        s = substr($0, RSTART, RLENGTH)
        split(s, a, /[ \t,]+/)
        stM = mnum[a[1]]; stY = a[3] + 0
    } else if (match($0, /[0-9]{1,2}\/[0-9]{1,2}\/[0-9]{4}/)) {
        s = substr($0, RSTART, RLENGTH)
        split(s, a, "/")
        stM = a[1] + 0; stY = a[3] + 0
    }
}

# Header: locate the amount columns by character offset.
/Deposits\// && /Withdrawals\// {
    depOff = index($0, "Deposits/")
    witOff = index($0, "Withdrawals/")
    endOff = index($0, "Ending")
    if (endOff == 0) endOff = length($0) + 1
    intable = 1
    printf "%-5s %-43s %9s %9s %10s\n", "Date", "Description", \
           "Credits", "Debits", "Balance"
    next
}
intable && /^[ \t]*(Check[ \t]+)?Number/ { next }
intable && /Credits[ \t]+Debits/ { next }

# End of table
intable && /^[ \t]*Totals/ {
    intable = 0
    csvflush()
    cr  = trim(substr($0, depOff, witOff - depOff))
    db  = trim(substr($0, witOff, endOff - witOff))
    print ""
    printf "%-5s %-43s %9.9s %9.9s\n", "", "Totals", cr, db
    print "Totals," csvq("") "," num(cr) "," num(db) "," > CSV
    next
}

intable {
    if (trim($0) == "") { print ""; next }
    left = trim(substr($0, 1, depOff - 1))
    cr   = trim(substr($0, depOff, witOff - depOff))
    db   = trim(substr($0, witOff, endOff - witOff))
    bal  = trim(substr($0, endOff))
    if (left ~ /^[0-9]{1,2}\//) {          # new transaction: leading date
        csvflush()
        date = left; sub(/[ \t].*/, "", date)
        desc = trim(substr(left, length(date) + 1))
        emit(date, desc, cr, db, bal)
        cDate = date; cDesc = desc; cCr = cr; cDb = db; cBal = bal
    } else {                                # continuation line
        emit("", left, cr, db, bal)
        cDesc = cDesc " " left
        if (cr  != "") cCr  = cr
        if (db  != "") cDb  = db
        if (bal != "") cBal = bal
    }
    next
}

# Outside the table: squeeze wide gaps so summary boxes fit 80 cols
{ gsub(/   +/, "  "); print }

END { csvflush(); close(CSV) }
' > "$out"

print "Wrote $out"
print "Wrote $csv"
print "Verify -- lines with standalone digit runs of 8+ (letter-prefixed ref codes ignored):"
grep -nE '(^|[^A-Za-z0-9])[0-9]{8,}' "$out" || print "  none found"
