#!/usr/bin/env ksh

#-------------------------------------------------------------------------------
# PROGRAM:
#   ~/bin/git_tmutil.ksh
#
#
# PURPOSE:
#   Copy tmutil.ksh and tcc_who.ksh from ~/bin into the ShellSetup (SS) repo,
#   then git add, commit, and push them.
#
# USAGE:
#   ~/bin/git_tmutil.ksh
#
#-------------------------------------------------------------------------------

REPO=~/Projects/SS
FILES="tmutil.ksh tcc_who.ksh"
MSG="tmutil.ksh, tcc_who.ksh: exit with a clear message on non-macOS systems"

if [[ ! -d $REPO/.git ]]; then
    print -u2 "Error: $REPO is not a git repository."
    exit 1
fi

for f in $FILES; do
    if [[ ! -f ~/bin/$f ]]; then
        print -u2 "Error: ~/bin/$f not found."
        exit 1
    fi
    cp ~/bin/$f $REPO/bin/$f || exit 1
    chmod +x $REPO/bin/$f
    print "Copied ~/bin/$f -> $REPO/bin/$f"
done

cd $REPO || exit 1

for f in $FILES; do
    git add bin/$f || exit 1
done

if git diff --cached --quiet; then
    print "Nothing new to commit; the repo already has these versions."
    exit 0
fi

print "\nStaged changes:"
git diff --cached --stat

git commit -m "$MSG" || exit 1
git push || { print -u2 "Error: git push failed."; exit 1; }

print "\nDone. Latest commit:"
git log -1 --oneline

#-------------------------------------------------------------------------------
