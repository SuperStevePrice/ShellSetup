#!/bin/ksh
#
# compress_image.ksh - resize / recompress images to cut file size
#
# Works with ImageMagick ("magick" or "convert") if installed, and falls
# back to macOS's built-in "sips" if ImageMagick isn't found. Handles
# filenames with spaces, wildcards, and mixed-case extensions safely.
#
# Usage:
#   compress_image.ksh [options] file1 [file2 ...]
#
# Options:
#   -w WIDTH    Max width in pixels; taller/wider images are shrunk to
#               fit, smaller ones are left alone. (default: 1600)
#   -q QUALITY  Output quality, 1-100, for JPEG output. (default: 80)
#   -o DIR      Write compressed copies into DIR instead of alongside
#               each original. DIR is created if it doesn't exist.
#   -s          Show messages in Spanish.
#   -g          Show messages in German.
#   -f          Show messages in French.
#   -h, --help  Show this help and exit.
#
# Examples:
#   compress_image.ksh photo.jpg
#   compress_image.ksh -w 1200 -q 75 *.png
#   compress_image.ksh -o ~/Desktop/compressed "My Photo.jpg" another.JPG
#
# Output filenames:
#   Without -o, each compressed file is written next to the original as
#   NAME_compressed.EXT (original is never overwritten).
#   With -o, each compressed file keeps its original name inside DIR.

LANG_CODE="en"
WIDTH=1600
QUALITY=80
OUTDIR=""

# ---- rewrite any "--help" to "-h" in place, keeping all other args ----
typeset -a newargs
newargs=()
for arg in "$@"; do
    if [[ "$arg" == "--help" ]]; then
        newargs+=("-h")
    else
        newargs+=("$arg")
    fi
done
set -- "${newargs[@]}"

usage() {
    case "$LANG_CODE" in
        es)
            print "Uso: compress_image.ksh [opciones] archivo1 [archivo2 ...]"
            print ""
            print "Opciones:"
            print "  -w ANCHO    Ancho máximo en píxeles (por defecto: 1600)"
            print "  -q CALIDAD  Calidad de salida JPEG, 1-100 (por defecto: 80)"
            print "  -o DIR      Carpeta de salida (si no, junto al original)"
            print "  -s          Mensajes en español"
            print "  -g          Mensajes en alemán"
            print "  -f          Mensajes en francés"
            print "  -h, --help  Mostrar esta ayuda"
            ;;
        de)
            print "Verwendung: compress_image.ksh [Optionen] datei1 [datei2 ...]"
            print ""
            print "Optionen:"
            print "  -w BREITE    Maximale Breite in Pixeln (Standard: 1600)"
            print "  -q QUALITAET Ausgabequalität JPEG, 1-100 (Standard: 80)"
            print "  -o VERZ      Ausgabeverzeichnis (sonst neben dem Original)"
            print "  -s           Meldungen auf Spanisch"
            print "  -g           Meldungen auf Deutsch"
            print "  -f           Meldungen auf Französisch"
            print "  -h, --help   Diese Hilfe anzeigen"
            ;;
        fr)
            print "Usage : compress_image.ksh [options] fichier1 [fichier2 ...]"
            print ""
            print "Options :"
            print "  -w LARGEUR   Largeur maximale en pixels (défaut : 1600)"
            print "  -q QUALITE   Qualité de sortie JPEG, 1-100 (défaut : 80)"
            print "  -o REP       Dossier de sortie (sinon à côté de l'original)"
            print "  -s           Messages en espagnol"
            print "  -g           Messages en allemand"
            print "  -f           Messages en français"
            print "  -h, --help   Afficher cette aide"
            ;;
        *)
            print "Usage: compress_image.ksh [options] file1 [file2 ...]"
            print ""
            print "Options:"
            print "  -w WIDTH    Max width in pixels (default: 1600)"
            print "  -q QUALITY  Output quality, 1-100 (default: 80)"
            print "  -o DIR      Output directory (default: alongside original)"
            print "  -s          Spanish messages"
            print "  -g          German messages"
            print "  -f          French messages"
            print "  -h, --help  Show this help"
            ;;
    esac
}

