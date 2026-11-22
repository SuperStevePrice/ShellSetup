#!/usr/bin/env python3
"""
bin_usage_report.py - build ~/Documents/bin_usage.txt, a quick reference of
every executable in ~/bin (description, usage, notes per file).

Usage:
    bin_usage_report.py      (normally run via bin_usage_report.ksh)

Descriptions are hand-written in the e(...) entries below. Usage text is
copied from each script's own USAGE header when it has one. A new ~/bin
file with no e(...) entry stops the run and is listed, so add one.
"""
import os, textwrap

BIN = os.path.expanduser("~/bin")
OUT = os.path.expanduser("~/Documents/bin_usage.txt")
SEP = "-" * 80

# name -> (summary, usage lines, notes)
D = {}
def e(name, summary, usage=(), notes=""):
    D[name] = (summary, list(usage), notes)

e("_speak_impl.sh",
  "Shared implementation behind speak.ksh and speak.sh. Reads text aloud "
  "with the system text-to-speech (macOS 'say', Linux 'espeak-ng') or "
  "saves it to an audio file.",
  ["Not run directly; sourced by speak.ksh / speak.sh (see 'speak')."],
  "Holds all of speak's logic so ksh and bash wrappers never drift apart.")
e("_speak_impl.sh.bak.20261003_124535",
  "Backup copy (2026-10-03) of an older _speak_impl.sh, the shared "
  "speak implementation.",
  [], "Old backup; not used by anything. Safe to archive or delete.")
e("add_mp3_from_text.ksh",
  "Generates MP3s from .txt files (poems, songs, prayers...) via "
  "ElevenLabs. Prompts once per file for a voice and remembers it in "
  "voices.txt. Copies results to Downloads, MyAudio and iCloud MyAudio, "
  "then moves the source .txt into english/ or german/ so it is never "
  "processed twice. Asks before overwriting an existing MP3.",
  ["1. Drop .txt files into ~/Downloads/add_txt",
   "2. add_mp3_from_text.ksh"],
  "Replaces the old one-off add_*.ksh scripts.")
e("AddToShell.ksh",
  "Lists programs in ~/bin that are not yet in ~/Projects/ShellSetup/prep "
  "(candidates to add to ShellSetup). Skips symlinks.",
  ["AddToShell.ksh"])
e("Ave.py",
  "Reads the Hail Mary aloud with macOS voices in English, German and "
  "Italian.",
  ["Ave.py                    list languages and speakers (no audio)",
   "Ave.py --voice V --language L [--rate R]",
   "Ave.py --all [--language L] [--voice V] [--rate R]"])
e("b43_sleep_hook.ksh",
  "Installs or removes a systemd sleep hook that unloads the Broadcom b43 "
  "Wi-Fi driver before suspend and reloads it on wake, so the 2011 MacBook "
  "Pro (Linux) keeps Wi-Fi, Tailscale, ssh and syncAll after sleep.",
  ["b43_sleep_hook.ksh            install",
   "b43_sleep_hook.ksh --remove   uninstall",
   "b43_sleep_hook.ksh --status   show whether installed"],
  "Linux only; uses sudo. Log: journalctl -t b43-sleep-hook --since today")
e("backup_zip_purge.ksh",
  "Zips everything in a folder (default ~/Downloads/backup) into a new "
  "timestamped zip, skipping existing zips, then (after confirmation) "
  "deletes everything at the top level except .zip files.",
  ["backup_zip_purge.ksh [-i DIR] [-y] [-s] [-h]",
   "  -i DIR  folder to zip/clean   -y  no confirmation",
   "  -s      Spanish messages"])
e("bad_chars.py",
  "Reports non-ASCII and control characters (with position and code "
  "point) in a UTF-8 text file.",
  ["bad_chars.py <inputfile>"])
e("bless_album.ksh",
  "Album version of bless_track: for every enhanced track in NEW_DIR, "
  "finds the matching original (by filename stem) in one or more folders "
  "and replaces its AUDIO while keeping tags and artwork. Backs up each "
  "original first.",
  ["bless_album.ksh [-s] NEW_DIR ORIGINAL_DIR [ORIGINAL_DIR2 ...]"],
  "-s = Spanish messages. Originals may be .m4a or .mp3.")
e("bless_track.ksh",
  "Replaces the audio inside an existing, fully tagged MP3 with new audio "
  "(e.g. a Demucs/mixdown_stems version), keeping tags and artwork. "
  "Overwrites in place so Apple Music keeps lyrics, play counts and "
  "playlists. Original saved as '<name> (original backup).mp3'.",
  ["bless_track.ksh [-s] NEW_AUDIO ORIGINAL_MP3"])
e("boot.ksh",
  "Forces an immediate reboot of the Mac (sudo shutdown -r now) after a "
  "y/n confirmation.",
  ["boot.ksh"])
e("bsky_thread.py",
  "Posts a long text file to Bluesky as a reply-chained thread. Dry run "
  "(preview) unless --post is given.",
  ["bsky_thread.py <textfile> [--post]"],
  "Credentials in ~/.bsky_config (BSKY_HANDLE, BSKY_APP_PASSWORD).")
e("build_german_vocab.py",
  "Data + builder that regenerates german_vocabulary_by_domain.xlsx (and "
  "the german_vocab_drill.html quiz) from the vocabulary data inside this "
  "file.",
  ["build_german_vocab.py       (writes ./german_vocabulary_by_domain.xlsx)",
   "build_german_vocab.py /dir/out.xlsx",
   "VOCAB_OUT_DIR=~/Documents build_german_vocab.py"],
  "Requires python3 + openpyxl. Normally run via german-vocab.ksh.")
e("bin_usage_report.py",
  "Builds ~/Documents/bin_usage.txt: one block per executable in ~/bin with "
  "Description, Usage (copied from the script's own USAGE header when "
  "present) and Notes.",
  ["bin_usage_report.py   (normally via bin_usage_report.ksh)"],
  "Descriptions are hand-written e(...) entries in this file; a new ~/bin "
  "file without one stops the run and is listed.")
e("bin_usage_report.ksh",
  "Wrapper for bin_usage_report.py: regenerates ~/Documents/bin_usage.txt.",
  ["bin_usage_report"])
e("bump_volume.ksh",
  "Applies a simple volume multiplier to an MP3 (e.g. 1.03 = +3%), "
  "writing a new file and keeping ID3 tags.",
  ["bump_volume.ksh -i IN.mp3 -g MULT [-o OUT.mp3] [-p] [-s]",
   "  -p play result   -s Spanish messages"],
  "Requires ffmpeg. Default output: INPUT_bumped.mp3")
e("check_txt_encoding.ksh",
  "Scans .txt files for non-UTF-8 encoding (common cause of Calibre "
  "importing a blank file). Optionally converts them to UTF-8, saving a "
  ".bak first.",
  ["check_txt_encoding.ksh [dir]          report only (default ~/Documents)",
   "check_txt_encoding.ksh [dir] -fix     report and convert"])
e("check_vnc.ksh",
  "Checks whether VNC (port 5900) is reachable on each Tailscale host.",
  ["check_vnc.ksh [-s]      -s = Spanish output"],
  "Host IPs are hard-coded (as of Oct 2026).")
