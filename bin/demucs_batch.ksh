#!/bin/ksh
#
# demucs_batch.ksh — batch-run Demucs AI stem separation over one or more
# audio files, or every audio file in a folder, producing per-track stems
# (vocals / drums / bass / other, or vocals / instrumental) ready to drag
# into GarageBand as separate tracks.
#
# Usage:
#   demucs_batch.ksh [-s] [-2] [-o OUTDIR] file1.mp3 [file2.wav ...]
#   demucs_batch.ksh [-s] [-2] [-o OUTDIR] -d SOURCE_DIR
#
#   -s          Spanish status messages
#   -2          2-stem split (vocals + instrumental) instead of the
#               default 4-stem split (vocals, drums, bass, other)
#   -d DIR      process every .mp3/.m4a/.wav/.aiff file in DIR
#   -o OUTDIR   where to write stems (default: ~/Desktop/stems)
#   -h          show this help
#
# Requires Python 3 with the demucs package:
#   pip3 install -U demucs
#
# Output: under OUTDIR you'll get a subfolder per track (named after the
# track) containing separate WAV files for each stem — drag those into
# GarageBand as individual tracks, pan them, add effects, bounce down.

typeset SPANISH=0
typeset TWOSTEM=0
typeset SRC_DIR=""
typeset OUTDIR="$HOME/Desktop/stems"
typeset SCRIPT_NAME="demucs_batch"
typeset TS=$(date +%Y%m%d_%H%M%S)
typeset LOGDIR="$HOME/logs"
typeset LOGFILE="$LOGDIR/${SCRIPT_NAME}.${TS}.log"

mkdir -p "$LOGDIR"

set -o pipefail

log() {
  # log TEXT -- prints to screen and appends to the log file
  print -- "$*" | tee -a "$LOGFILE"
}

msg() {
  # msg "english text" "texto en espanol"
  if [[ $SPANISH -eq 1 ]]; then
    log "$2"
  else
    log "$1"
  fi
}

while getopts "s2d:o:h" opt; do
  case $opt in
    s) SPANISH=1 ;;
    2) TWOSTEM=1 ;;
    d) SRC_DIR="$OPTARG" ;;
    o) OUTDIR="$OPTARG" ;;
    h)
      msg "Usage: $0 [-s] [-2] [-o OUTDIR] file1 [file2 ...]   OR   $0 [-s] [-2] [-d SOURCE_DIR] [-o OUTDIR]" \
          "Uso: $0 [-s] [-2] [-o OUTDIR] archivo1 [archivo2 ...]   O   $0 [-s] [-2] [-d DIRECTORIO] [-o OUTDIR]"
      exit 0
      ;;
    *) exit 1 ;;
  esac
done
shift $((OPTIND - 1))

mkdir -p "$OUTDIR"

log "=== $SCRIPT_NAME started $(date) ==="

if ! command -v demucs >/dev/null 2>&1; then
  msg "ERROR: the 'demucs' command was not found. Install it with: pip3 install -U demucs" \
      "ERROR: no se encontro el comando 'demucs'. Instalelo con: pip3 install -U demucs"
  log "See: $LOGFILE"
  exit 1
fi

typeset -a FILES

if [[ -n "$SRC_DIR" ]]; then
  if [[ ! -d "$SRC_DIR" ]]; then
    msg "ERROR: directory not found: $SRC_DIR" "ERROR: directorio no encontrado: $SRC_DIR"
    log "See: $LOGFILE"
    exit 1
  fi
  FILES=( "$SRC_DIR"/*.mp3 "$SRC_DIR"/*.m4a "$SRC_DIR"/*.wav "$SRC_DIR"/*.aiff )
else
  FILES=( "$@" )
fi

if [[ ${#FILES[@]} -eq 0 ]]; then
  msg "No audio files given. Use -d DIR or list files directly on the command line." \
      "No se indicaron archivos de audio. Use -d DIRECTORIO o indique los archivos directamente."
  log "See: $LOGFILE"
  exit 1
fi

typeset -a DEMUCS_ARGS
if [[ $TWOSTEM -eq 1 ]]; then
  DEMUCS_ARGS=( "--two-stems=vocals" )
fi

typeset -i OK=0
typeset -i FAIL=0

for f in "${FILES[@]}"; do
  [[ -f "$f" ]] || continue
  msg "Processing: $f" "Procesando: $f"
  if demucs -o "$OUTDIR" "${DEMUCS_ARGS[@]}" "$f" 2>&1 | tee -a "$LOGFILE"; then
    OK=$((OK + 1))
    msg "  OK -- stems in $OUTDIR" "  OK -- stems en $OUTDIR"
  else
    FAIL=$((FAIL + 1))
    msg "  FAILED: $f" "  FALLO: $f"
  fi
done

msg "Done. $OK succeeded, $FAIL failed. Stems are under: $OUTDIR" \
    "Listo. $OK con exito, $FAIL fallidos. Los stems estan en: $OUTDIR"

log "See: $LOGFILE"
