#!/Users/steve/miniconda3/bin/python3
"""
launch_threads.py — Post a text file to Bluesky, Mastodon, and optionally Threads.
                    LinkedIn text is always formatted for manual copy-paste.

All scripts must be in the same directory as this launcher, or on your PATH.

Usage:
    python3 launch_threads.py <textfile>                    # dry run: bsky + masto + LinkedIn text
    python3 launch_threads.py <textfile> --post             # post bsky + masto; show LinkedIn text
    python3 launch_threads.py <textfile> --threads manual   # also show Threads text for copy-paste
    python3 launch_threads.py <textfile> --threads auto     # also post to Threads via API
    python3 launch_threads.py <textfile> --post --threads auto  # post everything + Threads API
    python3 launch_threads.py <textfile> --skip masto       # skip a platform
    python3 launch_threads.py <textfile> --only bsky        # only one platform

Requires:
    ~/.bsky_config      (BSKY_HANDLE, BSKY_APP_PASSWORD)
    ~/.masto_config     (MASTO_INSTANCE, MASTO_ACCESS_TOKEN)
    ~/.threads_config   (THREADS_USER_ID, THREADS_ACCESS_TOKEN)  # only for --threads auto

Log:
    ~/logs/launch_threads.log  (appended on every run)
"""

import argparse
import logging
import re
import subprocess
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Platform registry — LinkedIn and Threads handled separately
# ---------------------------------------------------------------------------
PLATFORMS = {
    "bsky":  "bsky_thread.py",
    "masto": "masto_thread.py",
}

THREADS_AUTO_SCRIPT   = "threads_thread.py"
THREADS_MANUAL_SCRIPT = "threads_manual.py"

MAX_LINKEDIN_CHARS = 3000
URL_RE = re.compile(r'https?://\S+', re.IGNORECASE)

# ---------------------------------------------------------------------------
# Logging setup
# ---------------------------------------------------------------------------
LOG_DIR  = Path.home() / "logs"
LOG_FILE = LOG_DIR / "launch_threads.log"

def setup_logging():
    LOG_DIR.mkdir(exist_ok=True)
    logging.basicConfig(
        filename = LOG_FILE,
        level    = logging.INFO,
        format   = "%(asctime)s  %(levelname)-8s  %(message)s",
        datefmt  = "%Y-%m-%d %H:%M:%S",
    )

# ---------------------------------------------------------------------------
# Locate a sibling script
# ---------------------------------------------------------------------------
SCRIPT_DIR = Path(__file__).resolve().parent

def find_script(name):
    local = SCRIPT_DIR / name
    if local.exists():
        return str(local)
    return name

# ---------------------------------------------------------------------------
# Run one platform (bsky or masto)
# ---------------------------------------------------------------------------
def run_platform(label, script_name, textfile, post_mode):
    script = find_script(script_name)
    cmd    = [sys.executable, script, textfile]
    if post_mode:
        cmd.append("--post")

    print(f"\n{'═' * 60}")
    print(f"  {'[DRY RUN] ' if not post_mode else ''}→ {label.upper()}")
    print(f"{'═' * 60}")

    result = subprocess.run(cmd)

    mode = "POST" if post_mode else "DRY RUN"
    if result.returncode == 0:
        logging.info(f"{mode:8s}  {label:10s}  SUCCESS  file={textfile}")
    else:
        logging.error(f"{mode:8s}  {label:10s}  FAILED   file={textfile}  rc={result.returncode}")

    return result.returncode

# ---------------------------------------------------------------------------
# LinkedIn — format and print for manual copy-paste
# ---------------------------------------------------------------------------
def show_linkedin(textfile, post_mode):
    print(f"\n{'═' * 60}")
    print(f"  {'[DRY RUN] ' if not post_mode else ''}→ LINKEDIN  (copy-paste manually)")
    print(f"{'═' * 60}")

    raw  = Path(textfile).read_text(encoding="utf-8")
    text = re.sub(r"\n{3,}", "\n\n", raw.strip())
    text = re.sub(r"[ \t]+", " ", text)

    urls    = URL_RE.findall(text)
    cleaned = URL_RE.sub('', text)
    cleaned = re.sub(r'[ \t]{2,}', ' ', cleaned).strip()
    if urls:
        cleaned = cleaned + "\n\n" + "\n".join(urls)

    char_count = len(cleaned)
    status = "OK" if char_count <= MAX_LINKEDIN_CHARS \
             else f"WARNING: OVER LIMIT by {char_count - MAX_LINKEDIN_CHARS} chars"
    print(f"  {char_count}/{MAX_LINKEDIN_CHARS} chars  [{status}]\n")
    print(cleaned)
    print(f"\n{'─' * 60}")
    print("  ^ Copy the text above and paste into LinkedIn manually.")
    print(f"{'═' * 60}")

    mode = "POST" if post_mode else "DRY RUN"
    logging.info(f"{mode:8s}  {'linkedin':10s}  MANUAL   file={textfile}  chars={char_count}")

