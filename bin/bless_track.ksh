#!/bin/ksh
#
# bless_track.ksh — replace the AUDIO in an existing, fully-tagged MP3
# with new audio (e.g. a Demucs/mixdown_stems enhanced version), while
# keeping the original's metadata (artist/album/title/attributions) and
# embedded artwork. The original file is backed up first, then the same
# filename is overwritten in place -- so Apple Music's library entry
# (lyrics, play count, playlist membership) stays attached to it.
#
# Usage:
#   bless_track.ksh [-s] NEW_AUDIO ORIGINAL_MP3
#
#   -s   Spanish status messages
#   -h   show this help
#
# NEW_AUDIO    the new audio (wav or mp3) -- e.g. mixdown.mp3
# ORIGINAL_MP3 the existing tagged MP3 in your Music library whose
#              filename you want to keep (its tags/artwork are reused;
#              its audio is replaced)
#
# A backup of the original is written alongside it as:
#   <original name> (original backup).mp3
#
# Requires: ffmpeg (brew install ffmpeg if you don't have it).

typeset SPANISH=0
typeset SCRIPT_NAME="bless_track"
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
      msg "Usage: $0 [-s] NEW_AUDIO ORIGINAL_MP3" \
          "Uso: $0 [-s] AUDIO_NUEVO MP3_ORIGINAL"
      exit 0
      ;;
    *) exit 1 ;;
  esac
done
shift $((OPTIND - 1))

log "=== $SCRIPT_NAME started $(date) ==="

typeset NEW_AUDIO="$1"
typeset ORIGINAL="$2"

if ! command -v ffmpeg >/dev/null 2>&1; then
  msg "ERROR: ffmpeg not found. Install it with: brew install ffmpeg" \
      "ERROR: no se encontro ffmpeg. Instalelo con: brew install ffmpeg"
  log "See: $LOGFILE"
  exit 1
fi

if [[ -z "$NEW_AUDIO" || ! -f "$NEW_AUDIO" ]]; then
  msg "ERROR: new audio file not found: $NEW_AUDIO" \
      "ERROR: no se encontro el archivo de audio nuevo: $NEW_AUDIO"
  log "See: $LOGFILE"
  exit 1
fi

if [[ -z "$ORIGINAL" || ! -f "$ORIGINAL" ]]; then
  msg "ERROR: original MP3 not found: $ORIGINAL" \
      "ERROR: no se encontro el MP3 original: $ORIGINAL"
  log "See: $LOGFILE"
  exit 1
fi

typeset DIR="${ORIGINAL%/*}"
typeset BASE="${ORIGINAL##*/}"
typeset STEM="${BASE%.*}"
typeset BACKUP="$DIR/$STEM (original backup).mp3"
typeset TMPFILE="$DIR/.${STEM}.bless_tmp.mp3"

msg "New audio:     $NEW_AUDIO" "Audio nuevo:     $NEW_AUDIO"
msg "Original MP3:  $ORIGINAL" "MP3 original:     $ORIGINAL"
msg "Backup to:     $BACKUP" "Respaldo en:      $BACKUP"

# Build a new MP3: audio from NEW_AUDIO, tags + embedded artwork from ORIGINAL.
ffmpeg -y -i "$NEW_AUDIO" -i "$ORIGINAL" \
  -map 0:a:0 -map 1:v? \
  -c:a libmp3lame -q:a 2 \
  -c:v copy \
  -map_metadata 1 \
  -id3v2_version 3 \
  "$TMPFILE" 2>&1 | tee -a "$LOGFILE"
typeset -i RC=$?

if [[ $RC -ne 0 ]]; then
  msg "FAILED building tagged MP3 (ffmpeg exit code $RC). Original left untouched." \
      "FALLO al crear el MP3 con etiquetas (codigo de salida de ffmpeg $RC). El original no fue modificado."
  rm -f "$TMPFILE"
  log "See: $LOGFILE"
  exit $RC
fi

cp "$ORIGINAL" "$BACKUP"
mv "$TMPFILE" "$ORIGINAL"

msg "Done. Original backed up to: $BACKUP" "Listo. Original respaldado en: $BACKUP"
msg "New audio is now in place at: $ORIGINAL" "El audio nuevo ya esta en: $ORIGINAL"
msg "In Music, select the track and use File > Library > Update (or re-add it) if it doesn't refresh on its own." \
    "En Music, seleccione la pista y use Archivo > Biblioteca > Actualizar (o vuelva a agregarla) si no se actualiza sola."

log "See: $LOGFILE"
