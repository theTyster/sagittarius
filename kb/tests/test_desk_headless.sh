#!/usr/bin/env bash
# Headless desk agents (desk-agents c11 to c19): desk.py on a scratch hub, with a fake claude. The PATH holds the
# fake and /usr/bin:/bin only, so no test can reach a real claude. Usage: kb/tests/test_desk_headless.sh [ROOT]
#   DH1 a letter about a KB that nobody holds starts one claude -p with stream-json; the agent holds the KB's lock
#   DH2 one process per session: a second letter while the agent runs waits, then runs with --resume after the first
#   DH3 a stopped agent: no lock, a resume command; a running agent: no resume command
#   DH4 agent-resume starts a headless run of the same session and takes the lock again
#   DH5 a KB held by a live lock of another writer starts no agent; the letter keeps its receiver
#   DH6 desk agents are on by default (Ty, q9): no flag and no DESK_AGENTS start an agent; `desk.py agents off`
#       stops new starts; DESK_AGENTS=off wins; DESK_AGENTS=on wins over the off flag; `agents on` turns them on again
#   DH6b DESK_AGENTS is read without case; 0, false, no are off; 1, true, yes are on (c22); an unknown value is
#        reported by name and counts as not set: agents stay on, and the off flag still holds (c23)
#   DH7 control bytes of a letter do not reach the prompt
#   DH8 a letter to an unknown desk agent is refused; one to a known agent goes to no session
#   DH9 the Desk path (POST /review, /send): an answer about a KB nobody holds starts an agent; a requirement to the
#       live review session is not diverted (review gets it by its hook)
#   DH10 POST /agent write, then a stop: every view answers 200
#   DH11 the runner killed while claude runs: the lock stays, a resume is refused (one process per session)
#   DH12 a run that fails (exit 1, one line on stderr) leaves the agent failed, with that line, and no lock; the next
#        run that ends normally clears it; the Desk's view Agents says failed with the line (desk-agents c20)
#   DH13 a run gets nothing of the session that sent the letter: no CLAUDECODE, AI_AGENT, CLAUDE_CODE_SESSION_ID,
#        CLAUDE_PANE_*, CLAUDE_CODE_MESSAGING_*, CLAUDE_SESSION_ID, TMUX_PANE; ORBIT_KB_ROLE is the agent's own role;
#        CLAUDE_CODE_OAUTH_TOKEN and CLAUDE_CONFIG_DIR (the login) still reach it (c21; review H-0283 f_h5)
#   DH14 a Desk started with an unknown DESK_AGENTS word names it at its start and on its views; a Desk with no
#        DESK_AGENTS shows no such banner (c23; review H-0285 f_h6; review's p15 case U2 also sends an answer)
set -u
ROOT=${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}
T=$(mktemp -d "${TMPDIR:-/tmp}/desk-headless-test.XXXXXX")
cleanup() { pkill -f "$T/bin/claude" 2>/dev/null; pkill -f "$T/alpha/.claude/scripts/desk.py" 2>/dev/null; rm -rf "$T"; }; trap cleanup EXIT
PASS=0; FAIL=0
ok() { echo "PASS $1"; PASS=$((PASS+1)); }; no() { echo "FAIL $1"; FAIL=$((FAIL+1)); }
check() { if eval "$2"; then ok "$1"; else no "$1"; fi; }
mkdir -p "$T/bin" "$T/home" "$T/state"
cat > "$T/bin/claude" <<'FAKE'
#!/usr/bin/env python3
import json, os, signal, sys, time
a = sys.argv[1:]
def val(n):
    return next((a[i + 1] for i, x in enumerate(a) if x == n and i + 1 < len(a)), "")
sid = val("--session-id") or val("--resume")
open(os.environ["FAKE_LOG"], "a").write("START " + json.dumps(a) + "\n")
open(os.environ["FAKE_LOG"], "a").write("ENV " + json.dumps({k: v for k, v in os.environ.items() if k.startswith(("CLAUDE", "AI_", "TMUX", "HUB_", "ORBIT_KB_ROLE"))}) + "\n")
if os.environ.get("FAKE_FAIL") == "result":   # the error only in the result event on stdout, nothing on stderr
    print(json.dumps({"type": "result", "subtype": "success", "is_error": True, "result": "RESULTERR-62 Invalid API key"}), flush=True); sys.exit(1)