e("check_vnc_remote.ksh",
  "SSHes into the Linux Tailscale hosts and reports VNC processes, "
  "binaries, systemd units and any port-5900 listener.",
  ["check_vnc_remote.ksh [-s]      -s = Spanish output"])
e("clean_nocturia_pilot_error.ksh",
  "One-off: removes the two test rows logged with no amount on the night "
  "of 2026-11-17 (02:08 and 03:23) from ~/.nocturia_log.csv. Backs the "
  "file up first and writes nothing unless exactly 2 rows match.",
  ["clean_nocturia_pilot_error.ksh"],
  "Hardcoded on purpose; other amount-less rows are left alone.")
e("clean_text.py",
  "Replaces U+2028/U+2029 (line/paragraph separator) characters in a text "
  "file with plain newlines.",
  ["clean_text.py <inputfile> <outputfile>"])
e("clone.sh",
  "Notes/script (written with ChatGPT) for cloning the SATA HD of a 2011 "
  "MacBook Pro running Elementary OS to an SSD using ddrescue.",
  ["clone.sh"],
  "Header holds step-by-step notes (install gddrescue, lsblk, etc.).")
e("clone_safari_slideshow.sh",
  "Clones Safari settings and the slide-show folder from the MacBook to "
  "the iMac over SSH. Backs up the iMac's Safari folder, plist and slide "
  "show first, pausing for verification at each step.",
  ["clone_safari_slideshow.sh     (run on the MacBook)"])
e("clone_safari.sh.no-slide-show.sh",
  "Older Safari clone (MacBook -> iMac) without the slide-show folder. "
  "Moves the iMac's Safari folder and plist into a timestamped backup on "
  "its Desktop, then copies over the MacBook's.",
  ["clone_safari.sh.no-slide-show.sh"])
e("colors",
  "Not a program: a list of xterm background/foreground color pairs "
  "(CadetBlue/black, tan/black, ...).",
  [], "Data file with execute bit set.")
e("commit_pending_changes.ksh",
  "One-off: commits specific pending changes in the SS repo (renamed "
  "hostnames, speak-loop fix, aliases) and untracks .DS_Store, adding it "
  "to .gitignore.",
  ["commit_pending_changes.ksh [-s]     -s = Spanish messages"],
  "One-off script; likely obsolete.")
e("compat_perl.ksh",
  "Searches the system for perl installations that have Perl/Tk and runs "
  "xt.pl with them as a compatibility test.",
  ["compat_perl.ksh"])
e("compress_image.ksh",
  "Resizes/recompresses images to reduce file size using ImageMagick, or "
  "macOS 'sips' if ImageMagick is absent.",
  ["compress_image.ksh [-w WIDTH] [-q QUALITY] [-o DIR] [-s|-g|-f] file...",
   "  -w max width (1600)  -q JPEG quality (80)  -o output dir",
   "  -s/-g/-f Spanish/German/French messages"])
e("create_tmp_X11-unix.ksh",
  "Creates /tmp/.X11-unix (if missing) and sets mode 1777, for X11.",
  ["create_tmp_X11-unix.ksh      (call from macOS login scripts)"])
e("d.ksh",
  "No header. A parse_args() function (-d/--debug, -h/--help) - a copy or "
  "draft of parse_args.ksh.",
  [], "Appears to be a scratch file.")
e("dbg.ksh",
  "Library: provides a ksh function dbg() that prints and logs DEBUG "
  "messages, prefixed 'DEBUG: line:'.",
  ["source dbg.ksh", "dbg \"$msg\""])
e("del_inet6.ksh",
  "Deletes the IPv6 default routes on utun0-utun3 (sudo route delete).",
  ["del_inet6.ksh"], "No header comments.")
e("demucs_batch.ksh",
  "Batch-runs Demucs AI stem separation on audio files or a whole folder, "
  "producing per-track stems (vocals/drums/bass/other, or vocals + "
  "instrumental) for GarageBand.",
  ["demucs_batch.ksh [-s] [-2] [-o OUTDIR] file1.mp3 [file2 ...]",
   "demucs_batch.ksh [-s] [-2] [-o OUTDIR] -d SOURCE_DIR",
   "  -2 two-stem split   -o output (default ~/Desktop/stems)"],
  "Requires: pip3 install -U demucs")
e("deploy-nopasswd.ksh",
  "Run on the Mac: copies nopasswd-apt-update.ksh to each Linux host "
  "(found via tss) and runs it there to grant passwordless sudo for apt.",
  ["deploy-nopasswd.ksh"],
  "Prompts once per host for the sudo password.")
e("diff_bin_vs_project.ksh",
  "Compares every file in ~/Projects/SS/bin against its installed "
  "counterpart in ~/bin, ignoring the last 3 lines of the installed copy "
  "(the 'Last installed' trailer setup.ksh appends). Reports differences "
  "per file and a one-line summary at the end.",
  ["diff_bin_vs_project.ksh"],
  "Run before install-bin-files.ksh / git_bin.ksh to confirm what's "
  "installed matches the project source. Logs to ~/logs.")
e("diff_projects.ksh",
  "Runs diff on all files between two project folders.",
  ["diff_projects.ksh /path/to/old_project /path/to/new_project"])
e("disable_capslock.ksh",
  "Disables Caps Lock system-wide at the HID level (hidutil) and installs "
  "a LaunchAgent so it re-applies on every login.",
  ["disable_capslock.ksh"],
  "Logs to ~/logs. To undo: unload/remove "
  "~/Library/LaunchAgents/com.steve.disablecapslock.plist and run "
  "hidutil property --set '{\"UserKeyMapping\":[]}'")
e("down_utun.ksh",
  "Brings down every active utun network interface (sudo ifconfig down), "
  "then checks routes.",
  ["down_utun.ksh"])
e("eleven_tts_batch.ksh",
  "Batch-converts every .txt in a folder to .mp3 with the ElevenLabs TTS "
  "API. Long files are split into numbered parts on paragraph/line "
  "boundaries.",
  ["eleven_tts_batch.ksh -l                    list voices and IDs",
   "eleven_tts_batch.ksh -v VOICE_ID [-i IN] [-o OUT] [-m MODEL] [-c LIMIT] [-s]",
   "  -k KEY overrides $ELEVENLABS_API_KEY",
   "  -i default ~/Documents/elevenlabsUploads"],
  "Requires ELEVENLABS_API_KEY, curl, python3.")
e("encrypt_thumb.sh",
  "Erases an external USB thumb drive (default /dev/disk6) as APFS and "
  "starts APFS encryption on it.",
  ["encrypt_thumb.sh"],
  "DESTRUCTIVE. Edit DISK and VOLUME_NAME in the script first. Checks the "
  "disk is external and removable.")
e("extract_emails.ksh",
  "Extracts email addresses from 'Name <email@domain>' strings and prints "
  "them space-separated (or one per line).",
  ["extract_emails.ksh [-s] [-m] \"string\"",
   "echo \"string\" | extract_emails.ksh [-s] [-m]",
   "  -m one per line   -s Spanish messages"],
  "Always quote the string (it contains < and >).")
e("find_audio.ksh",
  "Finds audio files only in places you would have made them: Documents "
  "(incl. SFP_backup_*), Downloads, Desktop. Skips app libraries and "
  "hidden/tool dirs.",
  ["find_audio.ksh [-d DIR]... [-e EXT] [-s]",
   "  -d extra dir (repeatable)  -e one extension  -s Spanish"])
