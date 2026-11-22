#!/bin/bash
# Set high resolution for Elementary OS VM running on VirtualBox (M1)
# SSH into VM and configure xrandr for 16" MacBook Pro

VM_USER="steve"
VM_HOST="127.0.0.1"
VM_PORT="2222"   # change if your SSH port is different
RESOLUTION="2560 1600"  # change to 1920 1200 if slower
PROFILE_FILE="/home/$VM_USER/.xprofile"

ssh -p $VM_PORT $VM_USER@$VM_HOST bash -s <<EOF
# Detect VirtualBox display name
DISPLAY_NAME=\$(xrandr | grep " connected" | awk '{print \$1}' | head -n1)

# Create Modeline
MODELINE=\$(cvt $RESOLUTION | grep Modeline | cut -d' ' -f2-)

# Apply new mode
xrandr --newmode \$MODELINE
xrandr --addmode \$DISPLAY_NAME \$(echo \$MODELINE | awk '{print \$1}')
xrandr --output \$DISPLAY_NAME --mode \$(echo \$MODELINE | awk '{print \$1}')

# Save to ~/.xprofile to make it persistent
cat > $PROFILE_FILE <<EOL
xrandr --newmode \$MODELINE
xrandr --addmode \$DISPLAY_NAME \$(echo \$MODELINE | awk '{print \$1}')
xrandr --output \$DISPLAY_NAME --mode \$(echo \$MODELINE | awk '{print \$1}')
EOL

echo "Resolution set to $RESOLUTION. Log out and log back in to apply persistently."
EOF

