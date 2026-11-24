#!/usr/bin/env python3
"""Urine Log: time + amount (oz) of every urination, day and night, for
Dr. Lurvy's 24-hour voiding record and the sleep study.

Formerly nocturnal_log.py (and before that nocturia_log.py). Data lives in
~/.urine_log.csv, which setup_sleep_db.py imports into the urine_log table.
An older ~/.nocturia_log.csv is moved there automatically on first run.

Day vs. night
-------------
Each entry is marked "night" or "day" by the clock:
    night = from BEDTIME until WAKE (default 21:00 to 07:00)
    day   = everything else
Override with the environment variables URINE_LOG_BEDTIME and
URINE_LOG_WAKE (HH:MM, 24h), or per entry with --day / --night.

The "night" column of the CSV is a date key:
    night entries -> the date you woke up (the same key health_sleep.py
                     and the sleep_study database use for a night)
    day entries   -> the calendar date
A 24-hour period starting on date D is the daytime entries keyed D plus
the night entries keyed D+1 (the night that follows that day), ending
with the last night entry before WAKE the next morning.
"""
import argparse, csv, glob, os, re, shutil, subprocess, sys
from datetime import datetime, date, timedelta

LOGFILE = os.path.expanduser(os.environ.get("URINE_LOG_FILE", "~/.urine_log.csv"))
# Name used before 2026-11-24; moved to LOGFILE automatically on first run.
OLD_LOGFILE = os.path.expanduser("~/.nocturia_log.csv")
FIELDS = ["night", "time", "amount_oz", "notes", "period"]
DOWNLOADS_DIR = os.path.expanduser("~/Downloads")
ARCHIVE_DIR = os.path.expanduser("~/tests/urine_cmds")
# Old nocturnal_cmds_* files from before the rename are still picked up.
CMDFILE_GLOBS = [os.path.join(DOWNLOADS_DIR, "urine_cmds_*.ksh"),
                 os.path.join(DOWNLOADS_DIR, "nocturnal_cmds_*.ksh")]
CMDFILE_RE = re.compile(r"(?:urine|nocturnal)_cmds_(\d{8})_(\d{6})\.ksh$")
RUNLOG_DIR = os.path.expanduser("~/logs")
DESKTOP = os.path.expanduser("~/Desktop")

def _hhmm_to_min(s, default):
    try:
        hh, mm = map(int, s.split(":"))
        return hh * 60 + mm
    except (AttributeError, ValueError):
        return default

BEDTIME_MIN = _hhmm_to_min(os.environ.get("URINE_LOG_BEDTIME"), 21 * 60)
WAKE_MIN = _hhmm_to_min(os.environ.get("URINE_LOG_WAKE"), 7 * 60)

ACQUISITION_MESSAGE = """To acquire required data:
    1.  urine.ksh   This script will open a vi session
        named for date and time.
        Insert the commands generated on the iPhone by the
        Urine Log app.
    2.  On the iPhone, open the Urine Log app found in the
        Health folder.
        a.  Scroll to the very bottom.
        b.  Select "Copy urine_log Commands."
"""

_runlog_fh = None

def log(msg="", err=False):
    """Print to stdout/stderr and append the same line to this run's own log file."""
    if err:
        print(msg, file=sys.stderr)
    else:
        print(msg)
    if _runlog_fh:
        _runlog_fh.write(msg + "\n")
        _runlog_fh.flush()

def log_only(msg):
    """Write to this run's log file without printing again to the terminal -
    used right after an input() prompt, which already echoed itself live."""
    if _runlog_fh:
        _runlog_fh.write(msg + "\n")
        _runlog_fh.flush()

def open_runlog():
    global _runlog_fh
    os.makedirs(RUNLOG_DIR, exist_ok=True)
    # Microsecond resolution matters here: urine_log.py can be invoked
    # many times within the same wall-clock second (e.g. once per line of a
    # urine_cmds_*.ksh file), and second-resolution timestamps collide,
    # causing separate runs to append into the same "own" log file instead
    # of each getting its own as intended.
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")
    path = os.path.join(RUNLOG_DIR, f"urine_log.{timestamp}.log")
    _runlog_fh = open(path, "a")
    return path

def close_runlog(path):
    log(f"See: {path}")
    if _runlog_fh:
        _runlog_fh.close()

# --- day/night classification ------------------------------------------------

def is_night_time(hh, mm):
    m = hh * 60 + mm
    if BEDTIME_MIN > WAKE_MIN:          # usual case: bed before midnight
        return m >= BEDTIME_MIN or m < WAKE_MIN
    return BEDTIME_MIN <= m < WAKE_MIN  # bed after midnight

