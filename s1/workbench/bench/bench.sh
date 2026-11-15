#!/bin/sh
# The bench area: replay old prompts with this folder's questions.json and pipeline.py.
# Nothing here reaches a live call; the calls go to ~/.claude/logs/s1-bench.jsonl only.
here=$(cd "$(dirname "$0")" && pwd)
S1=${S1:-$(cd "$here/../.." && pwd)}
exec python3 "$S1/bench.py" --questions "$here/questions.json" --pipeline "$here/pipeline.py" "$@"