e("find_images.ksh",
  "Finds image files (jpg, png, gif, heic, webp, ...) in Documents "
  "(incl. SFP_backup_*), Downloads and Desktop only. Asks each time "
  "whether to also search the iCloud 'Gallery' folder.",
  ["find_images.ksh [-d DIR]... [-e EXT] [-s]",
   "find_images.ksh | grep -i sheridan"])
e("find_it.ksh",
  "Wrapper for find: start path, name pattern, repeatable exclude "
  "patterns, optional output file. Bare words become *word*; stderr is "
  "discarded.",
  ["find_it.ksh -p path -f pattern [-e exclude ...] [-o outfile]",
   "e.g. find_it.ksh -p ~ -f xxsls -e Library -e Container"])
e("finder.ksh",
  "Runs 'find / -name' for Tk.pm, perl and perl.h and prints results.",
  ["finder.ksh"], "No header; old Perl/Tk debugging helper.")
e("fix_bookmarks.py",
  "Restructures a Netscape bookmarks.html (Safari export) so no folder "
  "mixes loose links with subfolders - works around Opera/Chromium "
  "importers dropping loose links. Verifies link counts match.",
  ["fix_bookmarks.py Bookmarks.html [--out FILE]"],
  "Default output: Bookmarks_fixed.html")
e("fix-vm-xprofile.sh",
  "Overwrites a broken ~/.xprofile in the Elementary OS VirtualBox VM "
  "(via ssh -p 2222) with a clean template: display mode, terminal font, "
  "VBoxClient.",
  ["fix-vm-xprofile.sh"])
e("fix-xprofile.sh",
  "Patches ~/.xprofile in the VM so GUI commands run only when $DISPLAY "
  "is set.",
  ["fix-xprofile.sh"])
e("font_list.txt",
  "Not a program: font list data file used by good_fonts.sh / "
  "font_selector.py (currently mostly 'Last installed' footers).",
  [], "Data file with execute bit set.")
e("font_selector.py",
  "Tk GUI: scrollable pick list of fonts from font_list.txt with a sample "
  "preview; Submit returns the font, Cancel returns None.",
  ["font_selector.py                standalone",
   "import font_selector            as a module"])
e("force_down.ksh",
  "Forces an immediate shutdown of the Mac (sudo shutdown -h now) after "
  "y/n confirmation.",
  ["force_down.ksh   (also 'down', 'force_down')"])
e("german_test.ksh",
  "Opens the German vocabulary drill/quiz (german_vocab_drill.html) in "
  "the default browser, building it via german-vocab.ksh if missing.",
  ["german_test.ksh [file]    default ~/Documents/german_vocab_drill.html"])
e("german_vocabulary.ksh",
  "Opens the German vocabulary workbook: the .numbers copy on macOS if one "
  "exists, else the .xlsx (xdg-open on Linux). Builds it if missing.",
  ["german_vocabulary.ksh [file]"])
e("german-vocab.ksh",
  "Rebuilds german_vocabulary_by_domain.xlsx and german_vocab_drill.html "
  "from build_german_vocab.py, only if the source is newer.",
  ["german-vocab.ksh                       outputs to ~/Documents ($VOCAB_OUT_DIR)",
   "german-vocab.ksh out.xlsx out.html"],
  "Requires python3 + openpyxl.")
e("get_ip.ksh",
  "Shows the OS, host and first non-loopback IP address (Linux or macOS).",
  ["get_ip.ksh"])
e("getraenke.sh",
  "Small interactive German drinks ('Getraenke') ordering prompt, compiled "
  "to bash from Amber (amber-lang.com).",
  ["getraenke.sh"], "Generated code; no descriptive header.")
e("git_bin.ksh",
  "Installs scripts into ~/bin and the SS repo's bin/, then commits and "
  "pushes them. Files found in ~/Downloads are moved to ~/bin first.",
  ["git_bin.ksh \"commit message\" file.ksh [file.ksh ...]"],
  "Afterwards run setup.ksh, then syncAll. Replaces git_tmutil.ksh etc.")
e("git_clone.ksh",
  "Clones one of SuperStevePrice's GitHub repositories to this machine.",
  ["git_clone.ksh repository"])
e("git_config.ksh",
  "Sets git user name, email and editor.",
  ["git_config.ksh [user email]"])
e("git_mail.ksh",
  "Sets git user name, email and editor (same as git_config.ksh).",
  ["git_mail.ksh [user email]"])
e("git_merge.ksh",
  "Merges a branch into main for a repository.",
  ["git_merge.ksh git_repository branch_name"])
e("git_new.ksh",
  "Creates a new repository on GitHub (user SuperStevePrice).",
  ["git_new.ksh repository"])
e("git_pull.ksh",
  "Pulls changes for a project in ~/Projects; prompts for the repo name.",
  ["git_pull.ksh"])
e("git_push.ksh",
  "Adds, commits and pushes a project in ~/Projects; prompts for repo "
  "name and commit message.",
  ["git_push.ksh"])
e("git_stat_all.ksh",
  "Runs 'git status' in ~/Projects/SS on each machine (macbookprom1, "
  "imaclinux, macbookprolinux, imacintel) via ssh.",
  ["git_stat_all.ksh"])
e("git_tmutil.ksh",
  "One-off: copies tmutil.ksh and tcc_who.ksh into the SS repo and "
  "commits/pushes them.",
  ["git_tmutil.ksh"], "Superseded by git_bin.ksh.")
e("good_fonts.sh",
  "Opens xterm windows in various fonts/sizes and asks you to accept or "
  "reject each; accepted ones are saved.",
  ["good_fonts.sh"],
  "Input ~/Documents/font_list.txt, output ~/Documents/good_fonts.txt")
e("health_sleep.ksh",
  "Wrapper for health_sleep.py: summarizes Apple Health (Watch) sleep "
  "data per night. Logs each run to ~/logs/sleep_TIMESTAMP.log and prints "
  "it.",
  ["health_sleep.ksh export.xml|export.zip [-n nights] [-d YYYY-MM-DD]",
   "    [-c out.csv] [--since YYYY-MM-DD] [--include-naps] ..."])
e("health_sleep.py",
  "Extracts Apple Health sleep records from export.xml/zip and summarizes "
  "them per night; joins the sleep-drug log and stores into "
  "~/sleep_study.db.",
  ["health_sleep.py export.zip [-n 7] [-d DATE] [-c out.csv] [--since DATE]",
   "    [--include-naps] [--night-start H] [--night-end H]",
   "    [--drug-log F|--no-drug-log] [--db F|--no-db]"])
e("hosts_test.ksh",
  "Runs ssh against each IP listed in /etc/hosts as a connectivity test.",
  ["hosts_test.ksh"])
e("install-bin-files.ksh",
  "Copies files from the current directory into ~/Projects/SS/bin, "
  "installs via setup.ksh, commits/pushes, and verifies each is really "
  "tracked by git. Companion to remove-bin-files.ksh.",
  ["install-bin-files.ksh file1 [file2 ...]   (run where the files are)"])
e("install-elementary.sh",
  "Installs an Elementary-OS-like (Pantheon) desktop on Ubuntu ARM64 in "
  "an M1 Mac VirtualBox VM: desktop, LightDM, Plank.",
  ["install-elementary.sh   (inside the VM)"])
