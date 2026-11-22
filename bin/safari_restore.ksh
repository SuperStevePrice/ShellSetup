#!/bin/ksh
#
# safari_restore.ksh
# Restore Safari configuration from a safari_backup.ksh snapshot.
#
# Restore source : ~/Library/Mobile Documents/com~apple~CloudDocs/safari/
#                  (iCloud Drive root) — lists available Safari-backup-* dirs
# Log target     : ~/logs/safari_restore_<datestamp>.log
#
# Usage:
#   safari_restore.ksh [backup_dir]
#
#   backup_dir  Full path to a specific Safari-backup-<datestamp> directory.
#               If omitted, the script lists available backups from iCloud
#               Drive and prompts you to choose one.
#
# Examples:
#   safari_restore.ksh
#   safari_restore.ksh "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Safari-backup-20250409_143022"
#
# Notes:
#   - Quit Safari before running.
#   - Existing ~/Library/Safari and com.apple.Safari.plist are preserved as
#     a dated .pre-restore backup before anything is overwritten.
#   - The plist restore is skipped gracefully if not present in the snapshot.
#   - All diagnostic output is tee'd to both the terminal and ~/logs/.
#

set -euo pipefail

# ── configuration ──────────────────────────────────────────────────────────

DATESTAMP=$(date +%Y%m%d_%H%M%S)

ICLOUD_DIR="${HOME}/Library/Mobile Documents/com~apple~CloudDocs/safari"

SAFARI_DIR="${HOME}/Library/Safari"
SAFARI_PLIST="${HOME}/Library/Preferences/com.apple.Safari.plist"

LOG_DIR="${HOME}/logs"
LOG_FILE="${LOG_DIR}/safari_restore_${DATESTAMP}.log"

# ── bootstrap: log dir and file ────────────────────────────────────────────

mkdir -p "${LOG_DIR}" || { print -- "[ERROR] Cannot create log directory: ${LOG_DIR}" >&2; exit 1; }
: > "${LOG_FILE}"

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

print_info "Safari configuration restore — ${DATESTAMP}"
print_info "Hostname: $(hostname)"
print_info "User:     ${USER}"
print_info "Log file: ${LOG_FILE}"
_log ""

# Safari must not be running
if pgrep -xq "Safari" 2>/dev/null; then
    print_warn "Safari is running. Quit Safari before restoring."
    _log ""
    print -- "Continue anyway? (y/N) \c"
    read REPLY
    [[ "${REPLY}" == [yY] ]] || die "Aborted by user."
    _log ""
fi

# ── safety prompt: offer to run safari_backup.ksh first ───────────────────

BACKUP_SCRIPT="${HOME}/bin/safari_backup.ksh"

_log ""
print_warn "Have you backed up your Safari prefs recently?"
print_warn "If not, run ${BACKUP_SCRIPT} first."
_log ""
print -- "Shall I run the backup for you now and then continue this restore? (y/N) \c"
read RUN_BACKUP

if [[ "${RUN_BACKUP}" == [yY] ]]; then
    if [[ -x "${BACKUP_SCRIPT}" ]]; then
        print_info "Running ${BACKUP_SCRIPT} ..."
        _log ""
        "${BACKUP_SCRIPT}" | tee -a "${LOG_FILE}"
        _log ""
        print_ok "Backup complete. Continuing with restore ..."
    else
        print_warn "${BACKUP_SCRIPT} not found or not executable."
        print_warn "Skipping backup — continuing with restore."
    fi
else
    print_info "Skipping backup — continuing with restore."
fi

_log ""

# ── select backup directory ────────────────────────────────────────────────

