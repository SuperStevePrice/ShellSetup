#!/usr/bin/env ksh
#
# clean_last_installed.ksh
#
# Policy: no file in the project tree should carry any "Last installed:"
# stamp comment at all -- dated, or the placeholder "(set by setup.ksh)" --
# except setup.ksh itself, where the block's own implementation/template
# legitimately lives. This script restores that: every stray block is
# removed, with a count of zero remaining anywhere else in the tree as
# the target.
#
# A "block" is up to three consecutive lines, matching what setup.ksh has
# actually been appending, e.g.:
#     #-------------------------------------------------------------------------------
#     # Last installed: 2026-10-04 09:07:23
#     #-- End of File ----------------------------------------------------------------
# Only the lines that are actually present are removed -- a bare stamp line
# with no surrounding divider lines is still removed; a divider line (a pure
# dash rule, or a "-- End of File --" rule) is only removed when it sits
# directly next to a stamp line, so unrelated section dividers elsewhere in
# a file are left alone.
#
# This script never touches setup.ksh itself, since that file is where the
# block's own implementation/template legitimately lives. Everything else in
# the tree -- including pushInstall.ksh and installed.ksh -- is scanned and
# cleaned normally; their *code* that generates or reads a stamp (e.g.
# print "# Last installed: $stamp", or a grep pattern for it) is not a
# comment line and is never matched, so it's left alone automatically.
#
# It also reports (never removes) any "Last patched:" lines it finds --
# that looks like a hand-written note rather than a setup.ksh stamp, and is
# out of scope here.
#
# It also enforces a second, related policy: no backup-predeploy snapshot
# directory should survive anywhere in the tree -- setup.ksh is supposed to
# prune these itself after a successful install (that it doesn't is a
# separate bug in setup.ksh worth fixing directly), so this script sweeps
# any stragglers up as a safety net. That cleanup always runs first, before
# any stamp-line changes are made.
#
# Four steps, each gated by its own confirmation (or all run unattended
# with -y):
#   1. Delete stray backup-predeploy snapshot directories.
#   2. Remove stray "Last installed:" stamp blocks (setup.ksh excepted).
#   3. Re-run setup.ksh to reinstall/re-stamp.
#   4. git add/commit/push -- per project repo, never at $ROOT.
#
# On git: $ROOT (e.g. ~/Projects) is a container, not itself a pushable
# repo -- ShellSetup and Pray (the two with pending work as of 2026-11-20)
# are each their own independent git repo with their own GitHub remote.
# Step 4 therefore never runs git at the $ROOT level (doing so creates
# bogus embedded-repo gitlinks and typically fails outright with "no
# configured push destination"); instead it goes straight to each named
# project's own directory, runs `git add -A` from inside THAT repo's root,
# commits with its own message (prompted per repo, defaulting to a generic
# one), and only ever prints a push as successful once `git push`'s own
# exit status actually confirms it -- never assumed, as the earlier version
# of this script wrongly did.
#
# Step 4 also deliberately does NOT depend on steps 1-2 finding anything
# during *this* run -- if the real fix already happened on disk earlier (by
# hand, or an earlier live run), there's nothing left for this run's scan to
# find, but the uncommitted result is still sitting in ShellSetup/Pray and
# still needs to be caught and pushed.
#
# Usage:
#   clean_last_installed.ksh [-d DIR] [-n|--dry-run] [-y|--yes]
#                             [--no-reinstall] [--no-push] [-h|--help]
#   clean_last_installed.ksh --fix-permissions
#
#   -d DIR          Root directory to scan (default: $HOME/Projects)
#   -n, --dry-run   Preview only; make no changes, run nothing else
#   -y, --yes       Don't prompt for confirmation before each step
#   --no-reinstall  Skip offering to run setup.ksh after cleanup
#   --no-push       Skip offering to git add/commit/push after cleanup
#   --fix-permissions
#                   One-time repair, independent of the four normal steps:
#                   restores the executable bit on the specific ShellSetup
#                   files that an earlier version of this script's stamp
#                   cleanup silently flipped from 755 to 644 (it wrote via
#                   `mv` of a scratch file instead of `cat`-ing back into
#                   the original, which lost the original's permission
#                   bits) -- then commits and pushes just that fix. Exits
#                   immediately after; does not run the normal 4 steps.
#   -h, --help      Show this help and exit

