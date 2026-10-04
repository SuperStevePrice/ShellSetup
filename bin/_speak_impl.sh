#
# _speak_impl.sh — shared implementation, sourced by both speak.ksh and
# speak.sh. Not meant to be run directly (no shebang, no execute bit, and
# setup.ksh's set_symbolic_links() skips it on its leading underscore).
#
# Everything below is plain POSIX-ish shell ([[ ]], typeset, arrays,
# printf) that runs identically under ksh93 and bash, so one body serves
# both wrappers instead of two copies that could silently drift apart.
# $0 is whatever the CALLER (the wrapper) was invoked as — sourcing
# doesn't change it — so Usage/help text below correctly shows "speak",
# "speak.ksh", or "speak.sh" depending on which one the user actually ran.
#
# read text aloud using the system's built-in text-to-speech: macOS
# (say) or Linux (espeak-ng). Can also save audio to a file.
#
# macOS: works out of the box (uses the built-in 'say' command).
# Linux: requires espeak-ng — install with: sudo apt install espeak-ng
#        (Debian/Ubuntu) or your distro's equivalent.
# Windows: use speak.ps1 instead (native PowerShell version).

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
        printf '%s\n' "You're on Windows — use speak.ps1 instead (run it in PowerShell)."
        exit 0
        ;;
    *)
        printf '%s\n' "Unsupported platform: $(uname). This tool supports macOS and Linux; Windows users should use speak.ps1."
        exit 0
        ;;
esac

# Defaults — change these to taste.
# Run 'speak -l' to see every installed voice (and, on macOS, its locale).
# Voice NAMES differ by platform: macOS uses human names (Anna, Daniel,
# Samantha...); Linux/espeak-ng uses language codes (de, en-us, en-gb...).
typeset GERMAN_DEFAULT_VOICE=""
typeset ENGLISH_DEFAULT_VOICE=""
typeset SPANISH_DEFAULT_VOICE=""
typeset FRENCH_DEFAULT_VOICE=""
case "$PLATFORM" in
    darwin) GERMAN_DEFAULT_VOICE="Anna";  ENGLISH_DEFAULT_VOICE="Samantha"; SPANISH_DEFAULT_VOICE="Mónica"; FRENCH_DEFAULT_VOICE="Thomas" ;;
    linux)  GERMAN_DEFAULT_VOICE="de";    ENGLISH_DEFAULT_VOICE="en-us";    SPANISH_DEFAULT_VOICE="es";     FRENCH_DEFAULT_VOICE="fr"     ;;
esac
typeset DEFAULT_RATE=""   # leave blank to use the voice's own default rate

# Test sentences used by -t (and by running with no arguments).
typeset TEST_EN="This is the speak command, reading text aloud with your Mac's built-in voices at whatever rate and voice you choose."
typeset TEST_DE="Dies ist das Sprachprogramm, das Texte mit den eingebauten Stimmen Ihres Mac in beliebiger Geschwindigkeit und Stimme vorliest."
typeset TEST_ES="Este es el comando speak, que lee texto en voz alta con las voces integradas de su Mac a la velocidad y con la voz que usted elija."
typeset TEST_FR="Ceci est la commande speak, qui lit le texte à voix haute avec les voix intégrées de votre Mac, à la vitesse et avec la voix de votre choix."

typeset VOICE=""
typeset RATE=""
typeset OUTFILE=""
typeset INPUT=""
typeset LANG_FLAG=""   # "g", "e", "s", or "f", so we know which default/validation applies
typeset PFLAG=""       # set if -p (print text while speaking) was given
typeset NFLAG=""       # set if -n (natural/continuous reading, no per-line pause) was given
typeset XLANG=""       # set to the language name/code given after -x, if any

typeset USAGE_FILE="$HOME/Documents/speak.usage"

usage() {
    printf '%s\n' "Usage: $0 <textfile|-> [-v voice] [-g [voice]] [-e [voice]] [-s [voice]] [-f [voice]] [-r rate] [-o outfile] [-p] [-n] [-x lang]"
    printf '%s\n' "       $0 -l            (list available voices)"
    printf '%s\n' "       $0 -t            (speak English, German, then Spanish test sentences)"
    printf '%s\n' "       $0 -h | --help   (full help)"
    printf '%s\n' "See $USAGE_FILE"
    exit 1
}

