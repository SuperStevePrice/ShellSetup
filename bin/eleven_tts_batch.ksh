#!/usr/bin/env ksh
#-----------------------------------------------------------------------------
# eleven_tts_batch.ksh
#
# Batch-converts every .txt file in a folder to .mp3 via the ElevenLabs
# Text-to-Speech API. Files over the character limit are automatically
# split into numbered parts (part1, part2, ...), breaking on paragraph
# or line boundaries so no sentence gets cut in half.
#
# Usage:
#   eleven_tts_batch.ksh -l                       # list your voices + IDs
#   eleven_tts_batch.ksh -v VOICE_ID [-i IN_DIR] [-o OUT_DIR] [-m MODEL] [-c LIMIT] [-s]
#
# Requires:
#   - ELEVENLABS_API_KEY set in your environment, OR pass -k KEY
#   - curl and python3 (already on macOS/Linux)
#
# Options:
#   -k KEY     API key (overrides $ELEVENLABS_API_KEY)
#   -v ID      Voice ID to use (required unless -l)
#   -i DIR     Input directory of .txt files (default: ~/Documents/elevenlabsUploads)
#   -o DIR     Output directory for .mp3 files (default: same as -i)
#   -m MODEL   Model ID (default: eleven_multilingual_v2 -- good for German/English)
#   -c LIMIT   Max characters per API call before splitting (default: 9500)
#   -l         List available voices (name + voice_id) and exit
#   -s         Spanish status messages instead of English
#   -h         Help
#-----------------------------------------------------------------------------

typeset API_KEY="${ELEVENLABS_API_KEY}"
typeset VOICE_ID=""
typeset IN_DIR="$HOME/Documents/elevenlabsUploads"
typeset OUT_DIR=""
typeset MODEL="eleven_multilingual_v2"
typeset LIMIT=9500
typeset DO_LIST=0
typeset SPANISH=0

while getopts "k:v:i:o:m:c:lsh" opt; do
  case $opt in
    k) API_KEY="$OPTARG" ;;
    v) VOICE_ID="$OPTARG" ;;
    i) IN_DIR="$OPTARG" ;;
    o) OUT_DIR="$OPTARG" ;;
    m) MODEL="$OPTARG" ;;
    c) LIMIT="$OPTARG" ;;
    l) DO_LIST=1 ;;
    s) SPANISH=1 ;;
    h)
      sed -n '2,27p' "$0"
      exit 0
      ;;
    *)
      print -u2 "Unknown option. Use -h for help."
      exit 1
      ;;
  esac
done

msg() {
  # msg "english text" "spanish text"
  if [[ $SPANISH -eq 1 ]]; then
    print "$2"
  else
    print "$1"
  fi
}

if [[ -z "$API_KEY" ]]; then
  msg "Error: no API key. Set \$ELEVENLABS_API_KEY or pass -k KEY." \
      "Error: no hay clave de API. Define \$ELEVENLABS_API_KEY o usa -k CLAVE."
  exit 1
fi

if [[ $DO_LIST -eq 1 ]]; then
  msg "Fetching your voices..." "Obteniendo tus voces..."
  curl -s -X GET "https://api.elevenlabs.io/v1/voices" \
    --header "xi-api-key: $API_KEY" \
  | python3 -c '
import json,sys
data = json.load(sys.stdin)
for v in data.get("voices", []):
    print(f"{v.get(\"name\"):40s} {v.get(\"voice_id\")}")
'
  exit 0
fi

if [[ -z "$VOICE_ID" ]]; then
  msg "Error: no voice ID given. Use -l to list voices, then -v VOICE_ID." \
      "Error: no se dio un ID de voz. Usa -l para listar voces, luego -v ID_DE_VOZ."
  exit 1
fi

if [[ -z "$OUT_DIR" ]]; then
  OUT_DIR="$IN_DIR"
fi

if [[ ! -d "$IN_DIR" ]]; then
  msg "Error: input directory not found: $IN_DIR" \
      "Error: no se encontró el directorio de entrada: $IN_DIR"
  exit 1
fi

mkdir -p "$OUT_DIR"
typeset WORK_DIR=$(mktemp -d)

# split_file: writes chunk files to $WORK_DIR as <base>.partNN.txt
# (NN zero-padded). If the file fits under LIMIT, writes a single
# <base>.part01.txt so downstream logic is uniform.
split_file() {
  python3 -c '
import sys, os, re

path, limit, work_dir, base = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4]
with open(path, "r", encoding="utf-8") as fh:
    text = fh.read()

if len(text) <= limit:
    chunks = [text]
