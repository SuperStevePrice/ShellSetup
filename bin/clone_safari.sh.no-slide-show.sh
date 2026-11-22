#!/bin/bash

# --------------------------
# Safari Clone: MacBook → iMac
# --------------------------

# iMac credentials
IMAC="Steves-iMac.local"
USER="steve"

# Timestamp for unique backup
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FOLDER="Safari-BACKUP-$TIMESTAMP"

echo "Step 1: Backing up Safari on iMac..."

# Move Safari folder and plist into timestamped backup folder, with per-mv checks
ssh $USER@$IMAC "
mkdir -p ~/Desktop/$BACKUP_FOLDER
if ! mv ~/Library/Safari ~/Desktop/$BACKUP_FOLDER/; then
    echo 'ERROR: Moving Safari folder failed'
    exit 1
fi
if ! mv ~/Library/Preferences/com.apple.Safari.plist ~/Desktop/$BACKUP_FOLDER/; then
    echo 'ERROR: Moving plist failed'
    exit 1
fi
"

# Check if SSH command succeeded
if [ $? -ne 0 ]; then
    echo "ERROR: Backup/move failed on iMac. Aborting."
    exit 1
fi

echo
echo "Backup completed on iMac at ~/Desktop/$BACKUP_FOLDER."
echo "PAUSE: Please verify the backup folder on the iMac."
echo "Check that it contains the Safari folder and com.apple.Safari.plist"
echo
read -p "If everything looks correct, press ENTER to continue, or Ctrl+C to abort: "

# --------------------------
# Step 2: Copy Safari from MacBook to iMac
# --------------------------
echo "Copying Safari from MacBook to iMac..."
scp -rp ~/Library/Safari $USER@$IMAC:~/Library/
scp -p ~/Library/Preferences/com.apple.Safari.plist $USER@$IMAC:~/Library/Preferences/

if [ $? -ne 0 ]; then
    echo "ERROR: Copy failed. Check network/permissions."
    exit 1
fi

# --------------------------
# Step 3: Verify ownership on iMac
# --------------------------
echo "Verifying ownership on iMac..."
ssh $USER@$IMAC "ls -l ~/Library/Preferences/com.apple.Safari.plist && ls -l ~/Library/Safari"

echo
echo "Done! Launch Safari on iMac and check that everything matches MacBook."

