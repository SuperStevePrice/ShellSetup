#!/usr/bin/env python3
"""Sleep Summary: one short overview of everything the sleep study stores.

Pulls together:
    Urine Log     ~/.urine_log.csv              (urine_log.py)
    Apple Watch   ~/sleep_study.db, nightly_sleep (health_sleep.py)
    ResMed myAir  ~/Desktop/myAir-Steve-Price_stats.xlsx (myair_stats_report.py)

Prints a two-line overview and a table of averages, medians and totals for
the last 7 nights and for every night since the study began, and writes
sleep_summary.pdf / sleep_summary.xlsx to the Desktop.

Notes on the data:
  * Apple Watch only records once it detects sleep, so its first record is
    the time you fell asleep, not your bedtime. Time to fall asleep can't
    be measured from it.
  * ResMed myAir only provides its own 30-, 90- and 365-day averages, not
    nightly values. Events per night is estimated as AHI x hours of use.
"""
import argparse, csv, os, re, sqlite3, statistics, subprocess, sys
from datetime import date, datetime, timedelta

URINE_CSV = os.path.expanduser("~/.urine_log.csv")
DB = os.path.expanduser("~/sleep_study.db")
MYAIR_XLSX = os.path.expanduser("~/Desktop/myAir-Steve-Price_stats.xlsx")
DESKTOP = os.path.expanduser("~/Desktop")
STUDY_START = "2026-11-01"   # same as setup_sleep_db.py's DEFAULT_REPORT_SINCE
RECENT = 7

# --- helpers ------------------------------------------------------------------

def mean(xs):
    return sum(xs) / len(xs) if xs else None

def median(xs):
    return statistics.median(xs) if xs else None

def clock_to_min(hhmm):
    """Minutes after noon, so times either side of midnight average sensibly."""
    hh, mm = map(int, hhmm.split(":"))
    return ((hh - 12) % 24) * 60 + mm

def min_to_clock(m):
    if m is None:
        return ""
    m = int(round(m)) % (24 * 60)
    hh, mm = divmod(m, 60)
    hh = (hh + 12) % 24
    ampm = "am" if hh < 12 else "pm"
    return f"{(hh % 12) or 12}:{mm:02d} {ampm}"

def hours_str(h):
    if h is None:
        return ""
    total = int(round(h * 60))
    return f"{total // 60}h {total % 60:02d}m"

def num(x, fmt="{:.1f}"):
    return "" if x is None else fmt.format(x)

def fmt_date(d):
    return date.fromisoformat(d).strftime("%b %-d")

# --- data ---------------------------------------------------------------------

def load_urine(since):
    """night key -> {"n": voids, "oz": total, "amounts": [oz...]} for night entries."""
    nights, days = {}, {}
    if not os.path.exists(URINE_CSV):
        return nights, days
    with open(URINE_CSV) as f:
        for r in csv.DictReader(f):
            if r["night"] < since:
                continue
            bucket = days if r.get("period") == "day" else nights
            v = (r.get("amount_oz") or "").strip()
            a = float(v) if v else None
            n = bucket.setdefault(r["night"], {"n": 0, "oz": 0.0, "amounts": []})
            n["n"] += 1
            if a is not None:
                n["oz"] += a
                if a > 0:
                    n["amounts"].append(a)
    return nights, days

def load_watch(since):
    if not os.path.exists(DB):
        return {}
    conn = sqlite3.connect(DB)
    rows = conn.execute(
        "SELECT night, asleep_hours, awake_hours, wakings, first_record, last_record "
        "FROM nightly_sleep WHERE night >= ? AND asleep_hours IS NOT NULL ORDER BY night",
        (since,)).fetchall()
    conn.close()
    return {r[0]: {"asleep": r[1], "awake": r[2], "wakings": r[3],
                   "onset": r[4], "up": r[5]} for r in rows}

def _parse_hm(s):
    m = re.search(r"(\d+)\s*hours?\s*(\d+)?\s*min", s or "")
    return int(m.group(1)) + int(m.group(2) or 0) / 60 if m else None

def _first_float(s):
    m = re.search(r"[\d.]+", str(s or ""))
    return float(m.group()) if m else None

def load_myair():
    """List of window dicts from myair_stats_report's spreadsheet."""
    if not os.path.exists(MYAIR_XLSX):
        return []
    try:
        from openpyxl import load_workbook
    except ImportError:
        return []
    ws = load_workbook(MYAIR_XLSX, read_only=True).active
    out = []
    for row in ws.iter_rows(values_only=True):
        if not row or not isinstance(row[1], int):
            continue
        rng, days, usage, ahi, leak, n4, n6 = row[:7]
        hrs, ahi_v = _parse_hm(usage), _first_float(ahi)
        out.append({"range": rng, "days": days, "hours": hrs, "ahi": ahi_v,
                    "events": hrs * ahi_v if hrs and ahi_v is not None else None,
                    "leak": _first_float(leak), "n4": n4, "n6": n6})
    return out

# --- summary ------------------------------------------------------------------

