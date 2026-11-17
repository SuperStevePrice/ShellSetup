#!/usr/bin/env ksh
#-----------------------------------------------------------------------------
# process_new_poem.ksh
#
# One-step processing for a new poem recording headed into Steve's Favorite
# Poems: trims trailing silence off the end, then loudness-matches it
# against a reference track (default: Ozymandias), producing one finished
# MP3 ready to drop into FavoritePoems/Recordings/Final and hand to Claude
# Code for tagging/import.
#
# Usage:
#   process_new_poem.ksh -i RAW_INPUT [-r REFERENCE.mp3] [-o OUTPUT.mp3] \
#                         [-t THRESHOLD_DB] [-p] [-s]
#
# Options:
#   -i FILE   Raw recording to process (any format ffmpeg reads -- m4a, wav,
#             mp3, etc.)
#   -r FILE   Reference track to match loudness against (default:
#             ~/Documents/FavoritePoems/Recordings/Final/Ozymandias.mp3)
#   -o FILE   Final output MP3 (default: same base name as -i, .mp3, placed
#             in ~/Documents/FavoritePoems/Recordings/Final/)
#   -t DB     Silence threshold in dB for trimming (default: -35)
#   -p        Play the finished result afterward (afplay)
#   -s        Spanish status messages instead of English
#   -h        Help
#-----------------------------------------------------------------------------

typeset INPUT=""
typeset REFERENCE="$HOME/Documents/FavoritePoems/Recordings/Final/Ozymandias.mp3"
typeset OUTPUT=""
typeset THRESHOLD="-35"
typeset DO_PLAY=0
typeset SPANISH=0

while getopts "i:r:o:t:psh" opt; do
  case $opt in
    i) INPUT="$OPTARG" ;;
    r) REFERENCE="$OPTARG" ;;
    o) OUTPUT="$OPTARG" ;;
    t) THRESHOLD="$OPTARG" ;;
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
typeset LOGFILE="$HOME/logs/process_new_poem.$(date +%Y%m%d_%H%M%S).log"

extract_field() {
  typeset json="$1" field="$2"
  print "$json" | grep "\"${field}\"" | head -1 | sed -E 's/.*"'"${field}"'"[[:space:]]*:[[:space:]]*"?(-?[0-9.]+)"?.*/\1/'
}

main() {
  if [[ -z "$INPUT" ]]; then
    msg "Error: give a raw input file with -i. Use -h for help." \
        "Error: indica un archivo de entrada con -i. Usa -h para ayuda."
    return 1
  fi
  if [[ ! -f "$INPUT" ]]; then
    msg "Error: file not found: $INPUT" "Error: no se encontró el archivo: $INPUT"
    return 1
  fi
  if [[ ! -f "$REFERENCE" ]]; then
    msg "Error: reference file not found: $REFERENCE" \
        "Error: no se encontró el archivo de referencia: $REFERENCE"
    return 1
  fi
  if ! command -v ffmpeg >/dev/null 2>&1; then
    msg "Error: ffmpeg not found." "Error: no se encontró ffmpeg."
    return 1
  fi

  if [[ -z "$OUTPUT" ]]; then
    typeset base
    base=$(basename "${INPUT%.*}")
    mkdir -p "$HOME/Documents/FavoritePoems/Recordings/Final"
    OUTPUT="$HOME/Documents/FavoritePoems/Recordings/Final/${base}.mp3"
  fi

  typeset WORK_DIR
  WORK_DIR=$(mktemp -d)
  typeset TRIMMED="$WORK_DIR/trimmed.mp3"

  msg "Step 1: trimming trailing silence..." "Paso 1: recortando el silencio final..."
  msg "  Input:     $INPUT" "  Entrada:   $INPUT"
  msg "  Threshold: ${THRESHOLD} dB" "  Umbral:    ${THRESHOLD} dB"

  ffmpeg -y -i "$INPUT" \
    -af "areverse,silenceremove=start_periods=1:start_duration=0.1:start_threshold=${THRESHOLD}dB,areverse" \
    -map_metadata 0 -id3v2_version 3 \
    "$TRIMMED" 2>&1 | grep -v "^ffmpeg version\|^  built\|^  configuration\|^  lib"

  if [[ ! -f "$TRIMMED" ]]; then
    msg "Error: trimming step failed -- no output produced." \
        "Error: falló el paso de recorte -- no se produjo salida."
    rm -rf "$WORK_DIR"
    return 1
  fi

  msg "" ""
  msg "Step 2: loudness-matching against reference..." \
      "Paso 2: ajustando el volumen con referencia..."
  msg "  Reference: $REFERENCE" "  Referencia: $REFERENCE"
  msg "  Output:    $OUTPUT" "  Salida:    $OUTPUT"
  msg "" ""

  typeset ref_json
  ref_json=$(ffmpeg -i "$REFERENCE" -af loudnorm=I=-16:TP=-1.5:LRA=11:print_format=json -f null - 2>&1)
  typeset REF_I
  REF_I=$(extract_field "$ref_json" "input_i")

  typeset in_json
  in_json=$(ffmpeg -i "$TRIMMED" -af loudnorm=I=-16:TP=-1.5:LRA=11:print_format=json -f null - 2>&1)
  typeset IN_I IN_TP IN_LRA IN_THRESH
  IN_I=$(extract_field "$in_json" "input_i")
  IN_TP=$(extract_field "$in_json" "input_tp")
  IN_LRA=$(extract_field "$in_json" "input_lra")
  IN_THRESH=$(extract_field "$in_json" "input_thresh")

  if [[ -z "$REF_I" || -z "$IN_I" ]]; then
    msg "Error: couldn't measure loudness of one of the files." \
        "Error: no se pudo medir el volumen de uno de los archivos."
    rm -rf "$WORK_DIR"
    return 1
  fi

  ffmpeg -y -i "$TRIMMED" \
    -af "loudnorm=I=${REF_I}:TP=-1.5:LRA=11:measured_I=${IN_I}:measured_TP=${IN_TP}:measured_LRA=${IN_LRA}:measured_thresh=${IN_THRESH}:linear=true" \
    -map_metadata 0 -id3v2_version 3 \
    "$OUTPUT" 2>&1 | grep -v "^ffmpeg version\|^  built\|^  configuration\|^  lib"

  rm -rf "$WORK_DIR"

  if [[ ! -f "$OUTPUT" ]]; then
    msg "Error: loudness-matching step failed -- no output produced." \
        "Error: falló el paso de ajuste de volumen -- no se produjo salida."
    return 1
  fi

  typeset orig_dur new_dur
  orig_dur=$(ffprobe -v quiet -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$INPUT")
  new_dur=$(ffprobe -v quiet -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$OUTPUT")

  msg "" ""
  msg "Done. Original duration: ${orig_dur}s -> Finished duration: ${new_dur}s" \
      "Listo. Duración original: ${orig_dur}s -> Duración final: ${new_dur}s"
  msg "Finished file: $OUTPUT" "Archivo terminado: $OUTPUT"

  if [[ $DO_PLAY -eq 1 ]] && command -v afplay >/dev/null 2>&1; then
    msg "" ""
    msg "Playing finished result..." "Reproduciendo el resultado final..."
    afplay "$OUTPUT"
  fi

  msg "" ""
  msg "See: $LOGFILE" "Ver: $LOGFILE"
}

main 2>&1 | tee -a "$LOGFILE"
