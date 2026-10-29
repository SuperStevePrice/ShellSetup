#!/bin/ksh
# check_vnc_remote.ksh - SSH into the Linux Tailscale hosts and report
# what (if anything) is running/listening for VNC.
# Usage: ksh check_vnc_remote.ksh [-s]
#   -s   Spanish output

spanish=0
[ "$1" = "-s" ] && spanish=1

hosts="100.112.55.50:imaclinux 100.73.104.80:macbookprolinux"

remote_cmd='
echo "--- VNC-related processes ---"
pgrep -fla "vnc|Vnc|VNC" 2>/dev/null
echo "--- Known VNC binaries present ---"
for b in x11vnc vncserver Xtigervnc vino-server gnome-remote-desktop-daemon; do
    p=$(command -v $b 2>/dev/null)
    [ -n "$p" ] && echo "$b -> $p"
done
echo "--- systemd units mentioning vnc/remote-desktop ---"
systemctl list-units --all 2>/dev/null | grep -i -E "vnc|remote-desktop"
echo "--- Port 5900 listener ---"
(ss -tlnp 2>/dev/null || netstat -tlnp 2>/dev/null) | grep 5900
'

for entry in $hosts; do
    ip=${entry%%:*}
    name=${entry##*:}
    if [ $spanish -eq 1 ]; then
        print "===== ${name} (${ip}) ====="
    else
        print "===== ${name} (${ip}) ====="
    fi
    ssh -o ConnectTimeout=5 "steve@${ip}" "$remote_cmd" 2>&1
    print ""
done
