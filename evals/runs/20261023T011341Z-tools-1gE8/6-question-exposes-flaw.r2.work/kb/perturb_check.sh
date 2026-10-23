#!/bin/sh
# Check for c2: the suite must still pass after the sync job rewrites tracker.json.
# Replaces tracker.json with a different export, runs the suite, and always restores it.
cd /tmp/tmp.t449TQZTbC || exit 2
cp tracker.json /tmp/tracker.json.bak || exit 2
printf '[{"id": 1, "title": "x", "state": "open"}]\n' > tracker.json
python3 -m unittest
rc=$?
cp /tmp/tracker.json.bak tracker.json && rm /tmp/tracker.json.bak
exit $rc
