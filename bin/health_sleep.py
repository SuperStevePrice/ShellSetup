#!/usr/bin/env python3
"""Extract Apple Health sleep records and summarize them per night."""
import argparse, csv, os, re, sqlite3, sys, zipfile
from collections import defaultdict
from datetime import datetime, timedelta, date

# Change this if you ever want to look further back by default.
DEFAULT_SINCE = "2026-01-01"
DEFAULT_DRUG_LOG = os.path.expanduser("~/logs/sleep_drug_log.csv")
DEFAULT_DB = os.path.expanduser("~/sleep_study.db")

FMT = "%Y-%m-%d %H:%M:%S %z"
REC = re.compile(r'<Record type="HKCategoryTypeIdentifierSleepAnalysis"[^>]*>')

def attr(line, name):
    m = re.search(name + r'="([^"]*)"', line)
    return m.group(1) if m else ""

def open_xml(path):
    if not os.path.exists(path):
        print(f"Error: file '{path}' not found", file=sys.stderr)
        sys.exit(1)
    if path.lower().endswith(".zip"):
        try:
            z = zipfile.ZipFile(path)
            name = next(n for n in z.namelist() if n.endswith("export.xml"))
        except zipfile.BadZipFile:
            print(f"Error: '{path}' is not a valid zip file", file=sys.stderr)
            sys.exit(1)
        except StopIteration:
            print(f"Error: '{path}' doesn't contain an export.xml", file=sys.stderr)
            sys.exit(1)
        return z.open(name)
    return open(path, "rb")

def read_records(path):
    recs = []
    with open_xml(path) as f:
        for raw in f:
            if b"SleepAnalysis" not in raw:
                continue
            line = raw.decode("utf-8", "replace")
            if not REC.search(line):
                continue
            s = datetime.strptime(attr(line, "startDate"), FMT)
            e = datetime.strptime(attr(line, "endDate"), FMT)
            v = attr(line, "value").replace("HKCategoryValueSleepAnalysis", "")
            src = attr(line, "sourceName")
            recs.append((s, e, v, src))
    recs.sort(key=lambda r: r[0])
    return recs

def night_key(start):
    # Anything starting before 6pm belongs to the night that ended that morning.
    d = start.date() if start.hour < 18 else start.date() + timedelta(days=1)
    return d.isoformat()

def is_real_night(rows, night_start_hour, night_end_hour):
    """True if this block both STARTS in the usual bedtime window
    (hour >= night_start_hour, e.g. 8pm, OR hour < night_end_hour, e.g.
    10am) AND ENDS in that same window. Checking only the start hour
    let a block like 08:27->16:14 (a stuck Sleep Focus session that
    bled into the afternoon) slip through, since 8am alone satisfies
    "before 10am" -- but that block didn't END until 4:14pm, which is
    nowhere near a real wake-up time. Requiring both ends to fall in
    the window filters that case out while still keeping ordinary
    nights (e.g. 22:53->04:11)."""
    first_hour = rows[0][0].hour
    last_hour = max(r[1] for r in rows).hour
    starts_at_night = first_hour >= night_start_hour or first_hour < night_end_hour
    ends_by_morning = last_hour < night_end_hour or last_hour >= night_start_hour
    return starts_at_night and ends_by_morning

def load_drug_log(path):
    """Read sleep_drug_log.ksh's CSV (date,drug,melatonin,notes) into a
    dict keyed by date string. Missing file is not an error -- the
    drug-log columns just come back blank for every night. A malformed
    row is skipped rather than crashing the whole report."""
    log = {}
    if not path or not os.path.exists(path):
        return log
    with open(path, newline="") as f:
        for row in csv.DictReader(f):
            d = (row.get("date") or "").strip()
            if not d:
                continue
            log[d] = {
                "drug": (row.get("drug") or "").strip(),
                "melatonin": (row.get("melatonin") or "").strip(),
                "notes": (row.get("notes") or "").strip(),
            }
    return log

def night_stats(rows):
    """Compute asleep/awake/inbed hours, wakings, first/last times for one
    night's rows. Same arithmetic the display loop uses, factored out so
    the SQLite writer doesn't duplicate or drift from it."""
    asleep = awake = inbed = 0.0
    wakings = 0
    for s, e, v, src in rows:
        m = (e - s).total_seconds() / 60
        if "Asleep" in v:
            asleep += m
        elif v == "Awake":
            awake += m
            wakings += 1
        elif v == "InBed":
            inbed += m
    first = rows[0][0].strftime("%H:%M")
    last = max(r[1] for r in rows).strftime("%H:%M")
    return {
        "asleep_hours": round(asleep / 60, 2),
        "awake_hours": round(awake / 60, 2),
        "inbed_hours": round(inbed / 60, 2),
        "wakings": wakings,
        "first_record": first,
        "last_record": last,
    }

