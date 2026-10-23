#!/bin/sh
# Simulate a sync that renames "state" to "status". Passes only if the suite FAILS.
src=/tmp/tmp.8WaVSTQYHJ
d=$(mktemp -d)
cp "$src/report.py" "$src/test_report.py" "$d/"
printf '[{"id":1,"title":"x","status":"open"}]' > "$d/tracker.json"
cd "$d" && if python3 -m unittest 2>&1; then echo "suite passed on a broken tracker.json"; exit 1; else exit 0; fi
