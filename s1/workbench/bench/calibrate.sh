#!/bin/sh
# The tracked calibration cases, asked with the bench area's questions.json.
here=$(cd "$(dirname "$0")" && pwd)
S1=${S1:-$(cd "$here/../.." && pwd)}
exec python3 "$S1/calibrate.py" --questions "$here/questions.json" "$@"
