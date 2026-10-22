#!/usr/bin/env zsh
# Run the Sagittarius tool-use evals: one headless session each, with tools, in a copy
# of its fixture. Usage: run_tools.sh [ID...]   (no IDs: run every eval)
# Each eval goes through the real claude() from ~/.zshenv, so it gets the live prompt.
# The work directory is a temp copy of evals/fixtures/<fixture>/; setup.sh, if present,
# runs there first and is removed. Bash is allowed without prompts inside that copy.
# Output in runs/<UTC time>-tools/: <id>-<name>.jsonl (the transcript), <id>-<name>.grade.json
# (grade_tools.py), and <id>-<name>.work/ (the work directory after the run).
# An eval with "turns" instead of "prompt" is one session of several human turns: turn 1
# starts it, and each later turn resumes it (claude -p --resume), as a human who answers
# mid-work. It also leaves <id>-<name>.tK.jsonl and .work.tK (turn K alone, and the work
# directory after it), and <id>-<name>.session.jsonl: the persisted session, moved out of
# ~/.claude/projects. The empty project directory that Claude Code makes stays behind.
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
  name=$(field $id name); fixture=$(field $id fixture); checks=$(field $id checks)
  turns=$(mktemp -d)
  python3 - $spec $id $turns <<'PY'
import json,os,sys
e=[e for e in json.load(open(sys.argv[1]))["evals"] if e["id"]==int(sys.argv[2])][0]
for k,t in enumerate(e.get("turns") or [e["prompt"]],1):
    open(os.path.join(sys.argv[3],str(k)),"w").write(t)
PY
  n=$(ls $turns | wc -l); sid=$(python3 -c 'import uuid;print(uuid.uuid4())')
  work=$(mktemp -d)
  cp -r $here/fixtures/$fixture/. $work/
  if [[ -f $work/setup.sh ]]; then ( cd $work && zsh setup.sh ) && rm $work/setup.sh; fi
  base=$out/$id-$name
  print -u2 "eval $id ($name)..."
  : > $base.jsonl
  for k in {1..$n}; do
    if (( n == 1 )); then sess=(--no-session-persistence); tj=$base.jsonl
    elif (( k == 1 )); then sess=(--session-id $sid); tj=$base.t$k.jsonl
    else sess=(--resume $sid); tj=$base.t$k.jsonl; fi
    if (( n > 1 )); then print -u2 "  turn $k of $n"; fi
    # The prompt goes on stdin: --allowedTools takes several values and would swallow it.
    # timeout cannot call the claude() function, so it starts a zsh that loads ~/.zshenv;
    # a bare "timeout claude" would run the binary with no credential and no prompt.
    ( cd $work && unset ORBIT_KB && timeout $tmo zsh -c 'source ~/.zshenv && claude "$@"' claude -p --model $model \
        $sess --output-format stream-json --verbose --permission-mode acceptEdits \
        --allowedTools "Bash Read Write Edit Glob Grep" \
        --disallowedTools "$blocked" < $turns/$k ) > $tj 2>&1 || true
    # A lock counts only when the session did not finish: a working session can print the
    # words too, for example when it reads a file that contains them.
    if ! python3 -c 'import sys;sys.path.insert(0,sys.argv[1]);import grade_tools as g;sys.exit(0 if g.session_ran(sys.argv[2])[0] else 1)' $here $tj \
       && grep -q -e "is locked" -e "Not logged in" $tj; then
      print -u2 "The credential is locked. Run claude-auth in a real terminal, then run this again."
      rm -rf $work $out $turns; exit 3
    fi
    if (( n > 1 )); then cat $tj >> $base.jsonl; rsync -a --exclude .git $work/ $work.t$k/; fi
  done
  rm -rf $turns
  python3 $here/grade_tools.py --turns $n $base.jsonl $work ${(f)checks} > $base.grade.json
  python3 -c 'import json,sys;g=json.load(open(sys.argv[1]));print("  "+"  ".join(("PASS " if c["passed"] else "FAIL ")+c["text"] for c in g["checks"]))' $base.grade.json >&2
  find $work ${work}.t*(N) -name __pycache__ -prune -exec rm -rf {} +
  # runs/ is committed, so a fixture's .git stays out: it would become an embedded repository.
  rsync -a --exclude .git $work/ $base.work/
  for k in {1..$n}; do if [[ -d $work.t$k ]]; then mv $work.t$k $base.work.t$k; fi; done
  if (( n > 1 )); then
    proj=~/.claude/projects/$(python3 -c 'import os,re,sys;print(re.sub(r"[/.]","-",os.path.realpath(sys.argv[1])))' $work)
    if [[ -f $proj/$sid.jsonl ]]; then mv $proj/$sid.jsonl $base.session.jsonl; fi
    if [[ -d $proj/$sid ]]; then mv $proj/$sid $base.session; fi
  fi
  rm -rf $work
done
print -u2 "Results: $out"
