#!/usr/bin/env ksh

#-------------------------------------------------------------------------------
# PROGRAM:
#   ~/bin/b43_sleep_hook.ksh
#
#
# PURPOSE:
#   Install (or remove) a systemd sleep hook that unloads the Broadcom b43
#   Wi-Fi driver before suspend and reloads it after wake. This keeps the
#   2011 MacBook Pro's Wi-Fi (and therefore Tailscale, ssh, and syncAll)
#   working after sleep, without a reboot.
#
# USAGE:
#   ~/bin/b43_sleep_hook.ksh            # install
#   ~/bin/b43_sleep_hook.ksh --remove   # uninstall
#   ~/bin/b43_sleep_hook.ksh --status   # show whether it is installed
#   Uses sudo for the install/remove steps. Linux only.
#
# NOTES:
#   The hook logs to the system journal. To see its entries after a wake:
#     journalctl -t b43-sleep-hook --since today
#
#-------------------------------------------------------------------------------

HOOK_NAME=b43-reload

if [[ $(uname -s) != Linux ]]; then
    print -u2 "Error: $(basename $0) runs on Linux only."
    exit 1
fi

if [[ -d /usr/lib/systemd/system-sleep ]]; then
    HOOK_DIR=/usr/lib/systemd/system-sleep
elif [[ -d /lib/systemd/system-sleep ]]; then
    HOOK_DIR=/lib/systemd/system-sleep
else
    print -u2 "Error: no systemd system-sleep directory found."
    exit 1
fi
HOOK=$HOOK_DIR/$HOOK_NAME

case "$1" in
--remove)
    if [[ -f $HOOK ]]; then
        sudo rm -f $HOOK && print "Removed $HOOK"
    else
        print "Not installed: $HOOK"
    fi
    exit 0
    ;;
--status)
    if [[ -x $HOOK ]]; then
        print "Installed: $HOOK"
        print "\nRecent hook activity:"
        journalctl -t b43-sleep-hook --since "7 days ago" --no-pager 2>/dev/null \
            | tail -10
    else
        print "Not installed."
    fi
    exit 0
    ;;
"")
    ;;
*)
    print -u2 "Usage: $(basename $0) [--remove | --status]"
    exit 1
    ;;
esac

if ! lsmod | grep -q '^b43 '; then
    print -u2 "Warning: the b43 driver is not loaded right now."
    print -u2 "Installing anyway; the hook does nothing harmful if b43 is absent."
fi

TMP=$(mktemp) || exit 1
cat > $TMP <<'EOF'
#!/bin/sh
# systemd sleep hook: reload the Broadcom b43 Wi-Fi driver around suspend.
# Installed by ~/bin/b43_sleep_hook.ksh. $1 is pre|post, $2 is the sleep type.

case "$1" in
pre)
    logger -t b43-sleep-hook "$2: unloading b43"
    modprobe -r b43 2>/dev/null
    ;;
post)
    logger -t b43-sleep-hook "$2: reloading b43"
    modprobe b43
    sleep 3
    nmcli radio wifi on 2>/dev/null
    ;;
esac
exit 0
EOF

sudo install -m 755 -o root -g root $TMP $HOOK || { rm -f $TMP; exit 1; }
rm -f $TMP

print "Installed $HOOK"
print "Test it: suspend the machine, wake it, then run:"
print "  ip -brief addr; tailscale status"
print "  journalctl -t b43-sleep-hook --since today"

#-------------------------------------------------------------------------------
