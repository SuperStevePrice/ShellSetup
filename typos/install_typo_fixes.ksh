#!/bin/ksh
# install_typo_fixes.ksh -- install English/German typo corrections
#   vim:     ~/.vim/typos.vim, sourced from ~/.vimrc      (all machines)
#   Linux:   espanso match file, if espanso is installed
#   macOS:   opens Text Replacements and reveals the .plist to drag in
# Keep this script in the same folder as typos.vim, typos.yml, Text_Replacements.plist

HERE=$(cd "$(dirname "$0")" && pwd)
for f in typos.vim typos.yml Text_Replacements.plist; do
    [[ -f $HERE/$f ]] || { print -u2 "Missing $HERE/$f -- keep all files together."; exit 1; }
done

# --- vim ------------------------------------------------------------
mkdir -p ~/.vim
cp "$HERE/typos.vim" ~/.vim/typos.vim
LINE='if filereadable(expand("~/.vim/typos.vim")) | source ~/.vim/typos.vim | endif'
touch ~/.vimrc
if grep -qF '.vim/typos.vim' ~/.vimrc; then
    print "vim:     ~/.vimrc already sources typos.vim (file refreshed)"
else
    print -- "$LINE" >> ~/.vimrc
    print "vim:     installed ~/.vim/typos.vim and added source line to ~/.vimrc"
fi

case $(uname -s) in
Darwin)
    print "macOS:   Opening Keyboard settings and revealing Text_Replacements.plist."
    print "         Click 'Text Replacements...', then DRAG the .plist into the list."
    print "         (Syncs via iCloud to your other Macs and iPhone -- import on ONE Mac only.)"
    open "x-apple.systempreferences:com.apple.Keyboard-Settings.extension" 2>/dev/null \
        || open -b com.apple.systempreferences
    open -R "$HERE/Text_Replacements.plist"
    ;;
Linux)
    if command -v espanso >/dev/null 2>&1; then
        CFG=$(espanso path config 2>/dev/null)
        [[ -z $CFG ]] && CFG=~/.config/espanso
        mkdir -p "$CFG/match"
        cp "$HERE/typos.yml" "$CFG/match/typos.yml"
        espanso restart >/dev/null 2>&1
        print "espanso: installed $CFG/match/typos.yml (system-wide corrections)"
    else
        print "espanso: not installed -- vim is covered; for system-wide fixes see https://espanso.org"
    fi
    ;;
esac
print "Done."
