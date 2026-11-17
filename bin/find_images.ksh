#!/usr/bin/env ksh
#-----------------------------------------------------------------------------
# find_images.ksh
#
# Finds image files ONLY in places where you or Claude would reasonably have
# created or saved one: your own Documents folder (including every
# ~/Documents/SFP_backup_* folder), Downloads, and Desktop. Nowhere else is
# searched by default -- NOT Photos, iCloud Photo Library, or any other
# packaged app with its own managed library, and NOT hidden directories at
# any level (anything starting with ".").
#
# By default it looks for every common macOS-supported image format: jpg,
# jpeg, png, gif, bmp, tiff, tif, heic, heif, webp. Use -e to search one
# specific extension instead, or pipe the output through grep to narrow it
# down (e.g. find_images.ksh | grep -i sheridan).
#
# Add more directories to search with -d (repeatable) if you keep images
# somewhere else.
#
# The iCloud "Gallery" folder can be large, so the script asks you each
# time, right before searching: just answer y or n (Enter alone means no).
# When you say yes, it looks for any directory actually named "Gallery"
# (any case) under ~/Pictures and under ~/Library/Mobile Documents/
# com~apple~CloudDocs (where iCloud Drive folders live) and adds whichever
# one it actually finds.
#
# Usage:
#   find_images.ksh [-d DIR]... [-e EXT] [-s]
#
# Options:
#   -d DIR    Additional directory to search (repeatable). Default search
#             set is: ~/Documents, ~/Downloads, ~/Desktop
#   -e EXT    Search only this one extension, without the dot (default:
#             searches all common image extensions)
#   -s        Spanish status messages instead of English
#   -h        Help
#-----------------------------------------------------------------------------

typeset -a EXTRA_DIRS
set -A EXTRA_DIRS
typeset ONE_EXT=""
typeset SPANISH=0

while getopts "d:e:sh" opt; do
  case $opt in
    d) EXTRA_DIRS+=("$OPTARG") ;;
    e) ONE_EXT="$OPTARG" ;;
    s) SPANISH=1 ;;
    h)
      sed -n '2,30p' "$0"
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
typeset LOGFILE="$HOME/logs/find_images.$(date +%Y%m%d_%H%M%S).log"

main() {
  typeset -a SEARCH_DIRS
  SEARCH_DIRS=("$HOME/Documents" "$HOME/Downloads" "$HOME/Desktop" "${EXTRA_DIRS[@]}")

  typeset gallery_answer=""
  msg "Include the iCloud Gallery folder too? [y/N]: " \
      "¿Incluir también la carpeta Gallery de iCloud? [y/N]: "
  read gallery_answer

  if [[ "$gallery_answer" == ~(E)^[yY] ]]; then
    typeset gdir found_gallery=0
    typeset gtmp=$(mktemp)
    find "$HOME/Pictures" "$HOME/Library/Mobile Documents/com~apple~CloudDocs" \
         -maxdepth 2 -iname "Gallery" -type d 2>/dev/null > "$gtmp"
    while IFS= read -r gdir; do
      [[ -z "$gdir" ]] && continue
      SEARCH_DIRS+=("$gdir")
      found_gallery=1
      msg "Including Gallery folder: $gdir" "Incluyendo la carpeta Gallery: $gdir"
    done < "$gtmp"
    rm -f "$gtmp"
    if [[ $found_gallery -eq 0 ]]; then
      msg "Note: no Gallery folder found under ~/Pictures or iCloud Drive." \
          "Nota: no se encontró ninguna carpeta Gallery en ~/Pictures ni en iCloud Drive."
    fi
  fi

  typeset -a EXTS
  if [[ -n "$ONE_EXT" ]]; then
    EXTS=("$ONE_EXT")
  else
    EXTS=(jpg jpeg png gif bmp tiff tif heic heif webp)
  fi

  msg "Searching for images (${EXTS[*]}) in:" \
      "Buscando imágenes (${EXTS[*]}) en:"
  typeset d
  for d in "${SEARCH_DIRS[@]}"; do
    print "  $d"
  done
  msg "(skipping hidden directories at any level within these)" \
      "(omitiendo directorios ocultos en cualquier nivel dentro de estos)"
  msg "" ""

  typeset -a NAME_ARGS
  NAME_ARGS=()
  typeset e first=1
  for e in "${EXTS[@]}"; do
    if [[ $first -eq 1 ]]; then
      NAME_ARGS+=(-iname "*.${e}")
      first=0
    else
      NAME_ARGS+=(-o -iname "*.${e}")
    fi
  done

  for d in "${SEARCH_DIRS[@]}"; do
    [[ -d "$d" ]] || continue
    find "$d" -type d -name ".*" -prune -o -type f \( "${NAME_ARGS[@]}" \) -print
  done

  msg "" ""
  msg "See: $LOGFILE" "Ver: $LOGFILE"
}

main 2>&1 | tee -a "$LOGFILE"
