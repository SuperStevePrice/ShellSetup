#!/bin/bash
#-------------------------------------------------------------------------------
# PROGRAM:
#   clone_safari_slideshow.sh
#
# PURPOSE:
#   Clone Safari settings and slide show folder from MacBook to iMac.
#   Backs up existing Safari folder, plist, and slide show folder on iMac
#   before copying. Provides pause points for verification at each step.
#
# USAGE:
#   Run from MacBook terminal:
#     ./clone_safari_slideshow.sh
#   Ensure SSH access to iMac is configured, and script has execute permission:
#     chmod 755 clone_safari_slideshow.sh
#
#-------------------------------------------------------------------------------

# --------------------------
# iMac credentials
# --------------------------
IMAC="Steves-iMac.local"
USER="steve"

# --------------------------
# Timestamp for unique backups
# --------------------------
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
SAFARI_BACKUP="Safari-BACKUP-$TIMESTAMP"
SLIDESHOW_BACKUP="ChangingImages-BACKUP-$TIMESTAMP"

# --------------------------
# Step 1: Back up Safari on iMac
# --------------------------
echo "Step 1: Backing up Safari on iMac..."

ssh $USER@$IMAC "
mkdir -p ~/Desktop/$SAFARI_BACKUP

# Backup Safari folder
if ! mv ~/Library/Safari ~/Desktop/$SAFARI_BACKUP/; then
    echo 'ERROR: Moving Safari folder failed'
    exit 1
fi

# Backup Safari plist
if ! mv ~/Library/Preferences/com.apple.Safari.plist ~/Desktop/$SAFARI_BACKUP/; then
    echo 'ERROR: Moving plist failed'
    exit 1
fi
"

if [ $? -ne 0 ]; then
    echo "ERROR: Safari backup failed on iMac. Aborting."
    exit 1
fi

echo
echo "Safari backup completed at ~/Desktop/$SAFARI_BACKUP."
read -p "Verify contents and press ENTER to continue, or Ctrl+C to abort: "

# --------------------------
# Step 2: Back up Slide Show folder on iMac
# --------------------------
echo "Step 2: Backing up existing slide show folder on iMac..."

ssh $USER@$IMAC "
if [ -d ~/Pictures/ChangingImages ]; then
    mkdir -p ~/Desktop/$SLIDESHOW_BACKUP
    if ! mv ~/Pictures/ChangingImages ~/Desktop/$SLIDESHOW_BACKUP/; then
        echo 'ERROR: Moving ChangingImages folder failed'
        exit 1
    fi
    echo 'Slide show folder backed up at ~/Desktop/$SLIDESHOW_BACKUP'
else
    echo 'No existing slide show folder found; skipping backup.'
fi
"

read -p "Verify slide show backup on iMac, then press ENTER to continue, or Ctrl+C to abort: "

# --------------------------
# Step 3: Copy Safari from MacBook to iMac
# --------------------------
echo "Step 3: Copying Safari folder..."
scp -rp ~/Library/Safari $USER@$IMAC:~/Library/
if [ $? -ne 0 ]; then
    echo "ERROR: Safari folder copy failed."
    exit 1
fi
read -p "Verify ~/Library/Safari on iMac, press ENTER to continue, or Ctrl+C to abort: "

scp -p ~/Library/Preferences/com.apple.Safari.plist $USER@$IMAC:~/Library/Preferences/
if [ $? -ne 0 ]; then
    echo "ERROR: Safari plist copy failed."
    exit 1
fi
read -p "Verify ~/Library/Preferences/com.apple.Safari.plist on iMac, press ENTER to continue, or Ctrl+C to abort: "

# --------------------------
# Step 4: Copy Slide Show folder from MacBook to iMac
# --------------------------
echo "Step 4: Copying slide show folder..."
scp -rp ~/Pictures/ChangingImages $USER@$IMAC:~/Pictures/
if [ $? -ne 0 ]; then
    echo "ERROR: Slide show folder copy failed."
    exit 1
fi
read -p "Verify ~/Pictures/ChangingImages on iMac, press ENTER to continue, or Ctrl+C to abort: "

# --------------------------
# Step 5: Verify everything on iMac
# --------------------------
echo "Step 5: Verifying contents on iMac..."
ssh $USER@$IMAC "
echo '--- Safari plist ---'
ls -l ~/Library/Preferences/com.apple.Safari.plist
echo '--- Safari folder ---'
ls -l ~/Library/Safari
echo '--- Slide show folder ---'
ls -l ~/Pictures/ChangingImages
"

echo
echo "All done! Launch Safari on iMac and open the slide show to confirm everything works."

#-------------------------------------------------------------------------------
# Last installed: 2026-01-12 22:00:00
#-- End of File ----------------------------------------------------------------