e("install-vb-guest.sh",
  "Installs VirtualBox Guest Additions on Elementary OS (M1 VirtualBox) "
  "from the mounted ISO, then reboots.",
  ["install-vb-guest.sh   (inside the VM)"])
e("installed.ksh",
  "Shows the 'Last installed' footer line from a given file.",
  ["installed.ksh file"])
e("is_leap_year.c",
  "C source: is_leap_year(int year) function, linked by test_year and "
  "test_a_year.",
  [], "Source file, not a program. Build with Makefile.")
e("is_leap_year.o",
  "Compiled object of is_leap_year.c.", [], "Build artifact (make clean).")
e("is_project.ksh",
  "Checks whether ~/Projects/<name> is a git repo (has .git).",
  ["is_project.ksh [-s|-g] <ProjectName>    -s Spanish, -g German"])
e("launch_threads.py",
  "Posts a text file to Bluesky and Mastodon (and optionally Threads); "
  "always prints LinkedIn-formatted text for copy/paste. Dry run unless "
  "--post.",
  ["launch_threads.py <textfile> [--post]",
   "    [--threads manual|auto] [--skip PLATFORM] [--only PLATFORM]"],
  "Uses ~/.bsky_config, ~/.masto_config, ~/.threads_config. "
  "Log: ~/logs/launch_threads.log")
e("linkedin_thread.py",
  "Posts a text file as one LinkedIn post (max 3,000 chars), moving URLs "
  "to the end. Dry run unless --post.",
  ["linkedin_thread.py <textfile> [--post]"],
  "Token in ~/.linkedin_config (expires every 60 days).")
e("list-brew-mods.ksh",
  "Lists installed Perl modules (ExtUtils::Installed) for the current "
  "perl into ~/Documents/brew-mods.log.<timestamp>.",
  ["list-brew-mods.ksh"])
e("make_bookmarklet_icons.py",
  "Builds a bookmarks.html that gives the BS (Bluesky) and FB (Facebook) "
  "bookmarklets custom icons, for import into Chrome/Edge/Opera.",
  ["make_bookmarklet_icons.py bluesky_icon.png facebook_icon.png [--out F]"],
  "Chromium only; Safari can't do this.")
e("Makefile",
  "Makefile for the leap-year C examples: builds test_year and "
  "test_a_year from the .c files.",
  ["make        build", "make clean  remove binaries and .o files"])
e("masto_thread.py",
  "Posts a long text file to Mastodon as a reply-chained thread; supports "
  "inline images via ![alt](/path.jpg). Dry run unless --post.",
  ["masto_thread.py <textfile> [--post]"],
  "Credentials in ~/.masto_config (MASTO_INSTANCE, MASTO_ACCESS_TOKEN).")
e("match_loudness.ksh",
  "Normalizes an MP3 to match the perceived loudness (EBU R128, ffmpeg "
  "two-pass loudnorm) of a reference MP3. Writes a new file, keeps tags.",
  ["match_loudness.ksh -r REF.mp3 -i IN.mp3 [-o OUT.mp3] [-p] [-s]"],
  "Default output: INPUT_matched.mp3")
e("match_loudness_auto.ksh",
  "Wrapper for match_loudness.ksh that finds files by name pattern: the "
  "reference in Apple Music's folder (default 'Ozymandias'), the target "
  "as the newest match in SFP_backup_* or ~/Downloads.",
  ["match_loudness_auto.ksh -t TARGET_PATTERN [-r REF_PATTERN] [-p] [-s]"])
e("mixdown_stems.ksh",
  "Mixes a Demucs stems folder (vocals/drums/bass/other.wav) into a "
  "pseudo-stereo WAV (+MP3) with ffmpeg to compare with the original.",
  ["mixdown_stems.ksh [-s] [-r] [-w] [-o OUTFILE] STEMS_DIR",
   "  -r add reverb   -w WAV only (no MP3)"])
e("morning_sleep.ksh",
  "Morning sleep-study routine: confirms nightly meds and as-needed "
  "items, takes notes, logs them, runs health_sleep on the Watch export, "
  "then shows the combined database report (sleep + drugs + nocturia).",
  ["morning_sleep.ksh [-f export.zip|export.xml]"],
  "Default export: ./export.zip, then ~/Downloads/export.zip")
e("my_machine.ksh",
  "Prints the machine's hostname.", ["my_machine.ksh"])
e("myair_stats_report.ksh",
  "Wrapper for myair_stats_report.py. Renames ResMed's 'myAir-Steve "
  "Price.pdf' download to a space-free name, then builds a numbers-only "
  "stats PDF plus an xlsx numbers report, each with its own open prompt.",
  ["myair_stats_report.ksh [-s] [INPUT.pdf [OUTPUT.pdf [OUTPUT.xlsx]]]"],
  "Default output: ~/Desktop/myAir-Steve-Price_stats.pdf and .xlsx")
e("myair_stats_report.py",
  "Turns a ResMed myAir 'Sleep therapy report' PDF into a plain tables-"
  "only PDF (usage, AHI, leak, days-used per date window), plus the same "
  "data as an xlsx. No charts, no recomputation.",
  ["myair_stats_report.py INPUT.pdf [OUTPUT.pdf [OUTPUT.xlsx]]"],
  "Requires pdfplumber, reportlab, openpyxl.")
e("names.ksh",
  "Demo of basename/dirname on a hard-coded path.", ["names.ksh"],
  "Example snippet; no header.")
e("nocturia_log.ksh",
  "'Pissy Night' log wrapper for nocturia_log.py: records nighttime "
  "urination time and amount (oz) for the sleep study.",
  ["nocturia_log.ksh HH:MM [AMOUNT_OZ] [\"notes\"] [-d YYYY-MM-DD]",
   "nocturia_log.ksh -l [-n N] [--night YYYY-MM-DD]     list"])
e("nocturia_log.py",
  "Back end for nocturia_log.ksh; stores entries in ~/.nocturia_log.csv "
  "grouped by night.",
  ["see nocturia_log.ksh"])
e("nopasswd-apt-update.ksh",
  "Run once per Linux host: adds a sudoers rule allowing passwordless "
  "apt update / full-upgrade / --fix-broken / autoremove only.",
  ["(normally pushed and run by deploy-nopasswd.ksh)"])
e("NumText.am",
  "Amber language source showing Text-to-Num conversion.",
  ["amber NumText.am"], "Source for NumText.sh.")
e("NumText.sh",
  "Bash compiled from NumText.am (Amber): demonstrates converting text "
  "to a number with parse().",
  ["NumText.sh"])
e("os.ksh",
  "Prints the operating system name and version.", ["os.ksh"])
e("p.ksh",
  "Sources ~/.profile.", ["p.ksh"],
  "Running it as a subprocess has no effect on your shell; source it.")
e("pack_for_dwight.ksh",
  "Zips the enhanced 'Your Kingdom Come: Songs of Worship' album plus the "
  "'If It Be Your Will' single to send to Dwight, skipping '(original "
  "backup)' files.",
  ["pack_for_dwight.ksh [-s] [-o OUTDIR] ALBUM_DIR SINGLE_FILE"],
  "Output: OUTDIR/Hymns_of_Worship_for_Dwight_<timestamp>.zip")