help() {
    typeset HELPTEXT
    HELPTEXT=$(cat << 'HELPEOF'
speak — read text aloud (macOS 'say' or Linux 'espeak-ng'), or save it
as an audio file.

USAGE
    speak <textfile|-> [options]
    speak -l
    speak -t
    speak -h | --help

ARGUMENTS
    <textfile>        Path to a text file to read aloud. A bare filename
                       (no "/") is first looked for in the current
                       directory, as always; if not found there, it's
                       looked for in ~/Documents instead. If ~/Documents
                       doesn't exist, you'll be prompted for the full path.
    -                  Read from stdin instead of a file (e.g. for piping).
                       Example: echo "hello" | speak -

    Lines starting with "#" are never spoken, in any mode -- they're
    still shown on screen wherever the text is printed, just skipped by
    the voice. This matters for files setup.ksh has stamped with a
    "Last installed:" / "End of File" footer, so that footer doesn't
    get read aloud.

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
                       If the named voice isn't actually German, speak
                       prints a warning but still uses it — nothing stops
                       you from reading German text in an English voice
                       or vice versa on purpose.

    -e [voice]         English shortcut. Same pattern as -g, defaulting
                       to an English voice for this platform.
                       Same mismatch warning applies if the named voice
                       isn't English.

    -s [voice]         Spanish shortcut. Same pattern as -g/-e.
                         speak file.txt -s          uses the Spanish
                                                     default voice for
                                                     this platform
                         speak file.txt -s Paulina  uses the named voice
                                                     (macOS) or a language
                                                     code like -s es-MX
                                                     (Linux)
                       Same mismatch warning applies if the named voice
                       isn't Spanish.

    -f [voice]         French shortcut. Same pattern as -g/-e/-s.
                         speak file.txt -f          uses the French
                                                     default voice for
                                                     this platform
                         speak file.txt -f Thomas   uses the named voice
                                                     (macOS) or a language
                                                     code like -f fr-CA
                                                     (Linux)
                       Same mismatch warning applies if the named voice
                       isn't French.

    -r <rate>          Speech rate in words per minute. Typical usable
                       range is roughly 90-720; the voice's own default
                       is usually around 175-200. Example: -r 220
                       (Same numeric meaning on both platforms.)

    -o <outfile>       Save audio to a file instead of speaking it aloud.
                       macOS:   .aiff (uncompressed) or .m4a (AAC)
                       Linux:   .wav only (espeak-ng writes WAV); if you
                                give another extension on Linux, speak
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

    -x <language>      Translate each line and speak the translation
                       right after the original line. <language> accepts
                       either a common name (English, German, Spanish,
                       French...) or a code (en, de, es, fr...), case-
                       insensitive (English, english, and EN all work
                       the same), and can appear anywhere on the command
                       line like any other option.
                       Example: speak gedicht.txt -p -g -x English
                       Requires translate-shell (the 'trans' command):
                         macOS:  brew install translate-shell
                         Linux:  sudo apt install translate-shell
                       Source language comes from -g/-e/-s if one of
                       those is given, else it's auto-detected.
                       If <language> isn't a language trans can
                       translate to, you'll get a warning plus the full
                       list of available languages, and the file is
                       still spoken normally -- just without translation.
                       Only takes effect in plain -p mode (no -n, no
                       -o) -- translation is interleaved line-by-line,
                       which needs that loop. Combined with -n or -o,
                       or without -p at all, -x is ignored with a note
                       rather than failing outright.

    -l                 List every voice installed on this machine.
                       macOS:  name + locale (e.g. "Anna  de_DE").
                       Linux:  espeak-ng's own voice table (language
                               code, name, etc.) — the language code
                               (e.g. "de", "en-us") is what you pass to
                               -v, -g, or -e on this platform.

    -t                 Speak a short English test sentence, then German,
                       Spanish, and French, using each language's default
                       voice for this platform. Good for checking that
                       all four are installed and sound right.

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
    speak notes.txt -s
    speak poema.txt -s -r 150
    speak notes.txt -f
    speak texte.txt -f -r 150
    speak gedicht.txt -p -g -x English
    echo "hello" | speak -
    speak -l
    speak -t

    macOS only:
        speak notes.txt -v Samantha
        speak -r 220 -v Daniel wispr-flow-response.txt
        speak notes.txt -g Helga
        speak notes.txt -s Paulina
        speak notes.txt -f Thomas

    Linux only:
        speak notes.txt -v en-gb
        speak notes.txt -g de-AT
        speak notes.txt -s es-MX
        speak notes.txt -f fr-CA

WHILE SPEAKING
    space              Pause / resume the voice (works mid-sentence, in
                       any mode: plain, -p, -p -n, -t — whatever you're
                       running).
    q                  Stop speaking entirely and return to the prompt.
                       In -p line-by-line mode, this also cancels the
                       remaining lines rather than just the current one.

NOTES
    - Options can appear before or after the filename, in any order.
    - -v, -g, -e, -s, and -f all just set which voice is used; the last
      one given on the command line wins if you combine them.
    - After -g/-e/-s/-f, the next token is treated as a filename (not a
      voice name) if it contains "/" or "." — even if that file doesn't
      exist at the current path. That way a mistyped path or wrong
      working directory gives a clear "file not found", instead of the
      filename silently being swallowed as a bogus voice name.
    - A bare filename (no "/") is checked in the current directory
      first, as always. If not found there, ~/Documents is tried next.
      If ~/Documents doesn't exist, you'll be prompted for the full
      path instead. Give a relative (e.g. ./notes.txt) or absolute path
      directly to bypass this and use that path as-is.
    - Voice NAMES are platform-specific (see -g/-e/-s/-f/-v above); everything
      else (-r, -p, -n, -o's behavior, -t) works the same way on both.
    - -x only works in plain -p mode (no -n, no -o); elsewhere it's
      ignored with a note, since it needs the line-by-line loop.
    - Lines starting with "#" are never spoken, in any mode -- useful
      for files setup.ksh has stamped with its install footer. They're
      still printed on screen wherever the text is shown, just not
      spoken.
    - Decorative divider lines (made up entirely of characters like
      "====", "----", "****", "____", "~~~~", or a mix of these, with
      no actual letters or digits) are skipped the same way -- shown
      on screen, never read aloud.
    - space/q controls need a real terminal; if speak is run from
      somewhere with no controlling terminal (cron, certain pipelines),
      these are silently skipped and it just speaks straight through.
HELPEOF
    )

    # Write the file first, then display THAT file — so what you see on
    # screen and what's saved on disk are guaranteed to be the same text,
    # not two separate copies that could drift apart.
    mkdir -p "$HOME/Documents" 2>/dev/null
    printf '%s\n' "$HELPTEXT" > "$USAGE_FILE" 2>/dev/null

    if [[ -r "$USAGE_FILE" ]]; then
        cat "$USAGE_FILE"
    else
        printf '%s\n' "$HELPTEXT"   # fallback if the file couldn't be written
    fi

    printf '\n'

    if [[ "$PLATFORM" == "darwin" ]]; then
        printf '%s' "Open $USAGE_FILE in a text window? y or n: "
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
        printf '%s\n' "Saved to $USAGE_FILE — open it in any text editor."
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
            g) [[ "$voice" != de* ]] && printf '%s\n' "Note: '$voice' doesn't look like a German voice code — using it anyway." >&2 ;;
            e) [[ "$voice" != en* ]] && printf '%s\n' "Note: '$voice' doesn't look like an English voice code — using it anyway." >&2 ;;
            s) [[ "$voice" != es* ]] && printf '%s\n' "Note: '$voice' doesn't look like a Spanish voice code — using it anyway." >&2 ;;
            f) [[ "$voice" != fr* ]] && printf '%s\n' "Note: '$voice' doesn't look like a French voice code — using it anyway." >&2 ;;
        esac
        return
    fi

    lang=$(voice_lang_darwin "$voice")
    [[ -z "$lang" ]] && return   # unknown voice name; let 'say' report the error itself
    case "$flag" in
        g) [[ "$lang" != de_* ]] && printf '%s\n' "Note: '$voice' is a $lang voice, not German — using it anyway." >&2 ;;
        e) [[ "$lang" != en_* ]] && printf '%s\n' "Note: '$voice' is a $lang voice, not English — using it anyway." >&2 ;;
        s) [[ "$lang" != es_* ]] && printf '%s\n' "Note: '$voice' is a $lang voice, not Spanish — using it anyway." >&2 ;;
        f) [[ "$lang" != fr_* ]] && printf '%s\n' "Note: '$voice' is a $lang voice, not French — using it anyway." >&2 ;;
    esac
}