def classify(dt, force=None):
    """Return (key, period) for an event at datetime dt."""
    period = force or ("night" if is_night_time(dt.hour, dt.minute) else "day")
    d = dt.date()
    if period == "night" and dt.hour >= 12:
        d += timedelta(days=1)          # evening part of a night -> wake-up date
    return d.isoformat(), period

def event_datetime(row):
    """Recover the calendar date/time of a stored row from its key + period."""
    d = date.fromisoformat(row["night"])
    hh, mm = map(int, row["time"].split(":"))
    if row.get("period", "night") == "night" and hh >= 12:
        d -= timedelta(days=1)
    return datetime(d.year, d.month, d.day, hh, mm)

def cycle_date(row):
    """Start date of the 24-hour period this row belongs to."""
    d = date.fromisoformat(row["night"])
    return d - timedelta(days=1) if row.get("period", "night") == "night" else d

# --- data file ----------------------------------------------------------------

def read_rows():
    with open(LOGFILE) as f:
        return list(csv.DictReader(f))

def write_rows(rows):
    tmp = LOGFILE + ".tmp"
    with open(tmp, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=FIELDS, extrasaction="ignore")
        w.writeheader()
        for r in rows:
            w.writerow(r)
    os.replace(tmp, LOGFILE)

def migrate_old_file():
    """One-time upgrade of a nocturnal_log-era file (no "period" column).

    The old code keyed entries inconsistently: 18:00-23:59 under that
    evening's date, 00:00-11:59 under that morning's date, 12:00-17:59
    under the day before. So one night was split across two keys. This
    recovers each entry's real date/time, then re-keys and classifies it
    under the current rules. A backup copy is kept beside the file."""
    with open(LOGFILE) as f:
        reader = csv.DictReader(f)
        header = reader.fieldnames or []
        rows = list(reader)
    if "period" in header:
        return
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup = f"{LOGFILE}.bak-{stamp}"
    shutil.copy2(LOGFILE, backup)
    new_rows, moved = [], 0
    for r in rows:
        k = date.fromisoformat(r["night"])
        hh, mm = map(int, r["time"].split(":"))
        real = k + timedelta(days=1) if 12 <= hh < 18 else k
        dt = datetime(real.year, real.month, real.day, hh, mm)
        key, period = classify(dt)
        if key != r["night"]:
            moved += 1
        amt = r.get("amount_oz", r.get("amount_ml", ""))
        new_rows.append({"night": key, "time": r["time"], "amount_oz": amt,
                         "notes": r.get("notes", ""), "period": period})
    write_rows(new_rows)
    log(f"Upgraded {LOGFILE} to the Urine Log format: {len(new_rows)} row(s), "
        f"{moved} re-keyed to their wake-up date. Backup: {backup}")

def ensure_file():
    if not os.path.exists(LOGFILE) and "URINE_LOG_FILE" not in os.environ \
            and os.path.exists(OLD_LOGFILE):
        os.rename(OLD_LOGFILE, LOGFILE)
        log(f"Renamed {OLD_LOGFILE} -> {LOGFILE}")
    if not os.path.exists(LOGFILE):
        write_rows([])
    else:
        migrate_old_file()

# --- add ----------------------------------------------------------------------

def add_entry(time_str, amount, notes, on_date, force_period):
    ensure_file()
    try:
        hh, mm = map(int, time_str.split(":"))
    except ValueError:
        log(f"Bad time '{time_str}', expected HH:MM (24h)", err=True)
        sys.exit(1)

    if on_date:
        try:
            d = date.fromisoformat(on_date)
        except ValueError:
            log(f"Bad date '{on_date}', expected YYYY-MM-DD", err=True)
            sys.exit(1)
    else:
        d = date.today()
    dt = datetime(d.year, d.month, d.day, hh, mm)

    key, period = classify(dt, force_period)
    hhmm = dt.strftime("%H:%M")
    amt_field = str(amount) if amount is not None else ""
    rows = read_rows()
    for r in rows:
        if r["night"] == key and r["time"] == hhmm and r["amount_oz"] == amt_field:
            log(f"Skipped duplicate: {d} {hhmm}  {amt_field or '(amount unknown)'} already logged")
            return
    rows.append({"night": key, "time": hhmm, "amount_oz": amt_field,
                 "notes": notes or "", "period": period})
    write_rows(rows)
    amt_str = f"{amount:g} oz" if amount is not None else "(amount unknown)"
    log(f"Logged {period:5}: {d} {hhmm}  {amt_str}  {notes or ''}".rstrip())

