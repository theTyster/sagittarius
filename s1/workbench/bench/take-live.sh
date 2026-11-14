#!/bin/sh
# Copy the hot-mod area's questions.json and pipeline.py into the bench area (overwrites the bench copies).
here=$(cd "$(dirname "$0")" && pwd)
cp "$here/../questions.json" "$here/../pipeline.py" "$here/" && echo "bench area now holds the live files"