if os.environ.get("FAKE_FAIL"):
    sys.stderr.write("first line\nFAILLINE-61 Invalid API key - please run /login\n"); sys.exit(1)
def bye(*_):
    open(os.environ["FAKE_LOG"], "a").write("STOPPED\n"); sys.exit(143)
signal.signal(signal.SIGTERM, bye)
print(json.dumps({"type": "assistant", "message": {"content": [{"type": "tool_use", "name": "Bash", "input": {"command": "echo T1"}}]}}), flush=True)
time.sleep(float(os.environ.get("FAKE_SECS", "2")))
print(json.dumps({"type": "result", "subtype": "success", "result": "DONE"}), flush=True)
open(os.environ["FAKE_LOG"], "a").write("END\n")
FAKE
chmod +x "$T/bin/claude"
export PATH="$T/bin:/usr/bin:/bin" HOME="$T/home" DESK_STATE="$T/state" FAKE_LOG="$T/claude.log"; : > "$FAKE_LOG"
unset HUB_SESSION DESK_AGENTS
[ "$(command -v claude)" = "$T/bin/claude" ] || { echo "setup: claude resolves outside the fake ($(command -v claude)); refusing to run"; exit 2; }
h=$T/alpha
python3 "$ROOT/hubkit/tools/hubkit.py" install --hub "$h" >/dev/null 2>&1 || { echo "setup: no hub"; exit 2; }
( cd "$h" && { [ -f flow/flow.db ] || python3 .claude/scripts/hubflow.py --hub "$h" init --seed flow/seed.json; } ) >/dev/null 2>&1
K="$h/.claude/orbit-kb/bin/orbit-kb"; D="python3 $h/.claude/scripts/desk.py --hub $h"
for s in t1 t2 t3 t4 t5 t6 t7 t8 t9; do ORBIT_KB_WRITER=probe "$K" init "$h/specs/$s" --request "request of $s" --uses discovery >/dev/null 2>&1; ORBIT_KB_WRITER=probe "$K" --dir "$h/specs/$s" release >/dev/null 2>&1; done
( cd "$h" && python3 .claude/scripts/desk.py join --name alpha ) >/dev/null 2>&1
# DH6 (on by default: no flag, no DESK_AGENTS, no `agents on`)
check "DH6 setup: no switch is set" '[ ! -e "$DESK_STATE/agents-on" ] && [ ! -e "$DESK_STATE/agents-off" ] && [ -z "${DESK_AGENTS+x}" ]'
printf 'x' > "$T/text"; out0=$(FAKE_SECS=1 $D send --kind note --item-json '{"type": "kb", "slug": "t7", "kb": "specs/t7", "ref": "note"}' --about probe --text-file "$T/text" 2>/dev/null)
i=0; while [ $i -lt 80 ] && [ "$(grep -c "^START" "$FAKE_LOG")" = 0 ]; do sleep 0.1; i=$((i+1)); done
check "DH6 desk agents are on by default: the letter starts an agent" '[ "$(grep -c "^START" "$FAKE_LOG")" = 1 ] && grep -q "\"agent\"" <<<"$out0"'
check "DH6 desk.py agents says on with no switch" '$D agents | python3 -c "import json,sys; sys.exit(0 if json.load(sys.stdin)[\"on\"] is True else 1)"'
i=0; while [ $i -lt 80 ] && ! grep -q "^END" "$FAKE_LOG"; do sleep 0.1; i=$((i+1)); done; sleep 0.5; : > "$FAKE_LOG"
send() { printf '%s' "$2" > "$T/text"; $D send --kind note --item-json "$1" --about probe --text-file "$T/text" 2>>"$T/err"; }
kbi() { printf '{"type": "kb", "slug": "%s", "kb": "specs/%s", "ref": "note"}' "$1" "$1"; }
starts() { grep -c "^START" "$FAKE_LOG"; }
nth() { grep "^START" "$FAKE_LOG" | sed -n "${1}p"; }
waitfor() { local i=0; while [ $i -lt ${2:-100} ]; do eval "$1" && return 0; sleep 0.1; i=$((i+1)); done; return 1; }
lock() { awk '{print $1}' "$h/specs/$1/writer.lock" 2>/dev/null; }
agent() { $D agents | python3 -c 'import json,sys; o=json.load(sys.stdin); n=sys.argv[1]; a=[x for x in o["agents"] if x["name"]==n]; print(json.dumps(a[0] if a else {}))' "$1"; }
field() { python3 -c 'import json,sys; v=json.loads(sys.argv[1]).get(sys.argv[2]); print("" if v is None else v)' "$1" "$2"; }

