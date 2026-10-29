#!/bin/ksh
#
# commit_pending_changes.ksh
#
# Commits the legitimate pending changes already sitting in the SS
# working tree:
#   - bin/git_stat_all.ksh, bin/pushInstall.ksh: renamed hostnames
#   - bin/speak-loop.ksh: current-directory-first file lookup fix
#   - dots/aliases: new doc/docs aliases
# Also removes .DS_Store from git tracking and adds it to .gitignore,
# since it's Finder metadata, not source, and shouldn't churn the repo.
#
# Does NOT touch bin.zip or the empty 'main' file -- those are left
# for you to review and remove yourself if you confirm they're junk.
#
# Usage:
#   ./commit_pending_changes.ksh        (English messages)
#   ./commit_pending_changes.ksh -s     (Spanish messages)

SPANISH=0
while getopts "s" opt; do
    case $opt in
        s) SPANISH=1 ;;
    esac
done

msg() {
    if [ "$SPANISH" -eq 1 ]; then
        print "$2"
    else
        print "$1"
    fi
}

SS_DIR="$HOME/Projects/SS"

set -e
cd "$SS_DIR"

msg "Staging the legitimate pending changes ..." \
    "Preparando (staging) los cambios pendientes legítimos ..."
git add bin/git_stat_all.ksh bin/pushInstall.ksh bin/speak-loop.ksh dots/aliases

msg "Removing .DS_Store from tracking (keeping the file on disk) ..." \
    "Quitando .DS_Store del seguimiento (el archivo permanece en el disco) ..."
git rm --cached .DS_Store >/dev/null 2>&1 || true

msg "Adding .DS_Store to .gitignore (if not already present) ..." \
    "Agregando .DS_Store a .gitignore (si no está ya presente) ..."
if ! grep -qxF ".DS_Store" .gitignore 2>/dev/null; then
    print ".DS_Store" >> .gitignore
    git add .gitignore
fi

msg "Committing ..." \
    "Confirmando (commit) ..."
git commit -m "Rename hosts to new scheme; fix speak-loop directory precedence; add doc/docs aliases; stop tracking .DS_Store"

msg "Pushing ..." \
    "Subiendo (push) ..."
git push

msg "Done. bin.zip and the empty 'main' file were left untouched --" \
    "Listo. bin.zip y el archivo vacío 'main' quedaron intactos --"
msg "review those yourself; they're untracked so git isn't affected either way." \
    "revísalos tú mismo; no están rastreados, así que no afectan a git de ninguna forma."
