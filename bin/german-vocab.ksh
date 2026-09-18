#!/bin/ksh
#
# german-vocab.ksh — rebuilds german_vocabulary_by_domain.xlsx from source,
# but ONLY when the source (build_german_vocab.py) is newer than the
# existing output file. If nothing has changed, this is a no-op.
#
# Usage:
#   german-vocab.ksh                 # writes to ~/Documents (or $VOCAB_OUT_DIR)
#   german-vocab.ksh /path/to/out.xlsx
#
# Requires: python3 with the 'openpyxl' package installed.

typeset SCRIPT_DIR
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
typeset BUILDER="${SCRIPT_DIR}/build_german_vocab.py"

typeset OUT_DIR="${VOCAB_OUT_DIR:-$HOME/Documents}"
typeset OUT_FILE="${1:-${OUT_DIR}/german_vocabulary_by_domain.xlsx}"

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

# Skip the rebuild if the output already exists and is at least as new
# as the source. Only regenerate when the source has actually changed.
if [[ -f "${OUT_FILE}" && ! "${BUILDER}" -nt "${OUT_FILE}" ]]; then
    print "german-vocab.ksh: ${OUT_FILE} is already up to date; nothing to do."
    exit 0
fi

exec python3 "${BUILDER}" "${OUT_FILE}"
