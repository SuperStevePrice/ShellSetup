#!/usr/bin/env python3
"""Pissy Night log: nighttime urination time + amount (oz) for the sleep study."""
import argparse, csv, os, sys
from datetime import datetime, date, timedelta

LOGFILE = os.path.expanduser("~/.nocturia_log.csv")

def night_key(dt):
    # Anything before 6pm belongs to the "night" that started the evening before.
    d = dt.date() if dt.hour >= 18 or dt.hour < 12 else dt.date() - timedelta(days=1)
    return d.isoformat()

def ensure_file():
    if not os.path.exists(LOGFILE):
        with open(LOGFILE, "w", newline="") as f:
            csv.writer(f).writerow(["night", "time", "amount_oz", "notes"])

def add_entry(time_str, amount, notes, on_date):
    ensure_file()
    now = datetime.now()
    try:
        hh, mm = map(int, time_str.split(":"))
    except ValueError:
        print(f"Bad time '{time_str}', expected HH:MM (24h)", file=sys.stderr)
        sys.exit(1)

    if on_date:
        try:
            d = date.fromisoformat(on_date)
        except ValueError:
            print(f"Bad date '{on_date}', expected YYYY-MM-DD", file=sys.stderr)
            sys.exit(1)
        dt = datetime(d.year, d.month, d.day, hh, mm)
    else:
        dt = datetime(now.year, now.month, now.day, hh, mm)

    night = night_key(dt)
    with open(LOGFILE, "a", newline="") as f:
        csv.writer(f).writerow([night, dt.strftime("%H:%M"), amount if amount is not None else "", notes or ""])
    amt_str = f"{amount} oz" if amount is not None else "(amount unknown)"
    print(f"Logged: night {night} -> {dt.strftime('%H:%M')}  {amt_str}  {notes or ''}".rstrip())

def list_entries(for_night, n):
    ensure_file()
    with open(LOGFILE) as f:
        rows = list(csv.DictReader(f))
    if for_night:
        rows = [r for r in rows if r["night"] == for_night]

    nights = {}
    for r in rows:
        nights.setdefault(r["night"], []).append(r)

    keys = sorted(nights)[-n:] if not for_night else sorted(nights)
    if not keys:
        print("No entries.")
        return

    def sort_key(r):
        hh, mm = map(int, r["time"].split(":"))
        bucket = 0 if hh >= 18 else 1
        return (bucket, hh, mm)

    for k in keys:
        entries = sorted(nights[k], key=sort_key)
        amt_field = "amount_oz" if "amount_oz" in entries[0] else "amount_ml"
        amounts = [float(e[amt_field]) for e in entries if e.get(amt_field, "").strip() != ""]
        total = sum(amounts) if amounts else None
        unit = "oz" if amt_field == "amount_oz" else "ml"
        print(f"\nPissy Night: {k} \u2014 {len(entries)} urination(s)" + (f", total {total:g} {unit}" if total else ""))
        print("-" * 50)
        prev = None
        for e in entries:
            gap = ""
            if prev:
                t1 = datetime.strptime(prev, "%H:%M")
                t2 = datetime.strptime(e["time"], "%H:%M")
                mins = (t2 - t1).total_seconds() / 60
                if mins < 0:
                    mins += 24*60
                gap = f"  (+{int(mins)} min)"
            raw = e.get(amt_field, "")
            amt = f"{raw} {unit}" if raw else "amount unknown"
            note = f"  {e['notes']}" if e["notes"] else ""
            print(f"  {e['time']}  {amt}{gap}{note}")
            prev = e["time"]

def main():
    ap = argparse.ArgumentParser(description="Pissy Night log: nighttime urination time/amount (oz) for the sleep study.")
    ap.add_argument("time", nargs="?", help="time of event, HH:MM (24h)")
    ap.add_argument("amount", nargs="?", type=float, help="amount in fluid ounces (oz)")
    ap.add_argument("notes", nargs="?", default="", help="optional note")
    ap.add_argument("-d", "--date", help="date this event belongs to, YYYY-MM-DD (default: today)")
    ap.add_argument("-l", "--list", action="store_true", help="list entries instead of adding one")
    ap.add_argument("-n", type=int, default=7, help="with -l: number of recent nights to show (default 7)")
    ap.add_argument("--night", help="with -l: show only this night, YYYY-MM-DD")

    a = ap.parse_args()

    if a.list:
        list_entries(a.night, a.n)
        return

    if not a.time:
        ap.print_help()
        sys.exit(1)

    add_entry(a.time, a.amount, a.notes, a.date)

if __name__ == "__main__":
    main()
