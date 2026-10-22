#!/usr/bin/env zsh
# Run the Sagittarius tool-use evals: one headless session each, with tools, in a copy
# of its fixture. Usage: run_tools.sh [ID...]   (no IDs: run every eval)
# Each eval goes through the real claude() from ~/.zshenv, so it gets the live prompt.
# The work directory is a temp copy of evals/fixtures/<fixture>/; setup.sh, if present,
# runs there first and is removed. Bash is allowed without prompts inside that copy.
# Output in runs/<UTC time>-tools/: <id>-<name>.jsonl (the transcript), <id>-<name>.grade.json
# (grade_tools.py), and <id>-<name>.work/ (the work directory after the run).
set -eo pipefail
here=${0:A:h}
source ~/.zshenv
spec=$here/tools.json
model=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["model"])' $spec)
tmo=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["timeout_s"])' $spec)
mkdir -p $here/runs
out=$(mktemp -d $here/runs/$(date -u +%Y%m%dT%H%M%SZ)-tools-XXXX)
ids=$(python3 - $spec "$@" <<'PY'
import json,sys
d=json.load(open(sys.argv[1])); want=set(map(int,sys.argv[2:]))
print(" ".join(str(e["id"]) for e in d["evals"] if not want or e["id"] in want))
PY
)
# Calls that reach outside the work directory. A blocked call shows up as a permission
# denial in the transcript, and the check no_blocked_calls fails on it.
blocked="Bash(pip install *),Bash(pip3 install *),Bash(python3 -m pip *),Bash(npm install *),Bash(pnpm add *),Bash(lake *),Bash(git push *),Bash(curl *),Bash(wget *)"
field() { python3 -c 'import json,sys;e=[e for e in json.load(open(sys.argv[1]))["evals"] if e["id"]==int(sys.argv[2])][0];v=e[sys.argv[3]];print("\n".join(v) if isinstance(v,list) else v)' $spec $1 $2; }
for id in ${=ids}; do
  name=$(field $id name); fixture=$(field $id fixture); prompt=$(field $id prompt); checks=$(field $id checks)
  work=$(mktemp -d)
  cp -r $here/fixtures/$fixture/. $work/
  if [[ -f $work/setup.sh ]]; then ( cd $work && zsh setup.sh ) && rm $work/setup.sh; fi
  base=$out/$id-$name
  print -u2 "eval $id ($name)..."
  # The prompt goes on stdin: --allowedTools takes several values and would swallow it.
  # timeout cannot call the claude() function, so it starts a zsh that loads ~/.zshenv;
  # a bare "timeout claude" would run the binary with no credential and no prompt.
  ( cd $work && unset ORBIT_KB && print -r -- "$prompt" | timeout $tmo zsh -c 'source ~/.zshenv && claude "$@"' claude -p --model $model \
      --no-session-persistence --output-format stream-json --verbose --permission-mode acceptEdits \
      --allowedTools "Bash Read Write Edit Glob Grep" \
      --disallowedTools "$blocked" ) > $base.jsonl 2>&1 || true
  # A lock counts only when the session did not finish: a working session can print the
  # words too, for example when it reads a file that contains them.
  if ! python3 -c 'import sys;sys.path.insert(0,sys.argv[1]);import grade_tools as g;sys.exit(0 if g.session_ran(sys.argv[2])[0] else 1)' $here $base.jsonl \
     && grep -q -e "is locked" -e "Not logged in" $base.jsonl; then
    print -u2 "The credential is locked. Run claude-auth in a real terminal, then run this again."
    rm -rf $work $out; exit 3
  fi
  python3 $here/grade_tools.py $base.jsonl $work ${(f)checks} > $base.grade.json
  python3 -c 'import json,sys;g=json.load(open(sys.argv[1]));print("  "+"  ".join(("PASS " if c["passed"] else "FAIL ")+c["text"] for c in g["checks"]))' $base.grade.json >&2
  find $work -name __pycache__ -prune -exec rm -rf {} +
  cp -r $work $base.work
  rm -rf $work
done
print -u2 "Results: $out"
