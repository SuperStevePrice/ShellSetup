#!/bin/ksh
#
# update-linux-hosts.ksh - apt update, full-upgrade, and autoremove
# across all Linux hosts found via tss
#
# Requires: NOPASSWD sudo rule for apt update / full-upgrade -y /
# --fix-broken install -y / autoremove -y already deployed on each
# host (see nopasswd-apt-update.ksh / deploy-nopasswd.ksh).

for ip in $(tss | grep -i linux | awk '{print $1}')
do
    print "== $ip =="
    ssh -o BatchMode=yes -o ConnectTimeout=5 "$ip" \
        "sudo apt update && sudo apt full-upgrade -y" \
        || {
            print "!! upgrade failed on $ip, attempting --fix-broken install"
            ssh -o BatchMode=yes -o ConnectTimeout=5 "$ip" \
                "sudo apt --fix-broken install -y && sudo apt full-upgrade -y" \
                || print "!! still failed after fix-broken: $ip"
        }
    ssh -o BatchMode=yes -o ConnectTimeout=5 "$ip" "sudo apt autoremove -y" \
        || print "!! autoremove failed on $ip"
    print ""
done
