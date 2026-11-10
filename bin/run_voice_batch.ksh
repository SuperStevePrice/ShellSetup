#!/usr/bin/env ksh
#-----------------------------------------------------------------------------
# run_voice_batch.ksh
#
# One-shot runner:
#   1. Sorts your .txt files into english/ and german/ subfolders
#      (if not already sorted; leaves already-sorted files alone)
#   2. Runs eleven_tts_batch.ksh twice: one voice for English, one for German
#
# Voice IDs are passed directly (-e / -g below) rather than looked up via
# the ElevenLabs API, because the /v1/voices and /v1/shared-voices
# endpoints require the "voices_read" permission, which is not grantable
# on every account/key tier (confirmed unavailable on this account as of
# 2026-11-09 -- the permission toggle is greyed out even on a brand-new
# key). Look voice_ids up once in the web UI (Voices > My Voices > the
# voice's ... menu > Copy Voice ID) and reuse them; they don't change.
#
# Requires: eleven_tts_batch.ksh in the same directory (or on PATH)
# Requires: ELEVENLABS_API_KEY set in your environment (used only by
#           eleven_tts_batch.ksh for the actual Text to Speech calls,
#           which only needs the "Text to Speech" permission -- that one
#           works fine on this account).
#
# Usage:
#   run_voice_batch.ksh [-e ENGLISH_VOICE_ID] [-g GERMAN_VOICE_ID] \
#                        [-i IN_DIR] [-o OUT_DIR] [-s] [-y]
#     -e  Voice ID for English files (default: Henry - American poetry)
#     -g  Voice ID for German files (default: Brian)
#     -i  Source directory holding your mixed .txt files
#         (default: ~/Documents/elevenLabsUploads)
#     -o  Output directory for .mp3 files (default: ~/Downloads)
#     -s  Spanish status messages
#     -y  Skip the dry-run confirmation (for scripted/non-interactive runs)
#
# SAFETY: if you run this with NEITHER -e NOR -g given (a bare invocation,
# or with only -i/-o/-s), it will NOT touch the API right away. It first
# lists every file that would actually be generated and which voice would
# be used, and asks you to confirm. Pass -e and/or -g explicitly (as a
# script calling this non-interactively would) and it skips the prompt,
# since naming the voice yourself is itself the confirmation. -y also
# skips the prompt, for when you're sure and want it to just go.
#-----------------------------------------------------------------------------

# Defaults resolved 2026-11-10 via Voices > My Voices > Copy Voice ID.
# Override with -e / -g if you ever switch voices.
#
# Henry is the standing default for English/American poetry (Whitman,
# Frost, etc.) -- confirmed 2026-11-10. Harry (Articulate British
# Storyteller) is reserved for Blake specifically and is no longer the
# default; pass him explicitly when you want him:
#   -e H538pP1BbhodCGiYVMKD
typeset ENGLISH_VOICE_ID="pVnrL6sighQX7hVz89cp"   # Henry - American poetry default
typeset GERMAN_VOICE_ID="Gubgw9l4dtIoQA9YZHgx"    # Brian (multilingual model handles German)

typeset IN_DIR="$HOME/Documents/elevenLabsUploads"
typeset OUT_DIR="$HOME/Downloads"
typeset SPANISH=0
typeset FORCE=0
typeset ENG_EXPLICIT=0
typeset GER_EXPLICIT=0
typeset SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
typeset BATCH="$SCRIPT_DIR/eleven_tts_batch.ksh"

while getopts "e:g:i:o:syh" opt; do
  case $opt in
    e) ENGLISH_VOICE_ID="$OPTARG"; ENG_EXPLICIT=1 ;;
    g) GERMAN_VOICE_ID="$OPTARG"; GER_EXPLICIT=1 ;;
    i) IN_DIR="$OPTARG" ;;
    o) OUT_DIR="$OPTARG" ;;
    s) SPANISH=1 ;;
    y) FORCE=1 ;;
    h)
      sed -n '2,33p' "$0"
      exit 0
      ;;
    *) exit 1 ;;
  esac
done

msg() {
  if [[ $SPANISH -eq 1 ]]; then print "$2"; else print "$1"; fi
}

if [[ -z "$ELEVENLABS_API_KEY" ]]; then
  msg "Error: \$ELEVENLABS_API_KEY not set." \
      "Error: \$ELEVENLABS_API_KEY no está definida."
  exit 1
fi

if [[ ! -x "$BATCH" ]]; then
  msg "Error: eleven_tts_batch.ksh not found or not executable at $BATCH" \
      "Error: no se encontró o no es ejecutable eleven_tts_batch.ksh en $BATCH"
  exit 1
fi

if [[ ! -d "$IN_DIR" ]]; then
  msg "Error: input directory not found: $IN_DIR" \
      "Error: no se encontró el directorio de entrada: $IN_DIR"
  exit 1
fi

#--- Step 1: sort files into english/ and german/ subfolders ---------------
typeset ENG_DIR="$IN_DIR/english"
typeset GER_DIR="$IN_DIR/german"
mkdir -p "$ENG_DIR" "$GER_DIR"

# Known German filenames (adjust this list if you add more German poems later)
typeset -A GERMAN_FILES
GERMAN_FILES[auferstehung_voll.txt]=1
GERMAN_FILES[bildnis_voll.txt]=1
GERMAN_FILES[BruderJakob.txt]=1
GERMAN_FILES[Das_himmlische_Leben.txt]=1
GERMAN_FILES[Der_Erlkönig.txt]=1
GERMAN_FILES[Der_Rabe_ASCII.txt]=1
GERMAN_FILES[grenadiere_voll.txt]=1
GERMAN_FILES[kuehlenacht_voll.txt]=1
GERMAN_FILES[lorelei_voll.txt]=1
GERMAN_FILES[Mahler_3_voll.txt]=1
GERMAN_FILES[panther_voll.txt]=1
GERMAN_FILES[prometheus_voll.txt]=1
GERMAN_FILES[schlaf_kindlein.txt]=1
GERMAN_FILES[guten_morgen.txt]=1

