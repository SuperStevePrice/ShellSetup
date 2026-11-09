#!/usr/bin/env ksh
#-----------------------------------------------------------------------------
# sort_voice_files.ksh
#
# Sorts .txt files directly inside IN_DIR into german/ and english/
# subfolders, based on a known list of German filenames. Files already
# in a subfolder are left alone -- safe to re-run.
#
# Usage:
#   sort_voice_files.ksh [-i IN_DIR] [-s]
#     -i  Source directory holding your mixed .txt files
#         (default: ~/Documents/elevenLabsUploads)
#     -s  Spanish status messages
#-----------------------------------------------------------------------------

typeset IN_DIR="$HOME/Documents/elevenLabsUploads"
typeset SPANISH=0

while getopts "i:sh" opt; do
  case $opt in
    i) IN_DIR="$OPTARG" ;;
    s) SPANISH=1 ;;
    h)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    *) exit 1 ;;
  esac
done

msg() {
  if [[ $SPANISH -eq 1 ]]; then print "$2"; else print "$1"; fi
}

if [[ ! -d "$IN_DIR" ]]; then
  msg "Error: directory not found: $IN_DIR" "Error: directorio no encontrado: $IN_DIR"
  exit 1
fi

typeset ENG_DIR="$IN_DIR/english"
typeset GER_DIR="$IN_DIR/german"
mkdir -p "$ENG_DIR" "$GER_DIR"

# Known German filenames (edit this list if you add more German poems later)
typeset -A GERMAN_FILES
GERMAN_FILES[auferstehung_voll.txt]=1
GERMAN_FILES[bildnis_voll.txt]=1
GERMAN_FILES[Das_himmlische_Leben.txt]=1
GERMAN_FILES[grenadiere_voll.txt]=1
GERMAN_FILES[kuehlenacht_voll.txt]=1
GERMAN_FILES[lorelei_voll.txt]=1
GERMAN_FILES[Mahler_3_voll.txt]=1
GERMAN_FILES[panther_voll.txt]=1
GERMAN_FILES[prometheus_voll.txt]=1
GERMAN_FILES[schalf_Kindlein.txt]=1
GERMAN_FILES[Der_Erlkönig.txt]=1
GERMAN_FILES[BruderJakob.txt]=1
GERMAN_FILES[Der_Rabe_ASCII.txt]=1

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
  msg "Done. Sorted into $ENG_DIR and $GER_DIR" \
      "Listo. Ordenado en $ENG_DIR y $GER_DIR"
else
  msg "No unsorted .txt files found directly in $IN_DIR." \
      "No se encontraron archivos .txt sin ordenar directamente en $IN_DIR."
fi
