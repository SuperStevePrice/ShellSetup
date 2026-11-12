#!/usr/bin/env python3
"""Create/update the sleep study SQLite database and import existing logs into it."""
import argparse, csv, os, sqlite3, sys
from datetime import datetime

DEFAULT_DB = os.path.expanduser("~/sleep_study.db")

# Nights before this date are pre-study background data (short
# durations, odd hour-only timestamps, no medications logged) that
# predate the real sleep study and shouldn't appear in reports shared
# with Dr. Syed. Change this if the study's start date changes.
DEFAULT_REPORT_SINCE = "2026-11-01"

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

def export_xlsx(conn, path):
    """Write the full nightly_report to a formatted .xlsx file -- opens
    natively in Numbers (or Excel) via a Finder double-click. No
    formulas here (this is a data export, not a model), so no recalc
    step is needed."""
    import openpyxl
    from openpyxl.styles import Font, Alignment, PatternFill
    from openpyxl.utils import get_column_letter

    cur = conn.execute("SELECT * FROM nightly_report WHERE night >= ? ORDER BY night DESC", (DEFAULT_REPORT_SINCE,))
    cols = [d[0] for d in cur.description]
    rows = cur.fetchall()

    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = "Sleep Report"

    header_font = Font(name="Arial", bold=True, color="FFFFFF")
    header_fill = PatternFill(start_color="1A4480", end_color="1A4480", fill_type="solid")
    body_font = Font(name="Arial", size=10)

    for j, col in enumerate(cols, start=1):
        c = ws.cell(row=1, column=j, value=col.replace("_", " ").title())
        c.font = header_font
        c.fill = header_fill
        c.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)

    for i, row in enumerate(rows, start=2):
        for j, val in enumerate(row, start=1):
            c = ws.cell(row=i, column=j, value=val)
            c.font = body_font
            if cols[j-1] in ("drug_notes",):
                c.alignment = Alignment(wrap_text=True, vertical="top")
            else:
                c.alignment = Alignment(vertical="top")

    # Column widths: generous for notes, snug for everything else
    widths = {"night": 12, "asleep_hours": 11, "awake_hours": 11, "inbed_hours": 11,
              "wakings": 9, "first_record": 11, "last_record": 11, "drug": 24,
              "melatonin": 10, "drug_notes": 70, "urination_count": 12, "urination_total_oz": 12}
    for j, col in enumerate(cols, start=1):
        ws.column_dimensions[get_column_letter(j)].width = widths.get(col, 14)

    ws.freeze_panes = "A2"
    ws.auto_filter.ref = ws.dimensions

    path = os.path.expanduser(path)
    wb.save(path)
    return path, len(rows)

