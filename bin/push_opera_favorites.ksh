#!/bin/ksh
#
# push_opera_favorites.ksh
#
# Copies ~/Documents/opera_good_7_10_26.html to a list of remote machines,
# creating ~/Documents there if it doesn't exist.
#
# EDIT THE HOSTS ARRAY BELOW with the 3 machines you want to send to
# (everything except your MacBook Pro and cws, your current working server).
# Use whatever ssh already resolves for you: hostname, IP, or an entry
# from ~/.ssh/config. Include the username if it differs from your local one,
# e.g. "user@hostname".

typeset -a HOSTS
HOSTS[1]="100.112.55.50"   # imaclinux
HOSTS[2]="100.73.104.80"   # macbookprolinux
HOSTS[3]="100.77.201.99"   # imacintel

LOCAL_FILE="$HOME/Documents/opera_good_favorites_7_10_26.html"
REMOTE_DIR="Documents"
REMOTE_FILE="~/${REMOTE_DIR}/$(basename "$LOCAL_FILE")"

if [[ ! -f "$LOCAL_FILE" ]]; then
    print -u2 "ERROR: $LOCAL_FILE not found."
    exit 1
fi

typeset -i i=1
typeset -i fail_count=0

while (( i <= ${#HOSTS[@]} )); do
    host="${HOSTS[i]}"
    print "==> $host"

    ssh "$host" "mkdir -p ~/${REMOTE_DIR}"
    if (( $? != 0 )); then
        print -u2 "    Failed to mkdir on $host, skipping."
        fail_count=$((fail_count + 1))
        i=$((i + 1))
        continue
    fi

    scp "$LOCAL_FILE" "${host}:${REMOTE_FILE}"
    if (( $? != 0 )); then
        print -u2 "    scp to $host FAILED."
        fail_count=$((fail_count + 1))
    else
        print "    OK: copied to ${host}:${REMOTE_FILE}"
    fi

    i=$((i + 1))
done

if (( fail_count > 0 )); then
    print -u2 "Done with $fail_count failure(s)."
    exit 1
else
    print "Done. Copied to all ${#HOSTS[@]} hosts."
    exit 0
fi
