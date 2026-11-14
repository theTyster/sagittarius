#!/bin/sh
# The tracked calibration cases, asked with this folder's questions.json.
S1=${S1:-$(cd "$(dirname "$0")/.." && pwd)}
exec python3 "$S1/calibrate.py" --questions "$(dirname "$0")/questions.json" "$@"