# --- summaries ----------------------------------------------------------------

def amount(r):
    v = (r.get("amount_oz") or "").strip()
    return float(v) if v else None

def build_cycles(rows):
    """dict: cycle start date -> {"day": [rows], "night": [rows]}, each sorted by real time."""
    cycles = {}
    for r in rows:
        c = cycles.setdefault(cycle_date(r), {"day": [], "night": []})
        c[r.get("period", "night")].append(r)
    for c in cycles.values():
        for p in c:
            c[p].sort(key=event_datetime)
    return cycles

def cycle_summary(d, c):
    day_amt = [a for a in map(amount, c["day"]) if a is not None]
    night_amt = [a for a in map(amount, c["night"]) if a is not None]
    day_oz, night_oz = sum(day_amt), sum(night_amt)
    has_day = bool(c["day"])
    total = day_oz + night_oz if has_day else None
    pct = (100.0 * night_oz / total) if has_day and total else None
    return {"date": d, "day_n": len(c["day"]), "day_oz": day_oz,
            "night_n": len(c["night"]), "night_oz": night_oz,
            "total_oz": total, "night_pct": pct}

def fmt_day(d):
    return d.strftime("%a %b %-d")

def list_entries(for_day, for_night, n):
    ensure_file()
    cycles = build_cycles(read_rows())
    if for_night:
        for_day = (date.fromisoformat(for_night) - timedelta(days=1)).isoformat()
    if for_day:
        keys = [k for k in cycles if k.isoformat() == for_day]
    else:
        keys = sorted(cycles)[-n:]
    if not keys:
        log("No entries.")
        return

    for k in sorted(keys):
        c, s = cycles[k], cycle_summary(k, cycles[k])
        nxt = k + timedelta(days=1)
        log(f"\n24 hours starting {fmt_day(k)}")
        log("=" * 50)
        for period, label in (("day", f"Day   {fmt_day(k)}"),
                              ("night", f"Night {fmt_day(k)} -> {fmt_day(nxt)}")):
            entries = c[period]
            oz = s[f"{period}_oz"]
            log(f"{label}: {len(entries)} urination(s)" + (f", {oz:g} oz" if oz else ""))
            prev = None
            for e in entries:
                t = event_datetime(e)
                gap = f"  (+{int((t - prev).total_seconds() // 60)} min)" if prev else ""
                a = amount(e)
                amt = f"{a:g} oz" if a is not None else "amount unknown"
                note = f"  {e['notes']}" if e.get("notes") else ""
                log(f"  {e['time']}  {amt}{gap}{note}")
                prev = t
        if s["total_oz"] is not None:
            pct = f"{s['night_pct']:.0f}% at night" if s["night_pct"] is not None else ""
            log(f"24-hour total: {s['total_oz']:g} oz  {pct}".rstrip())
        else:
            log("24-hour total: (no daytime entries logged)")

# --- reports ------------------------------------------------------------------

SUMMARY_HEAD = ["Date", "Day voids", "Day (oz)", "Night voids", "Night (oz)",
                "24-hr (oz)", "% at night"]

def summary_row(s):
    return [s["date"].isoformat(), s["day_n"] if s["day_n"] else None,
            round(s["day_oz"], 1) if s["day_n"] else None,
            s["night_n"], round(s["night_oz"], 1),
            round(s["total_oz"], 1) if s["total_oz"] is not None else None,
            round(s["night_pct"]) if s["night_pct"] is not None else None]

def write_xlsx(path, summaries, cycles):
    from openpyxl import Workbook
    from openpyxl.styles import Font, PatternFill

    wb = Workbook()
    header_fill = PatternFill(start_color="1F3864", end_color="1F3864", fill_type="solid")
    header_font = Font(color="FFFFFF", bold=True)

    ws1 = wb.active
    ws1.title = "Summary"
    ws1.append(SUMMARY_HEAD)
    for cell in ws1[1]:
        cell.fill = header_fill
        cell.font = header_font
    for s in summaries:
        ws1.append(summary_row(s))
    for col, width in zip("ABCDEFG", (12, 10, 10, 12, 11, 11, 11)):
        ws1.column_dimensions[col].width = width

    ws2 = wb.create_sheet("Detail")
    ws2.append(["24-hr period", "Period", "Date", "Time", "Amount (oz)", "Notes"])
    for cell in ws2[1]:
        cell.fill = header_fill
        cell.font = header_font
    for s in summaries:
        c = cycles[s["date"]]
        for period in ("day", "night"):
            for e in c[period]:
                t = event_datetime(e)
                ws2.append([s["date"].isoformat(), period, t.date().isoformat(),
                            e["time"], amount(e), e.get("notes", "")])
    for col, width in zip("ABCDEF", (12, 8, 12, 8, 12, 60)):
        ws2.column_dimensions[col].width = width

    wb.save(path)

