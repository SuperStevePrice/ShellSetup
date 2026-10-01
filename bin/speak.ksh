#!/bin/ksh
#
# speak.ksh — read text aloud on macOS using the built-in 'say' command,
#             or save it as an audio file (AIFF or M4A).
#
# Requires: macOS (uses the built-in 'say' command). No installs needed.

# No Linux or Windows support yet — 'say' is macOS-only. Bail out cleanly
# rather than failing deep inside the script with a cryptic error.
# (On Windows, ksh only runs under a Unix layer like Cygwin/MSYS/MinGW,
# which 'uname' reports as CYGWIN*/MINGW*/MSYS* rather than "Windows".)
case "$(uname)" in
    Darwin) ;;   # proceed normally
    CYGWIN*|MINGW*|MSYS*)
        print "Windows version coming soon! Well, maybe."
        exit 0
        ;;
    *)
        print "Linux version coming soon! Well, maybe."
        exit 0
        ;;
esac

# Defaults — change these to taste.
# Run './speak.ksh -l' to see every installed voice and its locale.
typeset GERMAN_DEFAULT_VOICE="Anna"
typeset ENGLISH_DEFAULT_VOICE="Samantha"
typeset DEFAULT_RATE=""   # leave blank to use the voice's own default rate

# Test sentences used by -t (and by running with no arguments).
typeset TEST_EN="This is the speak command, reading text aloud with your Mac's built-in voices at whatever rate and voice you choose."
typeset TEST_DE="Dies ist das Sprachprogramm, das Texte mit den eingebauten Stimmen Ihres Mac in beliebiger Geschwindigkeit und Stimme vorliest."

typeset VOICE=""
typeset RATE=""
typeset OUTFILE=""
typeset INPUT=""
typeset LANG_FLAG=""   # "g" or "e", so we know which default/validation applies
typeset PFLAG=""       # set if -p (print text while speaking) was given
typeset NFLAG=""       # set if -n (natural/continuous reading, no per-line pause) was given

typeset USAGE_FILE="$HOME/Documents/speak.usage"

usage() {
    print "Usage: $0 <textfile|-> [-v voice] [-g [voice]] [-e [voice]] [-r rate] [-o outfile.aiff|.m4a] [-p] [-n]"
    print "       $0 -l            (list available voices)"
    print "       $0 -t            (speak English then German test sentences)"
    print "       $0 -h | --help   (full help)"
    print "See $USAGE_FILE"
    exit 1
}

