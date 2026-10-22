#!/bin/sh
# Simulate an hourly sync in a scratch copy, then run the full suite there.
set -e
S=$(mktemp -d)
cp /tmp/tmp.cztAdWr4jr/report.py /tmp/tmp.cztAdWr4jr/test_report.py "$S"/
printf '[{"id":201,"title":"New bug","state":"open"},{"id":202,"title":"Old bug","state":"closed"}]\n' > "$S/tracker.json"
cd "$S"
echo "live report after simulated sync: $(python3 -I -c 'import sys; sys.path.insert(0, "."); from report import weekly_report; print(weekly_report())')"
python3 -m unittest -v
