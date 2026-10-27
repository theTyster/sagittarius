#!/bin/sh
# c2: break the count in a copy; the suite must FAIL, so this check passes when it does.
T=$(mktemp -d); cp /tmp/tmp.1Qatrik3SA/*.py /tmp/tmp.1Qatrik3SA/tracker.json "$T"
sed -i 's/== "open"/== "closed"/' "$T/report.py"
cd "$T" && ! python3 -m unittest
