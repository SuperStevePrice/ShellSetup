#!/bin/ksh
# is_project.ksh
#
# Checks whether ~/Projects/<name> is a git repo (has a .git directory).
#
# Usage:
#   ksh is_project.ksh <ProjectName>        (English messages)
#   ksh is_project.ksh -s <ProjectName>      (Spanish messages)

LANG_ES=0
while getopts "s" opt; do
  case $opt in
    s) LANG_ES=1 ;;
  esac
done
shift $((OPTIND - 1))

PROJECT="$1"

msg() {
  if [ "$LANG_ES" -eq 1 ]; then
    print -- "$2"
  else
    print -- "$1"
  fi
}

if [ -z "$PROJECT" ]; then
  msg "Usage: is_project <ProjectName>" "Uso: is_project <NombreDelProyecto>"
  exit 2
fi

DIR="$HOME/Projects/$PROJECT/.git"

if [ -d "$DIR" ]; then
  msg "yes, $PROJECT is a repo" "si, $PROJECT es un repositorio"
  exit 0
else
  msg "no .git here for $PROJECT" "no hay .git aqui para $PROJECT"
  exit 1
fi