def export_pdf(conn, path):
    """Write the full nightly_report as a clean, paginated landscape PDF
    table -- meant for sharing with a doctor: read-only, no app needed
    to open it, renders identically everywhere."""
    from reportlab.lib.pagesizes import letter, landscape
    from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib import colors
    from reportlab.lib.units import inch

    cur = conn.execute("SELECT * FROM nightly_report WHERE night >= ? ORDER BY night DESC", (DEFAULT_REPORT_SINCE,))
    cols = [d[0] for d in cur.description]
    rows = cur.fetchall()

    path = os.path.expanduser(path)
    doc = SimpleDocTemplate(path, pagesize=landscape(letter),
                             topMargin=0.5*inch, bottomMargin=0.5*inch,
                             leftMargin=0.4*inch, rightMargin=0.4*inch)
    styles = getSampleStyleSheet()
    title_style = ParagraphStyle('TitleStyle', parent=styles['Title'], fontSize=16, spaceAfter=4)
    sub_style = ParagraphStyle('SubStyle', parent=styles['Normal'], fontSize=9,
                                textColor=colors.grey, spaceAfter=12)
    cell_style = ParagraphStyle('Cell', parent=styles['Normal'], fontSize=8, leading=10)
    header_style = ParagraphStyle('Header', parent=styles['Normal'], fontSize=8,
                                   leading=10, textColor=colors.white, alignment=1)

    story = []
    story.append(Paragraph("Sleep Study Report", title_style))
    from datetime import date as _date
    story.append(Paragraph(f"Generated {_date.today().isoformat()} &mdash; {len(rows)} night(s) on record",
                            sub_style))

    header_labels = {
        "night": "Night", "asleep_hours": "Asleep (hrs)", "awake_hours": "Awake (hrs)",
        "inbed_hours": "In Bed (hrs)", "wakings": "Wakings", "first_record": "First",
        "last_record": "Last", "drug": "Medication(s)", "melatonin": "Melatonin",
        "drug_notes": "Notes", "urination_count": "Nocturia #", "urination_total_oz": "Oz Total",
    }
    headers = [header_labels.get(c, c.replace("_", " ").title()) for c in cols]
    data = [[Paragraph(h, header_style) for h in headers]]
    for row in rows:
        line = []
        for col, val in zip(cols, row):
            if val is None:
                val = ""
            if col == "drug_notes":
                line.append(Paragraph(str(val), cell_style))
            else:
                line.append(Paragraph(str(val), cell_style))
        data.append(line)

    # Column widths tuned for landscape letter (~10.2" usable width)
    width_map = {"night": 0.78, "asleep_hours": 0.58, "awake_hours": 0.55, "inbed_hours": 0.58,
                 "wakings": 0.55, "first_record": 0.5, "last_record": 0.5, "drug": 1.3,
                 "melatonin": 0.68, "drug_notes": 2.85, "urination_count": 0.62,
                 "urination_total_oz": 0.6}
    col_widths = [width_map.get(c, 0.6) * inch for c in cols]

    table = Table(data, colWidths=col_widths, repeatRows=1)
    table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1a4480')),
        ('GRID', (0, 0), (-1, -1), 0.4, colors.HexColor('#cccccc')),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#f5f7fa')]),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 4),
        ('RIGHTPADDING', (0, 0), (-1, -1), 4),
    ]))
    story.append(table)

    doc.build(story)
    return path, len(rows)

def report(conn, n):
    cur = conn.execute("SELECT * FROM nightly_report WHERE night >= ? ORDER BY night DESC LIMIT ?", (DEFAULT_REPORT_SINCE, n))
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
    DEFAULT_XLSX = "~/Desktop/sleep_report.xlsx"
    DEFAULT_PDF = "~/Desktop/sleep_report.pdf"
    ap.add_argument("--export-xlsx", metavar="PATH", nargs="?", const=DEFAULT_XLSX,
                     help=f"write the full nightly_report to this .xlsx file (opens in Numbers/Excel); "
                          f"with --report, this now happens automatically to {DEFAULT_XLSX} unless "
                          f"--no-export is given")
    ap.add_argument("--export-pdf", metavar="PATH", nargs="?", const=DEFAULT_PDF,
                     help=f"write the full nightly_report to this .pdf file (for sharing with a doctor); "
                          f"with --report, this now happens automatically to {DEFAULT_PDF} unless "
                          f"--no-export is given")
    ap.add_argument("--no-export", action="store_true",
                     help="with --report: skip the automatic .xlsx/.pdf export")
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

        # Auto-export both formats alongside the report by default, so
        # the Numbers/PDF files are always kept current without having
        # to remember any extra flags -- opt out with --no-export, or
        # override either path with an explicit --export-xlsx/--export-pdf.
        if not a.no_export:
            if not a.export_xlsx:
                a.export_xlsx = DEFAULT_XLSX
            if not a.export_pdf:
                a.export_pdf = DEFAULT_PDF

    if a.export_xlsx:
        path, n_rows = export_xlsx(conn, a.export_xlsx)
        print(f"  wrote {n_rows} row(s) to {path}")

    if a.export_pdf:
        path, n_rows = export_pdf(conn, a.export_pdf)
        print(f"  wrote {n_rows} row(s) to {path}")

    conn.close()

if __name__ == "__main__":
    main()
#-------------------------------------------------------------------------------
# Last installed: 2026-11-11 06:11:52
#-- End of File ----------------------------------------------------------------
