#!/bin/bash
# fix-xprofile.sh — repair .xprofile inside the VM so GUI commands only run when DISPLAY exists

SSH_PORT=2222
VM_USER=steve
VM_HOST=127.0.0.1

ssh -p $SSH_PORT ${VM_USER}@${VM_HOST} "bash -s" <<'EOSCRIPT'
PROFILE_FILE="$HOME/.xprofile"

echo "🔧 Fixing $PROFILE_FILE ..."

if [ ! -f "$PROFILE_FILE" ]; then
  echo '# --- VM Display Setup for MacBook 16" ---' > "$PROFILE_FILE"
fi

# Only wrap the section once
if ! grep -q 'if \[ -n "\$DISPLAY" \]' "$PROFILE_FILE"; then
  awk '
    BEGIN {in_block=0}
    /# --- VM Display Setup for MacBook 16"/ {in_block=1; print "if [ -n \"$DISPLAY\" ]; then"; next}
    in_block && /EOL/ {print "fi"; in_block=0; next}
    {print}
  ' "$PROFILE_FILE" > /tmp/xprofile.fixed && mv /tmp/xprofile.fixed "$PROFILE_FILE"
fi

chmod +x "$PROFILE_FILE"
echo "✅ $PROFILE_FILE patched successfully."

sudo apt update -y
sudo apt install -y virtualbox-guest-utils virtualbox-guest-x11
echo "✅ Guest Additions utilities reinstalled."
EOSCRIPT