def write_nightly_sleep(db_path, nights):
    """Upsert every night in `nights` (dict of night-key -> rows) into the
    nightly_sleep table. Creates the table if it doesn't exist yet, so
    this works even before setup_sleep_db.ksh has been run. Writes ALL
    matched nights, not just the ones -n/-d are about to display, so the
    database stays complete regardless of what this particular run prints."""
    conn = sqlite3.connect(db_path)
    conn.execute("""
        CREATE TABLE IF NOT EXISTS nightly_sleep (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            night TEXT NOT NULL UNIQUE,
            asleep_hours REAL,
            awake_hours REAL,
            inbed_hours REAL,
            wakings INTEGER,
            first_record TEXT,
            last_record TEXT
        )
    """)
    for k, rows in nights.items():
        stats = night_stats(rows)
        conn.execute("""
            INSERT INTO nightly_sleep (night, asleep_hours, awake_hours, inbed_hours, wakings, first_record, last_record)
            VALUES (:night, :asleep_hours, :awake_hours, :inbed_hours, :wakings, :first_record, :last_record)
            ON CONFLICT(night) DO UPDATE SET
                asleep_hours=excluded.asleep_hours,
                awake_hours=excluded.awake_hours,
                inbed_hours=excluded.inbed_hours,
                wakings=excluded.wakings,
                first_record=excluded.first_record,
                last_record=excluded.last_record
        """, {"night": k, **stats})
    conn.commit()
    conn.close()

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("path")
    ap.add_argument("-n", type=int, default=7, help="number of recent nights")
    ap.add_argument("-d", help="single night, as the wake-up date YYYY-MM-DD")
    ap.add_argument("-c", help="write all sleep records to this CSV")
    ap.add_argument("--include-naps", action="store_true",
                     help="don't filter out daytime naps, show every block")
    ap.add_argument("--night-start", type=int, default=20,
                     help="hour (0-23) a real night is assumed to start at or after (default 20 = 8pm)")
    ap.add_argument("--night-end", type=int, default=10,
                     help="hour (0-23) a real night is assumed to end before (default 10 = 10am)")
    ap.add_argument("--since", default=DEFAULT_SINCE,
                     help=f"ignore nights before this date, YYYY-MM-DD (default {DEFAULT_SINCE}); "
                          f"pass --since 1900-01-01 to disable")
    ap.add_argument("--drug-log", default=DEFAULT_DRUG_LOG,
                     help=f"sleep_drug_log.ksh CSV to merge in as Drug/Mel columns "
                          f"(default {DEFAULT_DRUG_LOG}; pass --no-drug-log to omit entirely)")
    ap.add_argument("--no-drug-log", action="store_true",
                     help="don't show Drug/Mel columns at all, even if the log file exists")
    ap.add_argument("--db", default=DEFAULT_DB,
                     help=f"SQLite database to write nightly_sleep rows into (default {DEFAULT_DB})")
    ap.add_argument("--no-db", action="store_true",
                     help="don't write to the SQLite database at all")
    a = ap.parse_args()

    recs = read_records(a.path)
    if not recs:
        print("No sleep records found.")
        return

    if a.c:
        with open(a.c, "w", newline="") as f:
            w = csv.writer(f)
            w.writerow(["start", "end", "minutes", "stage", "source"])
            for s, e, v, src in recs:
                w.writerow([s.isoformat(), e.isoformat(),
                            round((e - s).total_seconds() / 60), v, src])

    since_date = date.fromisoformat(a.since)
    recs = [r for r in recs if r[0].date() >= since_date]
    if not recs:
        print(f"No sleep records on or after {a.since}.")
        return

    nights = defaultdict(list)
    for r in recs:
        nights[night_key(r[0])].append(r)

    if not a.include_naps:
        nights = {k: rows for k, rows in nights.items()
                  if is_real_night(rows, a.night_start, a.night_end)}

    if not nights:
        print("No nights matched (try --include-naps or adjust --night-start/--night-end).")
        return

    drug_log = {} if a.no_drug_log else load_drug_log(a.drug_log)

    if not a.no_db:
        write_nightly_sleep(a.db, nights)

    keys = [a.d] if a.d else sorted(nights)[-a.n:]

    header = f"{'Night ending':<13}{'Asleep':>8}{'Awake':>8}{'InBed':>8}{'Wakings':>9}  First->Last"
    rule_len = 68
    if drug_log:
        header += f"  {'Drug':<10}{'Mel':<4}"
        rule_len += 16
    print(header)
    print("-" * rule_len)

    for k in keys:
        rows = nights.get(k, [])
        if not rows:
            print(f"{k:<13}  no data")
            continue
        stats = night_stats(rows)
        line = (f"{k:<13}{stats['asleep_hours']:>7.1f}h{stats['awake_hours']:>7.1f}h{stats['inbed_hours']:>7.1f}h"
                f"{stats['wakings']:>9}  {stats['first_record']}->{stats['last_record']}")
        if drug_log:
            entry = drug_log.get(k, {})
            line += f"  {entry.get('drug', ''):<10}{entry.get('melatonin', ''):<4}"
        print(line)

if __name__ == "__main__":
    main()
#-------------------------------------------------------------------------------
# Last installed: (set by setup.ksh)
#-- End of File ----------------------------------------------------------------
#-------------------------------------------------------------------------------
# Last installed: 2026-10-31 18:11:12
#-- End of File ----------------------------------------------------------------
