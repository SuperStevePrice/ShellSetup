#!/usr/bin/env python3
"""Create/update the sleep study SQLite database and import existing logs into it."""
import argparse, csv, os, sqlite3, sys
from datetime import datetime

DEFAULT_DB = os.path.expanduser("~/sleep_study.db")

SCHEMA = """
CREATE TABLE IF NOT EXISTS prescriptions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    generic_name TEXT NOT NULL,
    brand_name TEXT,
    dosage TEXT NOT NULL,
    frequency TEXT NOT NULL,
    route TEXT,
    prescriber TEXT,
    pharmacy TEXT,
    refills_remaining INTEGER,
    last_filled TEXT,
    next_refill_date TEXT,
    auto_refill_date TEXT,
    active INTEGER NOT NULL DEFAULT 1,
    notes TEXT
);

CREATE TABLE IF NOT EXISTS sleep_drug_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    night TEXT NOT NULL,           -- YYYY-MM-DD
    drug TEXT NOT NULL,
    melatonin TEXT,                -- 'Y' / 'N'
    notes TEXT,
    imported_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS nightly_sleep (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    night TEXT NOT NULL UNIQUE,    -- YYYY-MM-DD
    asleep_hours REAL,
    awake_hours REAL,
    inbed_hours REAL,
    wakings INTEGER,
    first_record TEXT,
    last_record TEXT
);

CREATE TABLE IF NOT EXISTS nocturia_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    night TEXT NOT NULL,           -- YYYY-MM-DD
    time TEXT NOT NULL,            -- HH:MM
    amount_oz REAL,
    notes TEXT
);

-- Always dropped and recreated below (rather than CREATE VIEW IF NOT
-- EXISTS) so an existing database picks up changes to this view's
-- definition on the next run, instead of keeping whatever version was
-- first created.
DROP VIEW IF EXISTS nightly_report;

-- Full-outer-join equivalent (SQLite has no FULL OUTER JOIN): every
-- night that has EITHER sleep data OR a drug-log entry shows up, even
-- when the other side hasn't arrived yet. A drug entry logged before
-- the matching Watch export has synced (very common -- you log the
-- night before you can export) now appears with blank sleep columns
-- instead of silently vanishing from the report.
CREATE VIEW IF NOT EXISTS nightly_report AS
SELECT
    s.night,
    s.asleep_hours,
    s.awake_hours,
    s.inbed_hours,
    s.wakings,
    s.first_record,
    s.last_record,
    d.drug,
    d.melatonin,
    d.notes AS drug_notes,
    (SELECT COUNT(*) FROM nocturia_log n WHERE n.night = s.night) AS urination_count,
    (SELECT ROUND(SUM(amount_oz), 1) FROM nocturia_log n WHERE n.night = s.night) AS urination_total_oz
FROM nightly_sleep s
LEFT JOIN (
    SELECT night, drug, melatonin, notes
    FROM sleep_drug_log sd
    WHERE sd.id = (SELECT MAX(id) FROM sleep_drug_log sd2 WHERE sd2.night = sd.night)
) d ON d.night = s.night

UNION

SELECT
    d.night,
    NULL AS asleep_hours,
    NULL AS awake_hours,
    NULL AS inbed_hours,
    NULL AS wakings,
    NULL AS first_record,
    NULL AS last_record,
    d.drug,
    d.melatonin,
    d.notes AS drug_notes,
    (SELECT COUNT(*) FROM nocturia_log n WHERE n.night = d.night) AS urination_count,
    (SELECT ROUND(SUM(amount_oz), 1) FROM nocturia_log n WHERE n.night = d.night) AS urination_total_oz
FROM (
    SELECT night, drug, melatonin, notes
    FROM sleep_drug_log sd
    WHERE sd.id = (SELECT MAX(id) FROM sleep_drug_log sd2 WHERE sd2.night = sd.night)
) d
WHERE d.night NOT IN (SELECT night FROM nightly_sleep)

ORDER BY night DESC;
"""

def connect(db_path):
    conn = sqlite3.connect(db_path)
    conn.executescript(SCHEMA)
    conn.commit()
    return conn