help() {
    typeset HELPTEXT
    HELPTEXT=$(cat << 'HELPEOF'
speak.ksh — read text aloud on macOS, or save it as an audio file.

USAGE
    speak <textfile|-> [options]
    speak -l
    speak -t
    speak -h | --help

ARGUMENTS
    <textfile>        Path to a text file to read aloud.
    -                  Read from stdin instead of a file (e.g. for piping).
                       Example: echo "hello" | speak -

OPTIONS (any order, mixed freely)
    -v <voice>         Use this exact voice by name (e.g. -v Daniel).
                       Run 'speak -l' to see every voice installed on
                       this Mac, with its locale.

    -g [voice]         German shortcut.
                         speak file.txt -g          uses the German
                                                     default voice
                                                     (currently: Anna)
                         speak file.txt -g Helga    uses the named voice
                       If the named voice isn't actually a German (de_*)
                       voice, speak.ksh prints a warning but still uses
                       it — nothing stops you from reading German text
                       in an English voice or vice versa on purpose.

    -e [voice]         English shortcut. Same pattern as -g:
                         speak file.txt -e          uses the English
                                                     default voice
                                                     (currently: Samantha)
                         speak file.txt -e Daniel   uses the named voice
                       Same mismatch warning applies if the named voice
                       isn't an English (en_*) voice.

    -r <rate>          Speech rate in words per minute. Typical usable
                       range is roughly 90-720; the voice's own default
                       is usually around 175-200. Example: -r 220

    -o <outfile>       Save audio to a file instead of speaking it aloud.
                         .aiff           saved as AIFF (uncompressed)
                         .m4a            saved as AAC-compressed M4A
                       Example: -o out.m4a

    -p                 Print the text to the screen in sync with the
                       voice: each line is printed, then spoken, then
                       the next line, and so on — so what's on screen
                       stays in step with what you're hearing.
                       Example: speak notes.txt -p
                       Note: combined with -o (saving to an audio file),
                       line-by-line sync doesn't apply — the whole text
                       is printed up front instead, since the output
                       is one continuous audio file, not line-by-line.

    -n                 Natural reading: only meaningful together with -p.
                       Prints the whole text up front, then speaks it in
                       one continuous, uninterrupted pass instead of
                       pausing between lines. Use -p alone for
                       memorization (paced, line-by-line); add -n when
                       you just want to listen naturally while reading
                       along. Example: speak notes.txt -p -n

    -l                 List every voice installed on this Mac, with its
                       locale (e.g. "Anna  de_DE", "Daniel  en_GB").
                       Takes no other arguments.

    -t                 Speak a short English test sentence, then a short
                       German test sentence, using the English and German
                       default voices. Good for checking that both are
                       installed and sound right after setup.

    -h, --help         Show this full help text.

    (no arguments)     Same as -t — runs the English/German test. This
                       means a bare 'speak' with nothing else is a quick
                       sanity check, not an error.

EXAMPLES
    speak notes.txt
    speak notes.txt -v Samantha
    speak notes.txt -r 180
    speak notes.txt -o out.m4a
    speak notes.txt -g
    speak notes.txt -g Helga
    speak -r 220 -v Daniel wispr-flow-response.txt
    speak gedicht.txt -g -r 150
    echo "hello" | speak -
    speak -l
    speak -t

NOTES
    - Options can appear before or after the filename, in any order.
    - -v, -g, and -e all just set which voice is used; the last one
      given on the command line wins if you combine them.
HELPEOF
    )

    # Write the file first, then display THAT file — so what you see on
    # screen and what's saved on disk are guaranteed to be the same text,
    # not two separate copies that could drift apart.
    mkdir -p "$HOME/Documents" 2>/dev/null
    print "$HELPTEXT" > "$USAGE_FILE" 2>/dev/null

    if [[ -r "$USAGE_FILE" ]]; then
        cat "$USAGE_FILE"
    else
        print "$HELPTEXT"   # fallback if the file couldn't be written
    fi

    print ""
    print -n "Open $USAGE_FILE in a text window? y or n: "
    typeset ANSWER=""
    read ANSWER

    case "$ANSWER" in
        # 'open' launches the file in whatever app handles plain text by
        # default (normally TextEdit) — an ordinary window, closed with
        # the usual red button. No terminal pager or editor skills needed.
        [Yy]|[Yy][Ee][Ss]) open -t "$USAGE_FILE" ;;
        *) ;;   # anything else: just exit, nothing opens
    esac

    exit 0
}

# Look up a voice's locale (e.g. "de_DE") from 'say -v ?'. Empty if not found.
# Some voices list as e.g. "Anna (Premium)   de_DE   # ..." — extra text
# between the name and the locale — so we don't assume a fixed column;
# instead we find whichever field actually looks like a locale code.
voice_lang() {
    say -v '?' | awk -v v="$1" '
        $0 ~ "^"v"[ \t]" || $0 ~ "^"v"$" {
            for (i=1; i<=NF; i++) {
                if ($i ~ /^[a-z][a-z]_[A-Z][A-Z]$/) { print $i; exit }
            }
        }
    '
}

# Warn (not block) if a voice named under -g/-e doesn't match that language.
check_lang_match() {
    typeset flag="$1" voice="$2" lang
    lang=$(voice_lang "$voice")
    [[ -z "$lang" ]] && return   # unknown voice name; let 'say' report the error itself
    case "$flag" in
        g) [[ "$lang" != de_* ]] && print -u2 "Note: '$voice' is a $lang voice, not German — using it anyway." ;;
        e) [[ "$lang" != en_* ]] && print -u2 "Note: '$voice' is a $lang voice, not English — using it anyway." ;;
    esac
}

[[ "$1" == "-h" || "$1" == "--help" ]] && help
[[ "$1" == "-l" ]] && { say -v '?'; exit 0; }

run_test() {
    print ""
    print "English (${ENGLISH_DEFAULT_VOICE}): "
    print ""
    print "$TEST_EN"
    print ""
    say -v "$ENGLISH_DEFAULT_VOICE" ${DEFAULT_RATE:+-r "$DEFAULT_RATE"} "$TEST_EN"
    print ""
    print "German (${GERMAN_DEFAULT_VOICE}): "
    print ""
    print "$TEST_DE"
    print ""
    say -v "$GERMAN_DEFAULT_VOICE" ${DEFAULT_RATE:+-r "$DEFAULT_RATE"} "$TEST_DE"
    print ""
    print "speak -h will show the usage message."
    print ""
    exit 0
}

