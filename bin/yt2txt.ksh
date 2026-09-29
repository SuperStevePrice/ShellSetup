#!/bin/ksh
# yt2txt.ksh — fetch a YouTube video's captions and save them as plain text,
#              named after the video's title.
#
# Usage:  yt2txt [-l lang] [-o name] [-d dir] [-u] URL|VIDEO_ID
#   Accepts watch?v=, youtu.be/, /shorts/, /live/, /embed/ URLs (playlist
#   and timestamp tails are ignored) or a bare 11-character video id.
#   -l lang   caption language (default: en; e.g. de for German)
#   -o name   output base name (default: the video title, filename-safe,
#             trimmed to ~80 chars, e.g. Your_Mind_Isn_t_What_You_Think_...)
#   -d dir    output directory (default: $YT2TXT_DIR, else ~/Documents)
#   -u        upgrade yt-dlp first (brew on macOS, pipx/pip on Linux)
#
# Output: <dir>/<name>.txt. An existing file is never overwritten; a
#         numeric suffix (_2, _3, …) is added instead.

lang=en
name=""
outdir=${YT2TXT_DIR:-$HOME/Documents}
upgrade=0

usage() {
    print -u2 "Usage: ${0##*/} [-l lang] [-o name] [-d dir] [-u] URL|VIDEO_ID"
    exit 1
}

while getopts ":l:o:d:u" opt; do
    case $opt in
        l) lang=$OPTARG ;;
        o) name=$OPTARG ;;
        d) outdir=$OPTARG ;;
        u) upgrade=1 ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))
(( $# == 1 )) || usage
url=$1

# --- Pull the 11-char video id out of any YouTube URL form -----------------
case $url in
    *youtu.be/*) id=${url##*youtu.be/} ;;
    *[?\&]v=*)   id=${url##*[?\&]v=} ;;
    */shorts/*)  id=${url##*/shorts/} ;;
    */live/*)    id=${url##*/live/} ;;
    */embed/*)   id=${url##*/embed/} ;;
    [A-Za-z0-9_-][A-Za-z0-9_-][A-Za-z0-9_-][A-Za-z0-9_-][A-Za-z0-9_-][A-Za-z0-9_-][A-Za-z0-9_-][A-Za-z0-9_-][A-Za-z0-9_-][A-Za-z0-9_-][A-Za-z0-9_-])
                 id=$url ;;             # bare 11-char video id
    *)           print -u2 "Cannot find a video id in: $url"; exit 1 ;;
esac
id=${id%%['&?#/']*}
[[ $id == @(???????????) ]] || { print -u2 "Bad video id '$id' from: $url"; exit 1; }
clean="https://www.youtube.com/watch?v=$id"   # drops &list=… so no playlist

mkdir -p "$outdir" || { print -u2 "Cannot create $outdir"; exit 1; }

# --- Optional upgrade (answers brew's y/n prompt automatically) ------------
if (( upgrade )); then
    if whence brew >/dev/null; then
        print "Upgrading yt-dlp via brew…"
        print y | brew upgrade yt-dlp
    elif whence pipx >/dev/null; then
        pipx upgrade yt-dlp
    else
        python3 -m pip install -U yt-dlp --user
    fi
fi

whence yt-dlp >/dev/null || { print -u2 "yt-dlp not found. Install it first."; exit 1; }

# --- Fetch captions into a scratch dir, named by title ---------------------
# --restrict-filenames gives ASCII, no spaces (umlauts → ae/oe/ue etc.);
# %(title).80B caps the name at 80 bytes.
tmp=$(mktemp -d "${TMPDIR:-/tmp}/yt2txt.XXXXXX") || exit 1
trap 'rm -rf "$tmp"' EXIT

print "Fetching $lang captions for $id …"
yt-dlp --no-playlist --skip-download \
       --write-subs --write-auto-subs \
       --sub-langs "$lang" --sub-format vtt \
       --restrict-filenames \
       -o "$tmp/%(title).80B" "$clean" || {
    print -u2 "yt-dlp failed. Try again with -u to upgrade yt-dlp."
    exit 1
}

vtt=$(ls "$tmp"/*.vtt 2>/dev/null | head -1)
[[ -n $vtt ]] || { print -u2 "No '$lang' captions available for this video."; exit 1; }

if [[ -z $name ]]; then
    name=${vtt##*/}             # Title_Words.en.vtt
    name=${name%.vtt}           # Title_Words.en
    name=${name%.*}             # Title_Words
    name=${name%%+([_-])}       # trim trailing _ or - left by truncation
    [[ -z $name ]] && name="yt_$id"
fi

# --- Never overwrite: add _2, _3, … if needed ------------------------------
out="$outdir/$name.txt"
n=2
while [[ -e $out ]]; do
    out="$outdir/${name}_$n.txt"
    (( n++ ))
done

# --- VTT → plain text: drop headers/timestamps/tags, collapse rolling dupes -
grep -v -e '^WEBVTT' -e '-->' -e '^Kind:' -e '^Language:' -e '^[[:space:]]*$' "$vtt" |
    sed -e 's/<[^>]*>//g' -e 's/&amp;/\&/g' -e 's/&gt;/>/g' -e 's/&lt;/</g' |
    awk '!seen[$0]++' > "$out"

print "Done: $out ($(wc -w < "$out" | tr -d ' ') words)"
