#!/bin/bash
# set-vm-16in-res.sh
# SSH into Elementary OS VM and configure it to auto-set 16" MacBook Pro resolution at next login

VM_USER="steve"
VM_HOST="127.0.0.1"
VM_PORT="2222"         # change if your SSH port is different
RES_X="2560"
RES_Y="1600"
PROFILE_FILE="/home/$VM_USER/.xprofile"

ssh -p $VM_PORT $VM_USER@$VM_HOST bash -s <<EOF
echo "Adding auto-resolution commands to $PROFILE_FILE..."

cat >> $PROFILE_FILE <<EOL
# Automatically set VM resolution for 16\" MacBook Pro
DISPLAY_NAME=\$(xrandr | grep " connected" | awk '{print \$1}' | head -n1)
xrandr --newmode "${RES_X}x${RES_Y}_60.00"  348.25  ${RES_X} 2752 3024 3488  ${RES_Y} 1603 1613 1646 -hsync +vsync
xrandr --addmode \$DISPLAY_NAME "${RES_X}x${RES_Y}_60.00"
xrandr --output \$DISPLAY_NAME --mode "${RES_X}x${RES_Y}_60.00"
EOL

echo "Done. Log in to the VM desktop to apply the new resolution."
EOF

