#!/usr/bin/env ksh
#-----------------------------------------------------------------------------
# backup_zip_purge.ksh
#
# Zips everything in a folder (default ~/Downloads/backup) into a new,
# uniquely-timestamped zip file, excluding any .zip files already there --
# then, after confirmation, deletes every top-level file and folder except
# .zip files, since everything else is now safely archived.
#
# Usage:
#   backup_zip_purge.ksh [-i DIR] [-y] [-s]
#
# Options:
#   -i DIR   Directory to zip and clean (default: ~/Downloads/backup)
#   -y       Skip the confirmation prompt and purge immediately
#   -s       Spanish status messages instead of English
#   -h       Help
#-----------------------------------------------------------------------------

typeset TARGET_DIR="$HOME/Downloads/backup"
typeset AUTO_YES=0
typeset SPANISH=0

while getopts "i:ysh" opt; do
  case $opt in
    i) TARGET_DIR="$OPTARG" ;;
    y) AUTO_YES=1 ;;
    s) SPANISH=1 ;;
    h)
      sed -n '2,17p' "$0"
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

mkdir -p "$HOME/logs"
typeset LOGFILE="$HOME/logs/backup_zip_purge.$(date +%Y%m%d_%H%M%S).log"

main() {
  if [[ ! -d "$TARGET_DIR" ]]; then
    msg "Error: directory not found: $TARGET_DIR" \
        "Error: no se encontró el directorio: $TARGET_DIR"
    return 1
  fi

  cd "$TARGET_DIR" || return 1

  typeset ZIPNAME="backup_$(date +%Y%m%d_%H%M%S).zip"

  msg "Zipping everything in $TARGET_DIR (excluding existing .zip files) -> $ZIPNAME" \
      "Comprimiendo todo en $TARGET_DIR (excluyendo archivos .zip existentes) -> $ZIPNAME"

  zip -r "$ZIPNAME" . -x "*.zip"

  if [[ $? -ne 0 ]]; then
    msg "Error: zip failed. Nothing will be deleted." \
        "Error: falló la compresión. No se eliminará nada."
    return 1
  fi

  msg "Zip created: $TARGET_DIR/$ZIPNAME" \
      "Archivo zip creado: $TARGET_DIR/$ZIPNAME"

  msg "" ""
  msg "The following top-level items are about to be deleted (everything except .zip files):" \
      "Los siguientes elementos de nivel superior están a punto de eliminarse (todo excepto los archivos .zip):"
  find . -maxdepth 1 ! -name '.' ! -name '*.zip' -print | sed 's|^\./||'

  if [[ $AUTO_YES -ne 1 ]]; then
    msg "" ""
    msg "Proceed with deletion? [y/N] " "¿Continuar con la eliminación? [s/N] "
    read answer
    case "$answer" in
      [Yy]*|[Ss]*) ;;
      *)
        msg "Aborted. Nothing deleted; the zip above is still there." \
            "Cancelado. No se eliminó nada; el zip anterior sigue ahí."
        msg "See: $LOGFILE" "Ver: $LOGFILE"
        return 0
        ;;
    esac
  fi

  find . -maxdepth 1 ! -name '.' ! -name '*.zip' -exec rm -rf {} +

  msg "Done. $TARGET_DIR now contains only: " "Listo. $TARGET_DIR ahora contiene solo: "
  ls -la "$TARGET_DIR"

  msg "See: $LOGFILE" "Ver: $LOGFILE"
}

main 2>&1 | tee -a "$LOGFILE"