def write_pdf(path, summaries, cycles):
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
            ("FONTSIZE", (0, 0), (-1, -1), 9),
            ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ]))
        return t

    def cell(v, suffix=""):
        return "" if v is None else f"{v:g}{suffix}"

    styles = getSampleStyleSheet()
    doc = SimpleDocTemplate(path, pagesize=letter,
                             leftMargin=0.75*inch, rightMargin=0.75*inch,
                             topMargin=0.75*inch, bottomMargin=0.75*inch)
    bed = f"{BEDTIME_MIN // 60:02d}:{BEDTIME_MIN % 60:02d}"
    wake = f"{WAKE_MIN // 60:02d}:{WAKE_MIN % 60:02d}"
    story = [
        Paragraph("Urine Log: 24-Hour Voiding Record", styles["Title"]),
        Paragraph(f"Generated {datetime.now().strftime('%Y-%m-%d')}. "
                  f"Night = {bed} to {wake}. Each 24-hour period runs from the start "
                  f"of the day through the following night. 24-hour totals appear "
                  f"only for days with daytime entries.", styles["Normal"]),
        Spacer(1, 12),
    ]

    data = [SUMMARY_HEAD]
    for s in summaries:
        r = summary_row(s)
        data.append([r[0], cell(r[1]), cell(r[2]), cell(r[3]), cell(r[4]),
                     cell(r[5]), cell(r[6], "%")])
    story.append(style(Table(data, colWidths=[0.95*inch] + [0.85*inch] * 6)))
    story.append(Spacer(1, 16))

    for s in summaries:
        c = cycles[s["date"]]
        d, nxt = s["date"], s["date"] + timedelta(days=1)
        head = f"24 hours starting {fmt_day(d)}"
        if s["total_oz"] is not None:
            head += f" - {s['total_oz']:g} oz total, {s['night_pct']:.0f}% at night"
        story.append(Paragraph(head, styles["Heading3"]))
        data = [["Period", "Date", "Time", "Amount (oz)", "Notes"]]
        for period, label in (("day", "Day"), ("night", "Night")):
            for e in c[period]:
                t = event_datetime(e)
                a = amount(e)
                data.append([label, fmt_day(t.date()), e["time"],
                             f"{a:g}" if a is not None else "unknown",
                             Paragraph(e.get("notes", ""), styles["BodyText"])])
        story.append(style(Table(data, colWidths=[0.6*inch, 1.0*inch, 0.6*inch, 0.9*inch, 3.4*inch])))
        story.append(Spacer(1, 12))

    doc.build(story)

def ask_open(path, what):
    if not (path and os.path.isfile(path)):
        return
    prompt = f"Would you like to open the {what} report? [y/N]: "
    try:
        ans = input(prompt).strip().lower()
    except EOFError:
        ans = "n"
    log_only(prompt + ans)
    if ans == "y":
        subprocess.run(["open", path])

def generate_report():
    """Write urine_log.pdf and urine_log.xlsx to the Desktop, covering every
    24-hour period on record."""
    ensure_file()
    cycles = build_cycles(read_rows())
    if not cycles:
        log("No entries to report.")
        return
    summaries = [cycle_summary(k, cycles[k]) for k in sorted(cycles)]

    xlsx_path = os.path.join(DESKTOP, "urine_log.xlsx")
    pdf_path = os.path.join(DESKTOP, "urine_log.pdf")
    n = sum(len(c["day"]) + len(c["night"]) for c in cycles.values())

    try:
        write_xlsx(xlsx_path, summaries, cycles)
        log(f"wrote {n} row(s) to {xlsx_path}")
    except ImportError:
        log("openpyxl not installed - skipping urine_log.xlsx (pip3 install openpyxl)", err=True)
        xlsx_path = None

    try:
        write_pdf(pdf_path, summaries, cycles)
        log(f"wrote {n} row(s) to {pdf_path}")
    except ImportError:
        log("reportlab not installed - skipping urine_log.pdf (pip3 install reportlab)", err=True)
        pdf_path = None

    ask_open(pdf_path, "PDF")
    ask_open(xlsx_path, "numbers (xlsx)")

