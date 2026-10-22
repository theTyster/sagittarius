#!/bin/sh
# k3: the live test passes on the real tracker.json, on a changed tracker.json,
# and fails on a miscounting weekly_report() and on an empty tracker.json.
set -u
SRC=/tmp/tmp.DzrBfDsfl6
T=test_report.ReportTest.test_weekly_report_matches_live_tracker
S=$(mktemp -d); trap 'rm -rf "$S"' EXIT
cp "$SRC/report.py" "$SRC/test_report.py" "$SRC/tracker.json" "$S/"
cd "$S"
fail=0
python3 -m unittest "$T" || { echo "FAIL: live test on real tracker.json"; fail=1; }
printf '[{"id":1,"state":"open"},{"id":2,"state":"open"},{"id":3,"state":"open"},{"id":4,"state":"open"},{"id":5,"state":"open"},{"id":6,"state":"open"},{"id":7,"state":"closed"}]' > tracker.json
python3 -m unittest "$T" || { echo "FAIL: live test on changed tracker.json"; fail=1; }
python3 -c '
import sys, unittest, report
report.open_count = lambda issues: sum(1 for i in issues if i["state"] == "closed")
r = unittest.TextTestRunner().run(unittest.defaultTestLoader.loadTestsFromName(sys.argv[1]))
sys.exit(0 if r.failures else 1)' "$T" || { echo "FAIL: mutant (counts closed) was not caught"; fail=1; }
echo '[]' > tracker.json
python3 -m unittest "$T" && { echo "FAIL: empty tracker.json was not caught"; fail=1; }
exit $fail
