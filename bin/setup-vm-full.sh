#!/bin/bash
# setup-vm-full.sh — configure VM display, terminal, and VBoxClient

VM_USER="steve"
VM_HOST="127.0.0.1"
VM_PORT="2222"      # adjust if using a different port

ssh -p "$VM_PORT" "$VM_USER@$VM_HOST" bash -s <<'EOF'
PROFILE_FILE="$HOME/.xprofile"
BASHRC_FILE="$HOME/.bashrc"

echo "Appending display and terminal settings to $PROFILE_FILE..."

cat >> "$PROFILE_FILE" <<'EOL'
# --- VM Display Setup for MacBook 16" ---
DISPLAY_NAME=$(xrandr | grep " connected" | awk '{print $1}' | head -n1)
xrandr --newmode "2560x1600_60.00"  348.25  2560 2752 3024 3488  1600 1603 1613 1646 -hsync +vsync
xrandr --addmode "$DISPLAY_NAME" "2560x1600_60.00"
xrandr --output "$DISPLAY_NAME" --mode "2560x1600_60.00"

# --- Terminal Font ---
gsettings set io.elementary.terminal.settings font "Monospace 16"

# --- VBoxClient autostart for full-screen, clipboard, drag-and-drop ---
if ! pgrep -a VBoxClient >/dev/null 2>&1; then
  VBoxClient --vmsvga --clipboard --draganddrop &
fi
EOL

echo "Ensuring .xprofile is sourced from .bashrc..."
if ! grep -q '.xprofile' "$BASHRC_FILE"; then
  cat >> "$BASHRC_FILE" <<'EOL'

# Source .xprofile for GUI or TTY sessions
if [ -f "$HOME/.xprofile" ]; then
  source "$HOME/.xprofile"
fi
EOL
fi

echo "Setup complete. Log in to the VM desktop to apply resolution, font, and VBoxClient."
EOF

