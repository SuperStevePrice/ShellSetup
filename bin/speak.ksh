#!/bin/ksh
#
# speak.ksh — read text aloud using the system's built-in text-to-speech:
#             macOS (say) or Linux (espeak-ng). Can also save audio to a file.
#
# macOS: works out of the box (uses the built-in 'say' command).
# Linux: requires espeak-ng — install with: sudo apt install espeak-ng
#        (Debian/Ubuntu) or your distro's equivalent.
# Windows: not supported yet, even under Cygwin/MSYS/MinGW.

# ---------------------------------------------------------------------------
# Platform detection. Everything below that actually speaks goes through
# PLATFORM so macOS ('say') and Linux ('espeak-ng') share one set of flags
# (-v, -g, -e, -r, -o, -p, -n, -t, -l, -h) even though the underlying
# commands and voice-naming schemes are quite different.
# ---------------------------------------------------------------------------
typeset PLATFORM=""
case "$(uname)" in
    Darwin) PLATFORM="darwin" ;;
    Linux)  PLATFORM="linux" ;;
    CYGWIN*|MINGW*|MSYS*)
        print "Windows version coming soon! Well, maybe."
        exit 0
        ;;
    *)
        print "Unsupported platform: $(uname). This tool supports macOS and Linux (Windows coming soon)."
        exit 0
        ;;
esac

# Defaults — change these to taste.
# Run './speak.ksh -l' to see every installed voice (and, on macOS, its locale).
# Voice NAMES differ by platform: macOS uses human names (Anna, Daniel,
# Samantha...); Linux/espeak-ng uses language codes (de, en-us, en-gb...).
typeset GERMAN_DEFAULT_VOICE=""
typeset ENGLISH_DEFAULT_VOICE=""
case "$PLATFORM" in
    darwin) GERMAN_DEFAULT_VOICE="Anna";  ENGLISH_DEFAULT_VOICE="Samantha" ;;
    linux)  GERMAN_DEFAULT_VOICE="de";    ENGLISH_DEFAULT_VOICE="en-us"   ;;
esac
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
    print "Usage: $0 <textfile|-> [-v voice] [-g [voice]] [-e [voice]] [-r rate] [-o outfile] [-p] [-n]"
    print "       $0 -l            (list available voices)"
    print "       $0 -t            (speak English then German test sentences)"
    print "       $0 -h | --help   (full help)"
    print "See $USAGE_FILE"
    exit 1
}

