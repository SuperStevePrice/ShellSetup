#!/usr/bin/env ksh
#-----------------------------------------------------------------------------
# match_loudness.ksh
#
# Measures the loudness of a reference mp3 (e.g. one of your existing
# ElevenLabs-voiced tracks) and normalizes an input mp3 (e.g. your own
# Sheridan's Ride recording) to match it as closely as possible, using
# ffmpeg's two-pass loudnorm filter (EBU R128 loudness, not just a raw
# amplitude/dB bump -- this matches how loud things actually SOUND).
#
# Writes to a NEW output file so your original recording is untouched; you
# can audition the result (with -p) before deciding to swap it in.
#
# Preserves existing ID3 tags on the output file.
#
# Usage:
#   match_loudness.ksh -r REFERENCE.mp3 -i INPUT.mp3 [-o OUTPUT.mp3] [-p] [-s]
#
# Options:
#   -r FILE   Reference mp3 whose loudness you want to match (required)
#   -i FILE   Input mp3 to adjust, e.g. your own recording (required)
#   -o FILE   Output mp3 path (default: INPUT with "_matched" before .mp3)
#   -p        Play the result with afplay once it's done
#   -s        Spanish status messages instead of English
#   -h        Help
#
# Requires: ffmpeg (brew install ffmpeg if not already present)
#-----------------------------------------------------------------------------

typeset REF_FILE=""
typeset IN_FILE=""
typeset OUT_FILE=""
typeset DO_PLAY=0
typeset SPANISH=0

while getopts "r:i:o:psh" opt; do
  case $opt in
    r) REF_FILE="$OPTARG" ;;
    i) IN_FILE="$OPTARG" ;;
    o) OUT_FILE="$OPTARG" ;;
    p) DO_PLAY=1 ;;
    s) SPANISH=1 ;;
    h)
      sed -n '2,24p' "$0"
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
typeset LOGFILE="$HOME/logs/match_loudness.$(date +%Y%m%d_%H%M%S).log"

extract_field() {
  # extract_field "jsonfile" "fieldname"
  grep "\"$2\"" "$1" | sed -E 's/.*: *"?(-?[0-9.]+)"?.*/\1/' | head -1
}

main() {
  if ! command -v ffmpeg >/dev/null 2>&1; then
    msg "Error: ffmpeg not found. Install it (e.g. 'brew install ffmpeg') and try again." \
        "Error: no se encontró ffmpeg. Instálalo (p. ej. 'brew install ffmpeg') e inténtalo de nuevo."
    return 1
  fi

  if [[ -z "$REF_FILE" || -z "$IN_FILE" ]]; then
    msg "Error: both -r REFERENCE and -i INPUT are required. Use -h for help." \
        "Error: se requieren -r REFERENCIA e -i ENTRADA. Usa -h para ayuda."
    return 1
  fi

  if [[ ! -f "$REF_FILE" ]]; then
    msg "Error: reference file not found: $REF_FILE" \
        "Error: no se encontró el archivo de referencia: $REF_FILE"
    return 1
  fi

  if [[ ! -f "$IN_FILE" ]]; then
    msg "Error: input file not found: $IN_FILE" \
        "Error: no se encontró el archivo de entrada: $IN_FILE"
    return 1
  fi

  if [[ -z "$OUT_FILE" ]]; then
    OUT_FILE="${IN_FILE%.mp3}_matched.mp3"
  fi

  typeset WORK_DIR=$(mktemp -d)
  typeset ref_json="$WORK_DIR/ref.json"
  typeset in_json="$WORK_DIR/in.json"

  msg "Measuring reference loudness: $REF_FILE" \
      "Midiendo la sonoridad de referencia: $REF_FILE"
  ffmpeg -nostdin -y -i "$REF_FILE" \
    -af loudnorm=I=-16:TP=-1.5:LRA=11:print_format=json \
    -f null - 2> "$ref_json"

  typeset REF_I=$(extract_field "$ref_json" "input_i")

  if [[ -z "$REF_I" ]]; then
    msg "Error: couldn't measure reference loudness. Aborting." \
        "Error: no se pudo medir la sonoridad de referencia. Abortando."
    rm -rf "$WORK_DIR"
    return 1
  fi

  msg "Reference integrated loudness: ${REF_I} LUFS" \
      "Sonoridad integrada de referencia: ${REF_I} LUFS"

  msg "Measuring input loudness: $IN_FILE" \
      "Midiendo la sonoridad de entrada: $IN_FILE"
  ffmpeg -nostdin -y -i "$IN_FILE" \
    -af loudnorm=I=-16:TP=-1.5:LRA=11:print_format=json \
    -f null - 2> "$in_json"

  typeset IN_I=$(extract_field "$in_json" "input_i")
  typeset IN_TP=$(extract_field "$in_json" "input_tp")
  typeset IN_LRA=$(extract_field "$in_json" "input_lra")
  typeset IN_THRESH=$(extract_field "$in_json" "input_thresh")

  if [[ -z "$IN_I" || -z "$IN_TP" || -z "$IN_LRA" || -z "$IN_THRESH" ]]; then
    msg "Error: couldn't measure input loudness. Aborting." \
        "Error: no se pudo medir la sonoridad de entrada. Abortando."
    rm -rf "$WORK_DIR"
    return 1
  fi

  msg "Input integrated loudness: ${IN_I} LUFS -- normalizing to match reference..." \
      "Sonoridad integrada de entrada: ${IN_I} LUFS -- normalizando para igualar la referencia..."

  typeset tmpout="$WORK_DIR/out.mp3"

  ffmpeg -nostdin -y -i "$IN_FILE" \
    -af "loudnorm=I=${REF_I}:TP=-1.5:LRA=11:measured_I=${IN_I}:measured_TP=${IN_TP}:measured_LRA=${IN_LRA}:measured_thresh=${IN_THRESH}:linear=true" \
    -map_metadata 0 -id3v2_version 3 \
    -c:a libmp3lame -q:a 2 \
    "$tmpout"

  if [[ $? -eq 0 && -f "$tmpout" ]]; then
    mv "$tmpout" "$OUT_FILE"
    msg "Done. Loudness-matched file written to: $OUT_FILE" \
        "Listo. Archivo con sonoridad igualada escrito en: $OUT_FILE"
  else
    msg "Error: ffmpeg normalization failed. Nothing written." \
        "Error: falló la normalización con ffmpeg. No se escribió nada."
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
