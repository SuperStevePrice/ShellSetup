#!/usr/bin/env python3
"""Nocturnal Voiding log: nighttime urination time + amount (oz) for the sleep study."""
import argparse, csv, glob, os, re, shutil, subprocess, sys
from datetime import datetime, date, timedelta

LOGFILE = os.path.expanduser("~/.nocturia_log.csv")
DOWNLOADS_DIR = os.path.expanduser("~/Downloads")
ARCHIVE_DIR = os.path.expanduser("~/tests/nocturnal_cmds")
CMDFILE_PATTERN = os.path.join(DOWNLOADS_DIR, "nocturnal_cmds_*.ksh")
CMDFILE_RE = re.compile(r"nocturnal_cmds_(\d{8})_(\d{6})\.ksh$")
RUNLOG_DIR = os.path.expanduser("~/logs")

ACQUISITION_MESSAGE = """To acquire required data:
    1.  nocturnal.ksh   This script will open a vi session
        named for date and time.
        Insert the commands generated on the iPhone by the
        Nocturnal Log app.
        It is assumed that the nocturnal data will have been
        collected during the wee hours of the morning during
        which we are now collecting data.
    2.  On the iPhone, open the Nocturnal Log app found in the
        Health folder.
        a.  Scroll to the very bottom.
        b.  Select "Copy nocturnal_log Commands."
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
    # Microsecond resolution matters here: nocturnal_log.py can be invoked
    # many times within the same wall-clock second (e.g. once per line of a
    # nocturnal_cmds_*.ksh file), and second-resolution timestamps collide,
    # causing separate runs to append into the same "own" log file instead
    # of each getting its own as intended.
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")
    path = os.path.join(RUNLOG_DIR, f"nocturnal_log.{timestamp}.log")
    _runlog_fh = open(path, "a")
    return path

def close_runlog(path):
    log(f"See: {path}")
    if _runlog_fh:
        _runlog_fh.close()

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
        log(f"Bad time '{time_str}', expected HH:MM (24h)", err=True)
        sys.exit(1)

    if on_date:
        try:
            d = date.fromisoformat(on_date)
        except ValueError:
            log(f"Bad date '{on_date}', expected YYYY-MM-DD", err=True)
            sys.exit(1)
        dt = datetime(d.year, d.month, d.day, hh, mm)
    else:
        dt = datetime(now.year, now.month, now.day, hh, mm)

    night = night_key(dt)
    hhmm = dt.strftime("%H:%M")
    amt_field = str(amount) if amount is not None else ""
    with open(LOGFILE) as f:
        for r in csv.DictReader(f):
            if r["night"] == night and r["time"] == hhmm and r["amount_oz"] == amt_field:
                log(f"Skipped duplicate: night {night} -> {hhmm}  {amt_field or '(amount unknown)'} already logged")
                return
    with open(LOGFILE, "a", newline="") as f:
        csv.writer(f).writerow([night, dt.strftime("%H:%M"), amount if amount is not None else "", notes or ""])
    amt_str = f"{amount} oz" if amount is not None else "(amount unknown)"
    log(f"Logged: night {night} -> {dt.strftime('%H:%M')}  {amt_str}  {notes or ''}".rstrip())

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
        log("No entries.")
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
        log(f"\nNocturnal Voiding: {k} — {len(entries)} urination(s)" + (f", total {total:g} {unit}" if total else ""))
        log("-" * 50)
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
            log(f"  {e['time']}  {amt}{gap}{note}")
            prev = e["time"]

def write_nocturnal_xlsx(path, summary, detail_rows):
    from openpyxl import Workbook
    from openpyxl.styles import Font, PatternFill

    wb = Workbook()
    header_fill = PatternFill(start_color="1F3864", end_color="1F3864", fill_type="solid")
    header_font = Font(color="FFFFFF", bold=True)

    ws1 = wb.active
    ws1.title = "Summary"
    ws1.append(["Night", "Urinations", "Total (oz)"])
    for cell in ws1[1]:
        cell.fill = header_fill
        cell.font = header_font
    for night, count, total in summary:
        ws1.append([night, count, round(total, 1)])
    for col, width in zip("ABC", (14, 12, 12)):
        ws1.column_dimensions[col].width = width

    ws2 = wb.create_sheet("Detail")
    ws2.append(["Night", "Time", "Amount (oz)", "Notes"])
    for cell in ws2[1]:
        cell.fill = header_fill
        cell.font = header_font
    for night, time_, amt, notes in detail_rows:
        ws2.append([night, time_, float(amt) if amt not in ("", None) else None, notes])
    for col, width in zip("ABCD", (14, 10, 14, 60)):
        ws2.column_dimensions[col].width = width

    wb.save(path)

def write_nocturnal_pdf(path, summary, detail_rows):
    from reportlab.lib.pagesizes import letter
    from reportlab.lib import colors
    from reportlab.lib.units import inch
    from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
    from reportlab.lib.styles import getSampleStyleSheet

    styles = getSampleStyleSheet()
    doc = SimpleDocTemplate(path, pagesize=letter,
                             leftMargin=0.75*inch, rightMargin=0.75*inch,
                             topMargin=0.75*inch, bottomMargin=0.75*inch)
    story = [
        Paragraph("Nocturnal Voiding Report", styles["Title"]),
        Paragraph(f"Generated {datetime.now().strftime('%Y-%m-%d')} — {len(summary)} night(s) on record", styles["Normal"]),
        Spacer(1, 16),
    ]

    detail_by_night = {}
    for night, time_, amt, notes in detail_rows:
        detail_by_night.setdefault(night, []).append((time_, amt, notes))

    for night, count, total in summary:
        story.append(Paragraph(f"{night} — {count} urination(s), total {total:g} oz", styles["Heading3"]))
        data = [["Time", "Amount (oz)", "Notes"]]
        for time_, amt, notes in detail_by_night.get(night, []):
            data.append([time_, amt if amt else "unknown", notes])
        t = Table(data, colWidths=[0.9*inch, 1.1*inch, 4*inch])
        t.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1F3864")),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
            ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
            ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
            ("FONTSIZE", (0, 0), (-1, -1), 9),
            ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ]))
        story.append(t)
        story.append(Spacer(1, 16))

    doc.build(story)

def generate_report():
    """Write nocturnal.pdf and nocturnal.xlsx to the Desktop, covering every
    night on record - the nocturnal-side counterpart to morning_sleep's
    sleep_report.pdf/.xlsx pair, with the same open-when-done prompts."""
    ensure_file()
    with open(LOGFILE) as f:
        rows = list(csv.DictReader(f))

    nights = {}
    for r in rows:
        nights.setdefault(r["night"], []).append(r)

    keys = sorted(nights)
    if not keys:
        log("No entries to report.")
        return

    def sort_key(r):
        hh, mm = map(int, r["time"].split(":"))
        bucket = 0 if hh >= 18 else 1
        return (bucket, hh, mm)

    summary = []
    detail_rows = []
    for k in keys:
        entries = sorted(nights[k], key=sort_key)
        amounts = [float(e["amount_oz"]) for e in entries if e.get("amount_oz", "").strip() != ""]
        total = sum(amounts) if amounts else 0.0
        summary.append((k, len(entries), total))
        for e in entries:
            detail_rows.append((k, e["time"], e.get("amount_oz", ""), e.get("notes", "")))

    desktop = os.path.expanduser("~/Desktop")
    xlsx_path = os.path.join(desktop, "nocturnal.xlsx")
    pdf_path = os.path.join(desktop, "nocturnal.pdf")

    try:
        write_nocturnal_xlsx(xlsx_path, summary, detail_rows)
        log(f"wrote {len(detail_rows)} row(s) to {xlsx_path}")
    except ImportError:
        log("openpyxl not installed - skipping nocturnal.xlsx (pip3 install openpyxl)", err=True)
        xlsx_path = None

    try:
        write_nocturnal_pdf(pdf_path, summary, detail_rows)
        log(f"wrote {len(detail_rows)} row(s) to {pdf_path}")
    except ImportError:
        log("reportlab not installed - skipping nocturnal.pdf (pip3 install reportlab)", err=True)
        pdf_path = None

    if pdf_path and os.path.isfile(pdf_path):
        prompt = "Would you like to open the PDF report? [y/N]: "
        try:
            ans = input(prompt).strip().lower()
        except EOFError:
            ans = "n"
        log_only(prompt + ans)
        if ans == "y":
            subprocess.run(["open", pdf_path])

    if xlsx_path and os.path.isfile(xlsx_path):
        prompt = "Would you like to open the numbers (xlsx) report? [y/N]: "
        try:
            ans = input(prompt).strip().lower()
        except EOFError:
            ans = "n"
        log_only(prompt + ans)
        if ans == "y":
            subprocess.run(["open", xlsx_path])

def cmdfile_date(path):
    """Date encoded in the nocturnal_cmds_YYYYMMDD_HHMMSS.ksh filename itself,
    falling back to the file's mtime if the name doesn't match the pattern."""
    m = CMDFILE_RE.search(os.path.basename(path))
    if m:
        return datetime.strptime(m.group(1), "%Y%m%d").date()
    return datetime.fromtimestamp(os.path.getmtime(path)).date()

def process_pending():
    """Find, validate, run, and archive the latest pending
    nocturnal_cmds_*.ksh file in ~/Downloads. This is nocturnal_log.ksh's
    half of the handoff from nocturnal.ksh."""
    candidates = sorted(glob.glob(CMDFILE_PATTERN))
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

    file_date = cmdfile_date(latest)
    if file_date != date.today():
        when = file_date.isoformat()
        prompt = f"{base} is dated '{when}'. Use this data? [yN]: "
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
    ap = argparse.ArgumentParser(description="Nocturnal Voiding log: nighttime urination time/amount (oz) for the sleep study.")
    ap.add_argument("time", nargs="?", help="time of event, HH:MM (24h)")
    ap.add_argument("amount", nargs="?", type=float, help="amount in fluid ounces (oz)")
    ap.add_argument("notes", nargs="?", default="", help="optional note")
    ap.add_argument("-d", "--date", help="date this event belongs to, YYYY-MM-DD (default: today)")
    ap.add_argument("-l", "--list", action="store_true", help="list entries instead of adding one")
    ap.add_argument("-n", type=int, default=7, help="with -l: number of recent nights to show (default 7)")
    ap.add_argument("--night", help="with -l: show only this night, YYYY-MM-DD")
    ap.add_argument("-r", "--report", action="store_true", help="write nocturnal.pdf/.xlsx to the Desktop")

    a = ap.parse_args()

    runlog_path = open_runlog()
    log(f"=== nocturnal_log.py: starting {datetime.now()} ===")
    log("Args: " + (" ".join(sys.argv[1:]) if sys.argv[1:] else "(none - processing pending file)"))

    try:
        if a.report:
            generate_report()
        elif a.list:
            list_entries(a.night, a.n)
        elif not a.time:
            process_pending()
        else:
            add_entry(a.time, a.amount, a.notes, a.date)
    finally:
        log("")
        log(f"=== nocturnal_log.py: finished {datetime.now()} ===")
        close_runlog(runlog_path)

if __name__ == "__main__":
    main()
#-------------------------------------------------------------------------------
# Last installed: 2026-11-20 07:49:26
#-- End of File ----------------------------------------------------------------
