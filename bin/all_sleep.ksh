#!/bin/ksh
# all_sleep.ksh
#
# Master wrapper for the sleep-study pipeline. Runs in dependency order:
#   1. urine              - paste the Urine Log app's iPhone clipboard commands,
#                            opens vi for Cmd-V, logs entries via urine_log
#   2. urine_log          - (no args) processes the pasted commands,
#                            then (-l) lists/confirms, then (-r) writes the
#                            urine_log.pdf/.xlsx pair to the Desktop
#   3. morning_sleep      - Apple Health meds log + sleep_report.pdf/.xlsx
#                            pair; cross-references the urine data logged
#                            in steps 1-2, so it must run after them. It also
#                            runs health_sleep (Apple Watch sleep-stage data
#                            from export.xml) itself, so all_sleep does not
#                            run health_sleep as a separate step.
#   4. myair_stats_report - ResMed myAir report; independent of the above,
#                            writes its own PDF/xlsx pair to the Desktop
#   5. sleep_summary      - one-page overview of steps 1-4's stored data
#                            (averages, medians, totals); writes the
#                            sleep_summary.pdf/.xlsx pair to the Desktop
#
# Each sub-tool is skipped (not fatal) if not found on PATH. Shows live
# output on screen AND writes a single combined log file for the run.
#
# -d / --dry-run: don't run anything. Instead, for each of the five steps,
# print the command that WOULD run, and where applicable, check whether
# the required input data is actually sitting in ~/Downloads, printing a
# warning with how-to-get-it instructions if it's missing. Ends with a
# count of warnings (0-2; urine_log has nothing file-based to check,
# and morning_sleep's check covers health_sleep's export input).

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

# Looks up the most recently written ~/logs/<name>.*.log file for a given
# sub-step and prints its own "See: ..." line, if it has one. Reads the
# file from disk after the step has already finished, rather than piping
# the step's live output through another tee - urine's vi session in
# particular needs direct terminal access and must not be re-piped.
latest_see_line() {
	typeset f
	f=$(ls -t "$LOGDIR/$1".*.log 2>/dev/null | head -1)
	[[ -n "$f" ]] && grep '^See:' "$f" 2>/dev/null
}

run() {
	if [[ $DRYRUN -eq 1 ]]; then
		print "=== all_sleep: DRY RUN $(date) ==="
		WARNINGS=0

		print "\n--- urine ---"
		print "Would run: urine"
		leftover=$(ls "$DLDIR"/urine_cmds_*.ksh "$DLDIR"/nocturnal_cmds_*.ksh 2>/dev/null)
		if [[ -n "$leftover" ]]; then
			print "WARNING: found existing unconsumed cmds file(s) in $DLDIR:"
			print "$leftover"
			print "  -> make sure these were already run (ksh <file>) before logging new data."
			WARNINGS=$((WARNINGS + 1))
		else
			print "No leftover urine_cmds_*.ksh files found - OK."
		fi

		print "\n--- urine_log ---"
		print "Would run: urine_log (process pending), then urine_log -l, then urine_log -r"
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

		print "\n--- myair_stats_report ---"
		print "Would run: myair_stats_report"
		if [[ -f "$DLDIR/myAir-Steve Price.pdf" || -f "$DLDIR/myAir-Steve-Price.pdf" ]]; then
			print "Found myAir-Steve Price.pdf in $DLDIR - OK."
		else
			print "WARNING: no myAir-Steve Price.pdf found in $DLDIR."
			print "  -> Log in to sleep.myair.resmed.com, download your report PDF,"
			print "     save it to this Mac's Downloads folder."
			WARNINGS=$((WARNINGS + 1))
		fi

		print "\n--- sleep_summary ---"
		print "Would run: sleep_summary (reads the data the steps above store)"

		print "\n=== all_sleep: dry run finished $(date) - $WARNINGS warning(s) ==="
		print "See: $LOGFILE"
		return 0
	fi

	print "=== all_sleep: starting $(date) ==="
	SEE_LINES=""

	print ""
	print "In order for this script to complete, this script requires the following input:"
	print "  - Apple Health export: ~/Downloads/export.zip (or an already-unzipped"
	print "    apple_health_export/ folder). Get it via: iPhone Health app -> profile"
	print "    icon -> Export All Health Data -> AirDrop to this Mac."
	print "  - ResMed myAir report: ~/Downloads/myAir-Steve Price.pdf. Get it via:"
	print "    https://myair.resmed.com -> History -> Report -> save/export the PDF."

	print ""
	read ans?"Proceed? [Y/n]: "
	case "$ans" in
		[Nn]*)
			print ""
			print "Exiting at your request before starting the sleep-study run."
			print "=== all_sleep: finished $(date) - user chose to leave ==="
			print "See: $LOGFILE"
			return 0
			;;
	esac

	print "\n--- urine ---"
	if command -v urine >/dev/null 2>&1; then
		urine
		SEE_LINES="${SEE_LINES}$(latest_see_line urine)
"
	else
		print "urine not found on PATH - skipping"
	fi

	print "\n--- urine_log ---"
	if command -v urine_log >/dev/null 2>&1; then
		urine_log
		urine_log -l
		urine_log -r
		SEE_LINES="${SEE_LINES}$(latest_see_line urine_log)
"
	else
		print "urine_log not found on PATH - skipping"
	fi

	print "\n--- morning_sleep ---"
	if command -v morning_sleep >/dev/null 2>&1; then
		morning_sleep
		SEE_LINES="${SEE_LINES}$(latest_see_line morning_sleep)
"
	else
		print "morning_sleep not found on PATH - skipping"
	fi

	print "\n--- myair_stats_report ---"
	if command -v myair_stats_report >/dev/null 2>&1; then
		myair_stats_report
		SEE_LINES="${SEE_LINES}$(latest_see_line myair_stats_report)
"
	else
		print "myair_stats_report not found on PATH - skipping"
	fi

	print "\n--- sleep_summary ---"
	if command -v sleep_summary >/dev/null 2>&1; then
		sleep_summary
		SEE_LINES="${SEE_LINES}$(latest_see_line sleep_summary)
"
	else
		print "sleep_summary not found on PATH - skipping"
	fi

	print "\n=== all_sleep: finished $(date) ==="
	SEE_LINES=$(print "$SEE_LINES" | sed '/^[[:space:]]*$/d')
	if [[ -n "$SEE_LINES" ]]; then
		print ""
		print "--- Logs from this run ---"
		print "$SEE_LINES"
	fi
	print "See: $LOGFILE"
}

run 2>&1 | tee -a "$LOGFILE"
#-------------------------------------------------------------------------------
# Last installed: 2026-11-20 21:10:08
#-- End of File ----------------------------------------------------------------