e("parse_args.ksh",
  "Library: provides parse_args() and show_usage() and sets $debug "
  "(-d/--debug).",
  ["source ~/bin/parse_args.ksh"])
e("password_gen.py",
  "Generates passwords from German, French, Spanish, English, Swedish and "
  "Yiddish words joined by special characters, ending in a date stamp.",
  ["password_gen.py"])
e("paths.ksh",
  "Prints the full paths of cc, gcc, bash, sh, ksh, java, perl, python "
  "and xterm.", ["paths.ksh"])
e("paths.pl",
  "Perl version of paths.ksh: prints paths of ksh, perl, python, xterm.",
  ["paths.pl"])
e("pbc.ksh",
  "Copies a file's contents (or stdin) to the clipboard; wrapper around "
  "pbcopy.",
  ["pbc.ksh file", "pbc.ksh < file", "pbc.ksh -s [file]   Spanish"])
e("pbcopy",
  "Not a program: a saved 'ls -l' listing of some ~/bin files.",
  [], "Likely created by accident (output redirected to 'pbcopy'). It "
  "shadows /usr/bin/pbcopy if ~/bin is first in PATH - consider deleting.")
e("pbcopy_files.ksh",
  "Copies one or more files, each preceded by its name, to the clipboard "
  "(pbcopy / xclip / xsel) for pasting into a Claude chat. Skips missing "
  "or binary files unless -f.",
  ["pbcopy_files.ksh [-f|--force] file1 [file2 ...]"],
  "Log: ~/logs/pbpaste_files.<timestamp>")
e("pbp.ksh",
  "Writes the clipboard to stdout or to a file; wrapper around pbpaste.",
  ["pbp.ksh", "pbp.ksh file", "pbp.ksh -s [file]   Spanish"])
e("pbpaste_script.ksh",
  "Pastes the clipboard to stdout (/usr/bin/pbpaste).",
  ["pbpaste_script.ksh"])
e("per",
  "Ran macOS 'periodic' maintenance.", ["per"],
  "DEPRECATED 2026-04-14: Apple removed 'periodic'. Use mdfind instead of "
  "locate.")
e("playpause.ksh",
  "Plays an audio file with interactive controls: SPACE pause/resume, "
  "q quit. Uses afplay (macOS) or paplay/aplay (Linux).",
  ["playpause.ksh file.m4a"])
e("playpause.ps1",
  "Windows PowerShell version of playpause (SPACE pause/resume, q quit), "
  "using Windows Media Player.",
  [".\\playpause.ps1 file.wav"])
e("playpause.sh",
  "Bash version of playpause.ksh, for Linux without ksh.",
  ["playpause.sh file.m4a"])
e("pray.py",
  "Speaks prayers in many languages and voices (macOS 'say', Linux "
  "espeak-ng). Prayer texts live in prayers/ beside the script.",
  ["pray.py --list",
   "pray.py --prayer P --language L [--voice V] [--rate R]",
   "pray.py --all [--prayer P] [--language L] [--voice V]"])
e("pre-syncall-check.ksh",
  "Read-only check that the SS repo has nothing uncommitted, untracked or "
  "unpushed before you run syncAll.",
  ["pre-syncall-check.ksh"])
e("process_album.ksh",
  "Runs a whole album folder through demucs_batch, then mixdown_stems on "
  "each track, giving a mixdown per song.",
  ["process_album.ksh [-s] [-2] [-r] [-o OUTDIR] ALBUM_DIR"])
e("process_new_poem.ksh",
  "One step for a new poem recording: trims trailing silence, then "
  "loudness-matches to a reference (default Ozymandias), producing a "
  "finished MP3 in FavoritePoems/Recordings/Final.",
  ["process_new_poem.ksh -i RAW_INPUT [-r REF.mp3] [-o OUT.mp3]",
   "    [-t THRESHOLD_DB] [-p] [-s]"])
e("PS1.ksh",
  "Sets the ksh prompt ($PS1) to show host, $PWD and history number.",
  ["source ~/bin/PS1.ksh"])
e("push_file.ksh",
  "Interactive: asks for local and remote folder/filename, then scp's the "
  "file to every machine in ALL_HOSTS except the current one.",
  ["push_file.ksh"], "Edit ALL_HOSTS when your machines change.")
e("push_opera_favorites.ksh",
  "Copies ~/Documents/opera_good_favorites_7_10_26.html to the three "
  "other machines' ~/Documents.",
  ["push_opera_favorites.ksh"])
e("pushInstall.ksh",
  "On each remote host: git pull ShellSetup and install the named "
  "bin/ scripts into ~/bin with a 'Last installed' stamp.",
  ["pushInstall.ksh [script ...]      (default: syncAll)"])
e("readit.sh",
  "Prompts for a macOS voice and a text file, then reads the file aloud "
  "line by line with 'say'.",
  ["readit.sh"])
e("remote_tar.ksh",
  "Creates (-c) or extracts (-x) a .tar.gz and scp's the tarball to the "
  "other servers (never the local one).",
  ["remote_tar.ksh -c|-x <tarball_fullpath>"])
e("remove-bin-files.ksh",
  "Removes named files from the SS repo's bin/, from ~/bin, and their "
  "extension-less symlinks, then commits and pushes.",
  ["remove-bin-files.ksh file1 [file2 ...]"],
  "syncAll won't delete installed copies on other machines; repeat the "
  "rm's there.")
e("run_kingdom_come.ksh",
  "One-off: installs process_album.ksh into SS bin and runs it (2-stem) "
  "on the 'Your Kingdom Come' album.",
  ["run_kingdom_come.ksh [-s]"])
e("run_voice_batch.ksh",
  "Sorts .txt files into english/ and german/, then runs "
  "eleven_tts_batch.ksh once per language with the given voice IDs.",
  ["run_voice_batch.ksh -e EN_VOICE_ID -g DE_VOICE_ID ..."],
  "Needs ELEVENLABS_API_KEY. Copy voice IDs from the ElevenLabs web UI.")
e("safari_backup.ksh",
  "Snapshots Safari settings (~/Library/Safari + plist) to iCloud Drive "
  "safari/Safari-backup-<date>, optionally with an APFS local snapshot.",
  ["safari_backup.ksh [dest_dir]"],
  "Quit Safari first. Log: ~/logs/safari_backup_<date>.log")
e("safari_bookmarks_export.py",
  "Exports Safari bookmarks to an editable JSON file.",
  ["safari_bookmarks_export.py [output.json]"],
  "Default: ~/Safari-bookmarks-YYYYMMDD-HHMMSS.json")
e("safari_bookmarks_import.py",
  "Imports an edited bookmarks JSON back into Safari.",
  ["safari_bookmarks_import.py bookmarks.json"],
  "Run safari_backup.ksh first.")
e("safari_bookmarks_to_html.py",
  "Converts edited Safari bookmarks JSON to Netscape bookmark HTML for "
  "Safari's import.",
  ["safari_bookmarks_to_html.py bookmarks.json [output.html]"])
e("safari_prefs.ksh",
  "Older variant of safari_backup.ksh: snapshots Safari settings to the "
  "iCloud Drive root.",
  ["safari_prefs.ksh [dest_dir]"])