# Peek-ahead helper for -g/-e/-s: is the next token more likely a filename
# than a voice name? Real voice names on both platforms (Anna, Daniel,
# Helga, de-AT, es-MX, Mónica...) are bare words/codes — no "/" and no
# ".". A path or a file with an extension has one or the other, even if
# that file doesn't currently exist (wrong directory, typo). Without this,
# a missing/mistyped filename after -g/-e/-s got silently treated as a
# voice name instead, leaving no input file and a confusing generic usage
# error — this makes it fall through to the input slot instead, so the
# real "Error: file not found: ..." message fires.
looks_like_file() {
    case "$1" in
        */*|*.*) return 0 ;;
        *)       return 1 ;;
    esac
}

list_voices() {
    case "$PLATFORM" in
        darwin) say -v '?' ;;
        linux)  espeak-ng --voices ;;
    esac
    exit 0
}

# --- Comment-line filtering -----------------------------------------------
# Lines starting with "#" (e.g. the "Last installed:"/"End of File" footer
# setup.ksh stamps onto installed text files) are never spoken -- in any
# mode, not just -p. They're still shown on screen wherever the script
# already prints text, just never passed to say/espeak-ng.
#
# Used for whole-file speaking (plain mode, or -p combined with -n/-o,
# where the file goes to say/espeak-ng's own -f flag rather than through
# our line-by-line loop): makes a comment-stripped temp copy first, since
# say/espeak-ng read the file directly and have no way to skip lines
# themselves. The line-by-line loop below filters inline instead and
# never needs this.
# A "divider" line is one made up entirely of punctuation commonly used
# for ASCII section rules/underlines -- "====", "----", "****", "____",
# "~~~~", mixes of these, etc. -- with no actual letters or digits in it.
# Such lines are meant to be *looked at*, not read aloud; speaking "equals
# equals equals..." fifty times is just noise. They're still printed on
# screen wherever the script already shows text -- only the speaking is
# skipped, same as comment lines.
#
# Implementation: strip every character in the divider-character set out
# of the line; if nothing's left, it was made up entirely of those
# characters. A blank/whitespace-only line also strips down to nothing,
# but that's handled separately (callers already skip empty lines), so
# it never reaches this check in practice.
is_divider_line() {
    typeset stripped
    stripped=$(printf '%s' "$1" | tr -d ' \t=_*+.^#~>/\\-')
    [[ -z "$stripped" ]]
}

strip_comments_to_tmp() {
    typeset src="$1"
    typeset tmp line
    tmp=$(mktemp "${TMPDIR:-/tmp}/speak_filtered.XXXXXX")
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" == '#'* ]] && continue
        is_divider_line "$line" && continue
        printf '%s\n' "$line"
    done < "$src" > "$tmp"
    printf '%s' "$tmp"
}

# --- Translation (-x) helpers ------------------------------------------

# Turn a common language name or an existing code into a code trans,
# say, and espeak-ng can all work with. Anything not in this short list
# is passed through lowercased as-is -- trans itself recognizes many
# full language names too, so this isn't the only safety net, just a
# shortcut for the handful of languages this script also has a known
# default voice for.
resolve_lang_code() {
    typeset input
    input=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
    case "$input" in
        english|en)          printf '%s' "en" ;;
        german|deutsch|de)   printf '%s' "de" ;;
        spanish|espanol|es)  printf '%s' "es" ;;
        french|francais|fr)  printf '%s' "fr" ;;
        italian|it)          printf '%s' "it" ;;
        portuguese|pt)       printf '%s' "pt" ;;
        dutch|nl)            printf '%s' "nl" ;;
        russian|ru)          printf '%s' "ru" ;;
        japanese|ja)         printf '%s' "ja" ;;
        chinese|zh)          printf '%s' "zh" ;;
        *)                   printf '%s' "$input" ;;
    esac
}

# Translate one line of text via translate-shell. -brief keeps trans
# from printing dictionary/extra info -- just the translation itself.
translate_line() {
    typeset line="$1"
    trans -brief "${SOURCE_CODE}:${TARGET_CODE}" "$line" 2>/dev/null
}

# Full list of language CODES translate-shell recognizes, one per line
# (en, de, es, fr, ...) -- this is what gets checked against the
# resolved code below, so it has to be the codes list, not a list of
# language NAMES (an earlier version of this called -list-languages-all,
# which both doesn't exist as a real trans flag, and -- even swapped for
# the real -list-languages-english -- would still be the wrong kind of
# list to check a short code like "en" against).
list_available_languages() {
    trans -list-codes 2>/dev/null
}

# Check the resolved target code against that list before trusting it.
# Prints a warning plus the full list and returns failure if it's not
# recognized, rather than silently calling trans with a bogus code and
# getting back an empty/garbled result with no clear explanation.
#
# If the list itself can't be retrieved (older translate-shell version,
# flag name changed, network hiccup for whatever trans needs to build
# it), this doesn't block -- there's nothing solid to check against, so
# it lets trans itself be the final word once it actually runs.
validate_target_lang() {
    typeset code="$1" raw="$2"
    typeset lang_list
    lang_list=$(list_available_languages)

    [[ -z "$lang_list" ]] && return 0

    if printf '%s\n' "$lang_list" | tr '[:upper:]' '[:lower:]' | grep -qiE "(^|[^a-z])${code}([^a-z]|\$)"; then
        return 0
    fi

    printf '%s\n' "Warning: '$raw' is not a recognized language for translation. Available languages:" >&2
    printf '%s\n' "$lang_list" >&2
    return 1
}

[[ "$1" == "-h" || "$1" == "--help" ]] && help

if [[ "$PLATFORM" == "linux" ]]; then
    if ! command -v espeak-ng >/dev/null 2>&1; then
        printf '%s\n' "espeak-ng is not installed."
        printf '%s\n' "Install it with:  sudo apt install espeak-ng"
        printf '%s\n' "(or your distro's equivalent), then try again."
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

# Discard any characters already sitting in the /dev/tty input queue,
# without blocking. Used right after we detect a keypress we're about to
# act on, so leftover duplicate bytes from that same press (key-repeat,
# terminal buffering) don't get read and acted on again next tick.
drain_tty() {
    [[ "$HAVE_TTY" -ne 1 ]] && return
    typeset junk=""
    while read -t 0 -n 1 junk < /dev/tty 2>/dev/null; do
        :
    done
}

run_with_controls() {
    if [[ "$HAVE_TTY" -ne 1 ]]; then
        "$@"
        return
    fi

    "$@" &
    typeset cpid=$!
    typeset paused=0
    typeset key=""
    # After any space/q is acted on, the spacebar goes silent for a short
    # beat (a few poll ticks, ~0.4s at the 0.2s poll interval below) before
    # it'll respond again. Belt-and-suspenders alongside drain_tty: the
    # drain clears out whatever's already queued from this same press: the
    # ignore window below also shrugs off anything that lands a tick or two
    # later (a laggy key-repeat, a terminal that trickles bytes in). First
    # press always wins; nothing close behind it gets a second vote.
    typeset IGNORE_TICKS=0

    while kill -0 "$cpid" 2>/dev/null; do
        read -t 0.2 -n 1 key < /dev/tty 2>/dev/null

        if [[ "$IGNORE_TICKS" -gt 0 ]]; then
            IGNORE_TICKS=$((IGNORE_TICKS - 1))
            key=""
            continue
        fi

        case "$key" in
            " ")
                # Eat any duplicate space bytes left over from this same
                # press BEFORE acting, so one tap toggles state exactly
                # once instead of stuttering pause/resume/pause.
                drain_tty

                if [[ "$paused" -eq 0 ]]; then
                    if kill -STOP "$cpid" 2>/dev/null; then
                        paused=1
                        printf '\n' >&2
                        printf '%s\n' "Paused. (space = resume, q = stop)" >&2
                    fi
                    # If kill failed, the process already finished on its
                    # own — nothing to pause, so stay silent rather than
                    # print a misleading "Paused." for a clip that's gone.
                else
                    if kill -CONT "$cpid" 2>/dev/null; then
                        paused=0
                        printf '%s\n' "Resumed." >&2
                    fi
                fi
                IGNORE_TICKS=2
                ;;
            q|Q)
                drain_tty
                kill "$cpid" 2>/dev/null
                QUIT=1
                printf '%s\n' "Stopped." >&2
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

speak_file() {   # speak the contents of a file, skipping comment lines
    typeset f="$1"
    typeset filtered
    filtered=$(strip_comments_to_tmp "$f")
    case "$PLATFORM" in
        darwin) run_with_controls say "${SAY_ARGS[@]}" -f "$filtered" ;;
        linux)  run_with_controls espeak-ng "${SAY_ARGS[@]}" -f "$filtered" ;;
    esac
    rm -f "$filtered"
}

speak_stdin() {  # speak whatever's piped in on stdin, skipping comment/divider lines
    typeset tmp line
    tmp=$(mktemp "${TMPDIR:-/tmp}/speak_stdin_filtered.XXXXXX")
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" == '#'* ]] && continue
        is_divider_line "$line" && continue
        printf '%s\n' "$line"
    done > "$tmp"
    case "$PLATFORM" in
        darwin) run_with_controls say "${SAY_ARGS[@]}" -f "$tmp" ;;
        linux)  run_with_controls espeak-ng "${SAY_ARGS[@]}" -f "$tmp" ;;
    esac
    rm -f "$tmp"
}

speak_translation_text() {   # speak one translated line, using the TARGET voice/rate (TRANS_SAY_ARGS), not the source's
    typeset text="$1"
    case "$PLATFORM" in
        darwin) run_with_controls say "${TRANS_SAY_ARGS[@]}" "$text" ;;
        linux)  run_with_controls espeak-ng "${TRANS_SAY_ARGS[@]}" "$text" ;;
    esac
}

run_test() {
    typeset -a SAY_ARGS

    SAY_ARGS=()
    case "$PLATFORM" in
        darwin) SAY_ARGS+=("-v" "$ENGLISH_DEFAULT_VOICE"); [[ -n "$DEFAULT_RATE" ]] && SAY_ARGS+=("-r" "$DEFAULT_RATE") ;;
        linux)  SAY_ARGS+=("-v" "$ENGLISH_DEFAULT_VOICE"); [[ -n "$DEFAULT_RATE" ]] && SAY_ARGS+=("-s" "$DEFAULT_RATE") ;;
    esac
    printf '\n'
    printf '%s\n' "English (${ENGLISH_DEFAULT_VOICE}): "
    printf '\n'
    printf '%s\n' "$TEST_EN"
    printf '\n'
    speak_text "$TEST_EN"

    SAY_ARGS=()
    case "$PLATFORM" in
        darwin) SAY_ARGS+=("-v" "$GERMAN_DEFAULT_VOICE"); [[ -n "$DEFAULT_RATE" ]] && SAY_ARGS+=("-r" "$DEFAULT_RATE") ;;
        linux)  SAY_ARGS+=("-v" "$GERMAN_DEFAULT_VOICE"); [[ -n "$DEFAULT_RATE" ]] && SAY_ARGS+=("-s" "$DEFAULT_RATE") ;;
    esac
    printf '\n'
    printf '%s\n' "German (${GERMAN_DEFAULT_VOICE}): "
    printf '\n'
    printf '%s\n' "$TEST_DE"
    printf '\n'
    speak_text "$TEST_DE"

    SAY_ARGS=()
    case "$PLATFORM" in
        darwin) SAY_ARGS+=("-v" "$SPANISH_DEFAULT_VOICE"); [[ -n "$DEFAULT_RATE" ]] && SAY_ARGS+=("-r" "$DEFAULT_RATE") ;;
        linux)  SAY_ARGS+=("-v" "$SPANISH_DEFAULT_VOICE"); [[ -n "$DEFAULT_RATE" ]] && SAY_ARGS+=("-s" "$DEFAULT_RATE") ;;
    esac
    printf '\n'
    printf '%s\n' "Spanish (${SPANISH_DEFAULT_VOICE}): "
    printf '\n'
    printf '%s\n' "$TEST_ES"
    printf '\n'
    speak_text "$TEST_ES"

    SAY_ARGS=()
    case "$PLATFORM" in
        darwin) SAY_ARGS+=("-v" "$FRENCH_DEFAULT_VOICE"); [[ -n "$DEFAULT_RATE" ]] && SAY_ARGS+=("-r" "$DEFAULT_RATE") ;;
        linux)  SAY_ARGS+=("-v" "$FRENCH_DEFAULT_VOICE"); [[ -n "$DEFAULT_RATE" ]] && SAY_ARGS+=("-s" "$DEFAULT_RATE") ;;
    esac
    printf '\n'
    printf '%s\n' "French (${FRENCH_DEFAULT_VOICE}): "
    printf '\n'
    printf '%s\n' "$TEST_FR"
    printf '\n'
    speak_text "$TEST_FR"

    printf '\n'
    printf '%s\n' "speak -h will show the usage message."
    printf '\n'
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
            # -g optionally takes a voice name. Peek at the next token: if
            # it's not another option, not an existing file, AND doesn't
            # even look like a filename (looks_like_file), treat it as the
            # German voice name; otherwise use the default and leave that
            # token alone — it's the input file, found or not.
            if [[ -n "$2" && "$2" != -* && ! -f "$2" ]] && ! looks_like_file "$2"; then
                VOICE="$2"; LANG_FLAG="g"; shift 2
            else
                VOICE="$GERMAN_DEFAULT_VOICE"; LANG_FLAG="g"; shift 1
            fi
            ;;
        -e)
            # Same pattern as -g, but for English.
            if [[ -n "$2" && "$2" != -* && ! -f "$2" ]] && ! looks_like_file "$2"; then
                VOICE="$2"; LANG_FLAG="e"; shift 2
            else
                VOICE="$ENGLISH_DEFAULT_VOICE"; LANG_FLAG="e"; shift 1
            fi
            ;;
        -s)
            # Same pattern as -g/-e, but for Spanish.
            if [[ -n "$2" && "$2" != -* && ! -f "$2" ]] && ! looks_like_file "$2"; then
                VOICE="$2"; LANG_FLAG="s"; shift 2
            else
                VOICE="$SPANISH_DEFAULT_VOICE"; LANG_FLAG="s"; shift 1
            fi
            ;;
        -f)
            # Same pattern as -g/-e/-s, but for French.
            if [[ -n "$2" && "$2" != -* && ! -f "$2" ]] && ! looks_like_file "$2"; then
                VOICE="$2"; LANG_FLAG="f"; shift 2
            else
                VOICE="$FRENCH_DEFAULT_VOICE"; LANG_FLAG="f"; shift 1
            fi
            ;;
        -l) list_voices ;;
        -h|--help) help ;;
        -p) PFLAG=1; shift ;;
        -n) NFLAG=1; shift ;;
        -x) XLANG="$2"; shift 2 ;;
        -t) usage ;;   # -t only makes sense alone (handled above)
        -*) usage ;;
        *)  INPUT="$1"; shift ;;
    esac
done

[[ -z "$INPUT" ]] && usage

[[ -n "$VOICE" && -n "$LANG_FLAG" ]] && check_lang_match "$LANG_FLAG" "$VOICE"

# --- Translation (-x) setup ----------------------------------------------
typeset XENABLED=0
typeset SOURCE_CODE="auto"
typeset TARGET_CODE=""
typeset TARGET_VOICE=""
typeset -a TRANS_SAY_ARGS

if [[ -n "$XLANG" ]]; then
    if ! command -v trans >/dev/null 2>&1; then
        printf '%s\n' "Error: -x needs translate-shell (the 'trans' command), which isn't installed."
        printf '%s\n' "  macOS: brew install translate-shell"
        printf '%s\n' "  Linux: sudo apt install translate-shell"
        exit 1
    fi

    case "$LANG_FLAG" in
        g) SOURCE_CODE="de" ;;
        e) SOURCE_CODE="en" ;;
        s) SOURCE_CODE="es" ;;
        f) SOURCE_CODE="fr" ;;
        *) SOURCE_CODE="auto" ;;
    esac

    TARGET_CODE=$(resolve_lang_code "$XLANG")

    if validate_target_lang "$TARGET_CODE" "$XLANG"; then
        case "$TARGET_CODE" in
            en) TARGET_VOICE="$ENGLISH_DEFAULT_VOICE" ;;
            de) TARGET_VOICE="$GERMAN_DEFAULT_VOICE" ;;
            es) TARGET_VOICE="$SPANISH_DEFAULT_VOICE" ;;
            fr) TARGET_VOICE="$FRENCH_DEFAULT_VOICE" ;;
            *)
                # No known default voice for this target on this platform.
                # On Linux, espeak-ng's voice names ARE language codes, so
                # the target code itself usually works directly as a voice.
                # On macOS there's no equivalent shortcut, so TARGET_VOICE
                # stays blank and 'say' falls back to its system default.
                [[ "$PLATFORM" == "linux" ]] && TARGET_VOICE="$TARGET_CODE"
                ;;
        esac

        if [[ -n "$PFLAG" && -z "$OUTFILE" && -z "$NFLAG" ]]; then
            XENABLED=1
        else
            printf '%s\n' "Note: -x only works in plain -p mode (no -n, no -o) -- ignoring -x for this run." >&2
        fi
    fi
    # else: validate_target_lang already printed the warning and the
    # list of available languages; XENABLED stays 0, so the file is
    # still spoken normally, just without translation.
fi

if [[ "$XENABLED" -eq 1 ]]; then
    [[ -n "$TARGET_VOICE" ]] && TRANS_SAY_ARGS+=("-v" "$TARGET_VOICE")
    if [[ -n "$RATE" ]]; then
        case "$PLATFORM" in
            darwin) TRANS_SAY_ARGS+=("-r" "$RATE") ;;
            linux)  TRANS_SAY_ARGS+=("-s" "$RATE") ;;
        esac
    fi
fi

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
                    printf '%s\n' "Note: Linux (espeak-ng) only saves .wav files — saving as ${OUTFILE}.wav instead."
                    OUTFILE="${OUTFILE}.wav"
                    ;;
            esac
            SAY_ARGS+=("-w" "$OUTFILE")
            ;;
    esac
fi

# --- Resolve default directory for a bare filename ---------------------
# If INPUT is a bare filename (no "/"), the CURRENT DIRECTORY is checked
# first, same as always -- this is what lets "speak poem.txt" keep
# working from inside ~/Projects/SS or anywhere else the file actually
# lives. Only if it's NOT found there does ~/Documents get tried as a
# fallback default location. If ~/Documents doesn't exist either, prompt
# for the full path instead. A relative path like ./notes.txt or an
# absolute path is left alone and checked as given, below.
if [[ "$INPUT" != "-" ]]; then
    case "$INPUT" in
        */*) ;;   # a path was given -- leave it as-is
        *)
            if [[ ! -f "$INPUT" ]]; then
                # Not in the current directory -- try ~/Documents next.
                if [[ -d "$HOME/Documents" ]]; then
                    [[ -f "$HOME/Documents/$INPUT" ]] && INPUT="$HOME/Documents/$INPUT"
                    # If it's not in ~/Documents either, leave INPUT as the
                    # bare name -- the file-not-found check below reports it.
                else
                    printf '%s\n' "~/Documents does not exist."
                    printf '%s' "Enter the full path to the text file: "
                    read INPUT
                fi
            fi
            ;;
    esac
