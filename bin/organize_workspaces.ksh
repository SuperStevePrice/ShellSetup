#!/bin/ksh
# organize_workspaces.ksh
#
# macOS has no scriptable way to reorder Mission Control spaces - that
# is drag-and-drop only, by design. What this script DOES do: for
# each of the five apps below, if it is currently running, it brings
# it to the front (activates it) in the given order, and - best
# effort, requires Accessibility permission the first time for
# whatever app runs this script (Terminal, etc.) - nudges it into
# full-screen if it is not already. An app that is not running is
# skipped, not launched, per "if they exist at runtime."
#
# Order:
#   1. Classical California (KUSC)
#   2. Terminal
#   3. Claude
#   4. Mail
#   5. Safari
#
# One-time setup if the full-screen toggle silently does nothing:
# System Settings -> Privacy & Security -> Accessibility -> enable
# whatever app/terminal you run this script from.
#
# DEBUG: the "is it running" check and the full-screen step both log
# their raw AppleScript output/errors to the logfile now, instead of
# swallowing them, so a false "not running" or a silent full-screen
# failure can actually be diagnosed from the log.

SCRIPT_NAME=$(basename "$0" .ksh)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOGDIR="$HOME/logs"
LOGFILE="$LOGDIR/${SCRIPT_NAME}.${TIMESTAMP}.log"

mkdir -p "$LOGDIR"

run() {
	print "=== organize_workspaces: starting $(date) ==="

	for app in "Classical California" "Terminal" "Claude" "Mail" "Safari"; do
		print "\n--- $app ---"

		running=$(osascript -e "tell application \"System Events\" to (name of processes) contains \"$app\"" 2>&1)
		print "  [debug] running-check raw result: $running"

		if [[ "$running" == "true" ]]; then
			fs_result=$(osascript <<-APPLESCRIPT 2>&1
				tell application "$app" to activate
				delay 0.5
				try
					tell application "System Events"
						set appProc to first application process whose frontmost is true
						tell appProc
							if (count of windows) > 0 then
								set isFull to value of attribute "AXFullScreen" of window 1
								if isFull is false then
									keystroke "f" using {control down, command down}
									"toggled to full screen"
								else
									"already full screen"
								end if
							else
								"no windows"
							end if
						end tell
					end tell
				on error errMsg
					"full-screen step error: " & errMsg
				end try
			APPLESCRIPT
			)
			print "  [debug] full-screen step result: $fs_result"
			print "Activated $app"
		else
			print "$app not running - skipping (raw check result above)"
		fi
	done

	print "\n=== organize_workspaces: finished $(date) ==="
	print "See: $LOGFILE"
}

run 2>&1 | tee -a "$LOGFILE"