if [[ $# -ge 1 ]]; then
    BACKUP_DIR="$1"
    print_info "Using specified backup: ${BACKUP_DIR}"
else
    # Auto-discover Safari-backup-* directories in iCloud Drive
    [[ -d "${ICLOUD_DIR}" ]] || die "iCloud Drive not found: ${ICLOUD_DIR}"

    # Collect matches into positional parameters
    set +u
    set -- "${ICLOUD_DIR}"/Safari-backup-*
    set -u

    if [[ ! -d "$1" ]]; then
        die "No Safari-backup-* directories found in: ${ICLOUD_DIR}"
    fi

    BACKUP_COUNT=$#
    print_info "Found ${BACKUP_COUNT} backup(s) in iCloud Drive:"
    _log ""

    # Number and display them
    INDEX=1
    for DIR in "$@"; do
        print_info "  ${INDEX})  $(basename "${DIR}")"
        INDEX=$(( INDEX + 1 ))
    done

    _log ""
    print -- "Enter number to restore (1-${BACKUP_COUNT}): \c"
    read CHOICE

    # Validate choice
    [[ "${CHOICE}" =~ ^[0-9]+$ ]] || die "Invalid selection: ${CHOICE}"
    (( CHOICE >= 1 && CHOICE <= BACKUP_COUNT )) || die "Selection out of range: ${CHOICE}"

    # Walk to the chosen entry
    INDEX=1
    for DIR in "$@"; do
        if [[ ${INDEX} -eq ${CHOICE} ]]; then
            BACKUP_DIR="${DIR}"
            break
        fi
        INDEX=$(( INDEX + 1 ))
    done

    print_info "Selected: ${BACKUP_DIR}"
fi

_log ""

# Verify the chosen backup directory is valid
[[ -d "${BACKUP_DIR}" ]]         || die "Backup directory not found: ${BACKUP_DIR}"
[[ -d "${BACKUP_DIR}/Safari" ]]  || die "No Safari folder found inside: ${BACKUP_DIR}"

# ── safety: preserve existing Safari config before overwriting ─────────────

PRE="${HOME}/Library/Safari.pre-restore-${DATESTAMP}"
print_info "Preserving current Safari folder as: ${PRE}"
if [[ -d "${SAFARI_DIR}" ]]; then
    cp -R "${SAFARI_DIR}" "${PRE}"
    print_ok "Current Safari folder preserved."
else
    print_warn "No existing Safari folder found — nothing to preserve."
fi

PLIST_PRE="${HOME}/Library/Preferences/com.apple.Safari.pre-restore-${DATESTAMP}.plist"
if [[ -f "${SAFARI_PLIST}" ]]; then
    print_info "Preserving current Safari plist as: ${PLIST_PRE}"
    cp "${SAFARI_PLIST}" "${PLIST_PRE}"
    print_ok "Current Safari plist preserved."
else
    print_warn "No existing Safari plist found — nothing to preserve."
fi

_log ""

# ── restore Safari folder ──────────────────────────────────────────────────

print_info "Restoring Safari folder from: ${BACKUP_DIR}/Safari"
rm -rf "${SAFARI_DIR}"
cp -R "${BACKUP_DIR}/Safari" "${SAFARI_DIR}"
print_ok "Safari folder restored."

# ── restore Safari plist ───────────────────────────────────────────────────

BACKUP_PLIST="${BACKUP_DIR}/com.apple.Safari.plist"
if [[ -f "${BACKUP_PLIST}" ]]; then
    print_info "Restoring Safari plist from: ${BACKUP_PLIST}"
    cp "${BACKUP_PLIST}" "${SAFARI_PLIST}"
    print_ok "Safari plist restored."
else
    print_warn "No plist found in backup — skipping plist restore."
fi

# ── summary ────────────────────────────────────────────────────────────────

_log ""
print_ok "Restore complete."
print_info "Restored from:  ${BACKUP_DIR}"
print_info "Pre-restore backup of Safari folder: ${PRE}"
[[ -f "${PLIST_PRE}" ]] && print_info "Pre-restore backup of plist:         ${PLIST_PRE}"
_log ""
print_info "Launch Safari to verify the restore."
print_info "Log written to: ${LOG_FILE}"
