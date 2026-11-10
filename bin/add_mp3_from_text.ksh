#!/bin/ksh
# add_mp3_from_text.ksh
#
# Universal tool for generating MP3s from text files via ElevenLabs --
# poems, songs, prayers, or anything else. Replaces the one-off
# add_*.ksh scripts.
#
# HOW TO USE:
#   1. Drop new .txt files into ~/Downloads/add_txt
#   2. Run:  chmod +x add_mp3_from_text.ksh && ./add_mp3_from_text.ksh
#   3. For any file without a known voice assignment, you'll be
#      prompted once; your answer is remembered in
#      ~/Downloads/add_txt/voices.txt for next time.
#   4. Each file is generated in an ISOLATED temp folder (so nothing
#      else in your library can ever be accidentally re-voiced),
#      copied into Downloads, MyAudio, and iCloud MyAudio, then
#      moved out of add_txt into the permanent english/ or german/
#      source folder. Once moved, it will never be processed again --
#      that's the "skip if already handled" behavior.
#   5. If a file with the same name already exists in MyAudio, you'll
#      see both files' duration/size and be asked yes/no before
#      anything is overwritten. (A true "does this sound different"
#      audio diff isn't reliable -- ElevenLabs doesn't generate
#      byte-identical output even for the same text and voice twice
#      in a row, so duration/size is the honest proxy available.)
#
# ADDING A NEW NAMED VOICE: edit the VOICE_ID / VOICE_LANG tables
# below and add one line to each.
#
# Flags: -s for Spanish prompts/messages.

typeset SPANISH=0
while getopts "s" opt; do
  case $opt in
    s) SPANISH=1 ;;
  esac
done

msg() {
  if [[ $SPANISH -eq 1 ]]; then print "$2"; else print "$1"; fi
}

#--- Known named voices -----------------------------------------------------
typeset -A VOICE_ID
VOICE_ID[Henry]="pVnrL6sighQX7hVz89cp"
VOICE_ID[Harry]="H538pP1BbhodCGiYVMKD"
VOICE_ID[Maya]="ii0s2u4R3UFnxKL6DOrz"
VOICE_ID[James]="tkWr6klIDADZ7T8TWUuj"
VOICE_ID[Brian]="Gubgw9l4dtIoQA9YZHgx"

typeset -A VOICE_LANG
VOICE_LANG[Henry]="english"
VOICE_LANG[Harry]="english"
VOICE_LANG[Maya]="english"
VOICE_LANG[James]="english"
VOICE_LANG[Brian]="german"

#--- Paths -------------------------------------------------------------------
typeset ADD_DIR=~/Downloads/add_txt
typeset ENG_DIR=~/Documents/elevenLabsUploads/english
typeset GER_DIR=~/Documents/elevenLabsUploads/german
typeset OUT_DIR=~/Downloads
typeset LIBRARY_DIR=~/Documents/MyAudio
typeset ICLOUD_DIR=~/"Library/Mobile Documents/com~apple~CloudDocs/MyAudio"
typeset BATCH=~/bin/eleven_tts_batch.ksh
typeset MANIFEST="$ADD_DIR/voices.txt"

mkdir -p "$ADD_DIR" "$ENG_DIR" "$GER_DIR" "$LIBRARY_DIR" "$ICLOUD_DIR"
touch "$MANIFEST"

#--- Helper: look up a manifest entry for a file ------------------------------
manifest_lookup() {
  typeset base="$1"
  grep "^${base}=" "$MANIFEST" 2>/dev/null | tail -1 | cut -d= -f2
}

#--- Helper: get duration/size of an mp3 for the collision prompt -------------
describe_audio() {
  typeset f="$1"
  typeset dur size
  size=$(ls -la "$f" 2>/dev/null | awk '{print $5}')
  dur=$(afinfo "$f" 2>/dev/null | grep -i "estimated duration" | head -1)
  print "    file: $f"
  print "    size: ${size:-unknown} bytes"
  print "    ${dur:-duration unavailable}"
}

typeset -i processed=0