help() {
    typeset HELPTEXT
    HELPTEXT=$(cat << 'HELPEOF'
speak.ksh — read text aloud (macOS 'say' or Linux 'espeak-ng'), or save it
as an audio file.

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
    -v <voice>         Use this exact voice by name (e.g. -v Daniel on
                       macOS, or -v de on Linux). Voice names differ by
                       platform — run 'speak -l' to see what's actually
                       installed on THIS machine.

    -g [voice]         German shortcut.
                         speak file.txt -g          uses the German
                                                     default voice for
                                                     this platform
                         speak file.txt -g Helga    uses the named voice
                                                     (macOS) or a language
                                                     code like -g de-AT
                                                     (Linux)
                       If the named voice isn't actually German, speak.ksh
                       prints a warning but still uses it — nothing stops
                       you from reading German text in an English voice
                       or vice versa on purpose.

    -e [voice]         English shortcut. Same pattern as -g, defaulting
                       to an English voice for this platform.
                       Same mismatch warning applies if the named voice
                       isn't English.

    -r <rate>          Speech rate in words per minute. Typical usable
                       range is roughly 90-720; the voice's own default
                       is usually around 175-200. Example: -r 220
                       (Same numeric meaning on both platforms.)

    -o <outfile>       Save audio to a file instead of speaking it aloud.
                       macOS:   .aiff (uncompressed) or .m4a (AAC)
                       Linux:   .wav only (espeak-ng writes WAV); if you
                                give another extension on Linux, speak.ksh
                                will note that and save as .wav instead.
                       Example: -o out.m4a   (macOS)
                                -o out.wav   (Linux)

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

    -l                 List every voice installed on this machine.
                       macOS:  name + locale (e.g. "Anna  de_DE").
                       Linux:  espeak-ng's own voice table (language
                               code, name, etc.) — the language code
                               (e.g. "de", "en-us") is what you pass to
                               -v, -g, or -e on this platform.

    -t                 Speak a short English test sentence, then a short
                       German test sentence, using the English and German
                       default voices for this platform. Good for
                       checking that both are installed and sound right.

    -h, --help         Show this full help text.

    (no arguments)     Same as -t — runs the English/German test. This
                       means a bare 'speak' with nothing else is a quick
                       sanity check, not an error.

EXAMPLES
    speak notes.txt
    speak notes.txt -r 180
    speak notes.txt -o out.m4a         (macOS)
    speak notes.txt -o out.wav         (Linux)
    speak notes.txt -g
    speak gedicht.txt -g -r 150
    echo "hello" | speak -
    speak -l
    speak -t

    macOS only:
        speak notes.txt -v Samantha
        speak -r 220 -v Daniel wispr-flow-response.txt
        speak notes.txt -g Helga

    Linux only:
        speak notes.txt -v en-gb
        speak notes.txt -g de-AT

WHILE SPEAKING
    space              Pause / resume the voice (works mid-sentence, in
                       any mode: plain, -p, -p -n, -t — whatever you're
                       running).
    q                  Stop speaking entirely and return to the prompt.
                       In -p line-by-line mode, this also cancels the
                       remaining lines rather than just the current one.

NOTES
    - Options can appear before or after the filename, in any order.
    - -v, -g, and -e all just set which voice is used; the last one
      given on the command line wins if you combine them.
    - Voice NAMES are platform-specific (see -g/-e/-v above); everything
      else (-r, -p, -n, -o's behavior, -t) works the same way on both.
    - space/q controls need a real terminal; if speak.ksh is run from
      somewhere with no controlling terminal (cron, certain pipelines),
      these are silently skipped and it just speaks straight through.
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

    if [[ "$PLATFORM" == "darwin" ]]; then
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
    else
        print "Saved to $USAGE_FILE — open it in any text editor."
    fi

    exit 0
}

# --- Voice/locale lookup and mismatch warning, per platform ---------------

# macOS: look up a voice's locale (e.g. "de_DE") from 'say -v ?'. Some
# voices list as e.g. "Anna (Premium)   de_DE   # ..." — extra text between
# the name and the locale — so we don't assume a fixed column; instead we
# find whichever field actually looks like a locale code.
voice_lang_darwin() {
    say -v '?' | awk -v v="$1" '
        $0 ~ "^"v"[ \t]" || $0 ~ "^"v"$" {
            for (i=1; i<=NF; i++) {
                if ($i ~ /^[a-z][a-z]_[A-Z][A-Z]$/) { print $i; exit }
            }
        }
    '
}

# Warn (not block) if a voice named under -g/-e doesn't match that language.
# On Linux, the "voice" the user supplies IS the language code (e.g. "de",
# "en-gb"), so no lookup is needed — just check its own prefix directly.
check_lang_match() {
    typeset flag="$1" voice="$2" lang

    if [[ "$PLATFORM" == "linux" ]]; then
        case "$flag" in
            g) [[ "$voice" != de* ]] && print -u2 "Note: '$voice' doesn't look like a German voice code — using it anyway." ;;
            e) [[ "$voice" != en* ]] && print -u2 "Note: '$voice' doesn't look like an English voice code — using it anyway." ;;
        esac
        return
    fi

    lang=$(voice_lang_darwin "$voice")
    [[ -z "$lang" ]] && return   # unknown voice name; let 'say' report the error itself
    case "$flag" in
        g) [[ "$lang" != de_* ]] && print -u2 "Note: '$voice' is a $lang voice, not German — using it anyway." ;;
        e) [[ "$lang" != en_* ]] && print -u2 "Note: '$voice' is a $lang voice, not English — using it anyway." ;;
    esac
}

list_voices() {
    case "$PLATFORM" in
        darwin) say -v '?' ;;
        linux)  espeak-ng --voices ;;
    esac
    exit 0
}

[[ "$1" == "-h" || "$1" == "--help" ]] && help

