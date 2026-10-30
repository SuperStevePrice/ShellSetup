#!/usr/bin/env ksh
#
# tss.ksh - show Tailscale status.
#
# On macOS, calls the Tailscale.app CLI directly (not on PATH by
# default). On other platforms (the Linux boxes), assumes the
# `tailscale` CLI is already on PATH via apt/package install.

if [[ $(uname) == Darwin ]]; then
    /Applications/Tailscale.app/Contents/MacOS/Tailscale status
else
    tailscale status
fi
