#!/bin/sh
# Copy the bench area's questions.json and pipeline.py into the hot-mod area: every session uses them
# on its next prompt. The live files it replaces are kept first in bench/backups/<time>/live-*.
here=$(cd "$(dirname "$0")" && pwd)
keep="$here/backups/$(date +%Y%m%dT%H%M%S)-$$"
mkdir -p "$keep" || exit 1
for f in questions.json pipeline.py; do
  [ -f "$here/../$f" ] && { cp "$here/../$f" "$keep/live-$f" || exit 1; }
done
cp "$here/questions.json" "$here/pipeline.py" "$here/../" || exit 1
echo "live: every session's next prompt uses the bench files"
echo "the old live files are in $keep"
