#!/bin/ksh
# set_api_key.ksh — store an API key in a private file that .kshrc sources,
#                   without the key ever touching your shell history.
#
# Usage:  set_api_key [VARNAME]        (default: OPENAI_API_KEY)
#
# - Prompts for the key with echo OFF (nothing on screen, nothing in history).
# - Writes/updates:  export VARNAME='key'  in ~/.secrets/api_keys.ksh
#   (~/.secrets is mode 700, the file mode 600: readable by you alone).
# - Adds one source line to ~/Projects/SS/dots/kshrc if it is missing, so
#   setup.ksh deploys it. The line holds no secret, so it is safe to sync.
# - The secrets file itself is NOT part of SS; run this once on each machine.

var=${1:-OPENAI_API_KEY}
[[ $var == [A-Za-z_]*([A-Za-z0-9_]) ]] || { print -u2 "Bad variable name: $var"; exit 1; }

sdir=$HOME/.secrets
sfile=$sdir/api_keys.ksh
kshrc_src=$HOME/Projects/SS/dots/kshrc
srcline='[[ -r ~/.secrets/api_keys.ksh ]] && . ~/.secrets/api_keys.ksh'

# --- Read the key silently (not ksh93 'read -s', which SAVES to history) --
print -n "Paste $var (input hidden), then Return: "
stty -echo
trap 'stty echo' EXIT INT TERM
read -r key
stty echo
print
[[ -n $key ]] || { print -u2 "No key entered; nothing changed."; exit 1; }
[[ $key == *"'"* ]] && { print -u2 "Key contains a quote; refusing."; exit 1; }

# --- Private directory and file --------------------------------------------
umask 077
mkdir -p "$sdir" && chmod 700 "$sdir"
touch "$sfile" && chmod 600 "$sfile"

# Replace any existing line for this variable, then append the new one
tmp=$(mktemp "$sdir/.tmp.XXXXXX") || exit 1
grep -v "^export $var=" "$sfile" > "$tmp"
print -r -- "export $var='$key'" >> "$tmp"
mv "$tmp" "$sfile" && chmod 600 "$sfile"
print "Saved $var to $sfile (mode 600)."

# --- Make .kshrc source it --------------------------------------------------
if [[ -f $kshrc_src ]]; then
    if ! grep -qF '.secrets/api_keys.ksh' "$kshrc_src"; then
        print -r -- "" >> "$kshrc_src"
        print -r -- "# Private API keys (not in SS; see set_api_key.ksh)" >> "$kshrc_src"
        print -r -- "$srcline" >> "$kshrc_src"
        print "Added source line to $kshrc_src — run setup.ksh to deploy it."
    else
        print "Source line already present in $kshrc_src."
    fi
else
    print "SS kshrc not found; add this line to ~/.kshrc yourself:"
    print -r -- "  $srcline"
fi

# --- macOS: hand the key to GUI apps (replaces the old one) ----------------
if [[ $(uname) == Darwin ]]; then
    launchctl setenv "$var" "$key"
    print "launchctl: $var updated for GUI apps (this login session)."
fi

print "Open a new terminal (or: . $sfile) to use it."
