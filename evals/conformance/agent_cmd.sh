#!/usr/bin/env bash
# One Haiku session on one task of evals/tools.json, for runner.py live.
# Usage: agent_cmd.sh TASK_ID ARM RUN OUT_TRANSCRIPT      ARM: prompt | none
# The same way evals/run_tools.sh runs a session: a temp copy of the fixture (setup.sh runs
# there and is removed), the same allowed and blocked tools, stream-json, a task with "turns"
# as one session whose later turns resume it. Differences: the model is claude-haiku-5-5, the
# arm "prompt" appends prompt/SAGITTARIUS.md (the file itself, not what claude() appends), the
# arm "none" appends a blank, and the System 1 hooks are off (S1_OFF=1 here; the runner also
# sets it). The transcript is OUT_TRANSCRIPT; the work copy is deleted.
# CONFORMANCE_CLAUDE_BIN: a program to run in place of `claude` (a test stub). Unset: the real
# claude(), through zsh and ~/.zshenv with the personal key (EVAL_ACCOUNT=work for the work key).
# This script makes a PAID call when CONFORMANCE_CLAUDE_BIN is unset.
set -eo pipefail
if [ $# -ne 4 ]; then echo "usage: agent_cmd.sh TASK_ID ARM RUN OUT_TRANSCRIPT" >&2; exit 2; fi
task=$1 arm=$2 run=$3 out=$4
here=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)   # the Sagittarius root
model=${CONFORMANCE_AGENT_MODEL:-claude-haiku-5-5}
case $arm in prompt|none) ;; *) echo "ARM must be prompt or none, not $arm" >&2; exit 2 ;; esac
export S1_OFF=1
spec=$here/evals/tools.json
tmp=$(mktemp -d "${TMPDIR:-/tmp}/conf-agent-XXXXXX")
trap 'rm -rf "$tmp"' EXIT
python3 - "$spec" "$task" "$tmp" <<'PY'
import json, os, sys
spec, tid, tmp = sys.argv[1:]
d = json.load(open(spec))
es = [e for e in d["evals"] if str(e["id"]) == tid]
if not es:
    sys.exit(f"no task {tid} in {spec}")
e = es[0]
for k, t in enumerate(e.get("turns") or [e["prompt"]], 1):
    open(os.path.join(tmp, f"turn{k}"), "w").write(t)
open(os.path.join(tmp, "fixture"), "w").write(e["fixture"])
open(os.path.join(tmp, "timeout"), "w").write(str(d["timeout_s"]))
PY
fixture=$(cat "$tmp/fixture"); tmo=$(cat "$tmp/timeout")
n=$(ls "$tmp" | grep -c '^turn')
work=$tmp/work; mkdir "$work"
cp -r "$here/evals/fixtures/$fixture/." "$work/"
if [ -f "$work/setup.sh" ]; then ( cd "$work" && bash setup.sh ) && rm "$work/setup.sh"; fi
if [ "$arm" = prompt ]; then sp=(--append-system-prompt "$(cat "$here/prompt/SAGITTARIUS.md")"); else sp=(--append-system-prompt " "); fi
blocked="Bash(pip install *),Bash(pip3 install *),Bash(python3 -m pip *),Bash(npm install *),Bash(pnpm add *),Bash(lake *),Bash(git push *),Bash(curl *),Bash(wget *)"
sid=$(python3 -c 'import uuid;print(uuid.uuid4())')
: > "$out"
for k in $(seq 1 "$n"); do
  if [ "$n" -eq 1 ]; then sess=(--no-session-persistence)
  elif [ "$k" -eq 1 ]; then sess=(--session-id "$sid")
  else sess=(--resume "$sid"); fi
  args=(-p --model "$model" "${sp[@]}" "${sess[@]}" --output-format stream-json --verbose
        --permission-mode acceptEdits --allowedTools "Bash Read Write Edit Glob Grep"
        --disallowedTools "$blocked")
  # The turn goes on stdin: --allowedTools takes several values and would swallow it.
  if [ -n "$CONFORMANCE_CLAUDE_BIN" ]; then
    ( cd "$work" && unset ORBIT_KB && timeout "$tmo" "$CONFORMANCE_CLAUDE_BIN" "${args[@]}" < "$tmp/turn$k" ) >> "$out" 2>&1 || true
  else
    case ${EVAL_ACCOUNT:-personal} in personal) auth=claude-personal ;; work) auth=claude-40AU-claudeAPI-env ;;
      *) echo "EVAL_ACCOUNT must be personal or work" >&2; exit 2 ;; esac
    ( cd "$work" && unset ORBIT_KB && timeout "$tmo" zsh -c "source ~/.zshenv && $auth || exit 3; claude \"\$@\"" claude "${args[@]}" < "$tmp/turn$k" ) >> "$out" 2>&1 || true
  fi
done
# A multi-turn session is persisted by claude under ~/.claude/projects; leave nothing of it.
if [ "$n" -gt 1 ] && [ -z "$CONFORMANCE_CLAUDE_BIN" ]; then
  proj=$HOME/.claude/projects/$(python3 -c 'import os,re,sys;print(re.sub(r"[/.]","-",os.path.realpath(sys.argv[1])))' "$work")
  rm -rf "$proj/$sid.jsonl" "$proj/$sid"
fi