e("safari_restore.ksh",
  "Restores Safari settings from a safari_backup.ksh snapshot; lists "
  "backups and lets you pick one if none given.",
  ["safari_restore.ksh [backup_dir]"], "Quit Safari first.")
e("safari_start.ksh",
  "Starts Safari showing the nature slideshow "
  "(~/Pictures/ChangingImages/start.html).",
  ["safari_start.ksh"])
e("scp_file.ksh",
  "Copies a file to the four Tailscale machines.",
  ["scp_file.ksh file_to_copy"])
e("scp_this.ksh",
  "scp's a file or directory to the same (or a given) path on every other "
  "Tailscale machine (via tss).",
  ["scp_this.ksh source target"],
  "Use a bare relative target to land in each remote home directory.")
e("set_api_key.ksh",
  "Stores an API key (hidden input, not in history) in "
  "~/.secrets/api_keys.ksh and makes .kshrc source it.",
  ["set_api_key [VARNAME]     (default OPENAI_API_KEY)"],
  "Secrets file is not synced; run on each machine.")
e("set_locale.py",
  "Sets the locale; usable standalone or imported by other scripts.",
  ["set_locale.py", "from set_locale import set_locale"])
e("set-perl.ksh",
  "Lists installed perl versions and sets a symlink to the one you pick.",
  ["set-perl.ksh"])
e("set-vm-16in-res.sh",
  "Via ssh, adds xrandr commands to the VM's .xprofile for 2560x1600 "
  "(16\" MacBook Pro) at next login.",
  ["set-vm-16in-res.sh"])
e("set-vm-resolution.sh",
  "Via ssh, sets the VM display to a high resolution with cvt/xrandr now "
  "and saves it to .xprofile.",
  ["set-vm-resolution.sh"])
e("setup_sleep_db.ksh",
  "Wrapper for setup_sleep_db.py: creates/updates the sleep-study SQLite "
  "database and imports logs.",
  ["setup_sleep_db.ksh --import-prescriptions-sql FILE.sql",
   "setup_sleep_db.ksh --import-drug-log FILE",
   "setup_sleep_db.ksh --report [-n N]"])
e("setup_sleep_db.py",
  "Creates/updates ~/sleep_study.db (prescriptions, drug log, nocturia, "
  "sleep), imports logs, prints the nightly report and exports "
  "xlsx/pdf.",
  ["setup_sleep_db.py [--db F] [--import-nocturia CSV]",
   "    [--import-drug-log CSV] [--import-prescriptions-sql SQL]",
   "    [--report [-n 14]] [--export-xlsx [P]] [--export-pdf [P]]",
   "    [--no-export] [--rolling-window N]"],
  "Reports start 2026-11-01 by default.")
e("setup-shared-folder.sh",
  "Inside the VM: mounts the VirtualBox shared folder VMShared at "
  "~/Shared and adds it to /etc/fstab.",
  ["setup-shared-folder.sh"])
e("setup-vm.sh",
  "Via ssh, fully configures the Elementary/Ubuntu VM: safe .xprofile, "
  ".bashrc, VBoxClient startup script.",
  ["setup-vm.sh"])
e("setup-vm-display.sh",
  "Via ssh, appends high-res display, terminal font and VBoxClient "
  "settings to the VM's .xprofile.",
  ["setup-vm-display.sh"])
e("setup-vm-full.sh",
  "Via ssh, configures VM display, terminal font and VBoxClient "
  "(.xprofile + .bashrc).",
  ["setup-vm-full.sh"])
e("sleep_drug_log.ksh",
  "Appends or lists sleep-drug experiment entries in "
  "~/logs/sleep_drug_log.csv (date, drug, melatonin Y/N, notes).",
  ["sleep_drug_log.ksh 2026-11-01 Lunesta Y [\"notes\"]",
   "sleep_drug_log.ksh -l [-n 7]", "  -s Spanish"])
e("sort_voice_files.ksh",
  "Sorts .txt files into german/ and english/ subfolders using a known "
  "list of German filenames. Safe to re-run.",
  ["sort_voice_files.ksh [-i IN_DIR] [-s]"],
  "Default IN_DIR: ~/Documents/elevenLabsUploads")
e("speak.ksh",
  "Reads text aloud (macOS 'say' / Linux espeak-ng) or saves it to audio. "
  "Thin ksh wrapper around _speak_impl.sh.",
  ["speak <textfile|-> [-v voice] [-g|-e|-s|-f [voice]] [-r rate]",
   "      [-o outfile] [-p] [-n] [-c] [-x lang] [-b]",
   "speak -l | -xl | -t | -h",
   "  -g/-e/-s/-f German/English/Spanish/French  -r words/min",
   "  -o save audio  -p print in sync  -x translate  -l list voices"],
  "Bare filenames are looked for in . then ~/Documents. Lines starting "
  "with # are not spoken.")
e("speak.ps1",
  "Windows PowerShell port of speak (System.Speech): reads text aloud or "
  "saves .wav, same flags.",
  ["powershell -ExecutionPolicy Bypass -File speak.ps1 <args>"],
  "Rate uses Windows' -10..10 scale.")
e("speak.sh",
  "Bash wrapper for speak (same as speak.ksh), via _speak_impl.sh.",
  ["speak.sh <textfile> [options]   (see speak.ksh)"])
e("speak-loop.ksh",
  "Runs speak repeatedly on a text file until you quit; passes options "
  "through to speak.",
  ["speak-loop.ksh [-L] [-o outfile] [-s] [speak-options...] file.txt",
   "  -L loop forever (SPACE pause, q quit)",
   "  -o save translated text (needs -x)"])
e("ssh_tss.ksh",
  "Shows Tailscale status as seen from 100.73.104.80 (macbookprolinux).",
  ["ssh_tss.ksh"])
e("ssh-copy-id.ksh",
  "Copies ~/.ssh/id_rsa.pub to every 10.0.0.x machine in /etc/hosts.",
  ["ssh-copy-id.ksh"])
e("syncAllProjects.py",
  "Syncs ~/Projects git repos across all machines: pulls existing repos, "
  "clones missing ones, skips symlinks and *.backup.",
  ["syncAll", "syncAll -p PROJECT [PROJECT ...]"])
e("tcc_who.ksh",
  "Shows which program macOS holds responsible for Full Disk Access in "
  "the current terminal (the path to add in Privacy & Security).",
  ["tcc_who.ksh   (run in the terminal to diagnose)"], "macOS only.")
e("test_a_year",
  "Asks for a year and says whether it's a leap year.",
  ["test_a_year"], "Compiled binary (from test_a_year.c + is_leap_year.c).")
e("test_a_year.c",
  "C source for test_a_year.", [], "Build with Makefile.")
e("test_a_year.o", "Compiled object of test_a_year.c.", [],
  "Build artifact.")
e("test_leap_year",
  "Binary: tests whether 2024 is a leap year.", ["test_leap_year"],
  "Old build; the Makefile now builds this as test_year.")
e("test_leap_year.c",
  "C source: tests 2024 with is_leap_year().", [], "Build with Makefile.")
e("test_leap_year.o", "Compiled object of test_leap_year.c.", [],
  "Build artifact.")
e("test_year",
  "Binary built from test_leap_year.c: reports whether 2024 is a leap "
  "year.", ["test_year"])
e("test.pl",
  "Tiny Perl/Tk test window ('Hello, Tk!' + Quit).", ["test.pl"])
