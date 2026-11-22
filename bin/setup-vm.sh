#!/bin/bash
# setup-vm.sh — fully configure Elementary/Ubuntu VM via SSH

VM_USER="steve"
VM_HOST="127.0.0.1"
VM_PORT="2222"   # SSH port forwarded from VirtualBox

ssh -p $VM_PORT $VM_USER@$VM_HOST "bash -s" <<'EOF'
PROFILE="$HOME/.xprofile"
BASHRC="$HOME/.bashrc"
STARTUP_SCRIPT="$HOME/bin/start-vboxclient.sh"

# --- 1. Safe .xprofile template ---
mkdir -p "$HOME/bin"

cat > "$PROFILE" <<'EOL'
# ~/.xprofile — safe display setup for Elementary OS in VirtualBox

# Only run GUI commands if a display is available
if [ -n "$DISPLAY" ]; then
    # Run VBoxClient after GUI is ready
    if [ -x "$HOME/bin/start-vboxclient.sh" ]; then
        "$HOME/bin/start-vboxclient.sh" &
    fi
fi
EOL

chmod +x "$PROFILE"
echo "✅ $PROFILE installed."

# --- 2. Create VBoxClient startup script ---
cat > "$STARTUP_SCRIPT" <<'EOL'
#!/bin/bash
# start-vboxclient.sh — run VBoxClient safely

if command -v VBoxClient >/dev/null 2>&1; then
    VBoxClient --vmsvga --clipboard --draganddrop &
fi
EOL

chmod +x "$STARTUP_SCRIPT"
echo "✅ $STARTUP_SCRIPT created."

# --- 3. Ensure .bashrc sources .xprofile ---
if ! grep -q '.xprofile' "$BASHRC"; then
    echo -e '\n# Source .xprofile for GUI/TTY\nif [ -f "$HOME/.xprofile" ]; then\n    source "$HOME/.xprofile"\nfi' >> "$BASHRC"
fi
echo "✅ .bashrc updated."

# --- 4. Install Guest Additions ---
echo "🔧 Installing VirtualBox Guest Additions..."
sudo apt update -y
sudo apt install -y virtualbox-guest-utils virtualbox-guest-x11
echo "✅ Guest Additions installed."
EOF