def import_nocturia(conn, csv_path):
    csv_path = os.path.expanduser(csv_path)
    if not os.path.exists(csv_path):
        print(f"  (no nocturia log found at {csv_path}, skipping)")
        return 0
    # Re-importing is safe to run repeatedly: clear and reload from the CSV,
    # which is the source of truth, rather than appending duplicates each time.
    conn.execute("DELETE FROM nocturia_log")
    n = 0
    with open(csv_path) as f:
        reader = csv.DictReader(f)
        for row in reader:
            amt_field = "amount_oz" if "amount_oz" in row else "amount_ml"
            amt = row.get(amt_field, "")
            amt_val = float(amt) if amt not in (None, "") else None
            conn.execute(
                "INSERT INTO nocturia_log (night, time, amount_oz, notes) VALUES (?,?,?,?)",
                (row["night"], row["time"], amt_val, row.get("notes", ""))
            )
            n += 1
    conn.commit()
    return n

def import_sleep_drug_log(conn, csv_path):
    """Import sleep_drug_log's data file, if its path/format is known.
    This expects a CSV or whitespace-aligned text; adjust once the real
    file format is confirmed."""
    csv_path = os.path.expanduser(csv_path)
    if not os.path.exists(csv_path):
        print(f"  (sleep_drug_log file not found at {csv_path}, skipping)")
        return 0
    # Re-importing is safe to run repeatedly: clear and reload from the CSV,
    # which is the source of truth (including its own internal duplicate
    # dates from past corrections), rather than appending duplicates each time.
    conn.execute("DELETE FROM sleep_drug_log")
    n = 0
    with open(csv_path) as f:
        reader = csv.reader(f)
        header = next(reader, None)
        for row in reader:
            if len(row) < 3:
                continue
            night, drug, mel = row[0], row[1], row[2]
            notes = row[3] if len(row) > 3 else ""
            conn.execute(
                "INSERT INTO sleep_drug_log (night, drug, melatonin, notes) VALUES (?,?,?,?)",
                (night, drug, mel, notes)
            )
            n += 1
    conn.commit()
    return n

def run_sql_file(conn, path):
    path = os.path.expanduser(path)
    if not os.path.exists(path):
        print(f"  (SQL file not found at {path}, skipping)")
        return
    with open(path) as f:
        sql = f.read()
    # naive MySQL -> SQLite tweaks: TRUE/FALSE -> 1/0
    sql = sql.replace(", TRUE,", ", 1,").replace(", FALSE,", ", 0,")
    # Re-running is safe: this file is always a full prescriptions snapshot,
    # so clear the table first rather than appending duplicate rows.
    if "INTO prescriptions" in sql:
        conn.execute("DELETE FROM prescriptions")
    conn.executescript(sql)
    conn.commit()
    print(f"  ran {path}")

def report(conn, n):
    cur = conn.execute("SELECT * FROM nightly_report ORDER BY night DESC LIMIT ?", (n,))
    cols = [d[0] for d in cur.description]
    rows = cur.fetchall()
    if not rows:
        print("No nights in nightly_report yet.")
        return
    widths = [max(len(c), *(len(str(r[i])) for r in rows)) for i, c in enumerate(cols)]
    print("  ".join(c.ljust(w) for c, w in zip(cols, widths)))
    print("-" * (sum(widths) + 2*len(cols)))
    for r in rows:
        print("  ".join(str(v if v is not None else "").ljust(w) for v, w in zip(r, widths)))

def main():
    ap = argparse.ArgumentParser(description="Set up and manage the sleep study SQLite database.")
    ap.add_argument("--db", default=DEFAULT_DB, help=f"database file path (default {DEFAULT_DB})")
    ap.add_argument("--import-nocturia", metavar="CSV", default="~/.nocturia_log.csv",
                     help="path to nocturia_log's CSV (default ~/.nocturia_log.csv)")
    ap.add_argument("--import-drug-log", metavar="CSV",
                     help="path to sleep_drug_log's data file, if known")
    ap.add_argument("--import-prescriptions-sql", metavar="SQL",
                     help="path to a prescriptions INSERT .sql file to run")
    ap.add_argument("--report", action="store_true", help="print the consolidated nightly_report view")
    ap.add_argument("-n", type=int, default=14, help="with --report: number of recent nights (default 14)")
    a = ap.parse_args()

    conn = connect(a.db)
    print(f"Database ready at {a.db}")

    if a.import_nocturia:
        n = import_nocturia(conn, a.import_nocturia)
        print(f"  imported {n} nocturia_log row(s)")

    if a.import_drug_log:
        n = import_sleep_drug_log(conn, a.import_drug_log)
        print(f"  imported {n} sleep_drug_log row(s)")

    if a.import_prescriptions_sql:
        run_sql_file(conn, a.import_prescriptions_sql)

    if a.report:
        print()
        report(conn, a.n)

    conn.close()

if __name__ == "__main__":
    main()
