#!/bin/sh
# Simulate the hourly sync: rewrite tracker.json with a different open count, run the suite, restore.
cd /tmp/tmp.la73fH38eY || exit 2
cp tracker.json /tmp/tracker.bak
trap 'cp /tmp/tracker.bak tracker.json' EXIT
python -c "
import json
json.dump([{'id':i,'title':'t','state':'open'} for i in range(7)], open('tracker.json','w'))"
python -m unittest 2>&1
