#!/bin/ksh
#
# playpause.ksh — play an audio file with interactive pause/resume/quit.
#
# Usage:
#   ./playpause.ksh file.m4a
#
# While playing:
#   space   pause / resume
#   q       quit (stops playback)
#
# Works by sending SIGSTOP/SIGCONT to the underlying 'afplay' process —
# afplay itself has no native pause, but the OS can suspend any process.

# No Linux or Windows support yet — 'afplay' is macOS-only, same as 'say'
# in speak.ksh. (On Windows, ksh only runs under a Unix layer like
# Cygwin/MSYS/MinGW, which 'uname' reports as CYGWIN*/MINGW*/MSYS*.)
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

typeset FILE="$1"

if [[ -z "$FILE" ]]; then
    print "Usage: $0 <audiofile>"
    exit 1
fi

if [[ ! -f "$FILE" ]]; then
    print "Error: file not found: $FILE"
    exit 1
fi

afplay "$FILE" &
typeset PID=$!
typeset PAUSED=0

print "Playing: $FILE"
print "space = pause/resume   q = quit"
print ""

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
                print "Paused. (space = resume, q = quit)"
            else
                kill -CONT "$PID"
                PAUSED=0
                print "Resumed."
            fi
            ;;
        q|Q)
            kill "$PID" 2>/dev/null
            print "Stopped."
            break
            ;;
    esac
    KEY=""
done

stty echo icanon
print "Done."
