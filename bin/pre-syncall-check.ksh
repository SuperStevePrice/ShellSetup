#!/bin/ksh
#
# pre-syncall-check.ksh — confirm the SS repo has nothing uncommitted,
# untracked, or unpushed before you run syncAll out to your other
# machines. Read-only: never stages, commits, or pushes anything itself.

typeset SS_DIR="$HOME/Projects/SS"

if [[ ! -d "$SS_DIR" ]]; then
    print "Error: SS repo not found at $SS_DIR"
    exit 1
fi

cd "$SS_DIR" || exit 1

typeset -i PROBLEMS=0

print "### Working tree status (should be empty)"
typeset STATUS
STATUS=$(git status --short)
if [[ -n "$STATUS" ]]; then
    print "$STATUS"
    PROBLEMS=$((PROBLEMS + 1))
else
    print "(clean)"
fi
print ""

print "### Checking origin for anything not yet pushed"
git fetch -q origin main 2>/dev/null
typeset AHEAD BEHIND
AHEAD=$(git rev-list --count origin/main..HEAD 2>/dev/null)
BEHIND=$(git rev-list --count HEAD..origin/main 2>/dev/null)
if [[ "$AHEAD" -gt 0 ]]; then
    print "Local has $AHEAD commit(s) not yet pushed to origin/main."
    PROBLEMS=$((PROBLEMS + 1))
elif [[ "$BEHIND" -gt 0 ]]; then
    print "origin/main has $BEHIND commit(s) this machine hasn't pulled yet."
    PROBLEMS=$((PROBLEMS + 1))
else
    print "(in sync with origin/main)"
fi
print ""

if [[ "$PROBLEMS" -eq 0 ]]; then
    print "### CLEAN -- safe to run syncAll."
else
    print "### NOT CLEAN -- $PROBLEMS issue(s) above. Resolve before running syncAll,"
    print "    or the other machines won't end up with what you think they will."
    exit 1
fi