def stats_for(keys, urine, watch):
    u = [urine[k] for k in keys if k in urine]
    w = [watch[k] for k in keys if k in watch]
    voids = [x["n"] for x in u]
    oz = [x["oz"] for x in u]
    per_void = [a for x in u for a in x["amounts"]]
    def col(field):
        return [x[field] for x in w if x[field] is not None]
    onset = [clock_to_min(x["onset"]) for x in w if x["onset"]]
    up = [clock_to_min(x["up"]) for x in w if x["up"]]
    return {
        "u_n": len(u), "w_n": len(w),
        "voids": voids, "oz": oz, "per_void": per_void,
        "asleep": col("asleep"), "awake": col("awake"), "wakings": col("wakings"),
        "onset": onset, "up": up,
    }

ROWS = [
    # label, key, kind ("count", "oz", "hours", "clock", "int"), show total?
    ("Night voids per night",        "voids",    "count", True),
    ("Night urine per night (oz)",   "oz",       "oz",    True),
    ("Ounces per void",              "per_void", "oz",    False),
    ("Asleep (Watch)",               "asleep",   "hours", False),
    ("Awake after falling asleep",   "awake",    "hours", False),
    ("Wakings per night (Watch)",    "wakings",  "count", False),
    ("Fell asleep (Watch)",          "onset",    "clock", False),
    ("Final wake-up (Watch)",        "up",       "clock", False),
]

def fmt_val(v, kind):
    if v is None:
        return ""
    if kind == "hours":
        return hours_str(v)
    if kind == "clock":
        return min_to_clock(v)
    return num(v)

def table_rows(recent, overall):
    out = []
    for label, key, kind, show_total in ROWS:
        r, o = recent[key], overall[key]
        tot = ""
        if show_total and o:
            tot = num(sum(o), "{:g}")
        n = len(o)
        out.append([label, fmt_val(mean(r), kind), fmt_val(median(r), kind),
                    fmt_val(mean(o), kind), fmt_val(median(o), kind), tot, str(n)])
    return out

def overview(overall, myair, keys, urine_days):
    span = f"{fmt_date(keys[0])}–{fmt_date(keys[-1])}" if keys else ""
    o = overall
    line1 = (f"Sleep ({span}, {o['w_n']} Watch nights): asleep {hours_str(mean(o['asleep']))} avg "
             f"(median {hours_str(median(o['asleep']))}), {num(mean(o['wakings']))} wakings, "
             f"asleep about {min_to_clock(mean(o['onset']))}, up about {min_to_clock(mean(o['up']))}.")
    parts = [f"Urine ({o['u_n']} nights): {num(mean(o['voids']))} voids/night "
             f"(median {num(median(o['voids']), '{:g}')}), {num(mean(o['oz']))} oz/night, "
             f"{num(mean(o['per_void']))} oz per void"]
    if urine_days:
        parts[0] += f"; daytime logged on {len(urine_days)} day(s)"
    m30 = next((m for m in myair if m["days"] == 30), None)
    if m30:
        parts.append(f"CPAP (30 days): {hours_str(m30['hours'])}/night, AHI {num(m30['ahi'], '{:.2f}')} "
                     f"(~{num(m30['events'], '{:.0f}')} events/night)")
    return line1, "; ".join(parts) + "."

HEAD = ["Measure", f"Last {RECENT}: avg", f"Last {RECENT}: median",
        "All: avg", "All: median", "All: total", "Nights"]
MYAIR_HEAD = ["myAir window", "Avg use", "AHI (events/hr)", "Est. events/night",
              "Leak 95th %", "Nights >= 4 h", "Nights >= 6 h"]

def myair_rows(myair):
    return [[f"{m['days']} days", hours_str(m["hours"]), num(m["ahi"], "{:.2f}"),
             num(m["events"], "{:.0f}"), num(m["leak"], "{:.2f} L/min"), m["n4"], m["n6"]]
            for m in myair]

# --- output -------------------------------------------------------------------

def print_table(head, rows):
    widths = [max(len(str(x)) for x in col) for col in zip(head, *rows)]
    line = lambda r: "  ".join(str(x).ljust(w) for x, w in zip(r, widths))
    print(line(head))
    print("  ".join("-" * w for w in widths))
    for r in rows:
        print(line(r))

NOTES = [
    "Night = 9 pm to 7 am; night voids are counted by the morning you woke up.",
    "Ounces per void leaves out attempts logged as 0 oz.",
    "Apple Watch starts recording once you are asleep, so 'Fell asleep' is not "
    "your bedtime, and time to fall asleep can't be measured from it.",
    "ResMed myAir gives only its own 30/90/365-day averages; events per night "
    "is estimated as AHI x hours of use.",
]