typeset ROOT="$HOME/Projects"
typeset DRYRUN=0
typeset ASSUME_YES=0
typeset DO_REINSTALL=1
typeset DO_PUSH=1
typeset FIX_PERMISSIONS=0

# setup.ksh is the one file that legitimately owns this block's
# implementation/template -- never modified, only reported on.
typeset -A MECHANISM_FILES
MECHANISM_FILES[setup.ksh]=1

usage() {
    sed -n '2,75p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
}

# ---------------------------------------------------------------------------
# Arg parsing
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        -d) ROOT="$2"; shift 2;;
        -n|--dry-run) DRYRUN=1; shift;;
        -y|--yes) ASSUME_YES=1; shift;;
        --no-reinstall) DO_REINSTALL=0; shift;;
        --no-push) DO_PUSH=0; shift;;
        --fix-permissions) FIX_PERMISSIONS=1; shift;;
        -h|--help) usage;;
        *) print -u2 -- "Unknown option: $1"; usage;;
    esac
done

SETUP_SCRIPT="$HOME/Projects/SS/setup.ksh"

# ---------------------------------------------------------------------------
# Logging setup (standing preference: every script logs to ~/logs and shows
# live stdout/stderr on the terminal as well).
#
# NOTE: this deliberately uses a plain pipe to tee rather than
# "exec 1> >(tee ...)" process substitution -- the latter triggers a known
# "cannot create [Illegal byte sequence]" failure in the ksh93 build Apple
# ships as /bin/ksh on at least some machines/locales. A pipe is portable
# and gives the same live-tee-to-log behavior; stdin (and so interactive
# "read" prompts below) is unaffected since only stdout/stderr are piped.
# ---------------------------------------------------------------------------
typeset SCRIPTNAME=$(basename "$0")
typeset LOGDIR="$HOME/logs"
mkdir -p "$LOGDIR"
typeset STAMP=$(date +%Y%m%d_%H%M%S)
typeset LOGFILE="$LOGDIR/${SCRIPTNAME}.${STAMP}.log"

set -o pipefail 2>/dev/null

fix_permissions() {
    typeset shellsetup="$HOME/Projects/ShellSetup"
    typeset -a affected
    affected[0]="bin/eleven_tts_batch.ksh"
    affected[1]="bin/health_sleep.ksh"
    affected[2]="bin/health_sleep.py"
    affected[3]="bin/morning_sleep.ksh"
    affected[4]="bin/scp_this.ksh"
    affected[5]="templates/xt.py.template"

    if [[ ! -d "$shellsetup" ]]; then
        print -u2 -- "Error: $shellsetup not found."
        return 1
    fi
    typeset proot=$(git -C "$shellsetup" rev-parse --show-toplevel 2>/dev/null)
    if [[ -z "$proot" ]]; then
        print -u2 -- "Error: $shellsetup is not a git repository."
        return 1
    fi

    print -- "Restoring executable bit in $proot where the stamp-cleanup bug flipped it to 644..."
    typeset changed=0
    typeset rel full
    for rel in "${affected[@]}"; do
        full="$proot/$rel"
        if [[ ! -f "$full" ]]; then
            print -- "  not found, skipping: $rel"
            continue
        fi
        if [[ -x "$full" ]]; then
            print -- "  already executable: $rel"
        else
            chmod 755 "$full" && print -- "  restored 755: $rel"
            changed=1
        fi
    done

    if [[ $changed -eq 0 ]]; then
        print -- "Nothing to fix -- all listed files already executable."
        return 0
    fi

    if [[ $DRYRUN -eq 1 ]]; then
        print -- "DRY RUN: not committing/pushing."
        return 0
    fi

    typeset do_commit=1
    if [[ $ASSUME_YES -ne 1 ]]; then
        print -n -- "Commit and push this permission fix for ShellSetup now? [y/N] "
        read ans
        case "$ans" in [Yy]) do_commit=1;; *) do_commit=0;; esac
    fi
    if [[ $do_commit -ne 1 ]]; then
        print -- "Leaving the fix uncommitted on disk."
        return 0
    fi

    if ! git -C "$proot" add -- "${affected[@]}"; then
        print -- "ERROR: git add failed; not committing."
        return 1
    fi
    if ! git -C "$proot" commit -m "Restore executable bit lost by stamp-cleanup bug"; then
        print -- "Nothing committed (commit failed, or nothing staged)."
        return 1
    fi
    if git -C "$proot" push; then
        print -- "Pushed: ShellSetup permission fix."
    else
        print -- "WARNING: committed locally, but 'git push' failed (see output above) -- the fix has NOT reached GitHub."
    fi
}