for src in "$ADD_DIR"/*.txt; do
  [[ -f "$src" ]] || continue
  base=$(basename "$src" .txt)
  [[ "$base" == "voices" ]] && continue   # skip the manifest itself

  msg "=== Processing: $base ===" "=== Procesando: $base ==="

  #--- Step 1: determine the voice ------------------------------------------
  voice_name=$(manifest_lookup "$base")
  if [[ -z "$voice_name" ]]; then
    msg "Which voice should read '$base'? (${!VOICE_ID[*]})" \
        "¿Qué voz debe leer '$base'? (${!VOICE_ID[*]})"
    read -r voice_name
    if [[ -z "${VOICE_ID[$voice_name]}" ]]; then
      msg "Unknown voice name '$voice_name' -- skipping $base. (No files were moved or generated.)" \
          "Nombre de voz desconocido '$voice_name' -- omitiendo $base."
      continue
    fi
    print "${base}=${voice_name}" >> "$MANIFEST"
  fi

  voice_id="${VOICE_ID[$voice_name]}"
  lang="${VOICE_LANG[$voice_name]}"
  if [[ -z "$voice_id" ]]; then
    msg "** No voice ID on file for '$voice_name' -- skipping $base." \
        "** No hay ID de voz para '$voice_name' -- omitiendo $base."
    continue
  fi
  dest_dir="$ENG_DIR"
  [[ "$lang" == "german" ]] && dest_dir="$GER_DIR"

  #--- Step 2: collision check against MyAudio ------------------------------
  # A long text may have split into base_part1.mp3, base_part2.mp3, etc.
  # last time, so check for either the single file OR any numbered parts.
  typeset -a existing
  typeset -i n_existing=0
  set -A existing
  if [[ -f "$LIBRARY_DIR/$base.mp3" ]]; then
    existing[n_existing]="$LIBRARY_DIR/$base.mp3"
    n_existing=$((n_existing + 1))
  fi
  for p in "$LIBRARY_DIR/${base}_part"*.mp3; do
    [[ -f "$p" ]] || continue
    existing[n_existing]="$p"
    n_existing=$((n_existing + 1))
  done

  if [[ ${#existing[@]} -gt 0 ]]; then
    msg "'$base' already has ${#existing[@]} file(s) in MyAudio. Here's what's there:" \
        "'$base' ya tiene ${#existing[@]} archivo(s) en MyAudio. Esto es lo que hay:"
    for f in "${existing[@]}"; do
      describe_audio "$f"
    done
    msg "Overwrite with a freshly generated version using $voice_name? [y/N] " \
        "¿Sobrescribir con una versión recién generada usando $voice_name? [y/N] "
    read -r REPLY
    case "$REPLY" in
      y|Y|yes|YES|si|Si|SI|s|S) ;;
      *)
        msg "Skipped -- leaving the existing MyAudio copy/copies untouched." \
            "Omitido -- se dejan intactas las copias existentes en MyAudio."
        continue
        ;;
    esac
  fi

  #--- Step 3: generate in an isolated temp folder --------------------------
  TEMP_DIR=$(mktemp -d)
  cp "$src" "$TEMP_DIR/"
  msg "--- Generating '$base' with $voice_name ---" \
      "--- Generando '$base' con $voice_name ---"
  "$BATCH" -v "$voice_id" -i "$TEMP_DIR" -o "$OUT_DIR"
  rm -rf "$TEMP_DIR"

  # Collect whatever was actually produced: either base.mp3, or one or
  # more base_partN.mp3 files if the text was long enough to split.
  typeset -a produced
  typeset -i n_produced=0
  set -A produced
  if [[ -f "$OUT_DIR/$base.mp3" ]]; then
    produced[n_produced]="$OUT_DIR/$base.mp3"
    n_produced=$((n_produced + 1))
  fi
  for p in "$OUT_DIR/${base}_part"*.mp3; do
    [[ -f "$p" ]] || continue
    produced[n_produced]="$p"
    n_produced=$((n_produced + 1))
  done

  if [[ ${#produced[@]} -eq 0 ]]; then
    msg "** No mp3 (or parts) for $base were created -- see the output above for the error. Leaving $base.txt in add_txt to retry." \
        "** No se creó ningún mp3 (ni partes) para $base -- revisa el error arriba. Se deja $base.txt en add_txt para reintentar."
    continue
  fi

  #--- Step 4: copy into MyAudio (local + iCloud) ---------------------------
  for f in "${produced[@]}"; do
    cp "$f" "$LIBRARY_DIR/"
    cp "$f" "$ICLOUD_DIR/"
  done

  #--- Step 5: move the source text into permanent storage ------------------
  mv "$src" "$dest_dir/"
  processed=$((processed + 1))
  msg "'$base' done: ${#produced[@]} file(s) in Downloads/MyAudio/iCloud, text filed in $dest_dir." \
      "'$base' listo: ${#produced[@]} archivo(s) en Downloads/MyAudio/iCloud, texto archivado en $dest_dir."
done

msg "--- Done. $processed item(s) processed. ---" \
    "--- Listo. $processed elemento(s) procesados. ---"
