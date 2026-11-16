#!/usr/bin/env ksh
#-----------------------------------------------------------------------------
# bump_volume.ksh
#
# Applies a simple percentage volume bump to an mp3 -- e.g. -g 1.03 for a 3%
# increase, -g 1.05 for 5%, -g 0.9 for a 10% reduction. Writes to a NEW file
# so the original is untouched, and preserves existing ID3 tags.
#
# Usage:
#   bump_volume.ksh -i INPUT.mp3 -g MULTIPLIER [-o OUTPUT.mp3] [-p] [-s]
#
# Options:
#   -i FILE        Input mp3 (required)
#   -g MULTIPLIER  Volume multiplier, e.g. 1.03 (+3%), 1.05 (+5%), 0.9 (-10%)
#                  (required)
#   -o FILE        Output mp3 path (default: INPUT with "_bumped" before .mp3)
#   -p             Play the result with afplay once it's done
#   -s             Spanish status messages instead of English
#   -h             Help
#
# Requires: ffmpeg
#-----------------------------------------------------------------------------

typeset IN_FILE=""
typeset GAIN=""
typeset OUT_FILE=""
typeset DO_PLAY=0
typeset SPANISH=0

while getopts "i:g:o:psh" opt; do
  case $opt in
    i) IN_FILE="$OPTARG" ;;
    g) GAIN="$OPTARG" ;;
    o) OUT_FILE="$OPTARG" ;;
    p) DO_PLAY=1 ;;
    s) SPANISH=1 ;;
    h)
      sed -n '2,20p' "$0"
      exit 0
      ;;
    *)
      print -u2 "Unknown option. Use -h for help."
      exit 1
      ;;
  esac
done

msg() {
  if [[ $SPANISH -eq 1 ]]; then
    print "$2"
  else
    print "$1"
  fi
}

mkdir -p "$HOME/logs"
typeset LOGFILE="$HOME/logs/bump_volume.$(date +%Y%m%d_%H%M%S).log"

main() {
  if ! command -v ffmpeg >/dev/null 2>&1; then
    msg "Error: ffmpeg not found. Install it (e.g. 'brew install ffmpeg') and try again." \
        "Error: no se encontró ffmpeg. Instálalo (p. ej. 'brew install ffmpeg') e inténtalo de nuevo."
    return 1
  fi

  if [[ -z "$IN_FILE" || -z "$GAIN" ]]; then
    msg "Error: both -i INPUT and -g MULTIPLIER are required. Use -h for help." \
        "Error: se requieren -i ENTRADA y -g MULTIPLICADOR. Usa -h para ayuda."
    return 1
  fi

  if [[ ! -f "$IN_FILE" ]]; then
    msg "Error: input file not found: $IN_FILE" \
        "Error: no se encontró el archivo de entrada: $IN_FILE"
    return 1
  fi

  if [[ -z "$OUT_FILE" ]]; then
    OUT_FILE="${IN_FILE%.mp3}_bumped.mp3"
  fi

  msg "Applying volume multiplier ${GAIN} to: $IN_FILE" \
      "Aplicando multiplicador de volumen ${GAIN} a: $IN_FILE"

  typeset WORK_DIR=$(mktemp -d)
  typeset tmpout="$WORK_DIR/out.mp3"

  ffmpeg -nostdin -y -i "$IN_FILE" \
    -af "volume=${GAIN}" \
    -map_metadata 0 -id3v2_version 3 \
    -c:a libmp3lame -q:a 2 \
    "$tmpout"

  if [[ $? -eq 0 && -f "$tmpout" ]]; then
    mv "$tmpout" "$OUT_FILE"
    msg "Done. Adjusted file written to: $OUT_FILE" \
        "Listo. Archivo ajustado escrito en: $OUT_FILE"
  else
    msg "Error: ffmpeg adjustment failed. Nothing written." \
        "Error: falló el ajuste con ffmpeg. No se escribió nada."
    rm -rf "$WORK_DIR"
    return 1
  fi

  rm -rf "$WORK_DIR"

  if [[ $DO_PLAY -eq 1 ]]; then
    if command -v afplay >/dev/null 2>&1; then
      msg "Playing: $OUT_FILE" "Reproduciendo: $OUT_FILE"
      afplay "$OUT_FILE"
    else
      msg "Note: afplay not found, can't auto-play. Open the file manually to audition it." \
          "Nota: no se encontró afplay, no se puede reproducir automáticamente. Abre el archivo manualmente para escucharlo."
    fi
  fi

  msg "See: $LOGFILE" "Ver: $LOGFILE"
}

main 2>&1 | tee -a "$LOGFILE"