# --- pending command files ----------------------------------------------------

def cmdfile_stamp(path):
    m = CMDFILE_RE.search(os.path.basename(path))
    if m:
        return datetime.strptime(m.group(1) + m.group(2), "%Y%m%d%H%M%S")
    return datetime.fromtimestamp(os.path.getmtime(path))

def process_pending():
    """Find, validate, run, and archive the latest pending urine_cmds_*.ksh
    (or older nocturnal_cmds_*.ksh) file in ~/Downloads. This is
    urine_log.ksh's half of the handoff from urine.ksh."""
    candidates = sorted({p for g in CMDFILE_GLOBS for p in glob.glob(g)}, key=cmdfile_stamp)
    if not candidates:
        log(ACQUISITION_MESSAGE)
        sys.exit(1)

    latest = candidates[-1]
    base = os.path.basename(latest)

    if os.path.getsize(latest) == 0:
        log(f"{base} exists but is empty. Opening it for you to fill in.")
        # Blocking call, not exec - we need control back afterward to finish
        # validating and running the file once it's been saved.
        subprocess.run(["vi", latest])
        if os.path.getsize(latest) == 0:
            log(f"{base} is still empty after vi - nothing to run.")
            sys.exit(1)
        log(f"{base} now has content - continuing.")

    file_date = cmdfile_stamp(latest).date()
    if file_date != date.today():
        prompt = f"{base} is dated '{file_date.isoformat()}'. Use this data? [yN]: "
        try:
            ans = input(prompt).strip().lower()
        except EOFError:
            ans = "n"
        log_only(prompt + ans)
        if ans != "y":
            log(ACQUISITION_MESSAGE)
            sys.exit(1)

    log(f"Running {base}:")
    log("")
    result = subprocess.run(["ksh", latest])
    log("")
    if result.returncode != 0:
        log(f"Warning: {base} exited with status {result.returncode} - check the output above.")
        log(f"Leaving {base} (and any other pending files) in {DOWNLOADS_DIR} for review.")
        sys.exit(result.returncode)

    log(f"{base} completed.")

    os.makedirs(ARCHIVE_DIR, exist_ok=True)
    for f in candidates:
        dest = os.path.join(ARCHIVE_DIR, os.path.basename(f))
        shutil.move(f, dest)
        log(f"Archived {os.path.basename(f)} -> {ARCHIVE_DIR}")

def main():
    ap = argparse.ArgumentParser(description="Urine Log: urination time/amount (oz), day and night.")
    ap.add_argument("time", nargs="?", help="time of event, HH:MM (24h)")
    ap.add_argument("amount", nargs="?", type=float, help="amount in fluid ounces (oz)")
    ap.add_argument("notes", nargs="?", default="", help="optional note")
    ap.add_argument("-d", "--date", help="calendar date of the event, YYYY-MM-DD (default: today)")
    g = ap.add_mutually_exclusive_group()
    g.add_argument("--day", dest="force", action="store_const", const="day",
                   help="count this entry as daytime regardless of the clock")
    g.add_argument("--as-night", dest="force", action="store_const", const="night",
                   help="count this entry as nighttime regardless of the clock")
    ap.add_argument("-l", "--list", action="store_true", help="list entries instead of adding one")
    ap.add_argument("-n", type=int, default=7, help="with -l: number of recent 24-hour periods (default 7)")
    ap.add_argument("--on", metavar="YYYY-MM-DD", help="with -l: show only the 24 hours starting this date")
    ap.add_argument("--night", metavar="YYYY-MM-DD", help="with -l: show only the night ending (wake-up) on this date")
    ap.add_argument("-r", "--report", action="store_true", help="write urine_log.pdf/.xlsx to the Desktop")

    a = ap.parse_args()

    runlog_path = open_runlog()
    log(f"=== urine_log.py: starting {datetime.now()} ===")
    log("Args: " + (" ".join(sys.argv[1:]) if sys.argv[1:] else "(none - processing pending file)"))

    try:
        if a.report:
            generate_report()
        elif a.list:
            list_entries(a.on, a.night, a.n)
        elif not a.time:
            process_pending()
        else:
            add_entry(a.time, a.amount, a.notes, a.date, a.force)
    finally:
        log("")
        log(f"=== urine_log.py: finished {datetime.now()} ===")
        close_runlog(runlog_path)

if __name__ == "__main__":
    main()
