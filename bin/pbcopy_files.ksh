#!/usr/bin/env ksh
#
# pbcopy_files.ksh — concatenate one or more files, each preceded by its
# name, onto the clipboard (pbcopy on macOS, xclip/xsel on Linux) —
# for pasting into a Claude chat.
#
# Usage:
#   ksh pbcopy_files.ksh [-f|--force] file1 [file2 ...]
#   ksh pbcopy_files.ksh speak* play*        (your shell expands the globs)
#
# A bad file (missing, or binary-looking) is warned about and skipped --
# it does NOT stop the run; every other good file still gets processed.
# Binary files (images, PDFs, compiled executables, archives, etc.) are
# detected regardless of name or extension (NUL-byte test, below) and
# skipped by default -- pasting raw binary bytes as "text" is nonsense
# Claude can't meaningfully read anyway, and can choke a terminal or
# clipboard. Pass -f/--force to include them anyway.
#
# Every run writes a log to ~/logs/pbpaste_files.<timestamp>, listing
# both successes and failures, and offers to open it afterward.
#
# Size guidance:
#   Pasting plain text isn't governed by a file-upload size limit at all —
#   that only applies to actual file uploads (500MB/file). What a big
#   paste actually eats into is the conversation's own context window,
#   which is shared across the WHOLE chat, not just one message, and
#   is 200K, 500K, or up to 1M tokens depending on the Claude model in
#   use (see https://support.claude.com/en/articles/8606394). There's no
#   single official "too big" character count, so the thresholds below
#   are this script's own conservative heads-up, not an Anthropic-set
#   limit — it keeps going either way and copies whatever you give it.

typeset PLATFORM=""
typeset CLIP_CMD=""
case "$(uname)" in
    Darwin) PLATFORM="darwin"; CLIP_CMD="pbcopy" ;;
    Linux)
        PLATFORM="linux"
        if command -v xclip >/dev/null 2>&1; then
            CLIP_CMD="xclip -selection clipboard"
        elif command -v xsel >/dev/null 2>&1; then
            CLIP_CMD="xsel --clipboard --input"
        else
            CLIP_CMD=""
        fi
        ;;
    *)
        PLATFORM="other"
        CLIP_CMD=""
        ;;
esac

typeset OUTFILE="/tmp/pbcopy_files.out"

typeset LOGDIR="$HOME/logs"
mkdir -p "$LOGDIR" 2>/dev/null
typeset LOGFILE="$LOGDIR/pbpaste_files.$(date +%Y_%m_%d-%H:%M:%S)"

# A rough, conservative line, not a hard rule: roughly 4 characters per
# token is a common estimate for English text (code and non-English text
# often run denser than that, i.e. MORE tokens for the same character
# count) — so these are deliberately cautious.
typeset -i CAUTION_CHARS=50000     # ~12,500 tokens: just a heads-up
typeset -i WARNING_CHARS=200000    # ~50,000 tokens: suggests splitting up

# Is this file binary? The NUL-byte test: strip every NUL byte and see if
# the file got shorter. Virtually no real text format (plain text, code,
# JSON, XML...) ever contains a NUL byte; virtually every binary format
# (images, PDFs, archives, compiled executables) does somewhere in its
# header or body. Portable across macOS's BSD tr and Linux's GNU tr,
# unlike grep -P (not available in BSD grep) or relying on 'file's mime-
# type guesses (inconsistent wording across systems).
is_binary() {
    typeset orig_size stripped_size
    orig_size=$(wc -c < "$1" | tr -d ' ')
    stripped_size=$(tr -d '\000' < "$1" | wc -c | tr -d ' ')
    [[ "$orig_size" != "$stripped_size" ]]
}

typeset FORCE=0
typeset -a FILES
FILES=()
for a in "$@"; do
    case "$a" in
        -f|--force) FORCE=1 ;;
        *) FILES+=("$a") ;;
    esac
done

