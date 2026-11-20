#!/bin/ksh
#
# wispr_dictation_login.ksh
#
# Purpose:
#   Launch Wispr Flow and turn Dictation ON, so it ends up in the state
#   you want after every login/restart without you doing it by hand.
#
#   Run modes:
#     ./wispr_dictation_login.ksh            -> launch Wispr Flow + start dictation (the actual job)
#     ./wispr_dictation_login.ksh --install  -> install this script as a LaunchAgent that
#                                               runs automatically at every login
#     ./wispr_dictation_login.ksh --uninstall -> remove the LaunchAgent (does not touch Wispr Flow)
#
# One-time manual setup required (macOS will not let a script click menus otherwise):
#   System Settings > Privacy & Security > Accessibility
#     -> enable access for "Terminal" (or whichever app/shell you run this from)
#     -> enable access for "System Events" if it appears in the list after first run
#   The very first time you run this (or the LaunchAgent fires), macOS will likely pop up
#   a permission prompt itself -- approve it, then run again.
#
# Known unknown:
#   I don't know Wispr Flow's exact menu wording/structure yet. This script tries a
#   couple of plausible click-paths for "File > Option(s) > Start Dictation". If all
#   of them fail, it dumps the real menu hierarchy into the log so the exact path can
#   be fixed in one more pass -- just send me that log.
#
# Steve's standing conventions followed here:
#   - single downloadable script, no paste-multiple-commands
#   - logs to ~/logs/<scriptname>.<timestamp>.log
#   - final line: "See: ~/logs/....log"
#   - live stdout/stderr shown on screen AND logged (plain pipe, not process substitution --
#     ksh93 on Apple's Macs breaks on `exec 1> >(tee ...)`)

