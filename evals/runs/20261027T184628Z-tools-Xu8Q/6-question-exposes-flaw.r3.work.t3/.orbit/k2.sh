#!/bin/sh
# Simulate a sync: copy sources, change the live tracker.json, run the suite.
set -e
src=$1; t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
rsync -a --exclude .orbit --exclude __pycache__ "$src"/ "$t"/
python - "$t/tracker.json" <<'P'
import json,sys
p=sys.argv[1]; d=json.load(open(p))
d.append({"id":999,"title":"new","state":"open"})
json.dump(d,open(p,"w"))
P
cd "$t" && python -m unittest