if [[ ${#FILES[@]} -eq 0 ]]; then
    print "Usage: $0 [-f|--force] file1 [file2 ...]"
    print "  -f, --force   include binary-looking files anyway (normally skipped with a warning)"
    exit 1
fi

# Reconstruct the command line as a single, safely re-runnable string --
# each original arg wrapped in single quotes, so it's copy/paste-ready
# later even if a filename had a space in it (not just a bare $* join,
# which would lose word boundaries on anything with embedded spaces).
typeset CMDLINE="$0"
for a in "$@"; do
    CMDLINE="$CMDLINE '$a'"
done

print "Command: $CMDLINE" > "$LOGFILE"
print "pbcopy_files.ksh run: $(date)" >> "$LOGFILE"
print "" >> "$LOGFILE"

typeset -i INCLUDED=0
typeset -i SKIPPED=0

# Expand any arg that still looks like a glob pattern (*, ?, or [). This
# only ever matters if YOU quoted it on the command line (e.g. 's*') --
# that's the only way a literal pattern character can still be sitting
# in $f at all, since an UNQUOTED glob is expanded by your shell before
# this script even starts, and nothing in here can see or undo that.
# Quoting is what makes the log's "Command:" line above show the exact
# pattern you typed instead of the expanded file list.
typeset -a EXPANDED
EXPANDED=()
for f in "${FILES[@]}"; do
    case "$f" in
        *[\*\?\[]*)
            typeset -a matches
            matches=( $f )   # unquoted on purpose -- let the shell glob $f here
            if [[ ${#matches[@]} -eq 1 && "${matches[0]}" == "$f" && ! -e "$f" ]]; then
                print "Warning: no files matched pattern: $f — skipping."
                print "SKIPPED (no match): $f" >> "$LOGFILE"
                SKIPPED=$((SKIPPED + 1))
            else
                EXPANDED+=("${matches[@]}")
            fi
            ;;
        *) EXPANDED+=("$f") ;;
    esac
done
FILES=("${EXPANDED[@]}")

print "Files:" > "$OUTFILE"
print "" >> "$OUTFILE"

for f in "${FILES[@]}"; do
    if [[ ! -f "$f" ]]; then
        print "Warning: $f not found — skipping."
        print "SKIPPED (not found): $f" >> "$LOGFILE"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    if is_binary "$f"; then
        if [[ "$FORCE" -eq 1 ]]; then
            print "Warning: $f looks binary (contains NUL bytes) — including anyway (-f given)."
            print "INCLUDED (binary, forced): $f" >> "$LOGFILE"
        else
            print "Warning: $f looks binary (contains NUL bytes) — skipping. Use -f to include it anyway."
            print "SKIPPED (binary): $f" >> "$LOGFILE"
            SKIPPED=$((SKIPPED + 1))
            continue
        fi
    else
        print "OK: $f" >> "$LOGFILE"
    fi

    print "#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" >> "$OUTFILE"
    print "File #$((INCLUDED + 1)): $f" >> "$OUTFILE"
    print ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" >> "$OUTFILE"
    print "" >> "$OUTFILE"
    cat "$f" >> "$OUTFILE"
    print "" >> "$OUTFILE"
    INCLUDED=$((INCLUDED + 1))
done

if [[ "$INCLUDED" -eq 0 ]]; then
    print ""
    print "Nothing left to copy — every file given was skipped." | tee -a "$LOGFILE"
    print "" >> "$LOGFILE"
    print "Result: 0 included, ${SKIPPED} skipped." >> "$LOGFILE"
    print ""
    print -n "View log: $LOGFILE y or n: "
    typeset ANSWER=""
    read ANSWER
    case "$ANSWER" in
        # 'less', not 'view' -- vim (even read-only) can sync its default
        # register to the system pasteboard if 'clipboard=unnamed' is set
        # in ~/.vimrc, silently overwriting what pbcopy just placed there.
        # 'less' is a pure pager: it never touches the clipboard.
        y|Y|yes|YES) less "$LOGFILE" ;;
        *) ;;
    esac
    exit 1
fi

typeset -i TOTAL_CHARS
TOTAL_CHARS=$(wc -c < "$OUTFILE" | tr -d ' ')

print "Combined size: ${TOTAL_CHARS} characters across ${INCLUDED} file(s) (${SKIPPED} skipped)."

print "" >> "$LOGFILE"
print "Combined size: ${TOTAL_CHARS} characters, ${INCLUDED} included, ${SKIPPED} skipped." >> "$LOGFILE"

if [[ "$TOTAL_CHARS" -gt "$WARNING_CHARS" ]]; then
    print ""
    print "Note: past ~${WARNING_CHARS} characters (very roughly $((WARNING_CHARS / 4)) tokens)."
    print "The context window is shared across the WHOLE conversation, so a paste this"
    print "size takes a real bite out of it in one message. Worth considering a new"
    print "chat, or splitting this into a couple of smaller pastes, if things feel"
    print "sluggish or Claude starts missing earlier context."
    print ""
    print "Also: a paste this size eats into your USAGE limit too (your message"
    print "allotment over time), not just this chat's length -- longer messages"
    print "and longer conversations both draw on it, separately from each other."
elif [[ "$TOTAL_CHARS" -gt "$CAUTION_CHARS" ]]; then
    print ""
    print "Note: a moderately large paste (~${TOTAL_CHARS} characters) — should be fine,"
    print "just flagging it since you asked what 'too big' might mean here."
fi

print ""

if [[ -n "$CLIP_CMD" ]]; then
    $CLIP_CMD < "$OUTFILE"
    print "Copied to clipboard."
    print "Copied to clipboard via: $CLIP_CMD" >> "$LOGFILE"
else
    print "No clipboard tool found for this platform."
    if [[ "$PLATFORM" == "linux" ]]; then
        print "Install one with:  sudo apt install xclip"
        print "(or xsel), then try again."
    fi
    print "Combined text is saved at: $OUTFILE — copy it manually."
    print "No clipboard tool available on this platform ($PLATFORM)." >> "$LOGFILE"
fi

print ""
print -n "View log: $LOGFILE y or n: "
typeset ANSWER=""
read ANSWER
case "$ANSWER" in
    # 'less', not 'view' -- see the comment on the other y/n prompt above:
    # vim can silently overwrite the pasteboard we just filled, 'less' never touches it.
    y|Y|yes|YES) less "$LOGFILE" ;;
    *) ;;
esac

# Explicit, always -- without this the script's exit status is whatever
# 'read' above happened to return (0 on an ordinary answer, but possibly
# non-zero on EOF or other edge cases), which would silently break any
# '&&' chain the caller built around this script even though the actual
# run succeeded. A successful copy is success, full stop, regardless of
# how the optional log-viewing prompt was answered.
exit 0