fi

# Real file-not-found check happens before any of this for file input.
if [[ "$INPUT" != "-" && ! -f "$INPUT" ]]; then
    printf '%s\n' "Error: path not found: $INPUT"
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
            printf '%s\n' "$line"
            if [[ -n "$line" && "$line" != '#'* ]] && ! is_divider_line "$line"; then
                speak_text "$line"
                if [[ "$XENABLED" -eq 1 && "$QUIT" -ne 1 ]]; then
                    typeset translated
                    translated=$(translate_line "$line")
                    if [[ -n "$translated" ]]; then
                        printf '%s\n' "$translated"
                        speak_translation_text "$translated"
                    else
                        printf '%s\n' "(translation unavailable)" >&2
                    fi
                fi
            fi
            [[ "$QUIT" -eq 1 ]] && break
        done
    else
        while IFS= read -r line; do
            printf '%s\n' "$line"
            if [[ -n "$line" && "$line" != '#'* ]] && ! is_divider_line "$line"; then
                speak_text "$line"
                if [[ "$XENABLED" -eq 1 && "$QUIT" -ne 1 ]]; then
                    typeset translated
                    translated=$(translate_line "$line")
                    if [[ -n "$translated" ]]; then
                        printf '%s\n' "$translated"
                        speak_translation_text "$translated"
                    else
                        printf '%s\n' "(translation unavailable)" >&2
                    fi
                fi
            fi
            [[ "$QUIT" -eq 1 ]] && break
        done < "$INPUT"
    fi
elif [[ -n "$PFLAG" ]]; then
    # -p combined with -o or -n: skip the line-by-line pausing. Either
    # saving to one continuous audio file, or you explicitly asked for
    # a natural, uninterrupted reading (-n) — so print the whole text up
    # front, then speak it as a single continuous pass.
    printf '\n'
    if [[ "$INPUT" == "-" ]]; then
        tee /dev/stdout | speak_stdin
    else
        cat "$INPUT"
        printf '\n'
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
    printf '%s\n' "Saved audio to: $OUTFILE"
fi
