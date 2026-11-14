#!/bin/ksh
#
# run_kingdom_come.ksh — one-shot: copies process_album.ksh into your SS
# bin, deploys it with setup.ksh, then runs it against the "Your Kingdom
# Come: Songs of Worship" album with the 2-stem split.
#
# Usage:
#   run_kingdom_come.ksh [-s]
#
#   -s   Spanish status messages
#   -h   show this help
#
# Expects process_album.ksh to be sitting in the SAME folder as this
# script (e.g. both just downloaded into ~/Downloads together).

typeset SPANISH=0
typeset SCRIPT_NAME="run_kingdom_come"
typeset TS=$(date +%Y%m%d_%H%M%S)
typeset LOGDIR="$HOME/logs"
typeset LOGFILE="$LOGDIR/${SCRIPT_NAME}.${TS}.log"

typeset ALBUM_DIR="/Users/steve/Music/Music/Media.localized/Music/Steve Price/Your Kingdom Come_ Songs of Worship"
typeset SS_BIN="$HOME/Projects/SS/bin"
typeset SS_ROOT="$HOME/Projects/SS"

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
      msg "Usage: $0 [-s]" "Uso: $0 [-s]"
      exit 0
      ;;
    *) exit 1 ;;
  esac
done

log "=== $SCRIPT_NAME started $(date) ==="

# Locate process_album.ksh next to this script, wherever it was run from.
typeset SELF_DIR
case "$0" in
  /*) SELF_DIR="${0%/*}" ;;
  *)  SELF_DIR="$(cd "$(dirname "$0")" && pwd)" ;;
esac
typeset SRC_SCRIPT="$SELF_DIR/process_album.ksh"

if [[ ! -f "$SRC_SCRIPT" ]]; then
  msg "ERROR: process_album.ksh not found next to this script in: $SELF_DIR
Download it into the same folder as this script and try again." \
      "ERROR: no se encontro process_album.ksh junto a este script en: $SELF_DIR
Descarguelo en la misma carpeta que este script e intente de nuevo."
  log "See: $LOGFILE"
  exit 1
fi

if [[ ! -d "$SS_ROOT" ]]; then
  msg "ERROR: SS repo not found at: $SS_ROOT" \
      "ERROR: no se encontro el repositorio SS en: $SS_ROOT"
  log "See: $LOGFILE"
  exit 1
fi

if [[ ! -d "$ALBUM_DIR" ]]; then
  msg "ERROR: album folder not found at: $ALBUM_DIR" \
      "ERROR: no se encontro la carpeta del album en: $ALBUM_DIR"
  log "See: $LOGFILE"
  exit 1
fi

msg "Copying process_album.ksh into: $SS_BIN" "Copiando process_album.ksh a: $SS_BIN"
cp "$SRC_SCRIPT" "$SS_BIN/process_album.ksh" 2>&1 | tee -a "$LOGFILE"

msg "Deploying via setup.ksh" "Desplegando con setup.ksh"
( cd "$SS_ROOT" && ./setup.ksh ) 2>&1 | tee -a "$LOGFILE"
typeset -i SETUP_RC=$?

if [[ $SETUP_RC -ne 0 ]]; then
  msg "setup.ksh reported a problem (exit code $SETUP_RC)." \
      "setup.ksh reporto un problema (codigo $SETUP_RC)."
  log "See: $LOGFILE"
  exit $SETUP_RC
fi

if ! command -v process_album >/dev/null 2>&1; then
  msg "ERROR: 'process_album' still not found on PATH after deploy. Open a new terminal tab and retry." \
      "ERROR: 'process_album' sigue sin encontrarse en el PATH. Abra una nueva pestana de terminal e intente de nuevo."
  log "See: $LOGFILE"
  exit 1
fi

msg "Running process_album on: $ALBUM_DIR" "Ejecutando process_album en: $ALBUM_DIR"

typeset -a FLAGS
[[ $SPANISH -eq 1 ]] && FLAGS+=( -s )

process_album "${FLAGS[@]}" -2 "$ALBUM_DIR" 2>&1 | tee -a "$LOGFILE"
typeset -i RC=$?

msg "Done (process_album exit code $RC)." "Listo (codigo de salida de process_album $RC)."
log "See: $LOGFILE"
exit $RC