typeset moved_any=0
for f in "$IN_DIR"/*.txt; do
  [[ -f "$f" ]] || continue
  base=$(basename "$f")
  if [[ -n "${GERMAN_FILES[$base]}" ]]; then
    mv "$f" "$GER_DIR/"
    msg "  -> $base  [german]" "  -> $base  [aleman]"
  else
    mv "$f" "$ENG_DIR/"
    msg "  -> $base  [english]" "  -> $base  [ingles]"
  fi
  moved_any=1
done

if [[ $moved_any -eq 1 ]]; then
  msg "Sorted files into $ENG_DIR and $GER_DIR" \
      "Archivos ordenados en $ENG_DIR y $GER_DIR"
else
  msg "No unsorted .txt files found directly in $IN_DIR (already sorted, or empty)." \
      "No se encontraron archivos .txt sin ordenar directamente en $IN_DIR (ya ordenados, o vacío)."
fi

#--- Step 2: safety dry-run, only when NEITHER voice was given explicitly --
if [[ $ENG_EXPLICIT -eq 0 && $GER_EXPLICIT -eq 0 && $FORCE -eq 0 ]]; then
  msg "=== DRY RUN: no -e or -g given, so nothing has been generated yet ===" \
      "=== PRUEBA EN SECO: no se dio -e ni -g, así que no se ha generado nada todavía ==="

  typeset -i would_gen=0

  if [[ -n "$(ls -A "$ENG_DIR" 2>/dev/null)" ]]; then
    msg "English files -> voice_id=$ENGLISH_VOICE_ID (default: Henry)" \
        "Archivos en inglés -> voice_id=$ENGLISH_VOICE_ID (por defecto: Henry)"
    for f in "$ENG_DIR"/*.txt; do
      [[ -f "$f" ]] || continue
      base=$(basename "$f" .txt)
      if [[ -f "$OUT_DIR/$base.mp3" || -f "$OUT_DIR/${base}_part1.mp3" ]]; then
        msg "  [skip, mp3 exists] $base" "  [omitir, el mp3 ya existe] $base"
      else
        msg "  [WOULD GENERATE]    $base" "  [SE GENERARÍA]       $base"
        (( would_gen++ ))
      fi
    done
  fi

  if [[ -n "$(ls -A "$GER_DIR" 2>/dev/null)" ]]; then
    msg "German files -> voice_id=$GERMAN_VOICE_ID (default: Brian)" \
        "Archivos en alemán -> voice_id=$GERMAN_VOICE_ID (por defecto: Brian)"
    for f in "$GER_DIR"/*.txt; do
      [[ -f "$f" ]] || continue
      base=$(basename "$f" .txt)
      if [[ -f "$OUT_DIR/$base.mp3" || -f "$OUT_DIR/${base}_part1.mp3" ]]; then
        msg "  [skip, mp3 exists] $base" "  [omitir, el mp3 ya existe] $base"
      else
        msg "  [WOULD GENERATE]    $base" "  [SE GENERARÍA]       $base"
        (( would_gen++ ))
      fi
    done
  fi

  if [[ $would_gen -eq 0 ]]; then
    msg "Nothing would be generated -- every file already has an mp3. Exiting." \
        "No se generaría nada -- todos los archivos ya tienen mp3. Saliendo."
    exit 0
  fi

  msg "$would_gen file(s) above would be sent to the API using the voices shown." \
      "Los $would_gen archivo(s) de arriba se enviarían a la API usando las voces mostradas."
  msg "If that's not the voice you want for all of them, Ctrl-C now and re-run with -e/-g." \
      "Si esa no es la voz que quieres para todos, pulsa Ctrl-C ahora y vuelve a ejecutar con -e/-g."
  msg "Proceed? [y/N] " "¿Continuar? [y/N] "
  read -r REPLY
  case "$REPLY" in
    y|Y|yes|YES|si|Si|SI|s|S) ;;
    *)
      msg "Cancelled -- nothing was generated." "Cancelado -- no se generó nada."
      exit 0
      ;;
  esac
fi

#--- Step 3: run the batch TTS for each language ----------------------------
typeset extra_flag=""
[[ $SPANISH -eq 1 ]] && extra_flag="-s"

if [[ -n "$(ls -A "$ENG_DIR" 2>/dev/null)" ]]; then
  msg "--- Running English batch (voice_id=$ENGLISH_VOICE_ID) ---" \
      "--- Ejecutando lote en inglés (voice_id=$ENGLISH_VOICE_ID) ---"
  "$BATCH" -v "$ENGLISH_VOICE_ID" -i "$ENG_DIR" -o "$OUT_DIR" $extra_flag
fi

if [[ -n "$(ls -A "$GER_DIR" 2>/dev/null)" ]]; then
  msg "--- Running German batch (voice_id=$GERMAN_VOICE_ID) ---" \
      "--- Ejecutando lote en alemán (voice_id=$GERMAN_VOICE_ID) ---"
  "$BATCH" -v "$GERMAN_VOICE_ID" -i "$GER_DIR" -o "$OUT_DIR" $extra_flag
fi

msg "All done." "Todo listo."
#-------------------------------------------------------------------------------
# Last patched: 2026-11-10 -- Henry restored as English default; Harry now
# requires explicit -e; added dry-run confirmation for bare invocations.
#-- End of File ----------------------------------------------------------------