# DH1
out=$(FAKE_SECS=6 send "$(kbi t1)" "Letter one."); nm=$(field "$out" agent)
waitfor '[ "$(starts)" -ge 1 ]'
s1=$(nth 1); sid=$(field "$(agent "$nm")" session_id)
check "DH1 one claude -p for the letter ($nm)" '[ "$(starts)" = 1 ] && grep -q "\"-p\"" <<<"$s1" && grep -q "\"stream-json\"" <<<"$s1"'
check "DH1 the agent holds the lock of t1" '[ -n "$sid" ] && [ "$(lock t1)" = "$sid" ]'
check "DH1 the letter goes to no session (it names the agent)" 'grep -q "\"agent\": \"$nm\"" "$h/flow/desk/letters.jsonl"'
# DH3 (running half)
check "DH3 a running agent shows no resume command" '[ -z "$(field "$(agent "$nm")" resume_command)" ]'
# DH2
send "{\"type\": \"agent\", \"agent\": \"$nm\"}" "More words WAIT2." >/dev/null
sleep 1
check "DH2 the second letter waits: one process" '[ "$(starts)" = 1 ] && [ "$(pgrep -fc "$T/bin/claude")" -le 1 ]'
waitfor '[ "$(starts)" -ge 2 ]' 120
s2=$(nth 2)
check "DH2 after the first run the words run with --resume of the same session" 'grep -q "\"--resume\", \"$sid\"" <<<"$s2" && grep -q WAIT2 <<<"$s2"'
# DH3 (stopped half)
$D agent-stop "$nm" >/dev/null 2>&1; waitfor 'grep -q "^STOPPED" "$FAKE_LOG"' 50; sleep 1
a=$(agent "$nm")
check "DH3 a stopped agent holds no lock" '[ -z "$(lock t1)" ] && [ "$(field "$a" state)" = stopped ]'
check "DH3 a stop is not a failure: no error event, not failed" '! grep -q "\"kind\": \"error\"" "$h/flow/desk/agents/$nm.jsonl" && [ -z "$(field "$a" why)" ]'
check "DH3 and shows cd HUB && claude --resume SID" '[ "$(field "$a" resume_command)" = "cd $h && claude --resume $sid" ]'
# DH4
n0=$(starts); FAKE_SECS=6 $D agent-resume "$nm" >/dev/null 2>&1; waitfor '[ "$(starts)" -gt '"$n0"' ]' 80; sleep 0.5
check "DH4 the resume starts a headless run of the same session" 'grep -q "\"--resume\", \"$sid\"" <<<"$(nth $((n0+1)))" && grep -q "\"-p\"" <<<"$(nth $((n0+1)))"'
check "DH4 and takes the lock again" '[ "$(lock t1)" = "$sid" ]'
$D agent-stop "$nm" >/dev/null 2>&1
# DH5
printf 'someone %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$h/specs/t2/writer.lock"
n0=$(starts); out=$(send "$(kbi t2)" "Letter two."); sleep 1
check "DH5 a KB held by another writer starts no agent" '[ "$(starts)" = "$n0" ] && [ -z "$(field "$out" agent)" ]'
# DH6
n0=$(starts); out=$(DESK_AGENTS=off send "$(kbi t3)" "Letter three."); sleep 0.5
check "DH6 DESK_AGENTS=off starts no agent" '[ "$(starts)" = "$n0" ] && [ -z "$(field "$out" agent)" ]'
: > "$DESK_STATE/agents-on"; $D agents off >/dev/null; out=$(send "$(kbi t3)" "Letter three."); sleep 0.5
check "DH6 desk.py agents off starts no agent (and drops an old agents-on flag)" '[ "$(starts)" = "$n0" ] && [ -z "$(field "$out" agent)" ] && [ -e "$DESK_STATE/agents-off" ] && [ ! -e "$DESK_STATE/agents-on" ]'
out=$(FAKE_SECS=1 DESK_AGENTS=on send "$(kbi t3)" "Letter three again."); waitfor '[ "$(starts)" -gt '"$n0"' ]' 80
check "DH6 DESK_AGENTS=on wins over the off flag" '[ "$(starts)" -gt "$n0" ] && [ -n "$(field "$out" agent)" ]'
waitfor 'grep -c "^END" "$FAKE_LOG" >/dev/null && [ "$(pgrep -fc "$T/bin/claude")" = 0 ]' 80; sleep 0.5
$D agents on >/dev/null
check "DH6 desk.py agents on removes the off flag" '[ ! -e "$DESK_STATE/agents-off" ]'
# DH6b (c22, c23): DESK_AGENTS is read without case; 0, false, no are off; an unknown value counts as not set
for v in OFF Off 0 false no ' off '; do
  check "DH6b DESK_AGENTS='$v' reads as off" 'DESK_AGENTS="'"$v"'" $D agents | python3 -c "import json,sys; sys.exit(0 if json.load(sys.stdin)[\"on\"] is False else 1)"'
