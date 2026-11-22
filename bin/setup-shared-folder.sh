#!/bin/bash
# setup_shared_folder.sh
# Script to mount VirtualBox shared folder VMShared to /home/steve/Shared

# --- Variables ---
SHARED_NAME="VMShared"       # Folder Name in VirtualBox settings
MOUNT_POINT="/home/steve/Shared"
USER_NAME="steve"

# --- Create mount point if it doesn't exist ---
if [ ! -d "$MOUNT_POINT" ]; then
    echo "Creating mount point $MOUNT_POINT"
    mkdir -p "$MOUNT_POINT"
fi

# --- Add user to vboxsf group ---
echo "Adding $USER_NAME to vboxsf group"
sudo usermod -aG vboxsf "$USER_NAME"

# --- Mount shared folder manually ---
echo "Mounting $SHARED_NAME to $MOUNT_POINT"
sudo mount -t vboxsf "$SHARED_NAME" "$MOUNT_POINT"

# --- Add to /etc/fstab if not already present ---
FSTAB_LINE="$SHARED_NAME   $MOUNT_POINT   vboxsf   defaults   0  0"
if ! grep -q "$SHARED_NAME" /etc/fstab; then
    echo "Adding $SHARED_NAME to /etc/fstab for automatic mount at boot"
    echo "$FSTAB_LINE" | sudo tee -a /etc/fstab > /dev/null
fi

echo "Setup complete. You may need to log out and log back in for group changes."

