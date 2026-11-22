#!/bin/bash
# install-vb-guest.sh — installs VirtualBox Guest Additions on Elementary OS (M1 VirtualBox)

set -e

echo "=== Updating package list ==="
sudo apt update -y

echo "=== Installing prerequisite packages ==="
sudo apt install -y dkms build-essential

# Find the mounted VBoxGuestAdditions CD
GUEST_ISO=$(ls /media/$USER | grep VBox)
if [ -z "$GUEST_ISO" ]; then
    echo "Guest Additions ISO not found in /media/$USER. Please mount it."
    exit 1
fi

ISO_PATH="/media/$USER/$GUEST_ISO"

echo "=== Running Guest Additions installer ==="
sudo sh "$ISO_PATH/VBoxLinuxAdditions.run" || echo "Some warnings may appear — ignore if non-fatal"

echo "=== Enabling full-screen scaling ==="
VBoxClient --vmsvga --clipboard
VBoxClient --draganddrop

echo "=== Done! Rebooting to apply changes ==="
sudo reboot

