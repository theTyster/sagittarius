#!/usr/bin/env zsh
# Run the Sagittarius planning evals against Haiku, one headless session each.
# Usage: run.sh [ID...]   (no IDs: run every eval)
# Each eval goes through the real claude() from ~/.zshenv, so it gets exactly the live
# Sagittarius prompt (every account gets it).
# It runs in an empty temp directory, so no repo context leaks in.
# Answers go to runs/<UTC time>/<id>-<name>.md. Grading happens afterwards, by hand or by an
# agent, against "assertions" and "fails" in evals.json.
set -eo pipefail
here=${0:A:h}
source ~/.zshenv
# Evals run on the personal key unless EVAL_ACCOUNT=work. Claude Code does not pass its own
# token to the shells it starts, so the runner picks the account; claude() keeps a token that
# is already set and does not fall back to the work key.
case ${EVAL_ACCOUNT:-personal} in
  personal) claude-personal || { print -u2 "Cannot load the personal key. Run claude-auth in a real terminal."; exit 3; } ;;
  work) claude-40AU-claudeAPI-env || { print -u2 "Cannot load the work key. Run claude-auth in a real terminal."; exit 3; } ;;
  *) print -u2 "EVAL_ACCOUNT must be personal or work"; exit 2 ;;
esac
model=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["model"])' $here/evals.json)
mkdir -p $here/runs
out=$(mktemp -d $here/runs/$(date -u +%Y%m%dT%H%M%SZ)-XXXX)
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
  if ! ( cd $work && claude -p --model $model --no-session-persistence "$prompt" ) >> $f 2>&1; then
    print -r -- "(claude exited with an error)" >> $f
    if grep -q "is locked" $f; then
      rm -f $f; rmdir $out 2>/dev/null || true
      print -u2 "The credential is locked. Run claude-auth in a real terminal, then run this again."
      exit 3
    fi
  fi
done
print -u2 "Answers: $out"
