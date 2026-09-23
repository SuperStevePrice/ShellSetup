#!/bin/ksh
#===============================================================================
# pushInstall.ksh -- pull ShellSetup and install bin/ scripts on remote machines
#
# Usage:  pushInstall.ksh [script ...]      (default: syncAll)
#
# For each host: git pull --ff-only in ~/Projects/ShellSetup, then copy each
# named script from bin/ to ~/bin, stamping the "Last installed" footer.
#===============================================================================

HOSTS="steves-imac imac-linux macbookpro-linux"

(( $# )) || set -- syncAll

rc=0
for h in $HOSTS
do
    print "== $h"
    ssh -o ConnectTimeout=10 "$h" ksh -s -- "$@" <<'EOF'
cd ~/Projects/ShellSetup || exit 1
git pull --ff-only -q   || exit 2
mkdir -p ~/bin
stamp=$(date '+%Y-%m-%d %H:%M:%S')
status=0
for f
do
    src=bin/$f
    if [[ ! -f $src ]]
    then
        print -u2 "   missing: $src"
        status=3
        continue
    fi
    tmp=~/bin/.$f.$$
    {
        cat "$src"
        print '#-------------------------------------------------------------------------------'
        print "# Last installed: $stamp"
        print '#-- End of File ----------------------------------------------------------------'
    } > "$tmp" && chmod 755 "$tmp" && mv "$tmp" ~/bin/"$f" \
        && print "   installed ~/bin/$f" \
        || { print -u2 "   install failed: $f"; status=4; }
done
exit $status
EOF
    (( $? )) && { print -u2 "   FAILED on $h"; rc=1; }
done
exit $rc
#-- End of File ----------------------------------------------------------------
