#!/bin/ksh
#
# mixdown_stems.ksh — take a Demucs stems folder (vocals.wav, drums.wav,
# bass.wav, other.wav) and build a quick pseudo-stereo mixdown with ffmpeg,
# so you can A/B it against the original recording before deciding whether
# to send the "enhanced" version instead.
#
# Usage:
#   mixdown_stems.ksh [-s] [-r] [-w] [-o OUTFILE] STEMS_DIR
#
#   -s          Spanish status messages
#   -r          add a touch of reverb (room ambience) to the mix
#   -w          WAV only -- skip creating the MP3 copy
#   -o OUTFILE  output WAV file (default: STEMS_DIR/<track name>.wav,
#               using the stems folder's own name as the track name);
#               the MP3 copy gets the same name with a .mp3 extension
#   -h          show this help
#
# STEMS_DIR is the per-track folder Demucs created, e.g.:
#   ~/Desktop/stems/htdemucs/Leonard_Cohen_track/
# containing some subset of vocals.wav / drums.wav / bass.wav / other.wav.
# Missing stems are simply skipped.
#
# Default placement (a reasonable starting "pseudo-stereo" spread):
#   vocals  -> center
#   other   -> slightly left   (guitar/accordion/keys bucket)
#   bass    -> center, mostly mono (bass doesn't benefit from hard panning)
#   drums   -> slightly right
#
# Requires: ffmpeg (brew install ffmpeg if you don't have it).

typeset SPANISH=0
typeset REVERB=0
typeset WAVONLY=0
typeset OUTFILE=""
typeset STEMS_DIR=""
typeset SCRIPT_NAME="mixdown_stems"
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

while getopts "srwo:h" opt; do
  case $opt in
    s) SPANISH=1 ;;
    r) REVERB=1 ;;
    w) WAVONLY=1 ;;
    o) OUTFILE="$OPTARG" ;;
    h)
      msg "Usage: $0 [-s] [-r] [-w] [-o OUTFILE] STEMS_DIR" \
          "Uso: $0 [-s] [-r] [-w] [-o ARCHIVO_SALIDA] DIRECTORIO_DE_STEMS"
      exit 0
      ;;
    *) exit 1 ;;
  esac
done
shift $((OPTIND - 1))

STEMS_DIR="$1"

log "=== $SCRIPT_NAME started $(date) ==="

if ! command -v ffmpeg >/dev/null 2>&1; then
  msg "ERROR: ffmpeg not found. Install it with: brew install ffmpeg" \
      "ERROR: no se encontro ffmpeg. Instalelo con: brew install ffmpeg"
  log "See: $LOGFILE"
  exit 1
fi

if [[ -z "$STEMS_DIR" || ! -d "$STEMS_DIR" ]]; then
  msg "ERROR: give the path to a Demucs stems folder, e.g.:
  $0 ~/Desktop/stems/htdemucs/My_Track" \
      "ERROR: indique la ruta a una carpeta de stems de Demucs, por ejemplo:
  $0 ~/Desktop/stems/htdemucs/My_Track"
  log "See: $LOGFILE"
  exit 1
fi

if [[ -z "$OUTFILE" ]]; then
  # Default output name = the track name (the stems folder's own name),
  # e.g. .../htdemucs/Morning Has Broken/  ->  Morning Has Broken.wav
  typeset TRACK_NAME="${STEMS_DIR##*/}"
  OUTFILE="$STEMS_DIR/${TRACK_NAME}.wav"
fi

# stem_name : L_gain R_gain  (hand-tuned starting spread -- adjust to taste)
# no_vocals is what Demucs's 2-stem split (--two-stems=vocals) calls the
# instrumental stem instead of "other" -- panned the same as "other".
typeset -A PAN_L
typeset -A PAN_R
PAN_L[vocals]=0.80    ; PAN_R[vocals]=0.80
PAN_L[other]=0.90     ; PAN_R[other]=0.30
PAN_L[no_vocals]=0.90 ; PAN_R[no_vocals]=0.30
PAN_L[bass]=0.70      ; PAN_R[bass]=0.70
PAN_L[drums]=0.30     ; PAN_R[drums]=0.90

typeset -a INPUTS
typeset -a FILTERS
typeset -a LABELS
typeset -i N=0

for stem in vocals other no_vocals bass drums; do
  f="$STEMS_DIR/$stem.wav"
  if [[ -f "$f" ]]; then
    INPUTS+=( -i "$f" )
    FILTERS+=( "[${N}:a]pan=stereo|c0=${PAN_L[$stem]}*c0|c1=${PAN_R[$stem]}*c0[s${N}]" )
    LABELS+=( "[s${N}]" )
    msg "Including stem: $stem" "Incluyendo stem: $stem"
    N=$((N + 1))
  fi
done

if [[ $N -eq 0 ]]; then
  msg "ERROR: no vocals.wav/drums.wav/bass.wav/other.wav/no_vocals.wav found in: $STEMS_DIR" \
      "ERROR: no se encontraron vocals.wav/drums.wav/bass.wav/other.wav/no_vocals.wav en: $STEMS_DIR"
  log "See: $LOGFILE"
  exit 1
fi

typeset FILTERSTR
FILTERSTR=$(IFS=';'; print -- "${FILTERS[*]}")
typeset LABELSTR
LABELSTR=$(IFS=''; print -- "${LABELS[*]}")

typeset MIXCHAIN="${FILTERSTR};${LABELSTR}amix=inputs=${N}:duration=longest:normalize=0[mixed]"

typeset FINAL_LABEL="[mixed]"
if [[ $REVERB -eq 1 ]]; then
  MIXCHAIN="${MIXCHAIN};[mixed]aecho=0.8:0.7:40:0.25[reverbed]"
  FINAL_LABEL="[reverbed]"
  msg "Adding light reverb." "Agregando un poco de reverberacion."
fi

msg "Mixing $N stem(s) from: $STEMS_DIR" "Mezclando $N stem(s) desde: $STEMS_DIR"
msg "Output: $OUTFILE" "Salida: $OUTFILE"

ffmpeg -y "${INPUTS[@]}" -filter_complex "$MIXCHAIN" -map "$FINAL_LABEL" -ac 2 "$OUTFILE" 2>&1 | tee -a "$LOGFILE"
typeset -i RC=$?

if [[ $RC -eq 0 ]]; then
  msg "Done. Mixdown written to: $OUTFILE" "Listo. Mezcla escrita en: $OUTFILE"

  if [[ $WAVONLY -eq 0 ]]; then
    typeset MP3FILE="${OUTFILE%.wav}.mp3"
    msg "Creating MP3 copy: $MP3FILE" "Creando copia en MP3: $MP3FILE"
    ffmpeg -y -i "$OUTFILE" -q:a 2 "$MP3FILE" 2>&1 | tee -a "$LOGFILE"
    typeset -i MP3RC=$?
    if [[ $MP3RC -eq 0 ]]; then
      msg "MP3 ready: $MP3FILE" "MP3 listo: $MP3FILE"
    else
      msg "MP3 conversion FAILED (ffmpeg exit code $MP3RC)." \
          "La conversion a MP3 FALLO (codigo de salida de ffmpeg $MP3RC)."
      RC=$MP3RC
    fi
  fi
else
  msg "FAILED (ffmpeg exit code $RC)." "FALLO (codigo de salida de ffmpeg $RC)."
fi

log "See: $LOGFILE"
exit $RC
