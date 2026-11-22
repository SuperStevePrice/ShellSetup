#!/bin/bash
# fix-vm-xprofile.sh — overwrite broken .xprofile in VM via SSH

VM_USER="steve"
VM_HOST="127.0.0.1"
VM_PORT="2222"   # your SSH port

ssh -p $VM_PORT $VM_USER@$VM_HOST "bash -s" <<'EOF'
PROFILE="$HOME/.xprofile"
BASHRC="$HOME/.bashrc"

echo "🔧 Replacing $PROFILE with clean template..."

cat > "$PROFILE" <<'EOL'
# ~/.xprofile — safe display setup for Elementary OS in VirtualBox

if [ -n "$DISPLAY" ]; then
    # --- VM Display Setup for MacBook 16" ---
    DISPLAY_NAME=$(xrandr | grep " connected" | awk '{print $1}' | head -n1)
    xrandr --newmode "2560x1600_60.00"  348.25  2560 2752 3024 3488  1600 1603 1613 1646 -hsync +vsync
    xrandr --addmode "$DISPLAY_NAME" "2560x1600_60.00"
    xrandr --output "$DISPLAY_NAME" --mode "2560x1600_60.00"

    # --- Terminal Font ---
    gsettings set io.elementary.terminal.settings font "Monospace 16"

    # --- VBoxClient autostart ---
    if ! pgrep -a VBoxClient >/dev/null 2>&1; then
        VBoxClient --vmsvga --clipboard --draganddrop &
    fi
fi
EOL

chmod +x "$PROFILE"
echo "✅ $PROFILE replaced successfully."

# Make sure .xprofile is sourced in .bashrc
if ! grep -q '.xprofile' "$BASHRC"; then
    echo -e '\n# Source .xprofile for GUI/TTY\nif [ -f "$HOME/.xprofile" ]; then\n    source "$HOME/.xprofile"\nfi' >> "$BASHRC"
fi

echo "✅ .bashrc updated to source .xprofile."
EOF

