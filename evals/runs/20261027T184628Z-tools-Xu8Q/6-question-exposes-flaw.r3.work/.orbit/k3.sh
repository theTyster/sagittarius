#!/bin/sh
# Pass only if the suite passes on the real file AND fails on a corrupted live tracker.json.
src=$1; t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
(cd "$src" && python -m unittest) >/dev/null 2>&1 || { echo "suite fails on real file"; exit 1; }
rsync -a --exclude .orbit --exclude __pycache__ "$src"/ "$t"/
echo '[{"id": 1, "title": "x"}]' > "$t/tracker.json"
if (cd "$t" && python -m unittest) >/dev/null 2>&1; then echo "suite passes on corrupted file"; exit 1; fi
