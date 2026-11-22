#!/usr/bin/env ksh
# Disable all active utun interfaces

ifconfig -a | grep "^utun" | awk '{print $1}' | while read iface; do
    echo "Bringing down $iface ..."
    sudo ifconfig "$iface" down
done

echo "Done. Checking routes..."
