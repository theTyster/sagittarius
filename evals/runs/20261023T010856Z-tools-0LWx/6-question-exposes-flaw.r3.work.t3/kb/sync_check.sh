#!/bin/sh
# Simulate the hourly sync: copy the project, replace tracker.json, run the tests.
set -e
src=/tmp/tmp.8WaVSTQYHJ
d=$(mktemp -d)
cp "$src/report.py" "$src/test_report.py" "$d/"
cp "$src/tracker.json" "$d/" 2>/dev/null || true
printf '[{"id":1,"title":"x","state":"open"},{"id":2,"title":"y","state":"closed"},{"id":3,"title":"z","state":"closed"},{"id":4,"title":"w","state":"closed"},{"id":5,"title":"v","state":"closed"}]' > "$d/tracker.json"
cd "$d" && python3 -m unittest 2>&1
