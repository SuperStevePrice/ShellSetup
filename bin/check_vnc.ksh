#!/bin/ksh
# check_vnc.ksh - Check VNC (port 5900) reachability across Tailscale hosts
# Usage: ksh check_vnc.ksh [-s]
#   -s   Spanish output

spanish=0
[ "$1" = "-s" ] && spanish=1

# IP:name pairs from `tss` as of Oct 29 2026
hosts="100.113.102.87:macbookprom1 100.77.201.99:imacintel 100.112.55.50:imaclinux 100.73.104.80:macbookprolinux"

for entry in $hosts; do
    ip=${entry%%:*}
    name=${entry##*:}
    if nc -z -G 2 "$ip" 5900 2>/dev/null; then
        if [ $spanish -eq 1 ]; then
            print "${name} (${ip}): VNC ABIERTO -- puerto 5900 accesible"
        else
            print "${name} (${ip}): VNC OPEN -- port 5900 reachable"
        fi
    else
        if [ $spanish -eq 1 ]; then
            print "${name} (${ip}): VNC CERRADO o sin respuesta"
        else
            print "${name} (${ip}): VNC CLOSED or no response"
        fi
    fi
done
