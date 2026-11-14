#!/bin/sh
# Copy the bench area's questions.json and pipeline.py into the hot-mod area: every session uses them
# on its next prompt.
here=$(cd "$(dirname "$0")" && pwd)
cp "$here/questions.json" "$here/pipeline.py" "$here/../" && echo "live: every session's next prompt uses the bench files"
