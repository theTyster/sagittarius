#!/bin/sh
# Simulates the hourly sync: rewrites tracker.json with a different open count, runs the suite, restores the file.
cd /tmp/tmp.2d6RcYCfAf || exit 2
cp tracker.json /tmp/tracker.json.bak
printf '[{"id": 1, "title": "a", "state": "open"}, {"id": 2, "title": "b", "state": "open"}]\n' > tracker.json
python -m unittest 2>&1; rc=$?
cp /tmp/tracker.json.bak tracker.json
exit $rc