# ---------------------------------------------------------------------------
# Threads — either run manual script or auto-post script
# ---------------------------------------------------------------------------
def handle_threads(textfile, post_mode, threads_mode):
    if threads_mode == "manual":
        # Run threads_manual.py — no --post flag, it always just prints
        script = find_script(THREADS_MANUAL_SCRIPT)
        print(f"\n{'═' * 60}")
        print(f"  → THREADS  (copy-paste manually)")
        print(f"{'═' * 60}")
        result = subprocess.run([sys.executable, script, textfile])
        rc = result.returncode
        mode = "POST" if post_mode else "DRY RUN"
        if rc == 0:
            logging.info(f"{mode:8s}  {'threads':10s}  MANUAL   file={textfile}")
        else:
            logging.error(f"{mode:8s}  {'threads':10s}  FAILED   file={textfile}  rc={rc}")
        return rc

    elif threads_mode == "auto":
        # Run threads_thread.py with --post if in post mode
        return run_platform("threads", THREADS_AUTO_SCRIPT, textfile, post_mode)

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    setup_logging()

    all_skippable = list(PLATFORMS.keys()) + ["linkedin", "threads"]

    parser = argparse.ArgumentParser(
        description="Post to Bluesky, Mastodon, and optionally Threads; LinkedIn is copy-paste."
    )
    parser.add_argument("file",
                        help="Path to the text file to post")
    parser.add_argument("--post", action="store_true",
                        help="Actually publish to Bluesky, Mastodon (and Threads if --threads auto)")
    parser.add_argument("--threads", choices=["manual", "auto"], default=None,
                        metavar="MODE",
                        help="Include Threads: 'manual' (copy-paste) or 'auto' (post via API)")
    parser.add_argument("--only", nargs="+", choices=all_skippable,
                        metavar="PLATFORM",
                        help=f"Only run these: {all_skippable}")
    parser.add_argument("--skip", nargs="+", choices=all_skippable,
                        metavar="PLATFORM",
                        help="Skip these platforms")
    args = parser.parse_args()

    path = Path(args.file)
    if not path.exists():
        logging.error(f"File not found: {path}")
        sys.exit(f"File not found: {path}")

    # Build target list — linkedin always included, threads only if requested
    targets = list(PLATFORMS.keys()) + ["linkedin"]
    if args.threads:
        targets.append("threads")

    if args.only:
        targets = [p for p in targets if p in args.only]
    if args.skip:
        targets = [p for p in targets if p not in args.skip]

    if not targets:
        sys.exit("No platforms selected — nothing to do.")

    mode_label = "--post mode" if args.post else "DRY RUN mode"
    threads_label = f"  (Threads: {args.threads})" if args.threads else ""
    logging.info(f"{'─' * 50}")
    logging.info(f"START  {mode_label}  file={path}  targets={','.join(targets)}")

    print(f"\nlaunch_threads.py -- {mode_label}{threads_label}")
    print(f"File    : {path}")
    print(f"Targets : {', '.join(targets)}")
    print(f"Log     : {LOG_FILE}")

    failures = []
    for label in targets:
        if label == "linkedin":
            show_linkedin(str(path), args.post)
        elif label == "threads":
            rc = handle_threads(str(path), args.post, args.threads)
            if rc != 0:
                failures.append(label)
        else:
            rc = run_platform(label, PLATFORMS[label], str(path), args.post)
            if rc != 0:
                failures.append(label)

    print(f"\n{'═' * 60}")
    if failures:
        msg = f"COMPLETED WITH ERRORS on: {', '.join(failures)}"
        logging.error(f"END    {msg}  file={path}")
        print(f"  {msg}")
        sys.exit(1)
    else:
        parts = []
        if any(p in targets for p in ["bsky", "masto"]):
            parts.append(f"bsky/masto {'posted' if args.post else 'previewed'}")
        if "linkedin" in targets:
            parts.append("LinkedIn ready to paste")
        if "threads" in targets:
            parts.append(f"Threads ({args.threads})")
        msg = "ALL DONE -- " + "; ".join(parts) + "."
        logging.info(f"END    {msg}  file={path}")
        print(f"  {msg}")
    print(f"{'═' * 60}\n")

if __name__ == "__main__":
    main()
