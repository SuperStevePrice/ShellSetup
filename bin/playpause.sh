#!/usr/bin/env bash
#
# playpause.sh — play an audio file with interactive pause/resume/quit.
#
# This is the bash port of playpause.ksh — same behavior, targets bash
# instead of ksh so Linux users don't need to install ksh first.
#
# Usage:
#   ./playpause.sh file.m4a
#
# While playing:
#   space   pause / resume
#   q       quit (stops playback)
#
# Works by sending SIGSTOP/SIGCONT to the underlying player process —
# none of these players have native pause, but the OS can suspend any process.
#
# macOS:   afplay (built in)
# Linux:   paplay (PulseAudio) if present, else aplay (ALSA) — one of these
#          is present on nearly every desktop Linux distro. Only plays WAV
#          reliably without extra codecs, which matches what speak.sh's
#          -o produces on Linux (espeak-ng writes WAV only).
# Windows: use playpause.ps1 instead.

typeset PLATFORM=""
typeset PLAYER=""

case "$(uname)" in
    Darwin)
        PLATFORM="darwin"
        PLAYER="afplay"
        ;;
    Linux)
        PLATFORM="linux"
        if command -v paplay >/dev/null 2>&1; then
            PLAYER="paplay"
        elif command -v aplay >/dev/null 2>&1; then
            PLAYER="aplay"
        else
            printf '%s\n' "No audio player found (checked paplay, aplay)."
            printf '%s\n' "Install one with:  sudo apt install pulseaudio-utils"
            printf '%s\n' "(or alsa-utils for aplay), then try again."
            exit 1
        fi
        ;;
    CYGWIN*|MINGW*|MSYS*)
        printf '%s\n' "You're on Windows — use playpause.ps1 instead (run it in PowerShell)."
        exit 0
        ;;
    *)
        printf '%s\n' "Unsupported platform: $(uname). This tool supports macOS and Linux; Windows users should use playpause.ps1."
        exit 0
        ;;
esac

typeset FILE="$1"

if [[ -z "$FILE" ]]; then
    printf '%s\n' "Usage: $0 <audiofile>"
    exit 1
fi

if [[ ! -f "$FILE" ]]; then
    printf '%s\n' "Error: file not found: $FILE"
    exit 1
fi

if [[ "$PLATFORM" == "linux" && "$FILE" != *.wav ]]; then
    printf '%s\n' "Note: on Linux, $PLAYER reliably plays .wav files only."
    printf '%s\n' "If this file isn't a WAV, playback may fail or sound wrong."
fi

"$PLAYER" "$FILE" &
typeset PID=$!
typeset PAUSED=0

printf '%s\n' "Playing: $FILE"
printf '%s\n' "space = pause/resume   q = quit"
printf '\n'

# Put the terminal into raw mode so a single keypress is read
# immediately, with no Enter needed, and nothing echoed to the screen.
stty -echo -icanon min 1 time 0

# Always restore normal terminal behavior on exit, however we get there.
trap 'stty echo icanon' EXIT INT TERM

typeset KEY=""

while kill -0 "$PID" 2>/dev/null; do
    # Poll for a keypress once per second; if none arrives, loop back
    # and check whether playback has finished on its own.
    read -t 1 -n 1 KEY 2>/dev/null

    case "$KEY" in
        " ")
            if [[ "$PAUSED" -eq 0 ]]; then
                kill -STOP "$PID"
                PAUSED=1
                printf '%s\n' "Paused. (space = resume, q = quit)"
            else
                kill -CONT "$PID"
                PAUSED=0
                printf '%s\n' "Resumed."
            fi
            ;;
        q|Q)
            kill "$PID" 2>/dev/null
            printf '%s\n' "Stopped."
            break
            ;;
    esac
    KEY=""
done

stty echo icanon
printf '%s\n' "Done."
