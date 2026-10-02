#!/bin/ksh
#
# install-bin-files.ksh — companion to remove-bin-files.ksh: the other
# half of the same job. Copies one or more files from the CURRENT
# directory into ~/Projects/SS/bin, installs via setup.ksh, stages/
# commits/pushes them, and verifies each one is ACTUALLY tracked by git
# afterward -- not assumed, checked (the delete.txt saga established why
# that check matters: a silent .gitignore rule, or a skipped git add, can
# leave a file installed-but-untracked with no obvious sign at the time).
#
# Usage:
#   ksh install-bin-files.ksh file1 [file2 ...]
#
# Run this from the directory where the files currently sit (e.g.
# ~/Downloads) -- it copies them from there into the SS repo, same
# calling convention as remove-bin-files.ksh and deploy-speak-tools.ksh.

typeset SS_DIR="$HOME/Projects/SS"
typeset SRC_DIR="$(pwd)"

if [[ $# -eq 0 ]]; then
    print "Usage: $0 file1 [file2 ...]"
    exit 1
fi

if [[ ! -d "$SS_DIR" ]]; then
    print "Error: SS repo not found at $SS_DIR"
    exit 1
fi

typeset -a FOUND
FOUND=()
for f in "$@"; do
    if [[ -f "$SRC_DIR/$f" ]]; then
        FOUND+=("$f")
    else
        print "Warning: $SRC_DIR/$f not found — skipping."
    fi
done

if [[ ${#FOUND[@]} -eq 0 ]]; then
    print "Error: none of the given files were found in $SRC_DIR."
    exit 1
fi

print "### Step 1: copying into $SS_DIR/bin"
typeset -a COPIED
COPIED=()
for f in "${FOUND[@]}"; do
    if cp "$SRC_DIR/$f" "$SS_DIR/bin/$f"; then
        COPIED+=("$f")
        print "Copied: $f"
    else
        print "Error: failed to copy $f — skipping it for the rest of this run."
    fi
done
print ""

if [[ ${#COPIED[@]} -eq 0 ]]; then
    print "Nothing was copied — nothing to install."
    exit 1
fi

print "### Step 2: installing via setup.ksh"
cd "$SS_DIR" || exit 1
ksh setup.ksh
print ""

print "### Step 3: git add (forcing past .gitignore if it matches -- these"
print "            are deliberate additions, not accidental ignored files)"
typeset -a STAGED
STAGED=()
for f in "${COPIED[@]}"; do
    if git check-ignore -v "bin/$f" 2>/dev/null; then
        print "(bin/$f matched the rule above -- forcing the add anyway)"
    fi
    if git add -f "bin/$f"; then
        STAGED+=("$f")
    else
        print "Error: git add failed for bin/$f even with -f — leaving it unstaged."
    fi
done
print ""

if [[ ${#STAGED[@]} -eq 0 ]]; then
    print "Nothing staged — nothing to commit."
    exit 1
fi

print "### Step 4: git commit and push"
typeset FILELIST="${STAGED[@]}"
if git commit -m "Add: ${FILELIST}"; then
    print ""
    if git push origin main; then
        print ""
    else
        print ""
        print "Error: git push failed — commit is saved locally, but NOT on origin/main."
        print "Check your network/auth and push manually: cd $SS_DIR && git push origin main"
        exit 1
    fi
else
    print ""
    print "Note: nothing to commit (already matches what's in the repo)."
fi

print "### Step 5: verifying each file is ACTUALLY tracked"
typeset -i PROBLEMS=0
for f in "${STAGED[@]}"; do
    if git ls-files --error-unmatch "bin/$f" >/dev/null 2>&1; then
        print "Confirmed: bin/$f is tracked."
    else
        print "PROBLEM: bin/$f is still NOT tracked."
        PROBLEMS=$((PROBLEMS + 1))
    fi
done

print ""
if [[ "$PROBLEMS" -eq 0 ]]; then
    print "### Done. Run syncAll next to push this out to your other machines."
else
    print "### $PROBLEMS file(s) above did not verify as tracked -- investigate before syncAll."
    exit 1
fi
