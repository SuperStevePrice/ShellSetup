#!/bin/ksh
#
# pack_for_dwight.ksh — zip up the enhanced "Your Kingdom Come: Songs of
# Worship" album plus the enhanced "If It Be Your Will" single into one
# archive ready to send to Dwight. Automatically skips any "(original
# backup)" files sitting alongside the blessed tracks.
#
# Usage:
#   pack_for_dwight.ksh [-s] [-o OUTDIR] ALBUM_DIR SINGLE_FILE
#
#   -s          Spanish status messages
#   -o OUTDIR   where to write the zip (default: ~/Desktop)
#   -h          show this help
#
# ALBUM_DIR     folder containing the blessed album tracks, e.g.:
#               ~/Music/Swinsian/Steve Price/Your Kingdom Come- Songs of Worship
# SINGLE_FILE   the blessed single track, e.g. the "01 If It Be Your Will.mp3"
#
# Output: OUTDIR/Hymns_of_Worship_for_Dwight_<timestamp>.zip

typeset SPANISH=0
typeset OUTDIR="$HOME/Desktop"
typeset SCRIPT_NAME="pack_for_dwight"
typeset TS=$(date +%Y%m%d_%H%M%S)
typeset LOGDIR="$HOME/logs"
typeset LOGFILE="$LOGDIR/${SCRIPT_NAME}.${TS}.log"

mkdir -p "$LOGDIR"
set -o pipefail

log() {
  print -- "$*" | tee -a "$LOGFILE"
}

msg() {
  if [[ $SPANISH -eq 1 ]]; then
    log "$2"
  else
    log "$1"
  fi
}

while getopts "so:h" opt; do
  case $opt in
    s) SPANISH=1 ;;
    o) OUTDIR="$OPTARG" ;;
    h)
      msg "Usage: $0 [-s] [-o OUTDIR] ALBUM_DIR SINGLE_FILE" \
          "Uso: $0 [-s] [-o OUTDIR] DIRECTORIO_DEL_ALBUM ARCHIVO_SENCILLO"
      exit 0
      ;;
    *) exit 1 ;;
  esac
done
shift $((OPTIND - 1))

log "=== $SCRIPT_NAME started $(date) ==="

typeset ALBUM_DIR="$1"
typeset SINGLE_FILE="$2"

if [[ -z "$ALBUM_DIR" || ! -d "$ALBUM_DIR" ]]; then
  msg "ERROR: give the album folder as the first argument." \
      "ERROR: indique la carpeta del album como primer argumento."
  log "See: $LOGFILE"
  exit 1
fi

if [[ -z "$SINGLE_FILE" || ! -f "$SINGLE_FILE" ]]; then
  msg "ERROR: give the single track file as the second argument." \
      "ERROR: indique el archivo de la pista sencilla como segundo argumento."
  log "See: $LOGFILE"
  exit 1
fi

mkdir -p "$OUTDIR"

typeset STAGE="$HOME/.pack_for_dwight_stage.$$"
mkdir -p "$STAGE/Hymns of Worship"

typeset -i N=0
for f in "$ALBUM_DIR"/*; do
  [[ -f "$f" ]] || continue
  case "${f##*/}" in
    *"(original backup)"*) continue ;;
  esac
  cp "$f" "$STAGE/Hymns of Worship/"
  N=$((N + 1))
done

cp "$SINGLE_FILE" "$STAGE/"
N=$((N + 1))

msg "Staged $N file(s)." "Se prepararon $N archivo(s)."

typeset ZIPFILE="$OUTDIR/Hymns_of_Worship_for_Dwight_${TS}.zip"

( cd "$STAGE" && zip -r -X "$ZIPFILE" . ) 2>&1 | tee -a "$LOGFILE"
typeset -i RC=$?

rm -rf "$STAGE"

if [[ $RC -eq 0 ]]; then
  msg "Done. Zip ready at: $ZIPFILE" "Listo. El archivo zip esta en: $ZIPFILE"
else
  msg "FAILED (zip exit code $RC)." "FALLO (codigo de salida de zip $RC)."
fi

log "See: $LOGFILE"
exit $RC