else:
    # split on blank-line paragraph boundaries first
    paras = re.split(r"(\n\s*\n)", text)
    # re-glue the separators back onto their preceding paragraph
    merged = []
    i = 0
    while i < len(paras):
        p = paras[i]
        if i + 1 < len(paras) and paras[i+1].strip() == "":
            p += paras[i+1]
            i += 2
        else:
            i += 1
        merged.append(p)

    chunks = []
    cur = ""
    for p in merged:
        if len(cur) + len(p) <= limit:
            cur += p
        else:
            if cur:
                chunks.append(cur)
            if len(p) <= limit:
                cur = p
            else:
                # single paragraph itself too long -- split on lines
                lines = p.splitlines(keepends=True)
                cur = ""
                for ln in lines:
                    if len(cur) + len(ln) <= limit:
                        cur += ln
                    else:
                        if cur:
                            chunks.append(cur)
                        cur = ln
    if cur:
        chunks.append(cur)

for idx, c in enumerate(chunks, start=1):
    outpath = os.path.join(work_dir, f"{base}.part{idx:02d}.txt")
    with open(outpath, "w", encoding="utf-8") as out:
        out.write(c)

print(len(chunks))
' "$1" "$LIMIT" "$WORK_DIR" "$2"
}

typeset total_files=0
typeset total_parts=0
typeset done_count=0
typeset failed=0

for f in "$IN_DIR"/*.txt; do
  [[ -f "$f" ]] || continue
  total_files=$((total_files + 1))
done

if [[ $total_files -eq 0 ]]; then
  msg "No .txt files found in $IN_DIR" \
      "No se encontraron archivos .txt en $IN_DIR"
  rmdir "$WORK_DIR" 2>/dev/null
  exit 0
fi

msg "Found $total_files text file(s) in $IN_DIR. Output -> $OUT_DIR (limit ${LIMIT} chars/call)" \
    "Se encontraron $total_files archivo(s) de texto en $IN_DIR. Salida -> $OUT_DIR (límite ${LIMIT} caracteres/llamada)"

for f in "$IN_DIR"/*.txt; do
  [[ -f "$f" ]] || continue

  base=$(basename "$f" .txt)
  nparts=$(split_file "$f" "$base")

  if [[ "$nparts" -gt 1 ]]; then
    msg "$base: ${nparts} parts needed (file exceeds ${LIMIT} chars)" \
        "$base: se necesitan ${nparts} partes (el archivo excede ${LIMIT} caracteres)"
  fi

  typeset p=1
  while [[ $p -le $nparts ]]; do
    pnum=$(printf "%02d" $p)
    chunkfile="$WORK_DIR/${base}.part${pnum}.txt"

    if [[ $nparts -gt 1 ]]; then
      outfile="$OUT_DIR/${base}_part${p}.mp3"
      label="${base} (part ${p}/${nparts})"
    else
      outfile="$OUT_DIR/${base}.mp3"
      label="$base"
    fi

    total_parts=$((total_parts + 1))

    if [[ -f "$outfile" ]]; then
      msg "Skipping $label (mp3 already exists)" \
          "Omitiendo $label (el mp3 ya existe)"
      p=$((p + 1))
      continue
    fi

    msg "Generating: $label ..." "Generando: $label ..."

    python3 -c '
import json,sys
with open(sys.argv[1], "r", encoding="utf-8") as fh:
    text = fh.read()
payload = {
    "text": text,
    "model_id": sys.argv[2],
    "voice_settings": {"stability": 0.5, "similarity_boost": 0.75}
}
json.dump(payload, sys.stdout)
' "$chunkfile" "$MODEL" > "$WORK_DIR/payload.json"

    http_code=$(curl -s -o "$outfile" -w "%{http_code}" \
      -X POST "https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}" \
      --header "xi-api-key: $API_KEY" \
      --header "Content-Type: application/json" \
      --header "Accept: audio/mpeg" \
      -d @"$WORK_DIR/payload.json")

    if [[ "$http_code" == "200" ]]; then
      done_count=$((done_count + 1))
      msg "  -> saved $outfile" "  -> guardado $outfile"
    else
      failed=$((failed + 1))
      msg "  -> FAILED (HTTP $http_code) for $label -- see $outfile for error detail" \
          "  -> FALLÓ (HTTP $http_code) para $label -- ver $outfile para detalles del error"
    fi

    sleep 1
    p=$((p + 1))
  done
done

rm -rf "$WORK_DIR"

msg "Done. $done_count succeeded, $failed failed, out of $total_parts part(s) across $total_files file(s)." \
    "Listo. $done_count exitosos, $failed fallidos, de $total_parts parte(s) en $total_files archivo(s)."
