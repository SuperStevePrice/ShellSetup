#!/bin/ksh
#
# remove-bin-files.ksh — remove one or more named files from the SS repo's
# bin/, the installed copies in ~/bin, and any extension-stripped symlinks
# pointing at them -- then commit and push the removal in one go.
#
# Usage:
#   ksh remove-bin-files.ksh file1 [file2 ...]
#
# Generalized from remove-set-shell.ksh the moment a second file needed
# the same treatment -- same "don't repeat yourself" idea this whole
# session has followed elsewhere (pbcopy_files.ksh, deploy-speak-tools.ksh,
# the speak.ksh/speak.sh consolidation).
#
# IMPORTANT once you run syncAll on your other machines: syncAll's `git
# pull` DOES remove the file from each machine's copy of the SS repo's own
# bin/ -- but setup.ksh never deletes stale files, only adds/updates (the
# same reason "shutd" sat orphaned in ~/bin for who knows how long). So
# the ALREADY-INSTALLED copy and symlink in ~/bin on each of those other
# machines will NOT be cleaned up automatically. You'll still need to run
# Step 2's two rm's by hand on each remote machine (or copy this script
# over and run it there too -- Steps 1/3/4 will just no-op harmlessly
# since the repo side is already clean after the pull).
#
# Run this from anywhere; it cd's into the repo itself.

typeset SS_DIR="$HOME/Projects/SS"

if [[ $# -eq 0 ]]; then
    print "Usage: $0 file1 [file2 ...]"
    exit 1
fi

if [[ ! -d "$SS_DIR" ]]; then
    print "Error: SS repo not found at $SS_DIR"
    exit 1
fi

cd "$SS_DIR" || exit 1

# Confirm EVERY filename individually before anything destructive runs --
# a glob like *set* can silently expand to something you never meant to
# hand this script (setup.ksh, a whole other project's files, etc.), so
# nothing here is trusted just because it showed up in $@.
typeset -a CONFIRMED
CONFIRMED=()
for f in "$@"; do
    # Reject directories outright -- never even ask. A glob like *set* or
    # a plain typo can just as easily match a directory (e.g. "backup")
    # as a file, and this script only ever means to remove individual
    # files; rm -f on a directory would silently do nothing useful here,
    # but asking "are you sure" about it implies this script COULD
    # handle it, which it can't and shouldn't.
    if [[ -d "bin/$f" || -d "$HOME/bin/$f" ]]; then
        print "Rejected: $f is a directory, not a file — this script only removes individual files."
        continue
    fi

    print -n "Are you sure you want to remove $f? This cannot be undone. y or n: "
    typeset ANSWER=""
    read ANSWER
    case "$ANSWER" in
        y|Y|yes|YES) CONFIRMED+=("$f") ;;
        *) print "Skipping $f (not confirmed)." ;;
    esac
done
print ""

if [[ ${#CONFIRMED[@]} -eq 0 ]]; then
    print "Nothing confirmed for removal — exiting."
    exit 0
fi

typeset -a REMOVED
REMOVED=()

print "### Step 1: removing from the SS repo"
for f in "${CONFIRMED[@]}"; do
    if [[ -f "bin/$f" ]]; then
        # -f: force, even if it has uncommitted local modifications --
        # we're intentionally discarding it, not trying to preserve a version.
        # Checked, not assumed: a file can sit on disk in bin/ without ever
        # having been 'git add'ed (e.g. only ever installed via a plain cp +
        # setup.ksh, never committed) -- git rm then fails with a "pathspec
        # did not match" error, and REMOVED must NOT claim success for it.
        if git rm -f "bin/$f"; then
            REMOVED+=("$f")
        else
            print "git rm failed for bin/$f -- it likely exists on disk but was"
            print "never actually committed to the repo (only installed via a"
            print "plain cp). Nothing staged for it here; the ~/bin cleanup in"
            print "Step 2 below still happens independently either way."
        fi
    else
        print "bin/$f not in the repo — nothing to git rm."
    fi
done
print ""

print "### Step 2: removing installed copies and symlinks from ~/bin"
for f in "${CONFIRMED[@]}"; do
    if [[ -f "$HOME/bin/$f" ]]; then
        rm -f "$HOME/bin/$f"
        print "Removed $HOME/bin/$f"
    else
        print "$HOME/bin/$f not found — nothing to remove."
    fi

    # Extension-stripped symlink, same convention as setup.ksh's own
    # set_symbolic_links(): foo.ksh -> foo, foo.sh -> foo. Only remove it
    # if it's actually a symlink pointing at THIS file, so we never touch
    # an unrelated file that happens to share the stripped name.
    case "$f" in
        *.*sh)
            sym="${f%.*sh}"
            if [[ -L "$HOME/bin/$sym" ]]; then
                target=$(readlink "$HOME/bin/$sym")
                case "$target" in
                    */"$f"|"$f")
                        rm -f "$HOME/bin/$sym"
                        print "Removed symlink $HOME/bin/$sym"
                        ;;
                    *)
                        print "$HOME/bin/$sym exists but points elsewhere ($target) — leaving it alone."
                        ;;
                esac
            fi
            ;;
    esac
done
print ""

if [[ ${#REMOVED[@]} -eq 0 ]]; then
    print "Nothing was in the repo to remove — nothing to commit."
    exit 0
fi

print "### Step 3: git commit and push"
typeset FILELIST="${REMOVED[@]}"
if git commit -m "Remove: ${FILELIST}"; then
    print ""
    if git push origin main; then
        print ""
        print "### Done. Run syncAll next -- then see the note at the top of this"
        print "script about also cleaning ~/bin by hand on your other machines."
    else
        print ""
        print "Error: git push failed — commit is saved locally, but NOT on origin/main."
        print "Check your network/auth and push manually: cd $SS_DIR && git push origin main"
        exit 1
    fi
else
    print ""
    print "Note: nothing to commit — skipping push."
fi
