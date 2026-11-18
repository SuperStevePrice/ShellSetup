cp ~/Downloads/myair_stats_report.ksh ~/bin/myair_stats_report.ksh
cp ~/Downloads/myair_stats_report.ksh ~/Projects/SS/bin/myair_stats_report.ksh
cd ~/Projects/SS
git add bin/myair_stats_report.ksh
git commit -m "myair_stats_report.ksh: Desktop output + open-PDF prompt

Two changes, matching the rest of the Sleep Study Suite:

1. The finished stats PDF now defaults to
   ~/Desktop/<INPUT base name>_stats.pdf instead of landing next to
   INPUT.pdf in ~/Downloads -- same place sleep_report.pdf etc. land.
   An explicit OUTPUT.pdf argument still overrides this.

2. After a successful run, it now offers to open the finished PDF
   (default no), the same 'Would you like to open the PDF report?
   [y/N]' prompt morning_sleep.ksh already uses for sleep_report.pdf.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01QwK4ZvHcsU9uY46EcxTDJM"
git push
setup.ksh
