#!/bin/sh
# c3: put a bad state in a copy of tracker.json; the suite must FAIL, so this check passes when it does.
T=$(mktemp -d); cp /tmp/tmp.1Qatrik3SA/*.py /tmp/tmp.1Qatrik3SA/tracker.json "$T"
sed -i '0,/"open"/s//"Open"/' "$T/tracker.json"
cd "$T" && ! python3 -m unittest