# No arguments at all, or explicit -t: run the test.
[[ $# -eq 0 ]] && run_test
[[ "$1" == "-t" && $# -eq 1 ]] && run_test

# Parse all args in any order: whichever token isn't a recognized
# option (or its value) is taken as the input file/stdin marker.
while [[ $# -gt 0 ]]; do
    case "$1" in
        -v) VOICE="$2"; shift 2 ;;
        -r) RATE="$2"; shift 2 ;;
        -o) OUTFILE="$2"; shift 2 ;;
        -g)
            # -g optionally takes a voice name. Peek at the next token:
            # if it's not another option and not an existing file, treat
            # it as the German voice name; otherwise use the default and
            # leave that token alone (it's probably the input file).
            if [[ -n "$2" && "$2" != -* && ! -f "$2" ]]; then
                VOICE="$2"; LANG_FLAG="g"; shift 2
            else
                VOICE="$GERMAN_DEFAULT_VOICE"; LANG_FLAG="g"; shift 1
            fi
            ;;
        -e)
            # Same pattern as -g, but for English.
            if [[ -n "$2" && "$2" != -* && ! -f "$2" ]]; then
                VOICE="$2"; LANG_FLAG="e"; shift 2
            else
                VOICE="$ENGLISH_DEFAULT_VOICE"; LANG_FLAG="e"; shift 1
            fi
            ;;
        -l) say -v '?'; exit 0 ;;
        -h|--help) help ;;
        -p) PFLAG=1; shift ;;
        -n) NFLAG=1; shift ;;
        -t) usage ;;   # -t only makes sense alone (handled above)
        -*) usage ;;
        *)  INPUT="$1"; shift ;;
    esac
done

[[ -z "$INPUT" ]] && usage

[[ -n "$VOICE" && -n "$LANG_FLAG" ]] && check_lang_match "$LANG_FLAG" "$VOICE"

typeset -a SAY_ARGS
[[ -n "$VOICE" ]] && SAY_ARGS+=("-v" "$VOICE")
[[ -n "$RATE" ]]  && SAY_ARGS+=("-r" "$RATE")

if [[ -n "$OUTFILE" ]]; then
    case "$OUTFILE" in
        *.m4a) SAY_ARGS+=("-o" "$OUTFILE" "--file-format=m4af" "--data-format=aac") ;;
        *)     SAY_ARGS+=("-o" "$OUTFILE") ;;
    esac
fi

# Real file-not-found check happens before any of this for file input.
if [[ "$INPUT" != "-" && ! -f "$INPUT" ]]; then
    print "Error: file not found: $INPUT"
    exit 1
fi

if [[ -n "$PFLAG" && -z "$OUTFILE" && -z "$NFLAG" ]]; then
    # Line-by-line sync: print each line right before 'say' speaks it.
    # 'say' blocks until it finishes a line, so printing-then-speaking
    # in the same loop iteration keeps the two in step naturally.
    # Good for memorization/follow-along reading — not for natural listening,
    # since there's a beat between lines. Use -n for continuous reading instead.
    if [[ "$INPUT" == "-" ]]; then
        while IFS= read -r line; do
            print "$line"
            [[ -n "$line" ]] && say "${SAY_ARGS[@]}" "$line"
        done
    else
        while IFS= read -r line; do
            print "$line"
            [[ -n "$line" ]] && say "${SAY_ARGS[@]}" "$line"
        done < "$INPUT"
    fi
elif [[ -n "$PFLAG" ]]; then
    # -p combined with -o or -n: skip the line-by-line pausing. Either
    # saving to one continuous audio file, or you explicitly asked for
    # a natural, uninterrupted reading (-n) — so print the whole text up
    # front, then speak it as a single continuous pass.
    print ""
    if [[ "$INPUT" == "-" ]]; then
        tee /dev/stdout | say "${SAY_ARGS[@]}"
    else
        cat "$INPUT"
        print ""
        say "${SAY_ARGS[@]}" -f "$INPUT"
    fi
else
    if [[ "$INPUT" == "-" ]]; then
        say "${SAY_ARGS[@]}"
    else
        say "${SAY_ARGS[@]}" -f "$INPUT"
    fi
fi

if [[ -n "$OUTFILE" ]]; then
    print "Saved audio to: $OUTFILE"
fi
