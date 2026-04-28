#!/usr/bin/env ksh
# boot.ksh - Force reboot the Mac immediately with admin privileges
echo "This will force an immediate reboot. Unsaved work may be lost."
printf "Are you sure you want to proceed? (y/n): "
read CONFIRM?""
if [[ "$CONFIRM" != "y" ]]; then
  echo "Reboot aborted."
  exit 0
fi
echo "Rebooting now..."
sudo shutdown -r now
