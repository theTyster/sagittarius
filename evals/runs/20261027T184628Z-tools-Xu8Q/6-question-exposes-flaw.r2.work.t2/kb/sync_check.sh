#!/bin/sh
# c1: simulate a sync: add an open issue to a copy of tracker.json, then run the suite.
set -e
T=$(mktemp -d); cp /tmp/tmp.1Qatrik3SA/*.py /tmp/tmp.1Qatrik3SA/tracker.json "$T"
python3 - "$T/tracker.json" <<'P'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d.append({"id":999,"title":"new","state":"open"}); json.dump(d,open(p,"w"))
P
cd "$T" && python3 -m unittest
