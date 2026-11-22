#!/bin/bash
# encrypt_thumb.sh - safely erase and encrypt an external USB thumb drive

DISK="/dev/disk6"           # Change this to your target disk if different
VOLUME_NAME="SecureThumb"   # Change to desired volume name

# Confirm the disk exists and is external + removable
diskutil info "$DISK" | grep -q "Device Location:.*External" || { echo "Error: $DISK is not external."; exit 1; }
diskutil info "$DISK" | grep -q "Removable Media:.*Removable" || { echo "Error: $DISK is not removable."; exit 1; }

# Erase the disk as standard APFS
echo "Erasing $DISK and creating APFS volume $VOLUME_NAME..."
diskutil eraseDisk APFS "$VOLUME_NAME" "$DISK"

# Apply APFS encryption using Disk user
echo "Applying APFS encryption to $VOLUME_NAME..."
diskutil apfs encryptVolume /Volumes/"$VOLUME_NAME" -user disk

echo "Encryption started. Monitor progress with:"
echo "  diskutil apfs list | grep -i encrypt"
