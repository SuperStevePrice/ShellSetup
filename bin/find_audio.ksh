#!/usr/bin/env ksh
#-----------------------------------------------------------------------------
# find_audio.ksh
#
# Finds audio files ONLY in places where you or Claude would reasonably have
# created one: your own Documents folder (including every ~/Documents/
# SFP_backup_* folder), Downloads, and Desktop. Nowhere else is searched by
# default -- NOT Apple Music, Voice Memos, iTunes, Photos, or any other
# packaged app with its own managed library, and NOT tool/package
# directories (Python, Conda, Spyder, node_modules, etc.) or anything
# starting with "." (hidden directories).
#
# This is the opposite approach from scanning your whole home directory and
# trying to exclude the noise -- instead it only looks in the handful of
# places that could plausibly hold a file you made.
#
# Add more directories to search with -d (repeatable) if there's somewhere
# else you keep recordings.
#
# Usage:
#   find_audio.ksh [-d DIR]... [-e EXT] [-s]
#
# Options:
#   -d DIR    Additional directory to search (repeatable). Default search
#             set is: ~/Documents, ~/Downloads, ~/Desktop
#   -e EXT    File extension to search for, without the dot (default: mp3)
#   -s        Spanish status messages instead of English
#   -h        Help
#-----------------------------------------------------------------------------

typeset -a EXTRA_DIRS
set -A EXTRA_DIRS
typeset EXT="mp3"
typeset SPANISH=0

while getopts "d:e:sh" opt; do
  case $opt in
    d) EXTRA_DIRS+=("$OPTARG") ;;
    e) EXT="$OPTARG" ;;
    s) SPANISH=1 ;;
    h)
      sed -n '2,23p' "$0"
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
typeset LOGFILE="$HOME/logs/find_audio.$(date +%Y%m%d_%H%M%S).log"

main() {
  typeset -a SEARCH_DIRS
  SEARCH_DIRS=("$HOME/Documents" "$HOME/Downloads" "$HOME/Desktop" "${EXTRA_DIRS[@]}")

  msg "Searching for *.${EXT} files in:" \
      "Buscando archivos *.${EXT} en:"
  typeset d
  for d in "${SEARCH_DIRS[@]}"; do
    print "  $d"
  done
  msg "(skipping hidden directories within these)" \
      "(omitiendo directorios ocultos dentro de estos)"
  msg "" ""

  for d in "${SEARCH_DIRS[@]}"; do
    [[ -d "$d" ]] || continue
    find "$d" -type d -name ".*" -prune -o -type f -iname "*.${EXT}" -print
  done

  msg "" ""
  msg "See: $LOGFILE" "Ver: $LOGFILE"
}

main 2>&1 | tee -a "$LOGFILE"