msg() {
    # msg KEY [arg...]
    typeset key="$1"; shift
    case "$LANG_CODE:$key" in
        es:no_tool)    print -u2 "Error: no se encontró ImageMagick (magick/convert) ni sips." ;;
        es:no_file)    print -u2 "Error: archivo no encontrado: $1" ;;
        es:not_readable) print -u2 "Error: no se puede leer: $1" ;;
        es:no_files)   print -u2 "Error: no se indicó ningún archivo de imagen." ;;
        es:processing) print "Procesando: $1" ;;
        es:done)       print "  -> $1  ($2 -> $3, ahorro de $4%)" ;;
        es:skip_same)  print "  -> $1  (sin ahorro, se dejó igual: $2)" ;;
        es:failed)     print -u2 "  Error al procesar: $1" ;;
        es:summary)    print "Listo: $1 de $2 archivo(s) comprimido(s)." ;;

        de:no_tool)    print -u2 "Fehler: weder ImageMagick (magick/convert) noch sips gefunden." ;;
        de:no_file)    print -u2 "Fehler: Datei nicht gefunden: $1" ;;
        de:not_readable) print -u2 "Fehler: kann nicht gelesen werden: $1" ;;
        de:no_files)   print -u2 "Fehler: keine Bilddatei angegeben." ;;
        de:processing) print "Verarbeite: $1" ;;
        de:done)       print "  -> $1  ($2 -> $3, $4% gespart)" ;;
        de:skip_same)  print "  -> $1  (keine Ersparnis, unverändert: $2)" ;;
        de:failed)     print -u2 "  Fehler bei der Verarbeitung: $1" ;;
        de:summary)    print "Fertig: $1 von $2 Datei(en) komprimiert." ;;

        fr:no_tool)    print -u2 "Erreur : ni ImageMagick (magick/convert) ni sips trouvé." ;;
        fr:no_file)    print -u2 "Erreur : fichier introuvable : $1" ;;
        fr:not_readable) print -u2 "Erreur : lecture impossible : $1" ;;
        fr:no_files)   print -u2 "Erreur : aucun fichier image indiqué." ;;
        fr:processing) print "Traitement : $1" ;;
        fr:done)       print "  -> $1  ($2 -> $3, $4% économisé)" ;;
        fr:skip_same)  print "  -> $1  (aucun gain, inchangé : $2)" ;;
        fr:failed)     print -u2 "  Échec du traitement : $1" ;;
        fr:summary)    print "Terminé : $1 fichier(s) sur $2 compressé(s)." ;;

        *:no_tool)     print -u2 "Error: neither ImageMagick (magick/convert) nor sips was found." ;;
        *:no_file)     print -u2 "Error: file not found: $1" ;;
        *:not_readable) print -u2 "Error: cannot read: $1" ;;
        *:no_files)    print -u2 "Error: no image file given." ;;
        *:processing)  print "Processing: $1" ;;
        *:done)        print "  -> $1  ($2 -> $3, $4% saved)" ;;
        *:skip_same)   print "  -> $1  (no savings, left as-is: $2)" ;;
        *:failed)      print -u2 "  Failed to process: $1" ;;
        *:summary)     print "Done: $1 of $2 file(s) compressed." ;;
    esac
}

# ---- option parsing ----
while getopts "w:q:o:sgfh" opt; do
    case "$opt" in
        w) WIDTH="$OPTARG" ;;
        q) QUALITY="$OPTARG" ;;
        o) OUTDIR="$OPTARG" ;;
        s) LANG_CODE="es" ;;
        g) LANG_CODE="de" ;;
        f) LANG_CODE="fr" ;;
        h) usage; exit 0 ;;
        *) usage; exit 1 ;;
    esac
done
shift $((OPTIND - 1))

if (( $# == 0 )); then
    msg no_files
    usage
    exit 1
fi

# ---- pick a tool, once ----
TOOL=""
if command -v magick >/dev/null 2>&1; then
    TOOL="magick"
elif command -v convert >/dev/null 2>&1; then
    TOOL="convert"
elif [[ "$(uname)" == "Darwin" ]] && command -v sips >/dev/null 2>&1; then
    TOOL="sips"
else
    msg no_tool
    exit 1
fi

human_size() {
    # human_size BYTES -> prints e.g. "842K" or "3.1M"
    typeset bytes="$1"
    if (( bytes >= 1048576 )); then
        awk -v b="$bytes" 'BEGIN{printf "%.1fM", b/1048576}'
    elif (( bytes >= 1024 )); then
        awk -v b="$bytes" 'BEGIN{printf "%.0fK", b/1024}'
    else
        print "${bytes}B"
    fi
}

file_size() {
    # portable stat (macOS BSD stat vs GNU coreutils stat)
    stat -f%z "$1" 2>/dev/null || stat -c%s "$1" 2>/dev/null
}

typeset -i count_ok=0
typeset -i count_total=0

if [[ -n "$OUTDIR" ]]; then
    mkdir -p "$OUTDIR" 2>/dev/null
fi

for src in "$@"; do
    (( count_total = count_total + 1 ))

    if [[ ! -e "$src" ]]; then
        msg no_file "$src"
        continue
    fi
    if [[ ! -r "$src" ]]; then
        msg not_readable "$src"
        continue
    fi

    base="${src##*/}"
    stem="${base%.*}"
    ext="${base##*.}"

    if [[ -n "$OUTDIR" ]]; then
        dest="$OUTDIR/$base"
    else
        dir="${src%/*}"
        [[ "$dir" == "$src" ]] && dir="."
        dest="$dir/${stem}_compressed.${ext}"
    fi

    msg processing "$src"

    typeset -i orig_bytes
    orig_bytes=$(file_size "$src")

    case "$TOOL" in
        magick)
            magick "$src" -resize "${WIDTH}x${WIDTH}>" -quality "$QUALITY" "$dest" 2>/dev/null
            ;;
        convert)
            convert "$src" -resize "${WIDTH}x${WIDTH}>" -quality "$QUALITY" "$dest" 2>/dev/null
            ;;
        sips)
            cp "$src" "$dest" 2>/dev/null
            sips -Z "$WIDTH" "$dest" >/dev/null 2>&1
            case "$ext" in
                [Jj][Pp][Gg]|[Jj][Pp][Ee][Gg])
                    sips -s formatOptions "$QUALITY" "$dest" >/dev/null 2>&1
                    ;;
            esac
            ;;
    esac

    if [[ ! -e "$dest" ]]; then
        msg failed "$src"
        continue
    fi

    typeset -i new_bytes
    new_bytes=$(file_size "$dest")

    if (( orig_bytes > 0 )) && (( new_bytes < orig_bytes )); then
        typeset -i pct
        (( pct = (orig_bytes - new_bytes) * 100 / orig_bytes ))
        msg done "$dest" "$(human_size "$orig_bytes")" "$(human_size "$new_bytes")" "$pct"
    else
        msg skip_same "$dest" "$(human_size "$orig_bytes")"
    fi

    (( count_ok = count_ok + 1 ))
done

msg summary "$count_ok" "$count_total"

(( count_ok > 0 ))
