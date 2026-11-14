#!/bin/ksh
#
# bless_album.ksh — for every enhanced track in NEW_DIR, find the matching
# original (by filename, ignoring extension) in one or more ORIGINAL_DIRs,
# and replace that original's AUDIO with the enhanced version while keeping
# its tags and embedded artwork. The original is backed up first. Works
# like bless_track.ksh, but for a whole album across one or more folders
# in one pass.
#
# Usage:
#   bless_album.ksh [-s] NEW_DIR ORIGINAL_DIR [ORIGINAL_DIR2 ...]
#
#   -s   Spanish status messages
#   -h   show this help
#
# NEW_DIR        folder of enhanced tracks, e.g. ~/Downloads/mp3_backup
#                (matched by filename stem, e.g. "Morning Has Broken.mp3")
# ORIGINAL_DIR   one or more folders containing the real original audio
#                files to replace (.m4a or .mp3) -- e.g. both your
#                Swinsian copy and your Dropbox copy
#
# For each match, a backup is written alongside the original as:
#   <name> (original backup).<ext>
# and the original filename is then overwritten with a new file carrying
# the enhanced audio plus the original's tags/artwork. m4a originals are
# re-encoded to AAC (to stay a valid m4a); mp3 originals stay mp3.
#
# Tracks in NEW_DIR with no matching original in a given ORIGINAL_DIR are
# skipped for that folder (e.g. a track that only exists in one location).
#
# Requires: ffmpeg (brew install ffmpeg if you don't have it).

typeset SPANISH=0
typeset SCRIPT_NAME="bless_album"
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

while getopts "sh" opt; do
  case $opt in
    s) SPANISH=1 ;;
    h)
      msg "Usage: $0 [-s] NEW_DIR ORIGINAL_DIR [ORIGINAL_DIR2 ...]" \
          "Uso: $0 [-s] DIRECTORIO_NUEVO DIRECTORIO_ORIGINAL [DIRECTORIO_ORIGINAL2 ...]"
      exit 0
      ;;
    *) exit 1 ;;
  esac
done
shift $((OPTIND - 1))

log "=== $SCRIPT_NAME started $(date) ==="

if ! command -v ffmpeg >/dev/null 2>&1; then
  msg "ERROR: ffmpeg not found. Install it with: brew install ffmpeg" \
      "ERROR: no se encontro ffmpeg. Instalelo con: brew install ffmpeg"
  log "See: $LOGFILE"
  exit 1
fi

typeset NEW_DIR="$1"
shift

if [[ -z "$NEW_DIR" || ! -d "$NEW_DIR" ]]; then
  msg "ERROR: give the enhanced-tracks folder first, then one or more original folders." \
      "ERROR: indique primero la carpeta de pistas mejoradas, luego una o mas carpetas originales."
  log "See: $LOGFILE"
  exit 1
fi

if [[ $# -eq 0 ]]; then
  msg "ERROR: give at least one ORIGINAL_DIR to update." \
      "ERROR: indique al menos un DIRECTORIO_ORIGINAL para actualizar."
  log "See: $LOGFILE"
  exit 1
fi

typeset -i TOTAL_OK=0
typeset -i TOTAL_SKIP=0
typeset -i TOTAL_FAIL=0

for ORIGINAL_DIR in "$@"; do
  if [[ ! -d "$ORIGINAL_DIR" ]]; then
    msg "ERROR: directory not found, skipping: $ORIGINAL_DIR" \
        "ERROR: directorio no encontrado, omitiendo: $ORIGINAL_DIR"
    continue
  fi

  msg "=== Updating folder: $ORIGINAL_DIR ===" "=== Actualizando carpeta: $ORIGINAL_DIR ==="

  for orig in "$ORIGINAL_DIR"/*.m4a "$ORIGINAL_DIR"/*.mp3; do
    [[ -f "$orig" ]] || continue

    typeset base="${orig##*/}"
    typeset stem="${base%.*}"
    typeset ext="${base##*.}"
    typeset new="$NEW_DIR/$stem.mp3"

    if [[ ! -f "$new" ]]; then
      msg "  Skipping (no enhanced version found): $stem" \
          "  Omitiendo (no se encontro version mejorada): $stem"
      TOTAL_SKIP=$((TOTAL_SKIP + 1))
      continue
    fi

    typeset codec outext
    if [[ "$ext" == "m4a" ]]; then
      codec="aac"
      outext="m4a"
    else
      codec="libmp3lame"
      outext="mp3"
    fi

    typeset backup="$ORIGINAL_DIR/$stem (original backup).$ext"
    typeset tmp="$ORIGINAL_DIR/.${stem}.bless_tmp.${outext}"

    msg "  Blessing: $stem" "  Transformando: $stem"

    ffmpeg -y -i "$new" -i "$orig" \
      -map 0:a:0 -map 1:v? \
      -c:a "$codec" -b:a 256k \
      -c:v copy \
      -map_metadata 1 \
      "$tmp" 2>&1 | tee -a "$LOGFILE"
    typeset -i RC=$?

    if [[ $RC -ne 0 ]]; then
      msg "    FAILED (ffmpeg exit code $RC). Original left untouched." \
          "    FALLO (codigo de salida de ffmpeg $RC). El original no fue modificado."
      rm -f "$tmp"
      TOTAL_FAIL=$((TOTAL_FAIL + 1))
      continue
    fi

    cp "$orig" "$backup"
    mv "$tmp" "$orig"
    TOTAL_OK=$((TOTAL_OK + 1))
  done
done

msg "Done. $TOTAL_OK blessed, $TOTAL_SKIP skipped (no match), $TOTAL_FAIL failed." \
    "Listo. $TOTAL_OK transformados, $TOTAL_SKIP omitidos (sin coincidencia), $TOTAL_FAIL fallidos."

log "See: $LOGFILE"
