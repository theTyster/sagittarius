#!/bin/sh
# Copy the project, add an open issue to the live tracker.json (as the sync could), run all tests.
set -e
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
cp -r /tmp/tmp.3mXyuW69Wa/. "$d/" ; rm -rf "$d/kb" "$d/__pycache__"
python3 - "$d/tracker.json" <<'PY'
import json,sys
p=sys.argv[1]; x=json.load(open(p)); x.append({"id":999,"title":"new","state":"open"}); json.dump(x,open(p,"w"))
PY
cd "$d" && python3 -B -m unittest