def write_xlsx(path, lines, rows, mrows, since):
    from openpyxl import Workbook
    from openpyxl.styles import Font, PatternFill, Alignment
    wb = Workbook()
    ws = wb.active
    ws.title = "Summary"
    fill = PatternFill(start_color="1F3864", end_color="1F3864", fill_type="solid")
    white = Font(color="FFFFFF", bold=True)
    ws.append([f"Sleep Summary - generated {date.today().isoformat()}, data since {since}"])
    ws["A1"].font = Font(bold=True, size=13)
    for l in lines:
        ws.append([l])
    ws.append([])
    ws.append(HEAD)
    for c in ws[ws.max_row]:
        c.fill, c.font = fill, white
    for r in rows:
        ws.append(r)
    if mrows:
        ws.append([])
        ws.append(MYAIR_HEAD)
        for c in ws[ws.max_row]:
            c.fill, c.font = fill, white
        for r in mrows:
            ws.append(r)
    ws.append([])
    for n in NOTES:
        ws.append([n])
    for col, w in zip("ABCDEFG", (30, 15, 17, 13, 13, 12, 12)):
        ws.column_dimensions[col].width = w
    wb.save(path)

def write_pdf(path, lines, rows, mrows, since):
    from reportlab.lib.pagesizes import letter
    from reportlab.lib import colors
    from reportlab.lib.units import inch
    from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
    from reportlab.lib.styles import getSampleStyleSheet

    def style(t):
        t.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1F3864")),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
            ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
            ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
            ("FONTSIZE", (0, 0), (-1, -1), 8.5),
            ("ALIGN", (1, 1), (-1, -1), "RIGHT"),
        ]))
        return t

    ss = getSampleStyleSheet()
    doc = SimpleDocTemplate(path, pagesize=letter, leftMargin=0.6*inch, rightMargin=0.6*inch,
                            topMargin=0.6*inch, bottomMargin=0.6*inch)
    story = [Paragraph("Sleep Summary", ss["Title"]),
             Paragraph(f"Generated {date.today().isoformat()} - data since {since}", ss["Normal"]),
             Spacer(1, 8)]
    for l in lines:
        story += [Paragraph(l, ss["BodyText"]), Spacer(1, 4)]
    story.append(Spacer(1, 8))
    story.append(style(Table([HEAD] + rows, colWidths=[2.1*inch] + [0.95*inch] * 6)))
    if mrows:
        story += [Spacer(1, 12), style(Table([MYAIR_HEAD] + mrows,
                                             colWidths=[0.9*inch, 0.8*inch, 1.0*inch, 1.05*inch, 1.0*inch, 1.25*inch, 1.25*inch]))]
    story.append(Spacer(1, 12))
    for n in NOTES:
        story.append(Paragraph(n, ss["Italic"]))
    doc.build(story)

def ask_open(path, what, ask):
    if not (ask and path and os.path.isfile(path)):
        return
    try:
        ans = input(f"Would you like to open the {what} summary? [y/N]: ").strip().lower()
    except EOFError:
        ans = "n"
    if ans == "y":
        subprocess.run(["open", path])

def main():
    ap = argparse.ArgumentParser(description="One-page sleep summary across urine, Apple Watch and ResMed data.")
    ap.add_argument("--since", default=STUDY_START, help=f"first night to include, YYYY-MM-DD (default {STUDY_START})")
    ap.add_argument("--no-files", action="store_true", help="print only; don't write the PDF/xlsx")
    ap.add_argument("--no-prompt", action="store_true", help="don't ask to open the files")
    a = ap.parse_args()

    urine, urine_days = load_urine(a.since)
    watch = load_watch(a.since)
    myair = load_myair()
    keys = sorted(set(urine) | set(watch))
    if not keys:
        print(f"No sleep or urine data since {a.since}.")
        return 1
    recent_keys = keys[-RECENT:]
    overall = stats_for(keys, urine, watch)
    recent = stats_for(recent_keys, urine, watch)

    lines = overview(overall, myair, keys, urine_days)
    rows = table_rows(recent, overall)
    mrows = myair_rows(myair)

    print("Sleep Summary")
    print("=" * 13)
    for l in lines:
        print(l)
    print()
    print_table(HEAD, rows)
    if mrows:
        print()
        print_table(MYAIR_HEAD, mrows)
    else:
        print(f"\n(no ResMed figures: {MYAIR_XLSX} not found - run myair_stats_report)")

    if a.no_files:
        return 0
    pdf = os.path.join(DESKTOP, "sleep_summary.pdf")
    xlsx = os.path.join(DESKTOP, "sleep_summary.xlsx")
    print()
    try:
        write_xlsx(xlsx, lines, rows, mrows, a.since)
        print(f"wrote {xlsx}")
    except ImportError:
        print("openpyxl not installed - skipping sleep_summary.xlsx", file=sys.stderr)
        xlsx = None
    try:
        write_pdf(pdf, lines, rows, mrows, a.since)
        print(f"wrote {pdf}")
    except ImportError:
        print("reportlab not installed - skipping sleep_summary.pdf", file=sys.stderr)
        pdf = None
    ask_open(pdf, "PDF", not a.no_prompt)
    ask_open(xlsx, "numbers (xlsx)", not a.no_prompt)
    return 0

if __name__ == "__main__":
    sys.exit(main())
