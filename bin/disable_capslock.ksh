#!/usr/bin/env ksh
#
# disable_capslock.ksh
#
# Disables the Caps Lock key system-wide at the HID (hardware input) level,
# bypassing System Settings > Keyboard > Modifier Keys entirely. This works
# regardless of which keyboard profile macOS thinks is active (useful when
# a wireless receiver and a Bluetooth keyboard entry both claim the same
# physical keyboard, and the GUI setting won't stick to the real device).
#
# Installs a LaunchAgent so the remap re-applies automatically every login
#/ reboot, and also applies it immediately to the current session.
#
# To REVERSE this later, run:
#   launchctl unload ~/Library/LaunchAgents/com.steve.disablecapslock.plist
#   rm ~/Library/LaunchAgents/com.steve.disablecapslock.plist
#   hidutil property --set '{"UserKeyMapping":[]}'
#   (then log out/in or reboot)

LOGDIR="$HOME/logs"
mkdir -p "$LOGDIR"
TS=$(date +%Y%m%d_%H%M%S)
LOGFILE="$LOGDIR/disable_capslock.$TS.log"

PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST="$PLIST_DIR/com.steve.disablecapslock.plist"

mkdir -p "$PLIST_DIR"

{
  print "Starting Caps Lock disable setup: $(date)"

  cat > "$PLIST" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.steve.disablecapslock</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/hidutil</string>
        <string>property</string>
        <string>--set</string>
        <string>{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x700000000}]}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF

  print "Wrote LaunchAgent plist to $PLIST"

  launchctl unload "$PLIST" 2>/dev/null
  launchctl load "$PLIST"

  print "Loaded LaunchAgent (will re-apply remap on every future login)"

  /usr/bin/hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x700000000}]}'

  print "Applied hidutil remap to the current session"
  print "Done: $(date)"
} > "$LOGFILE" 2>&1

print "See: $LOGFILE"
