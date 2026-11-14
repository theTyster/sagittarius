#!/bin/sh
# The System 1 workbench. Edit questions.json here, then run ./bench.sh [options].
S1=${S1:-$(cd "$(dirname "$0")/.." && pwd)}
exec python3 "$S1/bench.py" --questions "$(dirname "$0")/questions.json" "$@"
