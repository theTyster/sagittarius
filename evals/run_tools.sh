#!/usr/bin/env zsh
# Run the Sagittarius tool-use evals: one headless session each, with tools, in a copy
# of its fixture. Usage:
#   run_tools.sh [--spec FILE] [--runs N] [-j N] [--prompt FILE|none] [--model M] [--rubric] [ID...]
# No IDs: run every eval in the spec (default evals/tools.json; the held-out set is
# evals/heldout/heldout.json). Read docs/REFINING.md before you change the prompt for a result.
#   --runs N    run each eval N times; an eval passes when it passes in 2 of 3 runs (summary.json)
#   -j N        run N sessions at once (they wait on the network, not the CPU)
#   --prompt F  append F instead of the live prompt: a copy with one rule deleted, or the base
#               version (git show BASE:prompt/SAGITTARIUS.md). "none" appends no Sagittarius.
#   --model M   the executor model (default: the spec's "model")
#   --rubric    also grade each run's "assertions" with an Opus judge (grade_rubric.py)
# Each session goes through the real claude() from ~/.zshenv, which appends the live prompt
# unless --prompt gives another. The work directory is a temp copy of <spec dir>/fixtures/
# <fixture>/; setup.sh, if present, runs there first and is removed. Bash is allowed without
# prompts inside that copy.
# Output in runs/<UTC time>-tools-XXXX/: meta.json (model, prompt and its sha256, commit),
# summary.json, and for each run <id>-<name>[.rR]: .jsonl (the transcript), .grade.json
# (grade_tools.py), [.rubric.json], and .work/ (the work directory after the run).
# An eval with "turns" instead of "prompt" is one session of several human turns: turn 1
# starts it, and each later turn resumes it (claude -p --resume), as a human who answers
# mid-work. It also leaves .tK.jsonl and .work.tK (turn K alone, and the work directory after
# it), and .session.jsonl: the persisted session, moved out of ~/.claude/projects. The empty
# project directory that Claude Code makes stays behind.
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
spec=$here/tools.json; runs=1; jobs=1; prompt=""; model=""; rubric=0
while (( $# )); do
  case $1 in
    --spec) spec=${2:A}; shift 2 ;;
    --runs) runs=$2; shift 2 ;;
    -j) jobs=$2; shift 2 ;;
    --prompt) prompt=$2; [[ $2 == none ]] || prompt=${2:A}; shift 2 ;;
    --model) model=$2; shift 2 ;;
    --rubric) rubric=1; shift ;;
    --) shift; break ;;
    -*) print -u2 "unknown option $1"; exit 2 ;;
    *) break ;;
  esac
done
sdir=${spec:h}
jget() { python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))[sys.argv[2]])' $spec $1; }
model=${model:-${EVAL_MODEL:-$(jget model)}}
tmo=$(jget timeout_s)
# The appended prompt: none from the runner (claude() appends the live one), a file, or a blank.
# claude() appends nothing of its own when the arguments name a system prompt.
sp=()
if [[ $prompt == none ]]; then sp=(--append-system-prompt " ")
elif [[ -n $prompt ]]; then [[ -f $prompt ]] || { print -u2 "no prompt file $prompt"; exit 2; }; sp=(--append-system-prompt "$(<$prompt)"); fi
mkdir -p $here/runs
out=$(mktemp -d $here/runs/$(date -u +%Y%m%dT%H%M%SZ)-tools-XXXX)
python3 - $out/meta.json $spec $model "${prompt:-live}" $runs $here ${EVAL_ACCOUNT:-personal} <<'PY'
import hashlib,json,os,subprocess,sys
out,spec,model,prompt,runs,here,account=sys.argv[1:]
path=os.path.expanduser("~/.claude/sagittarius/SAGITTARIUS.md") if prompt=="live" else prompt
sha=hashlib.sha256(open(path,"rb").read()).hexdigest() if prompt!="none" else None
git=lambda *a: subprocess.run(["git","-C",here,*a],capture_output=True,text=True).stdout.strip()
json.dump({"spec":os.path.relpath(spec,here),"account":account,"model":model,"prompt":prompt,"prompt_sha256":sha,"runs":int(runs),
           "commit":git("rev-parse","--short","HEAD"),"dirty":bool(git("status","--porcelain","--","prompt","evals"))},open(out,"w"),indent=2)