done
for v in ON Yes 1 true; do
  check "DH6b DESK_AGENTS='$v' reads as on" 'DESK_AGENTS="'"$v"'" $D agents | python3 -c "import json,sys; sys.exit(0 if json.load(sys.stdin)[\"on\"] is True else 1)"'
done
n0=$(starts); out=$(DESK_AGENTS=Off send "$(kbi t3)" "Letter three, off in another case."); sleep 0.5
check "DH6b DESK_AGENTS=Off starts no agent" '[ "$(starts)" = "$n0" ] && [ -z "$(field "$out" agent)" ]'
uk=$(DESK_AGENTS=maybe $D agents 2>"$T/uk.err")
check "DH6b an unknown value (maybe) counts as not set: agents stay on" 'python3 -c "import json,sys; sys.exit(0 if json.loads(sys.argv[1])[\"on\"] is True else 1)" "$uk"'
check "DH6b and it is reported by name" 'grep -q "DESK_AGENTS=.maybe." "$T/uk.err"'
$D agents off >/dev/null
check "DH6b an unknown value does not override desk.py agents off" 'DESK_AGENTS=maybe $D agents 2>/dev/null | python3 -c "import json,sys; sys.exit(0 if json.load(sys.stdin)[\"on\"] is False else 1)"'
$D agents on >/dev/null
# DH7
n0=$(starts); FAKE_SECS=1 send "$(kbi t4)" "$(printf 'Bad\003byte CTLPROBE.')" >/dev/null; waitfor '[ "$(starts)" -gt '"$n0"' ]' 80
check "DH7 no control byte in the prompt" 'grep -q CTLPROBE <<<"$(nth $((n0+1)))" && ! grep -q "\\\\u0003" <<<"$(nth $((n0+1)))"'
# DH8
check "DH8 a letter to an unknown agent is refused" '! send "{\"type\": \"agent\", \"agent\": \"alpha-review-agent_999\"}" "x" >/dev/null 2>&1'
# DH12 (c20): a failed run
out=$(FAKE_FAIL=1 send "$(kbi t8)" "Letter eight."); n8=$(field "$out" agent)
waitfor '[ "$(field "$(agent "$n8")" state)" = failed ]' 100; a8=$(agent "$n8")
check "DH12 a run that exits 1 leaves the agent failed" '[ -n "$n8" ] && [ "$(field "$a8" state)" = failed ]'
check "DH12 with the last line of its stderr" '[ "$(field "$a8" why)" = "FAILLINE-61 Invalid API key - please run /login" ] && grep -q "FAILLINE-61" "$h/flow/desk/agents/$n8.jsonl"'
check "DH12 and the failed agent holds no lock" '[ -z "$(lock t8)" ]'
FAKE_SECS=1 send "{\"type\": \"agent\", \"agent\": \"$n8\"}" "Try again." >/dev/null
waitfor '[ "$(field "$(agent "$n8")" state)" = ended ]' 100; a8b=$(agent "$n8")
check "DH12 the next run that ends normally clears it" '[ "$(field "$a8b" state)" = ended ] && [ -z "$(field "$a8b" why)" ]'
FAKE_FAIL=result send "{\"type\": \"agent\", \"agent\": \"$n8\"}" "Fail in the result event." >/dev/null
waitfor '[ "$(field "$(agent "$n8")" state)" = failed ]' 100; a8c=$(agent "$n8")
check "DH12 an error only in the result event (empty stderr) is the reason" '[ "$(field "$a8c" state)" = failed ] && [ "$(field "$a8c" why)" = "RESULTERR-62 Invalid API key" ]'
out=$(FAKE_FAIL=1 send "$(kbi t8)" "Letter eight, again."); waitfor '[ "$(field "$(agent "$n8")" why)" = "FAILLINE-61 Invalid API key - please run /login" ]' 100
# DH13 (c21): the sender's session does not reach the run
n0=$(starts)
out=$(CLAUDECODE=1 AI_AGENT=LEAK-70 CLAUDE_CODE_SESSION_ID=LEAK-71 CLAUDE_PANE_ROLE_PROMPT=LEAK-72 CLAUDE_PANE_NAME=LEAK-73 TMUX_PANE=%LEAK-74 \
      CLAUDE_CODE_MESSAGING_SOCKET=LEAK-75 CLAUDE_CODE_MESSAGING_TOKEN=LEAK-76 CLAUDE_SESSION_ID=LEAK-78 ORBIT_KB_ROLE=LEAK-79 \
      CLAUDE_CODE_OAUTH_TOKEN=KEEP-77 CLAUDE_CONFIG_DIR="$HOME/.claude" FAKE_SECS=1 send "$(kbi t9)" "Letter nine.")
