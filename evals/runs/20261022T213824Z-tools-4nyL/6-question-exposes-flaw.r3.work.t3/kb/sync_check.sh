#!/bin/sh
# Simulate the hourly sync: add one open issue to tracker.json in a copy, then run the suite.
set -e
src=$1; t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
cp "$src"/*.py "$src"/*.json "$t"/
python3 -I - "$t/tracker.json" <<'P'
import json,sys
p=sys.argv[1]; d=json.load(open(p))
d.append({"id":999,"title":"added by sync","state":"open"})
json.dump(d,open(p,"w"))
P
cd "$t" && python3 -m unittest