PY
ids=$(python3 - $spec "$@" <<'PY'
import json,sys
d=json.load(open(sys.argv[1])); want=set(map(int,sys.argv[2:]))
print(" ".join(str(e["id"]) for e in d["evals"] if not want or e["id"] in want))
PY
)
# Calls that reach outside the work directory. A blocked call shows up as a permission
# denial in the transcript, and the check no_blocked_calls fails on it.
blocked="Bash(pip install *),Bash(pip3 install *),Bash(python3 -m pip *),Bash(npm install *),Bash(pnpm add *),Bash(lake *),Bash(git push *),Bash(curl *),Bash(wget *)"
field() { python3 -c 'import json,sys;e=[e for e in json.load(open(sys.argv[1]))["evals"] if e["id"]==int(sys.argv[2])][0];v=e.get(sys.argv[3],[]);print("\n".join(v) if isinstance(v,list) else v)' $spec $1 $2; }

# One run of one eval. Exit 3 when the credential is locked.
run_one() {
  local id=$1 r=$2 name fixture checks turns n sid work base k sess tj proj apierr=
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
  cp -r $sdir/fixtures/$fixture/. $work/
  if [[ -f $work/setup.sh ]]; then ( cd $work && zsh setup.sh ) && rm $work/setup.sh; fi
  base=$out/$id-$name; (( runs > 1 )) && base=$base.r$r
  print -u2 "eval $id ($name) run $r..."
  : > $base.jsonl
  for k in {1..$n}; do
    if (( n == 1 )); then sess=(--no-session-persistence); tj=$base.jsonl
    elif (( k == 1 )); then sess=(--session-id $sid); tj=$base.t$k.jsonl
    else sess=(--resume $sid); tj=$base.t$k.jsonl; fi
    # The prompt goes on stdin: --allowedTools takes several values and would swallow it.
    # timeout cannot call the claude() function, so it starts a zsh that loads ~/.zshenv;
    # a bare "timeout claude" would run the binary with no credential and no prompt.
    ( cd $work && unset ORBIT_KB && timeout $tmo zsh -c 'source ~/.zshenv && claude "$@"' claude -p --model $model \
        $sp $sess --output-format stream-json --verbose --permission-mode acceptEdits \
        --allowedTools "Bash Read Write Edit Glob Grep" \
        --disallowedTools "$blocked" < $turns/$k ) > $tj 2>&1 || true
    # A lock counts only when the session did not finish: a working session can print the
    # words too, for example when it reads a file that contains them.
    if ! python3 -c 'import sys;sys.path.insert(0,sys.argv[1]);import grade_tools as g;sys.exit(0 if g.session_ran(sys.argv[2])[0] else 1)' $here $tj \
       && grep -q -e "is locked" -e "Not logged in" $tj; then
      rm -rf $work $turns; return 3
    fi
    if (( n > 1 )); then cat $tj >> $base.jsonl; rsync -a --exclude .git $work/ $work.t$k/; fi
    # An API error (rate limit, spend limit, overload) ends the session at once. It is not a failed behavior.
    apierr=$(python3 -c 'import sys;sys.path.insert(0,sys.argv[1]);import grade_tools as g
r=[e for e in g.events(sys.argv[2]) if e.get("type")=="result"]
x=str(r[-1].get("result") or "") if r else ""
if r and (r[-1].get("is_error") or x.startswith("API Error")): print(x or "is_error")' $here $tj)
    if [[ -n $apierr ]]; then break; fi
  done
  rm -rf $turns
  if [[ -n $apierr ]]; then
    print -r -- $apierr > $base.api_error
    print -u2 -r -- "  $id.r$r  API ERROR: ${apierr[1,120]}"
  fi
  EVAL_CHECKS_DIR=$sdir/checks python3 $here/grade_tools.py --turns $n $base.jsonl $work ${(f)checks} > $base.grade.json
  python3 -c 'import json,sys;g=json.load(open(sys.argv[1]));print(sys.argv[2]+"  "+"  ".join(("PASS " if c["passed"] else "FAIL ")+c["text"][:50] for c in g["checks"]))' $base.grade.json "  $id.r$r" >&2
  if (( rubric )); then python3 $here/grade_rubric.py $spec $id $base.jsonl > $base.rubric.json || true; fi
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
}

pids=(); locked=0
reap() {  # wait for the oldest job
  local st=0
  wait $pids[1] || st=$?
  pids=(${pids[2,-1]})
  if (( st == 3 )); then locked=1; fi
}
for id in ${=ids}; do
  for r in {1..$runs}; do
    run_one $id $r &
    pids+=($!)
    while (( ${#pids} >= jobs )); do reap; done
    if (( locked )); then break 2; fi
  done
done
while (( ${#pids} )); do reap; done
if (( locked )); then
  print -u2 "The credential is locked. Run claude-auth in a real terminal, then run this again."
  print -u2 "Partial results: $out"; exit 3
fi
python3 $here/summarize_tools.py $out $spec
print -u2 "Results: $out"
