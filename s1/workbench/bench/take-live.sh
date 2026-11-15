#!/bin/sh
# Copy the hot-mod area's questions.json and pipeline.py into the bench area. The bench files it
# replaces are kept first in bench/backups/<time>/bench-*.
here=$(cd "$(dirname "$0")" && pwd)
keep="$here/backups/$(date +%Y%m%dT%H%M%S)-$$"
mkdir -p "$keep" || exit 1
for f in questions.json pipeline.py; do
  [ -f "$here/$f" ] && { cp "$here/$f" "$keep/bench-$f" || exit 1; }
done
cp "$here/../questions.json" "$here/../pipeline.py" "$here/" || exit 1
echo "bench area now holds the live files"
echo "the old bench files are in $keep"