e("threads_manual.py",
  "Formats a text file as a Threads thread (500-char posts, N/T numbering, "
  "URLs moved) for manual copy/paste. No credentials needed.",
  ["threads_manual.py <textfile>"])
e("threads_thread.py",
  "Posts a long text file to Threads as a reply-chained thread via the "
  "Threads API. Dry run unless --post.",
  ["threads_thread.py <textfile> [--post]"],
  "Credentials in ~/.threads_config; tokens last 60 days.")
e("tk.ksh",
  "Tests a list of perl executables and prints a working shebang line for "
  "those that support Tk.",
  ["tk.ksh [-f perl_list_file] [-d|--debug]"],
  "Default list: ~/Documents/perls.txt")
e("tk_perl_tester.ksh",
  "Tests various perl executables for Tk support (used by xt.pl).",
  ["tk_perl_tester.ksh"])
e("tmreport.ksh",
  "Runs a set of Time Machine (tmutil) commands, shows results, logs them "
  "to ~/logs/<HD Name> and copies to the clipboard.",
  ["tmreport.ksh [HD Name]    (default: first TM destination)"],
  "Terminal needs Full Disk Access.")
e("trim_trailing_silence.ksh",
  "Trims silence from the END of an audio file only (ffmpeg "
  "silenceremove).",
  ["trim_trailing_silence.ksh -i IN.m4a [-o OUT.mp3] [-t DB] [-p] [-s]"],
  "Default threshold -35 dB; output INPUT_trimmed.mp3")
e("ts-loop.ksh",
  "Runs a command (default: tailscale status) locally, then on every "
  "Tailscale peer via ssh.",
  ["ts-loop.ksh", "ts-loop.ksh 'command ...'"])
e("tss.ksh",
  "Shows Tailscale status (handles macOS app path vs Linux CLI).",
  ["tss"])
e("txt2epub.ksh",
  "Converts a plain-text poem/document to a minimal EPUB preserving every "
  "line break (bypasses Calibre's TXT importer). First line = title.",
  ["txt2epub.ksh input.txt [output.epub]"])
e("txt2epub_batch.ksh",
  "Runs txt2epub.ksh over many files or a list file.",
  ["txt2epub_batch.ksh file1.txt file2.txt ...",
   "txt2epub_batch.ksh [-d DIR] -l list.txt [extra.txt]",
   "  -y overwrite existing  -n skip existing"],
  "Default dir ~/Documents.")
e("update_myair_stats_report.ksh",
  "One-off: copies myair_stats_report.ksh from ~/Downloads into ~/bin and "
  "the SS repo, commits and pushes it (Desktop output + open-PDF prompt), "
  "then runs setup.ksh.",
  ["update_myair_stats_report.ksh"])
e("update-linux-hosts.ksh",
  "Runs apt update, full-upgrade and autoremove on every Linux host found "
  "via tss, retrying with --fix-broken if needed.",
  ["update-linux-hosts.ksh"],
  "Needs the NOPASSWD rule from deploy-nopasswd.ksh.")
e("WellsFargoFormat.ksh",
  "Converts a Wells Fargo statement PDF into a redacted 80-column text "
  "file and a CSV (Date, Description, Credits, Debits, Balance).",
  ["WellsFargoFormat.ksh [input.pdf]     (default ~/Downloads/statement.pdf)"],
  "Requires pdftotext (poppler).")
e("x",
  "Not a program: saved text notes on California mail-in ballot rules "
  "(2026).", [], "Data file with execute bit set.")
e("xt.ksh",
  "Finds a Tk-capable perl and launches the xt.pl xterm GUI in the "
  "background.", ["xt"])
e("xt.pl",
  "Perl/Tk GUI panel of buttons, fields and checkboxes to create xterm "
  "windows with chosen attributes.",
  ["xt.pl [--debug]   (usually via xt)"])
e("xt.py",
  "Python dashboard for quickly creating xterms; uses xtrc.py.",
  ["xt.py"])
e("xterm_good_fonts.py",
  "Opens xterms using the fonts in ~/Documents/good_fonts.txt with a "
  "range of colors.", ["xterm_good_fonts.py"])
e("xterm_path.py",
  "Finds the full path of xterm (macOS).", ["xterm_path.py"])
e("xterm-examples.ksh",
  "Opens sample xterms in three fonts x two color schemes.",
  ["xterm-examples.ksh"])
e("xterm.pl",
  "Prompts for xterm settings and spawns the window.", ["xterm.pl"])
e("xterm.py",
  "Python: asks for xterm attributes on the command line and spawns the "
  "window (macOS).", ["xterm.py"])
e("xterms.ksh",
  "Opens 3 pairs of xterms (each pair shares a font), six unique colors.",
  ["xterms.ksh"])
e("xtermTk.ksh",
  "Loads .profile and ~/.locale, then launches xtermTk.py in the "
  "background.", ["xtermTk"])
e("xtermTk.py",
  "Python/Tk widget window for launching xterms (macOS).", ["xtermTk.py"])
e("xtpy",
  "Launches ~/bin/xt.py in the background.", ["xtpy"])
e("xtrc",
  "Copy of xtrc.py (helper module for xt.py and .xtrc settings).", [],
  "Identical header to xtrc.py; intended to be imported, not run.")
e("xtrc.py",
  "Helper module for xt.py: handles colors, .xtrc settings and xterm "
  "command data.", ["import xtrc"])
e("xtt.ksh",
  "Loads .profile and runs xterm.pl.", ["xtt"])
e("yt2txt.ksh",
  "Downloads a YouTube video's captions as plain text, named after the "
  "video title.",
  ["yt2txt [-l lang] [-o name] [-d dir] [-u] URL|VIDEO_ID",
   "  -l caption language (en)  -d output dir (~/Documents)",
   "  -u upgrade yt-dlp first"],
  "Never overwrites; adds _2, _3 ...")
e("all_sleep.ksh",
  "Unified sleep-study wrapper: runs nocturnal.ksh, nocturnal_log, "
  "morning_sleep, health_sleep and myair_stats_report in sequence "
  "(nocturnal data first, since morning_sleep cross-references it). "
  "Produces all 3 pairs of reports on the Desktop: sleep_report "
  "(pdf/xlsx), nocturnal (pdf/xlsx) and myAir-Steve-Price_stats "
  "(pdf/xlsx). Each component checks for its own required Downloads "
  "input file and exits with fetch instructions if it's missing, rather "
  "than prompting interactively.",
  ["all_sleep.ksh"],
  "Aliased as 'as' in dots/aliases (SS repo). Run order: nocturnal -> "
  "nocturnal_log -> morning_sleep -> health_sleep -> myair_stats_report.")
e("nocturnal.ksh",
  "Opens vi on a new ~/Downloads/nocturnal_cmds_<timestamp>.ksh file for "
  "pasting the Nocturnal Log web page's ready-to-paste commands copied from "
  "the iPhone (universal clipboard); after save/quit runs the saved file "
  "via ksh to log the entries through nocturnal_log.",
  ["nocturnal.ksh"],
  "Run via ksh, not chmod +x, per Steve's Downloads convention. First step "
  "in the all_sleep.ksh sequence.")