if [[ "$PLATFORM" == "linux" ]]; then
    if ! command -v espeak-ng >/dev/null 2>&1; then
        print "espeak-ng is not installed."
        print "Install it with:  sudo apt install espeak-ng"
        print "(or your distro's equivalent), then try again."
        exit 1
    fi
fi

[[ "$1" == "-l" ]] && list_voices

# --- Universal stop/restart control -----------------------------------------
# space = pause/resume, q = stop entirely — works the same way no matter
# which mode is speaking (plain, -p, -p -n, -t, -g/-e, any voice or rate),
# because every speak_* wrapper below runs through this one function.
#
# Mechanics: run the actual 'say'/'espeak-ng' call in the background, then
# poll the real keyboard (/dev/tty, not stdin — stdin may be busy carrying
# piped text) for a keypress every 0.2s. Space sends SIGSTOP/SIGCONT to
# pause/resume the voice process itself; q kills it and sets QUIT=1 so a
# caller further up (e.g. the -p line-by-line loop) knows to stop entirely
# rather than moving on to the next line.
#
# If there's no real controlling terminal (e.g. run from cron or over a
# plain pipe with no tty at all), controls are silently skipped and the
# command just runs normally — there's no keyboard to read from anyway.
typeset QUIT=0
typeset HAVE_TTY=0
[[ -r /dev/tty && -w /dev/tty ]] && HAVE_TTY=1

if [[ "$HAVE_TTY" -eq 1 ]]; then
    stty -echo -icanon min 1 time 0 < /dev/tty 2>/dev/null
    trap 'stty echo icanon < /dev/tty 2>/dev/null' EXIT INT TERM
fi

run_with_controls() {
    if [[ "$HAVE_TTY" -ne 1 ]]; then
        "$@"
        return
    fi

    "$@" &
    typeset cpid=$!
    typeset paused=0
    typeset key=""

    while kill -0 "$cpid" 2>/dev/null; do
        read -t 0.2 -n 1 key < /dev/tty 2>/dev/null
        case "$key" in
            " ")
                if [[ "$paused" -eq 0 ]]; then
                    if kill -STOP "$cpid" 2>/dev/null; then
                        paused=1
                        print -u2 ""
                        print -u2 "Paused. (space = resume, q = stop)"
                    fi
                    # If kill failed, the process already finished on its
                    # own — nothing to pause, so stay silent rather than
                    # print a misleading "Paused." for a clip that's gone.
                else
                    if kill -CONT "$cpid" 2>/dev/null; then
                        paused=0
                        print -u2 "Resumed."
                    fi
                fi
                ;;
            q|Q)
                kill "$cpid" 2>/dev/null
                QUIT=1
                print -u2 "Stopped."
                break
                ;;
        esac
        key=""
    done

    wait "$cpid" 2>/dev/null
}

# --- Cross-platform speak wrappers ------------------------------------------
# These are the only places that actually invoke 'say' or 'espeak-ng', so
# everything above and below them (argument parsing, -p/-n sync logic) is
# identical regardless of platform.

speak_text() {   # speak a single line/string of text
    typeset text="$1"
    case "$PLATFORM" in
        darwin) run_with_controls say "${SAY_ARGS[@]}" "$text" ;;
        linux)  run_with_controls espeak-ng "${SAY_ARGS[@]}" "$text" ;;
    esac
}

speak_file() {   # speak the contents of a file
    typeset f="$1"
    case "$PLATFORM" in
        darwin) run_with_controls say "${SAY_ARGS[@]}" -f "$f" ;;
        linux)  run_with_controls espeak-ng "${SAY_ARGS[@]}" -f "$f" ;;
    esac
}

speak_stdin() {  # speak whatever's piped in on stdin
    case "$PLATFORM" in
        darwin) run_with_controls say "${SAY_ARGS[@]}" ;;
        linux)  run_with_controls espeak-ng "${SAY_ARGS[@]}" ;;   # espeak-ng also reads stdin with no -f/text given
    esac
}

