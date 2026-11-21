#!/bin/ksh
# all_sleep.ksh
#
# Master wrapper for the sleep-study pipeline. Runs in dependency order:
#   1. nocturnal       - paste/run tonight's iPhone clipboard commands,
#                         opens vi for Cmd-V, logs entries via nocturnal_log
#   2. nocturnal_log   - (no args) list/confirm what was just logged
#   3. morning_sleep   - Apple Health sleep report; cross-references the
#                         nocturnal data logged in steps 1-2, so it must
#                         run after them
#   4. health_sleep    - ResMed myAir report; independent of nocturnal data
#
# Each sub-tool is skipped (not fatal) if not found on PATH. Shows live
# output on screen AND writes a single combined log file for the run.
#
# -d / --dry-run: don't run anything. Instead, for each of the four steps,
# print the command that WOULD run, and where applicable, check whether
# the required input data is actually sitting in ~/Downloads, printing a
# warning with how-to-get-it instructions if it's missing. Ends with a
# count of warnings (0-3; nocturnal_log has nothing file-based to check).

DRYRUN=0
case "$1" in
	-d|-D|--dry-run) DRYRUN=1 ;;
esac

SCRIPT_NAME=$(basename "$0" .ksh)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOGDIR="$HOME/logs"
LOGFILE="$LOGDIR/${SCRIPT_NAME}.${TIMESTAMP}.log"
DLDIR="$HOME/Downloads"

mkdir -p "$LOGDIR"

run() {
	if [[ $DRYRUN -eq 1 ]]; then
		print "=== all_sleep: DRY RUN $(date) ==="
		WARNINGS=0

		print "\n--- nocturnal ---"
		print "Would run: nocturnal"
		leftover=$(ls "$DLDIR"/nocturnal_cmds_*.ksh 2>/dev/null)
		if [[ -n "$leftover" ]]; then
			print "WARNING: found existing unconsumed cmds file(s) in $DLDIR:"
			print "$leftover"
			print "  -> make sure these were already run (ksh <file>) before logging new data."
			WARNINGS=$((WARNINGS + 1))
		else
			print "No leftover nocturnal_cmds_*.ksh files found - OK."
		fi

		print "\n--- nocturnal_log ---"
		print "Would run: nocturnal_log -l"
		print "(nothing to check - reads its own internal log)"

		print "\n--- morning_sleep ---"
		print "Would run: morning_sleep"
		if [[ -f "$DLDIR/export.zip" || -d "$DLDIR/apple_health_export" ]]; then
			print "Found export.zip or apple_health_export/ in $DLDIR - OK."
		else
			print "WARNING: no export.zip or apple_health_export/ found in $DLDIR."
			print "  -> On iPhone: Health app -> profile icon -> Export All Health Data ->"
			print "     AirDrop/save export.zip to this Mac's Downloads folder."
			WARNINGS=$((WARNINGS + 1))
		fi

		print "\n--- health_sleep ---"
		print "Would run: health_sleep"
		if [[ -f "$DLDIR/myAir-Steve Price.pdf" ]]; then
			print "Found myAir-Steve Price.pdf in $DLDIR - OK."
		else
			print "WARNING: no myAir-Steve Price.pdf found in $DLDIR."
			print "  -> Log in to sleep.myair.resmed.com, download your report PDF,"
			print "     save it to this Mac's Downloads folder."
			WARNINGS=$((WARNINGS + 1))
		fi

		print "\n=== all_sleep: dry run finished $(date) - $WARNINGS warning(s) ==="
		print "See: $LOGFILE"
		return 0
	fi

	print "=== all_sleep: starting $(date) ==="

	print "\n--- nocturnal ---"
	if command -v nocturnal >/dev/null 2>&1; then
		nocturnal
	else
		print "nocturnal not found on PATH - skipping"
	fi

	print "\n--- nocturnal_log ---"
	if command -v nocturnal_log >/dev/null 2>&1; then
		nocturnal_log -l
	else
		print "nocturnal_log not found on PATH - skipping"
	fi

	print "\n--- morning_sleep ---"
	if command -v morning_sleep >/dev/null 2>&1; then
		morning_sleep
	else
		print "morning_sleep not found on PATH - skipping"
	fi

	print "\n--- health_sleep ---"
	if command -v health_sleep >/dev/null 2>&1; then
		health_sleep
	else
		print "health_sleep not found on PATH - skipping"
	fi

	print "\n=== all_sleep: finished $(date) ==="
	print "See: $LOGFILE"
}

run 2>&1 | tee -a "$LOGFILE"
