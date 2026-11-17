#!/usr/bin/env ksh
#-----------------------------------------------------------------------------
# trim_trailing_silence.ksh
#
# Automatically trims trailing silence off the end of an audio file, using
# ffmpeg's silenceremove filter -- no manual waveform dragging needed.
#
# This only trims the END of the file. It leaves the beginning and the
# middle completely untouched, even if there are pauses between lines.
#
# Usage:
#   trim_trailing_silence.ksh -i INPUT.m4a [-o OUTPUT.mp3] [-t THRESHOLD_DB] [-p] [-s]
#
# Options:
#   -i FILE   Input audio file (any format ffmpeg reads -- m4a, mp3, wav, etc.)
#   -o FILE   Output file (default: INPUT with _trimmed inserted before the
#             extension, converted to .mp3 unless you give a different
#             extension explicitly)
#   -t DB     Silence threshold in dB (default: -35). More negative = only
#             treats quieter sound as "silence"; less negative = more
#             aggressive trimming.
#   -p        Play the trimmed result afterward (afplay)
#   -s        Spanish status messages instead of English
#   -h        Help
#-----------------------------------------------------------------------------

typeset INPUT=""
typeset OUTPUT=""
typeset THRESHOLD="-35"
typeset DO_PLAY=0
typeset SPANISH=0

while getopts "i:o:t:psh" opt; do
  case $opt in
    i) INPUT="$OPTARG" ;;
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
typeset LOGFILE="$HOME/logs/trim_trailing_silence.$(date +%Y%m%d_%H%M%S).log"

main() {
  if [[ -z "$INPUT" ]]; then
    msg "Error: give an input file with -i. Use -h for help." \
        "Error: indica un archivo de entrada con -i. Usa -h para ayuda."
    return 1
  fi
  if [[ ! -f "$INPUT" ]]; then
    msg "Error: file not found: $INPUT" "Error: no se encontró el archivo: $INPUT"
    return 1
  fi
  if ! command -v ffmpeg >/dev/null 2>&1; then
    msg "Error: ffmpeg not found." "Error: no se encontró ffmpeg."
    return 1
  fi

  if [[ -z "$OUTPUT" ]]; then
    typeset base="${INPUT%.*}"
    OUTPUT="${base}_trimmed.mp3"
  fi

  msg "Input:     $INPUT" "Entrada:   $INPUT"
  msg "Output:    $OUTPUT" "Salida:    $OUTPUT"
  msg "Threshold: ${THRESHOLD} dB" "Umbral:    ${THRESHOLD} dB"
  msg "" ""

  # reverse -> remove leading silence (which is now the trailing silence of
  # the original) -> reverse back. This trims ONLY the end.
  ffmpeg -y -i "$INPUT" \
    -af "areverse,silenceremove=start_periods=1:start_duration=0.1:start_threshold=${THRESHOLD}dB,areverse" \
    -map_metadata 0 -id3v2_version 3 \
    "$OUTPUT" 2>&1 | grep -v "^ffmpeg version\|^  built\|^  configuration\|^  lib"

  if [[ ! -f "$OUTPUT" ]]; then
    msg "Error: ffmpeg did not produce an output file." \
        "Error: ffmpeg no produjo un archivo de salida."
    return 1
  fi

  typeset orig_dur new_dur
  orig_dur=$(ffprobe -v quiet -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$INPUT")
  new_dur=$(ffprobe -v quiet -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$OUTPUT")

  msg "" ""
  msg "Original duration: ${orig_dur}s" "Duración original: ${orig_dur}s"
  msg "Trimmed duration:  ${new_dur}s" "Duración recortada: ${new_dur}s"

  if [[ $DO_PLAY -eq 1 ]] && command -v afplay >/dev/null 2>&1; then
    msg "Playing trimmed result..." "Reproduciendo el resultado recortado..."
    afplay "$OUTPUT"
  fi

  msg "" ""
  msg "See: $LOGFILE" "Ver: $LOGFILE"
}

main 2>&1 | tee -a "$LOGFILE"