run() {
    if [[ ! -d "$ROOT" ]]; then
        print -u2 -- "Error: $ROOT does not exist."
        return 1
    fi

    [[ $DRYRUN -eq 1 ]] && print -- "DRY RUN: no files will be modified."

    # -----------------------------------------------------------------------
    # Step 1: remove stray backup-predeploy snapshot directories. These
    # don't belong in the tree at all -- setup.ksh should be pruning them
    # itself after a successful install, so their presence here is a
    # separate bug in setup.ksh worth investigating directly. This runs
    # first, before any other file changes, and before setup.ksh is
    # re-run, so a fresh (and hopefully self-cleaning) backup isn't made
    # and then immediately swept up by this same pass.
    # -----------------------------------------------------------------------
    print -- "Scanning $ROOT for stray backup-predeploy snapshot directories..."
    typeset TMPBACKUPS=$(mktemp)
    typeset DO_BU=0
    find "$ROOT" -type d -name 'backup-predeploy' -not -path '*/.git/*' -print 2>/dev/null > "$TMPBACKUPS"

    if [[ -s "$TMPBACKUPS" ]]; then
        print -- "Found backup-predeploy directories:"
        while IFS= read -r bpd; do
            find "$bpd" -mindepth 1 -maxdepth 1 -print 2>/dev/null | while IFS= read -r snap; do
                print -- "  $snap"
            done
        done < "$TMPBACKUPS"

        if [[ $DRYRUN -eq 1 ]]; then
            DO_BU=0
        elif [[ $ASSUME_YES -eq 1 ]]; then
            DO_BU=1
        else
            print -n -- "Delete all of the above now? [y/N] "
            read ans
            case "$ans" in [Yy]) DO_BU=1;; *) DO_BU=0;; esac
        fi

        if [[ $DO_BU -eq 1 ]]; then
            while IFS= read -r bpd; do
                find "$bpd" -mindepth 1 -maxdepth 1 -print 2>/dev/null | while IFS= read -r snap; do
                    rm -rf -- "$snap" && print -- "  deleted: $snap"
                done
            done < "$TMPBACKUPS"
            print -- "backup-predeploy cleanup complete."
        else
            print -- "Skipping backup-predeploy cleanup (dry-run or user declined)."
        fi
    else
        print -- "No backup-predeploy directories found under $ROOT."
    fi
    rm -f "$TMPBACKUPS"

    print
    print -- "Scanning $ROOT for 'Last installed:' stamp lines (any form, including placeholders)..."

    # Selection regex: a comment line (first non-blank char is #) containing
    # "last installed:" anywhere, in any case. Used for candidate-file detection.
    typeset STAMP_SELECT='^[[:space:]]*#.*[Ll]ast[[:space:]]+[Ii]nstalled:'
    typeset PATCHED_PATTERN='[Ll]ast[[:space:]]+patched:'

    typeset TMPFILES=$(mktemp)
    typeset TMPPATCHED=$(mktemp)
    trap 'rm -f "$TMPFILES" "$TMPPATCHED"' EXIT

    find "$ROOT" -type f -not -path '*/.git/*' -print 2>/dev/null | while IFS= read -r f; do
        grep -IlE "$STAMP_SELECT" "$f" >/dev/null 2>&1 && print -- "$f" >> "$TMPFILES"
        grep -IlE "$PATCHED_PATTERN" "$f" >/dev/null 2>&1 && print -- "$f" >> "$TMPPATCHED"
    done

    typeset -A IS_MECHANISM
    if [[ -s "$TMPFILES" ]]; then
        print -- "Found 'Last installed:' stamp lines in:"
        while IFS= read -r f; do
            typeset bn=$(basename "$f")
            typeset n=$(grep -cE "$STAMP_SELECT" "$f")
            if [[ -n "${MECHANISM_FILES[$bn]}" ]]; then
                IS_MECHANISM[$f]=1
                print -- "  $f  ($n match(es)) -- setup.ksh, will NOT be modified"
            else
                print -- "  $f  ($n stamp line(s))"
            fi
        done < "$TMPFILES"
    else
        print -- "No 'Last installed:' stamp lines found anywhere in $ROOT."
    fi

    if [[ -s "$TMPPATCHED" ]]; then
        print
        print -- "Note: the following 'Last patched:' lines were left untouched (different marker, out of scope):"
        while IFS= read -r f; do
            grep -nE "$PATCHED_PATTERN" "$f" | sed "s|^|  $f: line |"
        done < "$TMPPATCHED"
    fi

    # -----------------------------------------------------------------------
    # Step 2: remove stamp blocks (stamp line, plus any dash-rule or
    # "End of File" divider line directly touching it on either side),
    # skipping setup.ksh.
    # -----------------------------------------------------------------------
    typeset DO_RM=0
    if [[ ! -s "$TMPFILES" ]]; then
        : # nothing to remove, but don't return early -- a backup-predeploy
          # cleanup above may still need the reinstall/push steps below
    else
        print
        if [[ $DRYRUN -eq 1 ]]; then
            DO_RM=0
        elif [[ $ASSUME_YES -eq 1 ]]; then
            DO_RM=1
        else
            print -n -- "Remove these stamp blocks now (setup.ksh skipped)? [y/N] "
            read ans
            case "$ans" in [Yy]) DO_RM=1;; *) DO_RM=0;; esac
        fi
    fi

    if [[ $DO_RM -eq 1 ]]; then
        print -- "Removing stamp blocks..."
        while IFS= read -r f; do
            if [[ -n "${IS_MECHANISM[$f]}" ]]; then
                print -- "  skipped (setup.ksh): $f"
                continue
            fi
            typeset tmp="${f}.tmp.$$"
            # NOTE: output is written to a scratch file, then catted back
            # INTO the original file (never `mv`'d over it) so the original
            # inode -- and so its permission bits, including the executable
            # bit on scripts -- is preserved. An earlier version of this
            # script used `mv "$tmp" "$f"` here, which replaces the file
            # with the temp file's own (umask-determined, non-executable)
            # permissions -- that silently flipped several *.ksh/*.py
            # scripts from 755 to 644, and that mode change got committed
            # and pushed before this was caught. See the 2026-11-20 fixup
            # note at the end of this script for the one-time repair of
            # files already affected.
            awk '
                { lines[NR] = $0; n = NR }
                END {
                    for (i = 1; i <= n; i++) {
                        t = tolower(lines[i])
                        is_stamp[i]   = (t ~ /^[ \t]*#.*last[ \t]+installed:/) ? 1 : 0
                        # plain dash rule: "#" then only dashes/space to end of line
                        is_divider[i] = (t ~ /^[ \t]*#-+[ \t]*$/) ? 1 : 0
                        # "-- End of File --" rule line, dashes/spaces around the words
                        if (t ~ /^[ \t]*#-+[ \t]*end of file[ \t]*-+[ \t]*$/) is_divider[i] = 1
                    }
                    for (i = 1; i <= n; i++) {
                        del[i] = is_stamp[i]
                    }
                    for (i = 1; i <= n; i++) {
                        if (is_divider[i]) {
                            if ((i > 1 && is_stamp[i-1]) || (i < n && is_stamp[i+1])) {
                                del[i] = 1
                            }
                        }
                    }
                    for (i = 1; i <= n; i++) {
                        if (!del[i]) print lines[i]
                    }
                }
            ' "$f" > "$tmp" && cat "$tmp" > "$f" && rm -f "$tmp"
            print -- "  cleaned: $f"
        done < "$TMPFILES"
        print -- "Stamp blocks removed (setup.ksh untouched)."
    elif [[ -s "$TMPFILES" ]]; then
        print -- "Skipping removal (dry-run or user declined)."
    fi

    # -----------------------------------------------------------------------
    # Step 3: reinstall via setup.ksh
    #
    # Deliberately NOT gated on whether steps 1-2 found anything *this run*:
    # if the real cleanup already happened on disk in an earlier run (or by
    # hand) and all that's left is to reinstall/commit/push it, this still
    # needs to offer that.
    # -----------------------------------------------------------------------
    print
    if [[ $DO_REINSTALL -eq 0 || $DRYRUN -eq 1 ]]; then
        print -- "Skipping reinstall."
    elif [[ ! -f "$SETUP_SCRIPT" ]]; then
        print -- "setup.ksh not found at $SETUP_SCRIPT; skipping reinstall."
    else
        typeset DO_RI=0
        if [[ $ASSUME_YES -eq 1 ]]; then
            DO_RI=1
        else
            print -n -- "Run setup.ksh to reinstall? [y/N] "
            read ans
            case "$ans" in [Yy]) DO_RI=1;; *) DO_RI=0;; esac
        fi
        if [[ $DO_RI -eq 1 ]]; then
            print -- "Running setup.ksh..."
            ksh "$SETUP_SCRIPT"
        else
            print -- "Skipping reinstall."
        fi
    fi

    # -----------------------------------------------------------------------
    # Step 4: git add / commit / push -- per project repo, never at $ROOT.
    #
    # $ROOT (e.g. ~/Projects) is a container, not itself a pushable repo --
    # ShellSetup and Pray are each their own independent git repo with their
    # own GitHub remote. Each is handled on its own: staged with a blanket
    # `git add -A` run FROM INSIDE that repo's own root (never from $ROOT,
    # which is what creates bogus embedded-repo gitlinks), committed with
    # its own message, and "pushed" is only ever printed once `git push`'s
    # own exit status confirms it actually succeeded -- not assumed.
    #
    # Also deliberately NOT gated on this run's own DO_BU/DO_RM: if the
    # real fix already happened on disk earlier, this still needs to find
    # and push it.
    # -----------------------------------------------------------------------
    print
    if [[ $DO_PUSH -eq 0 || $DRYRUN -eq 1 ]]; then
        print -- "Skipping git add/commit/push."
    else
        typeset -a PROJECT_LABELS PROJECT_DIRS
        PROJECT_LABELS[0]="ShellSetup"; PROJECT_DIRS[0]="$HOME/Projects/ShellSetup"
        PROJECT_LABELS[1]="Pray";       PROJECT_DIRS[1]="$HOME/Projects/Pray"

        typeset pi
        for ((pi = 0; pi < ${#PROJECT_DIRS[@]}; pi++)); do
            typeset label="${PROJECT_LABELS[pi]}"
            typeset pdir="${PROJECT_DIRS[pi]}"
            print
            print -- "-- $label ($pdir) --"

            if [[ ! -d "$pdir" ]]; then
                print -- "  not found; skipping."
                continue
            fi

            typeset proot=$(git -C "$pdir" rev-parse --show-toplevel 2>/dev/null)
            if [[ -z "$proot" ]]; then
                print -- "  not a git repository; skipping."
                continue
            fi

            typeset statusout=$(git -C "$proot" status --porcelain 2>/dev/null)
            if [[ -z "$statusout" ]]; then
                print -- "  no uncommitted changes; nothing to do."
                continue
            fi

            print -- "  Uncommitted changes in $proot:"
            git -C "$proot" status --short | sed 's/^/    /'

            typeset do_commit=0
            if [[ $ASSUME_YES -eq 1 ]]; then
                do_commit=1
            else
                print -n -- "  Commit and push all of the above for $label now? [y/N] "
                read ans
                case "$ans" in [Yy]) do_commit=1;; *) do_commit=0;; esac
            fi

            if [[ $do_commit -ne 1 ]]; then
                print -- "  Skipping $label."
                continue
            fi

            typeset default_msg="Clean up stray setup.ksh install-stamp artifacts"
            typeset commit_msg="$default_msg"
            if [[ $ASSUME_YES -ne 1 ]]; then
                print -n -- "  Commit message for $label [default: \"$default_msg\"]: "
                read custom_msg
                [[ -n "$custom_msg" ]] && commit_msg="$custom_msg"
            fi

            if ! git -C "$proot" add -A; then
                print -- "  ERROR: git add failed in $proot; not committing."
                continue
            fi
            if ! git -C "$proot" commit -m "$commit_msg"; then
                print -- "  Nothing committed in $proot (commit failed or nothing staged)."
                continue
            fi
            if git -C "$proot" push; then
                print -- "  Pushed: $label."
            else
                print -- "  WARNING: committed locally in $proot, but 'git push' failed (see output above) -- changes have NOT reached GitHub."
            fi
        done
    fi

    print
    print -- "Done."
    print -- "See: $LOGFILE"
}

if [[ $FIX_PERMISSIONS -eq 1 ]]; then
    fix_permissions 2>&1 | tee -a "$LOGFILE"
    print -- "See: $LOGFILE"
else
    run 2>&1 | tee -a "$LOGFILE"
fi