run_test() {
    typeset -a SAY_ARGS

    SAY_ARGS=()
    case "$PLATFORM" in
        darwin) SAY_ARGS+=("-v" "$ENGLISH_DEFAULT_VOICE"); [[ -n "$DEFAULT_RATE" ]] && SAY_ARGS+=("-r" "$DEFAULT_RATE") ;;
        linux)  SAY_ARGS+=("-v" "$ENGLISH_DEFAULT_VOICE"); [[ -n "$DEFAULT_RATE" ]] && SAY_ARGS+=("-s" "$DEFAULT_RATE") ;;
    esac
    print ""
    print "English (${ENGLISH_DEFAULT_VOICE}): "
    print ""
    print "$TEST_EN"
    print ""
    speak_text "$TEST_EN"

    SAY_ARGS=()
    case "$PLATFORM" in
        darwin) SAY_ARGS+=("-v" "$GERMAN_DEFAULT_VOICE"); [[ -n "$DEFAULT_RATE" ]] && SAY_ARGS+=("-r" "$DEFAULT_RATE") ;;
        linux)  SAY_ARGS+=("-v" "$GERMAN_DEFAULT_VOICE"); [[ -n "$DEFAULT_RATE" ]] && SAY_ARGS+=("-s" "$DEFAULT_RATE") ;;
    esac
    print ""
    print "German (${GERMAN_DEFAULT_VOICE}): "
    print ""
    print "$TEST_DE"
    print ""
    speak_text "$TEST_DE"

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
        -l) list_voices ;;
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
if [[ -n "$RATE" ]]; then
    case "$PLATFORM" in
        darwin) SAY_ARGS+=("-r" "$RATE") ;;
        linux)  SAY_ARGS+=("-s" "$RATE") ;;
    esac
fi

if [[ -n "$OUTFILE" ]]; then
    case "$PLATFORM" in
        darwin)
            case "$OUTFILE" in
                *.m4a) SAY_ARGS+=("-o" "$OUTFILE" "--file-format=m4af" "--data-format=aac") ;;
                *)     SAY_ARGS+=("-o" "$OUTFILE") ;;
            esac
            ;;
        linux)
            # espeak-ng only writes WAV. If the name doesn't end in .wav,
            # say so plainly and switch the extension rather than silently
            # producing a mislabeled file.
            case "$OUTFILE" in
                *.wav) ;;
                *)
                    print "Note: Linux (espeak-ng) only saves .wav files — saving as ${OUTFILE}.wav instead."
                    OUTFILE="${OUTFILE}.wav"
                    ;;
            esac
            SAY_ARGS+=("-w" "$OUTFILE")
            ;;
    esac
fi

# Real file-not-found check happens before any of this for file input.
if [[ "$INPUT" != "-" && ! -f "$INPUT" ]]; then
    print "Error: file not found: $INPUT"
    exit 1
fi

if [[ -n "$PFLAG" && -z "$OUTFILE" && -z "$NFLAG" ]]; then
    # Line-by-line sync: print each line right before speaking it.
    # Both 'say' and 'espeak-ng' block until they finish a line, so
    # printing-then-speaking in the same loop iteration keeps the two
    # in step naturally.
    # Good for memorization/follow-along reading — not for natural listening,
    # since there's a beat between lines. Use -n for continuous reading instead.
    if [[ "$INPUT" == "-" ]]; then
        while IFS= read -r line; do
            print "$line"
            [[ -n "$line" ]] && speak_text "$line"
            [[ "$QUIT" -eq 1 ]] && break
        done
    else
        while IFS= read -r line; do
            print "$line"
            [[ -n "$line" ]] && speak_text "$line"
            [[ "$QUIT" -eq 1 ]] && break
        done < "$INPUT"
    fi
elif [[ -n "$PFLAG" ]]; then
    # -p combined with -o or -n: skip the line-by-line pausing. Either
    # saving to one continuous audio file, or you explicitly asked for
    # a natural, uninterrupted reading (-n) — so print the whole text up
    # front, then speak it as a single continuous pass.
    print ""
    if [[ "$INPUT" == "-" ]]; then
        tee /dev/stdout | speak_stdin
    else
        cat "$INPUT"
        print ""
        speak_file "$INPUT"
    fi
else
    if [[ "$INPUT" == "-" ]]; then
        speak_stdin
    else
        speak_file "$INPUT"
    fi
fi

if [[ -n "$OUTFILE" ]]; then
    print "Saved audio to: $OUTFILE"
fi
