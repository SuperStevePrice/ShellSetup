#!/usr/bin/env ksh
# force_down.ksh - Force shutdown the Mac immediately with admin privileges

echo "This will force an immediate shutdown. Unsaved work may be lost."
printf "Are you sure you want to proceed? (y/n): "
read CONFIRM?""

if [[ "$CONFIRM" != "y" ]]; then
  echo "Shutdown aborted."
  exit 0
fi

echo "Shutting down now..."
sudo shutdown -h now
