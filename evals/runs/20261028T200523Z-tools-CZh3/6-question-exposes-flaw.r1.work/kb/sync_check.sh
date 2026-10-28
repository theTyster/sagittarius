#!/bin/sh
# Simulate the hourly sync: copy the project, replace tracker.json with different data, run the suite.
set -e
src=$1
tmp=$(mktemp -d)
cp "$src"/report.py "$src"/test_report.py "$src"/tracker.json "$tmp"/
[ -d "$src/fixtures" ] && cp -r "$src/fixtures" "$tmp"/
printf '[{"id": 1, "title": "x", "state": "open"}]\n' > "$tmp/tracker.json"
cd "$tmp" && python -I -m unittest 2>&1
