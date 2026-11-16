#!/usr/bin/env ksh
#-----------------------------------------------------------------------------
# match_loudness_auto.ksh
#
# Smart wrapper around match_loudness.ksh: instead of giving exact file
# paths (which drift as new SFP_backup_<date> folders get created), give a
# NAME PATTERN for the target poem and (optionally) for the reference. This
# script finds the actual files for you:
#
#   - Reference: searched for live inside Apple Music's own managed folder
#     (~/Music/Music/Media.localized), so it's always whatever's really
#     there now. Defaults to "Ozymandias" if -r isn't given.
#
#   - Target: searched across every ~/Documents/SFP_backup_* folder (any
#     date) plus ~/Downloads, picking whichever matching file was modified
#     most recently.
#
# Requires match_loudness.ksh to be installed alongside this script (same
# bin/ directory) -- it does the actual loudness measuring/normalizing.
#
# Usage:
#   match_loudness_auto.ksh -t TARGET_PATTERN [-r REF_PATTERN] [-p] [-s]
#
# Options:
#   -t PATTERN  Name pattern to find the target mp3 (e.g. "Sheridan")
#               (required)
#   -r PATTERN  Name pattern to find the reference mp3 (default: "Ozymandias")
#   -p          Play the result with afplay once it's done
#   -s          Spanish status messages instead of English
#   -h          Help
#-----------------------------------------------------------------------------

typeset TARGET_PATTERN=""
typeset REF_PATTERN="Ozymandias"
typeset DO_PLAY=0
typeset SPANISH=0

while getopts "t:r:psh" opt; do
  case $opt in
    t) TARGET_PATTERN="$OPTARG" ;;
    r) REF_PATTERN="$OPTARG" ;;
    p) DO_PLAY=1 ;;
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
  if [[ $SPANISH -eq 1 ]]; then
    print "$2"
  else
    print "$1"
  fi
}

mkdir -p "$HOME/logs"
typeset LOGFILE="$HOME/logs/match_loudness_auto.$(date +%Y%m%d_%H%M%S).log"
typeset SCRIPT_DIR=$(dirname "$0")

# find_latest PATTERN DIR1 [DIR2 ...]
# Searches each directory (recursively) for *PATTERN*.mp3, case-insensitive,
# and prints the full path of the most recently modified match.
find_latest() {
  typeset pattern="$1"
  shift
  typeset d best bestmtime f mtime
  bestmtime=0
  best=""
  for d in "$@"; do
    [[ -d "$d" ]] || continue
    for f in $(find "$d" -iname "*${pattern}*.mp3" -type f 2>/dev/null); do
      mtime=$(stat -f "%m" "$f" 2>/dev/null)
      [[ -z "$mtime" ]] && continue
      if (( mtime > bestmtime )); then
        bestmtime=$mtime
        best="$f"
      fi
    done
  done
  print -- "$best"
}

main() {
  if [[ -z "$TARGET_PATTERN" ]]; then
    msg "Error: -t TARGET_PATTERN is required. Use -h for help." \
        "Error: se requiere -t PATRON_OBJETIVO. Usa -h para ayuda."
    return 1
  fi

  if [[ ! -x "$SCRIPT_DIR/match_loudness.ksh" && ! -f "$SCRIPT_DIR/match_loudness.ksh" ]]; then
    msg "Error: match_loudness.ksh not found alongside this script in $SCRIPT_DIR" \
        "Error: no se encontró match_loudness.ksh junto a este script en $SCRIPT_DIR"
    return 1
  fi

  msg "Searching for reference matching \"$REF_PATTERN\" in Apple Music's library..." \
      "Buscando referencia que coincida con \"$REF_PATTERN\" en la biblioteca de Apple Music..."
  typeset REF_FILE=$(find_latest "$REF_PATTERN" "$HOME/Music/Music/Media.localized")

  if [[ -z "$REF_FILE" ]]; then
    msg "Error: no reference file matching \"$REF_PATTERN\" found." \
        "Error: no se encontró ningún archivo de referencia que coincida con \"$REF_PATTERN\"."
    return 1
  fi

  msg "Searching for target matching \"$TARGET_PATTERN\" in SFP_backup_* folders and Downloads..." \
      "Buscando objetivo que coincida con \"$TARGET_PATTERN\" en las carpetas SFP_backup_* y Downloads..."
  typeset -a BACKUP_DIRS
  set -A BACKUP_DIRS $HOME/Documents/SFP_backup_*
  typeset TARGET_FILE=$(find_latest "$TARGET_PATTERN" "${BACKUP_DIRS[@]}" "$HOME/Downloads")

  if [[ -z "$TARGET_FILE" ]]; then
    msg "Error: no target file matching \"$TARGET_PATTERN\" found." \
        "Error: no se encontró ningún archivo objetivo que coincida con \"$TARGET_PATTERN\"."
    return 1
  fi

  msg "Using reference: $REF_FILE" "Usando referencia: $REF_FILE"
  msg "Using target:    $TARGET_FILE" "Usando objetivo:  $TARGET_FILE"
  msg "" ""

  typeset -a FORWARD_ARGS
  FORWARD_ARGS=(-r "$REF_FILE" -i "$TARGET_FILE")
  [[ $DO_PLAY -eq 1 ]] && FORWARD_ARGS+=(-p)
  [[ $SPANISH -eq 1 ]] && FORWARD_ARGS+=(-s)

  ksh "$SCRIPT_DIR/match_loudness.ksh" "${FORWARD_ARGS[@]}"

  msg "See: $LOGFILE" "Ver: $LOGFILE"
}

main 2>&1 | tee -a "$LOGFILE"
