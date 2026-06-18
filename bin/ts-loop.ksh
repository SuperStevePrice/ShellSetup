#!/usr/bin/env ksh
TAILSCALE="/Applications/Tailscale.app/Contents/MacOS/Tailscale"

if [ $# -eq 0 ]; then
  # Run on local machine first
  print "=== LOCAL MACHINE ==="
  $TAILSCALE status
  
  # Then run on remotes
  for ip in $($TAILSCALE status | tail -n +2 | awk '{print $1}'); do
    print "=== $ip ==="
    ssh steve@$ip 'if [ -x /usr/bin/tailscale ]; then /usr/bin/tailscale status; else /Applications/Tailscale.app/Contents/MacOS/Tailscale status; fi'
  done
else
  # Run on local machine first
  print "=== LOCAL MACHINE ==="
  eval "$@"
  
  # Then run on remotes
  for ip in $($TAILSCALE status | tail -n +2 | awk '{print $1}'); do
    print "=== $ip ==="
    ssh steve@$ip "$@"
  done
fi
