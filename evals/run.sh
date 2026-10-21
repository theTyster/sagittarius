#!/usr/bin/env zsh
# Run the orbital-shifting planning evals against Haiku, one headless session each.
# Usage: run.sh [ID...]   (no IDs: run every eval)
# Each eval goes through the real claude() from ~/.zshenv, so it gets exactly the live
# Orbital Shifting prompt. It runs in an empty temp directory, so no repo context leaks in.
# Answers go to runs/<UTC time>/<id>-<name>.md. Grading happens afterwards, by hand or by an
# agent, against "assertions" and "fails" in evals.json.
set -eo pipefail
here=${0:A:h}
source ~/.zshenv
model=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["model"])' $here/evals.json)
out=$here/runs/$(date -u +%Y%m%dT%H%M%SZ)
mkdir -p $out
work=$(mktemp -d)
trap 'rm -rf $work' EXIT
ids=$(python3 - $here/evals.json "$@" <<'PY'
import json,sys
d=json.load(open(sys.argv[1])); want=set(map(int,sys.argv[2:]))
print(" ".join(str(e["id"]) for e in d["evals"] if not want or e["id"] in want))
PY
)
for id in ${=ids}; do
  name=$(python3 -c 'import json,sys;print([e for e in json.load(open(sys.argv[1]))["evals"] if e["id"]==int(sys.argv[2])][0]["name"])' $here/evals.json $id)
  prompt=$(python3 -c 'import json,sys;d=json.load(open(sys.argv[1]));e=[e for e in d["evals"] if e["id"]==int(sys.argv[2])][0];print(d["preamble"]+"\n\n"+e["prompt"])' $here/evals.json $id)
  f=$out/$id-$name.md
  print -r -- "# $id $name ($model)" > $f
  print -r -- "" >> $f; print -r -- '## Prompt' >> $f; print -r -- "" >> $f; print -r -- "$prompt" >> $f
  print -r -- "" >> $f; print -r -- '## Answer' >> $f; print -r -- "" >> $f
  print -u2 "eval $id ($name)..."
  ( cd $work && claude -p --model $model --no-session-persistence "$prompt" ) >> $f 2>&1 \
    || print -r -- "(claude exited $?)" >> $f
done
print -u2 "Answers: $out"
