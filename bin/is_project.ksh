#!/bin/ksh
# is_project.ksh
#
# Checks whether ~/Projects/<name> is a git repo (has a .git directory).
#
# Usage:
#   ksh is_project.ksh <ProjectName>        (English messages)
#   ksh is_project.ksh -s <ProjectName>      (Spanish messages)
#   ksh is_project.ksh -g <ProjectName>      (German messages)

LANG_CODE=en
while getopts "sg" opt; do
  case $opt in
    s) LANG_CODE=es ;;
    g) LANG_CODE=de ;;
  esac
done
shift $((OPTIND - 1))

PROJECT="$1"

msg() {
  case "$LANG_CODE" in
    es) print -- "$2" ;;
    de) print -- "$3" ;;
    *)  print -- "$1" ;;
  esac
}

if [ -z "$PROJECT" ]; then
  msg "Usage: is_project <ProjectName>" \
      "Uso: is_project <NombreDelProyecto>" \
      "Verwendung: is_project <Projektname>"
  exit 2
fi

DIR="$HOME/Projects/$PROJECT/.git"

if [ -d "$DIR" ]; then
  msg "yes, $PROJECT is a repo" \
      "si, $PROJECT es un repositorio" \
      "ja, $PROJECT ist ein Repository"
  exit 0
else
  msg "no .git here for $PROJECT" \
      "no hay .git aqui para $PROJECT" \
      "kein .git hier fur $PROJECT"
  exit 1
fi