SCRIPT_NAME=${0##*/}
SCRIPT_BASE=${SCRIPT_NAME%.*}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOGDIR="$HOME/logs"
mkdir -p "$LOGDIR"
LOGFILE="$LOGDIR/${SCRIPT_BASE}.${TIMESTAMP}.log"

APP_NAME="Wispr Flow"
INSTALL_DIR="$HOME/bin"
INSTALLED_SCRIPT="$INSTALL_DIR/${SCRIPT_NAME}"
PLIST_LABEL="com.steveprice.wispr-dictation-login"
PLIST_PATH="$HOME/Library/LaunchAgents/${PLIST_LABEL}.plist"

do_install() {
	print "Installing login automation for ${APP_NAME}..."

	mkdir -p "$INSTALL_DIR"
	cp "$0" "$INSTALLED_SCRIPT"
	chmod +x "$INSTALLED_SCRIPT"
	print "Copied script to: $INSTALLED_SCRIPT"

	mkdir -p "$HOME/Library/LaunchAgents"
	cat > "$PLIST_PATH" <<-PLIST
	<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	<plist version="1.0">
	<dict>
	    <key>Label</key>
	    <string>${PLIST_LABEL}</string>
	    <key>ProgramArguments</key>
	    <array>
	        <string>${INSTALLED_SCRIPT}</string>
	    </array>
	    <key>RunAtLoad</key>
	    <true/>
	    <key>LimitLoadToSessionType</key>
	    <string>Aqua</string>
	    <key>ProcessType</key>
	    <string>Interactive</string>
	    <key>StandardOutPath</key>
	    <string>${LOGDIR}/${PLIST_LABEL}.out.log</string>
	    <key>StandardErrorPath</key>
	    <string>${LOGDIR}/${PLIST_LABEL}.err.log</string>
	</dict>
	</plist>
	PLIST

	launchctl unload "$PLIST_PATH" 2>/dev/null
	launchctl load "$PLIST_PATH"

	print "LaunchAgent installed and loaded: $PLIST_PATH"
	print "It will now run automatically at every login."
	print ""
	print "IMPORTANT one-time step: open System Settings > Privacy & Security >"
	print "Accessibility, and make sure Terminal (or whatever ran this install) and"
	print "System Events are both allowed. Without that, the menu click will fail"
	print "silently every time."
	print ""
	print "To test right now without logging out, run:"
	print "  $INSTALLED_SCRIPT"
}

do_uninstall() {
	print "Removing LaunchAgent..."
	launchctl unload "$PLIST_PATH" 2>/dev/null
	rm -f "$PLIST_PATH"
	print "Removed: $PLIST_PATH"
	print "(Left $INSTALLED_SCRIPT in place in case you want it again -- delete by hand if not.)"
}

wait_for_process() {
	# Poll up to ~20 seconds for the app's process to show up to AppleScript
	typeset tries=0
	while [ $tries -lt 20 ]; do
		running=$(osascript -e "tell application \"System Events\" to (name of processes) contains \"${APP_NAME}\"" 2>/dev/null)
		if [ "$running" = "true" ]; then
			return 0
		fi
		sleep 1
		tries=$((tries + 1))
	done
	return 1
}

try_start_dictation() {
	# Confirmed from a screenshot of the real menu: File menu contains
	# "Start dictation" and "Start Notetaker" directly -- no submenu at all.
	# Try the exact casing first, then a couple of harmless case variants
	# in case macOS/Wispr changes it between versions.

	for label in "Start dictation" "Start Dictation" "Start dictation..."; do
		osascript 2>/tmp/wispr_osa_err_$$ <<-APPLESCRIPT
		tell application "System Events"
			tell process "Wispr Flow"
				set frontmost to true
				click menu bar item "File" of menu bar 1
				click menu item "${label}" of menu "File" of menu bar item "File" of menu bar 1
			end tell
		end tell
		APPLESCRIPT
		if [ $? -eq 0 ]; then
			cat /tmp/wispr_osa_err_$$ 2>/dev/null
			rm -f /tmp/wispr_osa_err_$$
			return 0
		fi
		print "Attempt 'File > ${label}' failed:"
		cat /tmp/wispr_osa_err_$$ 2>/dev/null
		rm -f /tmp/wispr_osa_err_$$
	done

	return 1
}

dump_ui_hierarchy() {
	print ""
	print "=== Diagnostic dump: Wispr Flow menu structure (for fixing the script) ==="
	osascript <<-'APPLESCRIPT' 2>&1
	tell application "System Events"
		tell process "Wispr Flow"
			set out to ""
			try
				set out to out & "App menu bar items: " & (name of every menu bar item of menu bar 1) & linefeed
			end try
			try
				set out to out & "Status/extras menu bar items: " & (name of every menu bar item of menu bar 2) & linefeed
			end try
			return out
		end tell
	end tell
	APPLESCRIPT
	print "=== end diagnostic dump ==="
	print ""
	print "If this didn't print anything useful, Terminal/System Events most likely"
	print "still needs Accessibility permission in System Settings > Privacy & Security."
}

run() {
	print "=== ${SCRIPT_NAME} starting at $(date) ==="

	already_running=$(osascript -e "tell application \"System Events\" to (name of processes) contains \"${APP_NAME}\"" 2>/dev/null)
	if [ "$already_running" = "true" ]; then
		print "${APP_NAME} is already running."
	else
		print "Launching ${APP_NAME}..."
		open -a "$APP_NAME"
		if ! wait_for_process; then
			print "ERROR: ${APP_NAME} did not appear to System Events within 20 seconds."
			print "Check that the app name is exactly \"${APP_NAME}\" (case-sensitive) and try again."
			return 1
		fi
		print "${APP_NAME} is running; giving it a couple more seconds to finish loading."
		sleep 2
	fi

	print "Attempting to start dictation..."
	if try_start_dictation; then
		print "Dictation start command sent successfully."
	else
		print "ERROR: all click-path attempts failed."
		dump_ui_hierarchy
		print "Send me the diagnostic dump above and I'll fix the exact menu path."
		return 1
	fi

	print "=== ${SCRIPT_NAME} finished at $(date) ==="
}

case "$1" in
	--install)
		do_install
		exit $?
		;;
	--uninstall)
		do_uninstall
		exit $?
		;;
	*)
		run 2>&1 | tee -a "$LOGFILE"
		;;
esac

print "See: $LOGFILE"
