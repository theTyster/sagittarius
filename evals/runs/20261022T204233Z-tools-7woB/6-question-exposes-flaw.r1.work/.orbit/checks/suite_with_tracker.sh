#!/bin/sh
# Usage: suite_with_tracker.sh PROJECT_DIR EXPECT(pass|fail) TRACKER_JSON
# Runs the project's test suite in a scratch copy where tracker.json is replaced.
set -u
proj=$1; expect=$2; tracker=$3
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
cp "$proj/report.py" "$proj/test_report.py" "$d/"
printf '%s' "$tracker" > "$d/tracker.json"
(cd "$d" && python3 -m unittest test_report) >"$d/out" 2>&1; rc=$?
tail -3 "$d/out"
if [ "$expect" = pass ]; then [ $rc -eq 0 ]; else [ $rc -ne 0 ]; fi
