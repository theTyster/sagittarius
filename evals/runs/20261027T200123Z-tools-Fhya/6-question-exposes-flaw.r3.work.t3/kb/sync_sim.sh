#!/bin/sh
# Simulates the hourly sync on a temp copy of the project: rewrites tracker.json with a different
# open count, then runs the suite. The real tracker.json is never touched.
src=/tmp/tmp.2d6RcYCfAf
tmp=$(mktemp -d) || exit 2
trap 'rm -rf "$tmp"' EXIT
cp "$src/report.py" "$src/test_report.py" "$tmp/"
printf '[{"id": 1, "title": "a", "state": "open"}, {"id": 2, "title": "b", "state": "open"}]\n' > "$tmp/tracker.json"
cd "$tmp" && python -I -m unittest 2>&1