e("nocturnal_log.ksh",
  "'Nocturnal Log' wrapper for nocturnal_log.py (renamed Nov 2026 from "
  "nocturia_log.ksh): records nighttime urination time and amount (oz) for "
  "the sleep study, and (with -r) writes the nocturnal.pdf/.xlsx report "
  "pair to the Desktop.",
  ["nocturnal_log.ksh HH:MM [AMOUNT_OZ] [\"notes\"] [-d YYYY-MM-DD]",
   "nocturnal_log.ksh -l [-n N] [--night YYYY-MM-DD]     list",
   "nocturnal_log.ksh -r                                 write report pair"],
  "Second step in the all_sleep.ksh sequence, after nocturnal.ksh.")
e("nocturnal_log.py",
  "Back end for nocturnal_log.ksh (renamed Nov 2026 from nocturia_log.py); "
  "stores entries in ~/.nocturnal_log.csv grouped by night, and (with "
  "-r/--report) writes nocturnal.pdf/.xlsx to the Desktop.",
  ["see nocturnal_log.ksh"])
e("wispr_dictation_login.ksh",
  "Launches Wispr Flow and clicks File > Start Dictation via System Events "
  "UI automation; installable as a login-time LaunchAgent so dictation "
  "starts automatically at login.",
  ["wispr_dictation_login.ksh"],
  "Companion to wispr_stop_dictation.ksh (quits/relaunches Wispr Flow as an "
  "emergency dictation-off).")
e("clean_last_installed.ksh",
  "Enforces that no file in the project tree carries a stray 'Last "
  "installed:' setup.ksh stamp block (setup.ksh itself excepted): sweeps "
  "stray backup-predeploy snapshot dirs, strips stamp blocks, offers to "
  "rerun setup.ksh, then offers to git add/commit/push ShellSetup and Pray "
  "individually. Also reports (never removes) any unrelated 'Last patched:' "
  "lines.",
  ["clean_last_installed.ksh [-d DIR] [-n|--dry-run] [-y|--yes]",
   "                          [--no-reinstall] [--no-push] [-h|--help]",
   "clean_last_installed.ksh --fix-permissions"],
  "--fix-permissions is a separate one-time repair for files an earlier "
  "version of this script flipped from 755 to 644 via mv instead of cat; "
  "exits immediately, skipping the normal 4 steps.")

import re

SECTION = re.compile(r'^([A-Z][A-Za-z0-9 /()~._-]*:\s*$|[A-Z][A-Z ]{3,}$|\.[A-Z]+$|-{5,}|={5,})')
USAGE = re.compile(r'^usage\b\s*:?', re.I)

def header_lines(path):
    """Return the leading comment/docstring text of a script, markers stripped."""
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            raw = f.read().splitlines()[:150]
    except OSError:
        return []
    out, in_doc, doc_delim = [], False, None
    for i, line in enumerate(raw):
        s = line.rstrip()
        if i == 0 and s.startswith("#!"):
            continue
        if in_doc:
            if doc_delim in s:
                out.append(s.split(doc_delim)[0]); break
            out.append(s); continue
        st = s.strip()
        for d in ('"""', "'''", "<#"):
            if st.startswith(d):
                in_doc, doc_delim = True, ('#>' if d == "<#" else d)
                rest = st[len(d):]
                if doc_delim in rest:
                    out.append(rest.split(doc_delim)[0]); in_doc = False
                else:
                    out.append(rest)
                break
        else:
            if st.startswith("#") or st.startswith("//"):
                out.append(re.sub(r'^\s*(#+|//+) ?', '', s).replace("\t", "    "))
            elif st == "" or st.startswith("# -*-"):
                out.append("")
            elif out and any(o.strip() for o in out):
                # code reached; a docstring may still follow (python)
                if st.startswith(("import", "from")):
                    break
                break
        if in_doc is False and doc_delim and not out[-1:]:
            pass
    return out

def extract_usage(path):
    lines = header_lines(path)
    for i, l in enumerate(lines):
        if USAGE.match(l.strip()):
            break
    else:
        return None
    first = l.strip()
    base = len(l) - len(l.lstrip())
    rest_of_first = USAGE.sub("", first, count=1).strip()
    block = [rest_of_first] if rest_of_first else []
    j = i + 1
    while j < len(lines):
        cur = lines[j]
        st = cur.strip()
        ind = len(cur) - len(cur.lstrip())
        if st and ind <= base and SECTION.match(st):
            if 'option' not in st.lower():
                break
            if block and block[-1].strip():
                block.append("")
        if not st:
            nxt = next((x for x in lines[j+1:] if x.strip()), None)
            if nxt is None or ((len(nxt) - len(nxt.lstrip())) <= base
                               and 'option' not in nxt.lower()):
                break
        block.append(cur.rstrip())
        j += 1
    while block and not block[-1].strip():
        block.pop()
    if not block:
        return None
    # dedent
    ind = min(len(b) - len(b.lstrip()) for b in block if b.strip())
    if block[0] == rest_of_first and rest_of_first:
        others = [len(b) - len(b.lstrip()) for b in block[1:] if b.strip()]
        ind = min(others) if others else 0
        return [block[0]] + [b[ind:] if b.strip() else "" for b in block[1:]]
    return [b[ind:] if b.strip() else "" for b in block]

def wrap(text, indent="  "):
    return textwrap.fill(text, width=79, initial_indent=indent,
                         subsequent_indent=indent)

def fit(line, indent="  "):
    full = indent + line
    if len(full) <= 80:
        return [full]
    lead = len(line) - len(line.lstrip())
    return textwrap.wrap(line.strip(), width=79,
                         initial_indent=indent + " " * lead,
                         subsequent_indent=indent + " " * (lead + 4))

entries, missing, verbatim = [], [], 0
names = sorted(os.listdir(BIN), key=str.lower)
for n in names:
    p = os.path.join(BIN, n)
    if not os.path.isfile(p) or not os.access(p, os.X_OK):
        continue
    # Skip backups: any name containing "bak", or anything that lives
    # (or whose symlink target lives) inside a folder named backup.
    real = os.path.realpath(p)
    if "bak" in n.lower() or "bak" in os.path.basename(real).lower() or \
       any(d.lower() == "backup" for d in os.path.dirname(real).split(os.sep)):
        continue
    src, notes_pre = n, []
    if os.path.islink(p):
        src = os.path.basename(os.readlink(p))
        notes_pre.append(f"Symlink to {src} (same program).")
    if src not in D:
        missing.append(n); continue
    desc, my_usage, notes = D[src]
    usage = extract_usage(os.path.join(BIN, src))
    if usage:
        verbatim += 1
    else:
        usage = my_usage
    note_text = " ".join(notes_pre + ([notes] if notes else []))

    out = [f"File:\t{n}", "", "Description:", wrap(desc)]
    if usage:
        out += ["", "Usage:"]
        for u in usage:
            out += fit(u) if u.strip() else [""]
    if note_text:
        out += ["", "Notes:", wrap(note_text)]
    out.append(SEP)
    entries.append("\n".join(out) + "\n\n\n")

if missing:
    raise SystemExit(f"missing descriptions: {missing}")
with open(OUT, "w") as f:
    f.write("".join(entries))
print(len(entries), "entries;", verbatim, "with usage copied from the script")
#-------------------------------------------------------------------------------
# Last installed: 2026-11-17 09:48:53
#-- End of File ----------------------------------------------------------------
