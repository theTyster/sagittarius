#!/bin/sh
# Simulate the hourly sync: run the project's tests against a copy whose tracker.json changed.
set -e
src="$1"; tmp=$(mktemp -d)
cp "$src/report.py" "$src/test_report.py" "$tmp/"
cat > "$tmp/tracker.json" <<'J'
[
  {"id": 1, "title": "a", "state": "open"},
  {"id": 2, "title": "b", "state": "open"},
  {"id": 3, "title": "c", "state": "open"},
  {"id": 4, "title": "d", "state": "open"},
  {"id": 5, "title": "e", "state": "closed"},
  {"id": 6, "title": "f", "state": "open"},
  {"id": 7, "title": "g", "state": "open"}
]
J
cd "$tmp" && python3 -m unittest