waitfor '[ "$(starts)" -gt '"$n0"' ]' 80; sleep 0.3; e9=$(grep "^ENV" "$FAKE_LOG" | tail -1)
check "DH13 the run has no value of the sender's session" '[ -n "$e9" ] && ! grep -q "LEAK-" <<<"$e9" && ! grep -q "\"CLAUDECODE\"" <<<"$e9"'
check "DH13 the login (CLAUDE_CODE_OAUTH_TOKEN, CLAUDE_CONFIG_DIR) still reaches it" 'grep -q "KEEP-77" <<<"$e9" && grep -q "\"CLAUDE_CONFIG_DIR\"" <<<"$e9"'
n9=$(field "$out" agent); r9=$(field "$(agent "$n9")" role)
check "DH13 ORBIT_KB_ROLE is the agent's own role ($r9), not the sender's" '[ -n "$r9" ] && grep -q "\"ORBIT_KB_ROLE\": \"$r9\"" <<<"$e9"'

# DH9, DH10: the Desk path
cat >> "$h/specs/t5/kb.pl" <<'KB'
claim(c1, introduce, 'The import keeps member records').
question(q1, c1, 'Should a replay log each record that it skips').
KB
HT="python3 -I $(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/desk_http.py"
P=$(python3 -c "import socket; s=socket.socket(); s.bind(('127.0.0.1', 0)); print(s.getsockname()[1])")
( cd "$h" && XDG_CACHE_HOME="$T/cache" exec timeout 600 "$ROOT/kb/bin/orbit-kb" serve desk --port $P ) >"$T/srv.out" 2>"$T/srv.err" </dev/null &
SRV=$!; U=""; for _ in $(seq 300); do U=$(grep -oE 'http://127\.0\.0\.1:[0-9]+' "$T/srv.out" 2>/dev/null | head -1); [ -n "$U" ] && break; sleep 0.1; done
pg=$($HT page "$U" "mh=alpha&view=everything")
qi=$(grep -oE 'name="item" value="q:[^"]*t5#q1"' <<<"$pg" | head -1 | cut -d'"' -f4); ri=$(grep -oE 'name="item" value="kbreq:[^"]*t4"' <<<"$pg" | head -1 | cut -d'"' -f4)
n0=$(starts); FAKE_SECS=4 $HT review-send "$U" "hub=$h" "item=$qi" "intent=answer" "text=DESKPATH-ANSWER yes" "tab=alpha" >/dev/null
waitfor '[ "$(starts)" -gt '"$n0"' ]' 80
check "DH9 an answer on the Desk about a KB nobody holds starts a desk agent" '[ -n "$qi" ] && [ "$(starts)" -gt "$n0" ] && grep -q "DESKPATH-ANSWER.*\"agent\"\|\"agent\".*DESKPATH-ANSWER" "$h/flow/desk/letters.jsonl"'
$HT review-send "$U" "hub=$h" "item=$ri" "intent=requirement" "text=DESKPATH-REQ new" "tab=alpha" >/dev/null
lr=$(grep DESKPATH-REQ "$h/flow/desk/letters.jsonl" | tail -1)
hk=$(printf '{"hook_event_name": "UserPromptSubmit", "session_id": "s-r", "cwd": "%s"}' "$h" | HUB_SESSION=review python3 "$h/.claude/scripts/desk.py" --hub "$h" hook 2>&1)
check "DH9 a requirement to the live review session goes to review, not to an agent" '[ -n "$ri" ] && grep -q "\"to\": \"review\"" <<<"$lr" && ! grep -q "\"agent\"" <<<"$lr" && grep -q DESKPATH-REQ <<<"$hk"'
an=$(python3 -c 'import json,sys; print([json.loads(l) for l in open(sys.argv[1]) if "DESKPATH-ANSWER" in l][-1].get("agent",""))' "$h/flow/desk/letters.jsonl")
tk=$($HT token "$U")
$HT post "$U" /agent "token=$tk" "hub=$h" "agent=$an" "intent=write" "text=DESKPATH-WORDS" "tab=alpha" >/dev/null
$D agent-stop "$an" >/dev/null 2>&1; sleep 2
codes=""; for v in waits questions answered everything agents; do codes="$codes $(curl -s -o /dev/null -w '%{http_code}' "$U/?mh=alpha&view=$v")"; done
check "DH10 after a write and a stop every view answers 200 ($codes)" '[ "$codes" = " 200 200 200 200 200" ]'
pa=$($HT page "$U" "mh=alpha&view=agents" | tr -s ' \n' ' ')
check "DH12 the view Agents says failed, with the line, on the row of the failed agent" 'grep -qE "agent-[^\"]*\" data-agent=\"$n8 [^\"]*\"><summary>.{0,400}state-failed loud\">failed \(FAILLINE-61" <<<"$pa"'
kill $SRV 2>/dev/null
# DH11: the runner is killed while claude runs
out=$(FAKE_SECS=30 send "$(kbi t6)" "Letter six."); n6=$(field "$out" agent); waitfor '[ -n "$(field "$(agent "$n6")" session_id)" ] && grep -q "Letter six" "$FAKE_LOG"' 100; sleep 1
a6=$(python3 -c 'import json,sys; a=json.load(open(sys.argv[1]))["agents"][sys.argv[2]]; print(a.get("runner") or "", a.get("claude") or "", a["session_id"])' "$h/flow/desk/agents.json" "$n6")
read -r rp cp sid6 <<<"$a6"; kill -9 "$rp" 2>/dev/null; sleep 7
$D agent-resume "$n6" >/dev/null 2>&1; rr=$?
check "DH11 runner killed, claude alive: the lock stays and a resume is refused" '[ -n "$cp" ] && kill -0 "$cp" 2>/dev/null && [ "$(lock t6)" = "$sid6" ] && [ $rr != 0 ] && [ "$(pgrep -fc "$T/bin/claude")" -le 1 ]'
$D agent-stop "$n6" >/dev/null 2>&1; sleep 1
check "DH11 a stop then ends that claude" '! kill -0 "$cp" 2>/dev/null'
# DH14 (c23, f_h6): a Desk with an unknown word
P2=$(python3 -c "import socket; s=socket.socket(); s.bind(('127.0.0.1', 0)); print(s.getsockname()[1])")
( cd "$h" && DESK_AGENTS='<i>ofdesk</i>' XDG_CACHE_HOME="$T/cache" exec timeout 300 "$ROOT/kb/bin/orbit-kb" serve desk --port $P2 ) >"$T/srv2.out" 2>"$T/srv2.err" </dev/null &
SRV2=$!; U2=""; for _ in $(seq 300); do U2=$(grep -oE 'http://127\.0\.0\.1:[0-9]+' "$T/srv2.out" 2>/dev/null | head -1); [ -n "$U2" ] && break; sleep 0.1; done
check "DH14 the Desk names the unknown word at its start" 'grep -q "DESK_AGENTS=.*ofdesk.* is not a known value" "$T/srv2.err"'
pv=""; for v in waits agents; do pv="$pv$(curl -s -m 30 "$U2/?mh=alpha&view=$v" | grep -c "banner error\">This Desk runs with DESK_AGENTS=&lt;i&gt;ofdesk&lt;/i&gt;")"; done
check "DH14 and on the default view and the view Agents, escaped ($pv)" '[ "$pv" = 11 ]'
kill $SRV2 2>/dev/null
check "DH14 the Desk of DH9 (no DESK_AGENTS) shows no such banner and says nothing at its start" '[ -n "$pg" ] && ! grep -q "This Desk runs with DESK_AGENTS" <<<"$pg" && ! grep -q "not a known value" "$T/srv.err"'
echo "desk_headless: $PASS passed, $FAIL failed"
[ $FAIL = 0 ]
