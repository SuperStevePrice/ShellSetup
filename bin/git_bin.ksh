#!/usr/bin/env ksh

#-------------------------------------------------------------------------------
# PROGRAM:
#   ~/bin/git_bin.ksh
#
#
# PURPOSE:
#   Install one or more scripts into ~/bin and the ShellSetup (SS) repo's bin
#   directory, then commit and push them. Any named file found in ~/Downloads
#   is moved to ~/bin first; otherwise the existing ~/bin copy is used.
#   Replaces the one-off git_tmutil.ksh, git_tmreport.ksh and git_b43.ksh.
#
# USAGE:
#   ~/bin/git_bin.ksh "commit message" file.ksh [file.ksh ...]
#   Example:
#     git_bin.ksh "tmreport.ksh: default to first Time Machine destination" \
#         tmreport.ksh
#   Afterwards run setup.ksh, then syncAll.
#
#-------------------------------------------------------------------------------

REPO=~/Projects/SS

if (( $# < 2 )); then
    print -u2 "Usage: $(basename $0) \"commit message\" file.ksh [file.ksh ...]"
    exit 1
fi

MSG="$1"
shift

if [[ ! -d $REPO/.git ]]; then
    print -u2 "Error: $REPO is not a git repository."
    exit 1
fi

#--- Install each file in ~/bin and copy it to the repo -------------------------
for f in "$@"; do
    f=${f##*/}                      # accept paths; use the file name only
    if [[ -f ~/Downloads/$f ]]; then
        mv ~/Downloads/$f ~/bin/$f || exit 1
        print "Moved ~/Downloads/$f -> ~/bin/$f"
    elif [[ ! -f ~/bin/$f ]]; then
        print -u2 "Error: $f not found in ~/Downloads or ~/bin."
        exit 1
    fi
    chmod +x ~/bin/$f
    cp ~/bin/$f $REPO/bin/$f || exit 1
    chmod +x $REPO/bin/$f
    print "Copied ~/bin/$f -> $REPO/bin/$f"
done

#--- Commit and push ------------------------------------------------------------
cd $REPO || exit 1
for f in "$@"; do
    git add bin/${f##*/} || exit 1
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

print "\nNext: run setup.ksh, then syncAll."

#-------------------------------------------------------------------------------
