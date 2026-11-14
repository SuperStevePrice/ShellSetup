#!/bin/ksh
#
# process_album.ksh — run an entire album folder through demucs_batch,
# then automatically run mixdown_stems on every resulting track, so you
# end up with a mixdown.wav/mixdown.mp3 per song without running the two
# tools by hand for each track.
#
# Usage:
#   process_album.ksh [-s] [-2] [-r] [-o OUTDIR] ALBUM_DIR
#
#   -s          Spanish status messages
#   -2          2-stem split (vocals + instrumental) instead of the
#               default 4-stem split -- better fit for solo voice+guitar
#   -r          add a touch of reverb in the mixdown step
#   -o OUTDIR   where demucs writes stems (default: ~/Desktop/stems)
#   -h          show this help
#
# Requires demucs_batch and mixdown_stems already installed and on PATH.

typeset SPANISH=0
typeset TWOSTEM=0
typeset REVERB=0
typeset OUTDIR="$HOME/Desktop/stems"
typeset ALBUM_DIR=""
typeset SCRIPT_NAME="process_album"
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

while getopts "s2ro:h" opt; do
  case $opt in
    s) SPANISH=1 ;;
    2) TWOSTEM=1 ;;
    r) REVERB=1 ;;
    o) OUTDIR="$OPTARG" ;;
    h)
      msg "Usage: $0 [-s] [-2] [-r] [-o OUTDIR] ALBUM_DIR" \
          "Uso: $0 [-s] [-2] [-r] [-o OUTDIR] DIRECTORIO_DEL_ALBUM"
      exit 0
      ;;
    *) exit 1 ;;
  esac
done
shift $((OPTIND - 1))

ALBUM_DIR="$1"

log "=== $SCRIPT_NAME started $(date) ==="

for cmd in demucs_batch mixdown_stems; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    msg "ERROR: '$cmd' not found on PATH. Install/deploy it first." \
        "ERROR: no se encontro '$cmd' en el PATH. Instalelo primero."
    log "See: $LOGFILE"
    exit 1
  fi
done

if [[ -z "$ALBUM_DIR" || ! -d "$ALBUM_DIR" ]]; then
  msg "ERROR: give the path to the album folder, e.g.:
  $0 ~/Music/.../MyAlbum" \
      "ERROR: indique la ruta a la carpeta del album, por ejemplo:
  $0 ~/Music/.../MiAlbum"
  log "See: $LOGFILE"
  exit 1
fi

typeset -a SEPARATE_FLAGS
[[ $SPANISH -eq 1 ]] && SEPARATE_FLAGS+=( -s )
[[ $TWOSTEM -eq 1 ]] && SEPARATE_FLAGS+=( -2 )

msg "Step 1: separating all tracks in: $ALBUM_DIR" "Paso 1: separando todas las pistas en: $ALBUM_DIR"

demucs_batch "${SEPARATE_FLAGS[@]}" -o "$OUTDIR" -d "$ALBUM_DIR" 2>&1 | tee -a "$LOGFILE"
typeset -i SEP_RC=$?

if [[ $SEP_RC -ne 0 ]]; then
  msg "demucs_batch reported a problem (exit code $SEP_RC) -- continuing to mix whatever succeeded." \
      "demucs_batch reporto un problema (codigo $SEP_RC) -- se continua mezclando lo que si se complet\u00f3."
fi

typeset -a MIX_FLAGS
[[ $SPANISH -eq 1 ]] && MIX_FLAGS+=( -s )
[[ $REVERB -eq 1 ]] && MIX_FLAGS+=( -r )

msg "Step 2: building mixdowns for each track" "Paso 2: generando la mezcla de cada pista"

typeset -i N=0
for trackdir in "$OUTDIR"/htdemucs/*/; do
  [[ -d "$trackdir" ]] || continue
  trackdir="${trackdir%/}"
  msg "Mixing: $trackdir" "Mezclando: $trackdir"
  mixdown_stems "${MIX_FLAGS[@]}" "$trackdir" 2>&1 | tee -a "$LOGFILE"
  N=$((N + 1))
done

msg "Done. Processed $N track(s). Stems and mixdowns are under: $OUTDIR/htdemucs" \
    "Listo. Se procesaron $N pista(s). Los stems y mezclas estan en: $OUTDIR/htdemucs"

log "See: $LOGFILE"
