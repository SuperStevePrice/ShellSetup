#!/bin/ksh
# Run ONCE per remote Linux host (via deploy-nopasswd.sh from the Mac).
# Grants passwordless sudo for `apt update` and `apt full-upgrade -y`
# only — nothing else.
echo "$USER ALL=(root) NOPASSWD: /usr/bin/apt update, /usr/bin/apt full-upgrade -y, /usr/bin/apt --fix-broken install -y, /usr/bin/apt autoremove -y" | \
    sudo tee /etc/sudoers.d/apt-update-nopasswd
sudo chmod 440 /etc/sudoers.d/apt-update-nopasswd
sudo visudo -c   # validates syntax; should print "parsed OK"
