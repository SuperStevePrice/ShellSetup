#!/usr/bin/env ksh
# restore_from_tm.ksh - Restore files lost when ~/bin was rebuilt (2026-11-21 15:57)
#   from the Time Machine drive into ~/bin.
#
# Usage: restore_from_tm.ksh [-n]
#   -n   dry run: show what would be restored, copy nothing
#
# Reads the names marked "NEEDS TIME MACHINE" in ~/Downloads/missing_bin_files.txt.
# For each one, searches backups from newest to oldest, starting with the
# last backup taken before 2026-11-21 15:57, and copies the first copy found.
# Backups are mounted read-only as needed and unmounted afterwards.
# Never overwrites a file that already exists in ~/bin.
# Needs Full Disk Access for the app running it (System Settings > Privacy & Security).

LIST="$HOME/Downloads/missing_bin_files.txt"
CUTOFF="2026-11-21-155700"
DEST="$HOME/bin"
DRY=0
[[ "$1" == "-n" ]] && DRY=1

MP=$(tmutil destinationinfo 2>/dev/null | awk -F': ' '/^Mount Point/{print $2; exit}')
if [[ -z "$MP" || ! -d "$MP" ]]; then
    echo "Time Machine drive is not connected."; exit 1
fi
DEV=$(df "$MP" | awk 'NR==2{print $1}')

# Snapshot names before the cutoff, newest first.
SNAPS=$(diskutil apfs listSnapshots "$DEV" 2>/dev/null |
        sed -n 's/.*Name: *com\.apple\.TimeMachine\.\([0-9-]*\)\.backup.*/\1/p' |
        awk -v c="$CUTOFF" '$0 < c' | sort -r)
if [[ -z "$SNAPS" ]]; then
    echo "No backups found from before $CUTOFF (or no Full Disk Access)."; exit 1
fi

WORK=$(mktemp -d /tmp/restore_from_tm.XXXXXX)
MOUNTED=""
cleanup() {
    for m in $MOUNTED; do umount "$m" 2>/dev/null; done
    rm -rf "$WORK" 2>/dev/null
}
trap cleanup EXIT INT TERM

# Print the bin folder inside backup $1, mounting it if needed.
bin_of() {
    typeset s=$1 m="$WORK/$1"
    if [[ ! -d "$m/$s.backup" ]]; then
        mkdir -p "$m"
        mount_apfs -o ro,nobrowse -s "com.apple.TimeMachine.$s.backup" "$DEV" "$m" 2>/dev/null || return 1
        MOUNTED="$MOUNTED $m"
    fi
    print -r -- "$m/$s.backup/Data/Users/$USER/bin"
}

echo "Searching $(print -- "$SNAPS" | wc -l | tr -d ' ') backups, newest first: $(print -- "$SNAPS" | head -1)"

restored=0; notfound=""
for f in $(grep 'NEEDS TIME MACHINE' "$LIST" | awk '{print $1}'); do
    if [[ -e "$DEST/$f" || -L "$DEST/$f" ]]; then
        echo "skip (exists): $f"; continue
    fi
    hit=""
    for s in $SNAPS; do
        d=$(bin_of "$s") || continue
        # bin_of runs in a subshell; record the mount so cleanup sees it
        [[ "$MOUNTED" == *"$WORK/$s"* ]] || MOUNTED="$MOUNTED $WORK/$s"
        if [[ -e "$d/$f" || -L "$d/$f" ]]; then hit="$d/$f"; from=$s; break; fi
    done
    if [[ -z "$hit" ]]; then
        echo "NOT FOUND:   $f"; notfound="$notfound $f"; continue
    fi
    echo "restore:     $f  <-  backup $from"
    (( DRY )) || cp -npR "$hit" "$DEST/$f"
    ((restored++))
done

echo
(( DRY )) && echo "Dry run: $restored file(s) would be restored." \
          || echo "Restored $restored file(s) into $DEST."
[[ -n "$notfound" ]] && echo "Not in any backup:$notfound"
