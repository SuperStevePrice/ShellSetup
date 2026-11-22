#!/bin/ksh
#
# safari_backup.ksh
# Snapshot Safari configuration (~/Library/Safari + com.apple.Safari.plist)
# and optionally create an APFS local snapshot via tmutil.
#
# Backup target : ~/Library/Mobile Documents/com~apple~CloudDocs/safari/
#                 subdirectory Safari-backup-<datestamp>
# Log target    : ~/logs/safari_backup_<datestamp>.log
#
# Usage:
#   safari_backup.ksh [dest_dir]
#
#   dest_dir  Optional override for the backup destination.
#             Defaults to iCloud Drive safari/ folder if not specified.
#
# Examples:
#   safari_backup.ksh
#   safari_backup.ksh ~/Backups/Safari
#
# Notes:
#   - Quit Safari before running for a clean, consistent snapshot.
#   - The iCloud Drive path contains spaces; the script handles this cleanly
#     via a variable — no escaping needed at the call site.
#   - tmutil localsnapshot requires Time Machine to be configured.
#   - APFS local snapshots are ephemeral; macOS may purge them under
#     disk pressure.  An external Time Machine drive gives durable backups.
#   - All diagnostic output is tee'd to both the terminal and ~/logs/.
#

set -euo pipefail

# ── configuration ──────────────────────────────────────────────────────────

DATESTAMP=$(date +%Y%m%d_%H%M%S)

# iCloud Drive root — spaces in path are safe inside a quoted variable
ICLOUD_DIR="${HOME}/Library/Mobile Documents/com~apple~CloudDocs/safari"

DEST_DIR="${1:-${ICLOUD_DIR}}"
BACKUP_DIR="${DEST_DIR}/Safari-backup-${DATESTAMP}"

SAFARI_DIR="${HOME}/Library/Safari"
SAFARI_PLIST="${HOME}/Library/Preferences/com.apple.Safari.plist"

LOG_DIR="${HOME}/logs"
LOG_FILE="${LOG_DIR}/safari_backup_${DATESTAMP}.log"

# ── bootstrap: create log dir and log file before any output ───────────────

mkdir -p "${LOG_DIR}"  || { print -- "[ERROR] Cannot create log directory: ${LOG_DIR}" >&2; exit 1; }
: > "${LOG_FILE}"       # truncate/create

# ── helpers ────────────────────────────────────────────────────────────────

_log()       { print -- "$*" | tee -a "${LOG_FILE}"; }
print_info() { _log "[INFO]  $*"; }
print_ok()   { _log "[OK]    $*"; }
print_warn() { _log "[WARN]  $*"; }
print_err()  { print -- "[ERROR] $*" | tee -a "${LOG_FILE}" >&2; }

die() {
    print_err "$*"
    exit 1
}

# ── preflight ──────────────────────────────────────────────────────────────

print_info "Safari configuration snapshot — ${DATESTAMP}"
print_info "Hostname:    $(hostname)"
print_info "User:        ${USER}"
print_info "Backup dest: ${BACKUP_DIR}"
print_info "Log file:    ${LOG_FILE}"
_log ""

# Warn if Safari is running
if pgrep -xq "Safari" 2>/dev/null; then
    print_warn "Safari appears to be running."
    print_warn "For a clean snapshot, quit Safari before proceeding."
    _log ""
    print -- "Continue anyway? (y/N) \c"
    read REPLY
    [[ "${REPLY}" == [yY] ]] || die "Aborted by user."
    _log ""
fi

# Ensure backup destination exists — create it if needed (first run bootstrap)
if [[ ! -d "${DEST_DIR}" ]]; then
    print_info "Backup destination not found — creating: ${DEST_DIR}"
    mkdir -p "${DEST_DIR}" || die "Cannot create backup destination: ${DEST_DIR}"
    print_ok  "Created: ${DEST_DIR}"
fi

# Verify Safari folder exists
[[ -d "${SAFARI_DIR}" ]] || die "Safari folder not found: ${SAFARI_DIR}"

# Warn (don't die) if plist is absent — unusual but not fatal
[[ -f "${SAFARI_PLIST}" ]] || print_warn "Safari plist not found (skipping): ${SAFARI_PLIST}"

# Create timestamped backup subdirectory
mkdir -p "${BACKUP_DIR}" || die "Cannot create backup directory: ${BACKUP_DIR}"

# ── copy Safari folder ─────────────────────────────────────────────────────

print_info "Copying ${SAFARI_DIR} ..."
cp -R "${SAFARI_DIR}" "${BACKUP_DIR}/Safari"
print_ok  "Safari folder copied."

# ── copy Safari plist ──────────────────────────────────────────────────────

if [[ -f "${SAFARI_PLIST}" ]]; then
    print_info "Copying ${SAFARI_PLIST} ..."
    cp "${SAFARI_PLIST}" "${BACKUP_DIR}/com.apple.Safari.plist"
    print_ok  "Safari plist copied."
fi

# ── APFS local snapshot via tmutil ─────────────────────────────────────────

if command -v tmutil >/dev/null 2>&1; then
    print_info "Creating APFS local snapshot via tmutil ..."
    if tmutil localsnapshot 2>/dev/null; then
        print_ok "Local snapshot created."
        print_info "Current local snapshots:"
        tmutil listlocalsnapshots / 2>/dev/null \
            | sed 's/^/        /' \
            | tee -a "${LOG_FILE}"
    else
        print_warn "tmutil localsnapshot failed (Time Machine may not be configured)."
    fi
else
    print_warn "tmutil not found — skipping APFS snapshot."
fi

# ── summary ────────────────────────────────────────────────────────────────

_log ""
print_ok "Snapshot complete."
print_info "Backup contents:"
ls -lh "${BACKUP_DIR}" | tee -a "${LOG_FILE}"
_log ""
print_info "Log written to: ${LOG_FILE}"
