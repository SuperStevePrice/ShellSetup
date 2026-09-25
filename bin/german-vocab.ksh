#!/bin/ksh
#
# german-vocab.ksh — rebuilds german_vocabulary_by_domain.xlsx AND
# german_vocab_drill.html from source (build_german_vocab.py now
# produces both from the same DOMAINS data in one run), but ONLY when
# the source is newer than the existing outputs. If both outputs are
# already current, this is a no-op.
#
# Usage:
#   german-vocab.ksh                              # both outputs -> ~/Documents (or $VOCAB_OUT_DIR)
#   german-vocab.ksh /path/to/out.xlsx /path/to/out.html
#
# Requires: python3 with the 'openpyxl' package installed.

typeset SCRIPT_DIR
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
typeset BUILDER="${SCRIPT_DIR}/build_german_vocab.py"

typeset OUT_DIR="${VOCAB_OUT_DIR:-$HOME/Documents}"
typeset XLSX_FILE="${1:-${OUT_DIR}/german_vocabulary_by_domain.xlsx}"
typeset HTML_FILE="${2:-${OUT_DIR}/german_vocab_drill.html}"

if [[ ! -f "${BUILDER}" ]]; then
    print -u2 "german-vocab.ksh: cannot find ${BUILDER}"
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    print -u2 "german-vocab.ksh: python3 not found on PATH"
    exit 1
fi

if ! python3 -c "import openpyxl" >/dev/null 2>&1; then
    print -u2 "german-vocab.ksh: missing dependency — run: pip3 install --user openpyxl"
    exit 1
fi

# Skip the rebuild only if BOTH outputs already exist and are at least
# as new as the source. Either one being missing or stale rebuilds both,
# since a single build_german_vocab.py run regenerates them together.
if [[ -f "${XLSX_FILE}" && -f "${HTML_FILE}" ]] \
    && [[ ! "${BUILDER}" -nt "${XLSX_FILE}" ]] \
    && [[ ! "${BUILDER}" -nt "${HTML_FILE}" ]]; then
    print "german-vocab.ksh: both outputs are already up to date; nothing to do."
    exit 0
fi

exec python3 "${BUILDER}" "${XLSX_FILE}" "${HTML_FILE}"
