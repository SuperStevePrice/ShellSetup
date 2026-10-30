#!/usr/bin/env python3
"""Extract Apple Health sleep records and summarize them per night."""
import argparse, csv, re, sys, zipfile
from collections import defaultdict
from datetime import datetime, timedelta, date

# Change this if you ever want to look further back by default.
DEFAULT_SINCE = "2026-01-01"

FMT = "%Y-%m-%d %H:%M:%S %z"
REC = re.compile(r'<Record type="HKCategoryTypeIdentifierSleepAnalysis"[^>]*>')

def attr(line, name):
    m = re.search(name + r'="([^"]*)"', line)
    return m.group(1) if m else ""

def open_xml(path):
    if path.lower().endswith(".zip"):
        z = zipfile.ZipFile(path)
        name = next(n for n in z.namelist() if n.endswith("export.xml"))
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
    """True if this block's first record falls in the usual bedtime window
    (hour >= night_start_hour, e.g. 8pm, OR hour < night_end_hour, e.g. 10am).
    Keeps real nights, filters out afternoon/evening naps."""
    first_hour = rows[0][0].hour
    return first_hour >= night_start_hour or first_hour < night_end_hour

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

    keys = [a.d] if a.d else sorted(nights)[-a.n:]
    print(f"{'Night ending':<13}{'Asleep':>8}{'Awake':>8}{'InBed':>8}{'Wakings':>9}  First->Last")
    print("-" * 68)
    for k in keys:
        rows = nights.get(k, [])
        if not rows:
            print(f"{k:<13}  no data")
            continue
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
        print(f"{k:<13}{asleep/60:>7.1f}h{awake/60:>7.1f}h{inbed/60:>7.1f}h{wakings:>9}  {first}->{last}")

if __name__ == "__main__":
    main()
