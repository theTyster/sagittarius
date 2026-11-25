#!/usr/bin/env bash
# The Desk by store (spec KB desk-speed-orbit-door: checks k16 k17 k18 k19 k20 for claims c13 c14 c15 c16
# c17; and k13 k14 again at each depth: store, group, KB sheet, layer). Scratch hubs only: nothing of a
# real mindhole or of the real home is read or written.
# usage: kb/tests/test_desk_stores.sh [k13] [k14] [k16] [k17] [k18] [k19] [k20] [shots:OUTDIR]   (none: all checks)
# env: DESK_ROOT  the checkout whose Desk is tested (default: this checkout); set it to a tree of 0.9.1
#                 (5549830) to see the checks fail (the control)
#      DESK_BASE  the tree of the Desk of 0.9.1 that k17, k18 and k19 compare with (default: git archive
#                 5549830 of this repo into the scratch directory)
#      DESK_KEEP=1 keep the scratch directory
#      (the Desk is started with DESK_ROWS=2, so that a group of three rows or more shows its step)
# Exit 0: every check held. 1: one failed. 2: the setup failed (no Chromium, no Node 22, no base).
set -u
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P); REPO=$(cd "$HERE/../.." && pwd -P)
ROOT=${DESK_ROOT:-$REPO}
WANT=${*:-k13 k14 k16 k17 k18 k19 k20}
D=$(mktemp -d "${TMPDIR:-/tmp}/desk-stores.XXXXXX") || exit 2
PIDS=""
cleanup() { for p in $PIDS $(cat "$D/pids" 2>/dev/null); do kill $(pgrep -P "$p") "$p" 2>/dev/null; done; [ "${DESK_KEEP:-}" = 1 ] && echo "kept: $D" || rm -rf "$D"; }
trap cleanup EXIT
die() { echo "setup: $*"; exit 2; }
CB=$(command -v chromium-browser || command -v chromium || command -v google-chrome) || die "no Chromium"
ND=$(command -v node) && "$ND" -e 'process.exit(typeof WebSocket==="function"?0:1)' || die "no Node 22"
FAILS=0; OKS=0
BASE=${DESK_BASE:-}
if [ -z "$BASE" ]; then
  BASE="$D/base"; mkdir -p "$BASE"
  git -C "$REPO" archive 5549830 | tar -x -C "$BASE" || die "no tree of 5549830 (set DESK_BASE)"
fi
[ -x "$BASE/kb/bin/orbit-kb" ] || die "no kb/bin/orbit-kb in $BASE"

hf() { local h=$1; shift; ( cd "$h" && python3 .claude/scripts/hubflow.py --hub "$h" "$@" ) 2>/dev/null; }

# kbfile DIR: a KB from stdin
kbfile() { mkdir -p "$1"; cat > "$1/kb.pl"; }

# mkset DEST: the hubs alpha and beta, joined to one Desk store DEST/state.
#  alpha: a project KB with the repos rone and rtwo and a proposed decision; spec KBs s-one-a (repos rone,
#  then rtwo: a question, a question with a default, a proposed hypothesis, a visual claim with a demo),
#  s-one-b (rone: a question with a default), s-two (rtwo), s-none (no repo: discovery-a, which has a
#  vote); asks: two with no KB, one reserved by a policy, one with kb:s-one-a, one closed; a thread of build
#  with kb:s-one-a.  beta: one fixture KB and one ask.
mkset() {
  local dest=$1 n h d
  mkdir -p "$dest/home" "$dest/state"
  for n in alpha beta; do
    h="$dest/$n"
    python3 "$REPO/hubkit/tools/hubkit.py" install --hub "$h" >"$D/out" 2>&1 || die "the kit installs no hub ($(tail -1 "$D/out"))"
    ( cd "$h" && { [ -f flow/flow.db ] || python3 .claude/scripts/hubflow.py --hub "$h" init --seed flow/seed.json; } ) >"$D/out" 2>&1 || die "no ledger in $h"
  done
  h="$dest/alpha"
  kbfile "$h/project-kb" <<'EOF'
uses([project]).
request(r1, 'Import members safely').
repo(rone, '/srv/rone').
repo(rtwo, '/srv/rtwo').
decision(dec_replay, 'A replay never changes a member record.').
decided_by(dec_replay, agent, '2026-11-20T10:00:00Z').
EOF
  printf '%s\n' "$h/specs/s-one-a" "$h/specs/s-one-b" "$h/specs/s-two" > "$h/project-kb/spec_kbs.txt"
  mkdir -p "$h/specs/s-one-a"; printf 'png' > "$h/specs/s-one-a/shot.png"
  d=$(sha256sum "$h/specs/s-one-a/shot.png" | cut -d' ' -f1)
  kbfile "$h/specs/s-one-a" <<EOF
uses([build, project]).
project_kb('../../project-kb').
repo(rone, '/srv/rone').
repo(rtwo, '/srv/rtwo').
request(r1, 'Replays must be safe').
goal(g1, defect, human:'Ty', 'A replayed import leaves the member records as one clean run would.').
premise(p1, g1, 'The import file has one record per line.').
hypothesis(hy2, g1, agent, 'Skipping only a record that equals the stored one makes a replay safe.').
defeating_case(hy2, agent, 'A replay that changes a member record.').
claim(c1, introduce, 'After a replay the member count equals the count of one clean run').
cites(c1, 'Replays must be safe').
predicts(hy2, c1).
check(k1, c1).
checks_that(k1, 'the member count after a replay of the November file').
attest(a3, test_result, 'runs/1-k1.log', result(k1, 1, pass), script, '2026-11-23T11:00:00Z').
claim(c2, introduce, 'The import pane uses three colors at most').
cites(c2, 'Replays must be safe').
example(c2, 'The idle pane shows grey, green and amber only.').
predicts(hy2, c2).
visual(c2).
subject(shot, 'shot.png', 'sha256:$d').
demo(shot, c2).
question(q1, c1, 'Should a replay log each record that it skips').
question(q2, c1, 'Should a replay stop at the first error').
assumed(q2, no).
option(q2, no, 'Go on with the next record').
option(q2, yes, 'Stop the replay').
EOF
  kbfile "$h/specs/s-one-b" <<'EOF'
uses([build, project]).
project_kb('../../project-kb').
repo(rone, '/srv/rone').
request(r1, 'Exports run nightly').
claim(c1, preserve, 'The export runs each night').
cites(c1, 'Exports run nightly').
question(q1, c1, 'Does the export skip holidays').
assumed(q1, no).
EOF
  kbfile "$h/specs/s-two" <<'EOF'
uses([build, project]).
project_kb('../../project-kb').
repo(rtwo, '/srv/rtwo').
request(r1, 'Retries are bounded').
claim(c1, preserve, 'A retry stops after five tries').
cites(c1, 'Retries are bounded').
EOF
  mkdir -p "$h/specs/s-none"; cp "$REPO/kb/tests/fixtures/discovery-a/kb.pl" "$h/specs/s-none/kb.pl"
  hf "$h" --session process add ask --no-kb --title 'stores ask one' --note 'The case. A: yes, B: no; default A.' --waits-on me >/dev/null || die "no ask"
  hf "$h" --session process add ask --no-kb --title 'stores ask two' --note 'The case. A: yes, B: no; default A.' --waits-on me >/dev/null
  hf "$h" --session process add ask --no-kb --title 'Push the hub' --note 'Only Ty pushes.' --waits-on me --reserved 'MindHole Policy: Outbound text is staged, never sent by an agent; a human sends.' >/dev/null
  KBASK=$(hf "$h" --session build add ask --ref kb:s-one-a --title 'stores ask about s-one-a' --note 'The case of the KB. A or B; default A.' --waits-on me)
  KBTHR=$(hf "$h" --session build add thread --ref kb:s-one-a --owner build --title 'stores thread on s-one-a' --note 'Build works on it.')
  CLOSED=$(hf "$h" --session process add ask --no-kb --title 'stores ask closed' --note 'Answered.' --waits-on me)
  hf "$h" --session process close "$CLOSED" --reason done --note 'Ty answered: yes.' >/dev/null || die "cannot close $CLOSED"
  [ -n "$KBASK" ] && [ -n "$KBTHR" ] && [ -n "$CLOSED" ] || die "the ledger of alpha took no kb ask, thread or closed ask"
  echo "$KBASK $KBTHR $CLOSED" > "$dest/ids"
  h="$dest/beta"
  mkdir -p "$h/specs/b-valid"; cp "$REPO/kb/tests/fixtures/valid/kb.pl" "$h/specs/b-valid/kb.pl"
  hf "$h" --session process add ask --no-kb --title 'stores ask of beta' --note 'The case. A or B.' --waits-on me >/dev/null
  for n in alpha beta; do
    ( cd "$dest/$n" && HOME="$dest/home" DESK_STATE="$dest/state" python3 .claude/scripts/desk.py join --name "$n" ) >"$D/out" 2>&1 || die "$n cannot join the Desk"
  done
}
# start TREE SET NAME: the Desk of TREE on the set SET; prints its address
start() {
  ( cd "$2/alpha" && HOME="$2/home" DESK_STATE="$2/state" XDG_CACHE_HOME="$2/cache-$3" DESK_ROWS=2 exec timeout 1800 "$1/kb/bin/orbit-kb" serve desk --port 0 ) >"$2/$3.out" 2>"$2/$3.err" </dev/null &
  echo "$!" >> "$D/pids"        # start runs in $(...): the pid goes to a file that cleanup reads
  local i=0 u
  while [ "$i" -lt 300 ]; do
    u=$(grep -oE 'http://127\.0\.0\.1:[0-9]+' "$2/$3.out" 2>/dev/null | head -n1)
    [ -n "$u" ] && { echo "$u"; return 0; }
    sleep 0.1; i=$((i + 1))
  done
  return 1
}
browse() {
  local prof cpid r
  prof=$(mktemp -d /tmp/desk-chrome.XXXXXX) || return 1   # short: Chromium keeps a socket in it
  TMPDIR=/tmp "$CB" --headless --disable-gpu --no-first-run --no-default-browser-check --user-data-dir="$prof" --remote-debugging-port=0 about:blank >/dev/null 2>&1 &
  cpid=$!
  timeout 300 "$ND" "$HERE/desk_ux.js" "$prof" "$1" "$2" ${3:+"$3"} >"$D/br.json" 2>"$D/br.err"; r=$?
  kill "$cpid" 2>/dev/null; wait "$cpid" 2>/dev/null; sleep 0.3; rm -rf "$prof" 2>/dev/null
  [ $r = 0 ] || { echo "FAIL: the browser run $2 failed: $(tail -c 400 "$D/br.err")"; FAILS=$((FAILS + 1)); return 1; }
}
report() {
  local out
  out=$(python3 -I - "$1" <<'PY'
import json, sys
lines = [l for l in open(sys.argv[1]).read().splitlines() if l.strip().startswith("{")]
for n, ok, d in json.loads(lines[-1])["checks"]:
    print(("ok   " if ok else "FAIL ") + n + ("  [" + d[:400] + "]" if (d and not ok) else ""))
PY
) || { echo "FAIL: no result ($(tail -c 300 "$1"))"; FAILS=$((FAILS + 1)); return; }
  echo "$out"
  OKS=$((OKS + $(grep -c '^ok' <<<"$out"))); FAILS=$((FAILS + $(grep -c '^FAIL' <<<"$out")))
}
py() { python3 -I "$HERE/desk_stores.py" "$@" >"$D/py.json" 2>"$D/py.err" || { echo "FAIL: desk_stores.py $1: $(tail -c 300 "$D/py.err")"; FAILS=$((FAILS + 1)); return 1; }; }

SET="$D/set"; mkset "$SET"
read -r KBASK KBTHR CLOSED < "$SET/ids"
U=$(start "$ROOT" "$SET" new) || die "the Desk does not start ($(head -c 300 "$SET/new.err"))"
echo "# the Desk of $ROOT at $U; 0.9.1 from $BASE"
UO=""
need_old() { [ -n "$UO" ] || UO=$(start "$BASE" "$SET" old) || die "the Desk of 0.9.1 does not start"; }
# the scenario file of the browser checks
cat > "$D/spec.json" <<EOF
{"tab": "alpha", "kbask": "$KBASK", "kbthr": "$KBTHR", "closed": "$CLOSED", "kb": "s-one-a"}
EOF

for w in $WANT; do
  case $w in
  k13) echo "== k13 (c3) at each depth: store, group, KB sheet, layer"; browse "$U" k13 "$D/spec.json" && report "$D/br.json" ;;
  k14) echo "== k14 (c4) at each depth, with a view and a step that shows more rows"; browse "$U" k14 "$D/spec.json" && report "$D/br.json" ;;
  k16) echo "== k16 (c13): the stores are the sections; the views narrow them"; browse "$U" k16 "$D/spec.json" && report "$D/br.json" ;;
  k20) echo "== k20 (c17): one layer Questions with Open questions and Has a default"; browse "$U" k20 "$D/spec.json" && report "$D/br.json" ;;
  k17)
    echo "== k17 (c14): the spec KBs grouped by repo"; need_old
    printf '%s' '{"groups": {"rone": ["s-one-a", "s-one-b"], "rtwo": ["s-two"], "No repo": ["s-none"]}, "second": ["s-one-a", "rtwo"]}' >"$D/k17.json"
    py k17 "$U" "$UO" alpha "$D/k17.json" && report "$D/py.json" ;;
  k18)
    echo "== k18 (c15): every form on one KB is in its sheet and writes the record of 0.9.1"
    # two equal copies of the set: 0.9.1 writes into one, this Desk into the other
    rm -rf "$D/s18o" "$D/s18n"; cp -a "$SET" "$D/s18o"; cp -a "$SET" "$D/s18n"
    for c in s18o s18n; do
      rm -rf "$D/$c/state" && mkdir -p "$D/$c/state"
      for n in alpha beta; do ( cd "$D/$c/$n" && HOME="$D/$c/home" DESK_STATE="$D/$c/state" python3 .claude/scripts/desk.py join --name "$n" ) >/dev/null 2>&1; done
    done
    U18o=$(start "$BASE" "$D/s18o" old) || die "no Desk of 0.9.1 on the copy"
    U18n=$(start "$ROOT" "$D/s18n" new) || die "no Desk on the copy"
    python3 -I - "$D" "$KBASK" "$KBTHR" >"$D/k18.json" <<'PY'
import json, sys
d, a, t = sys.argv[1:4]
o, n = d + "/s18o", d + "/s18n"
print(json.dumps({"kb": "s-one-a", "anchor": "kb-alpha-s-one-a", "dir_old": o + "/alpha/specs/s-one-a", "dir_new": n + "/alpha/specs/s-one-a",
  "ledger_ids": [a, t], "want_kinds": ["act", "adopt", "ask", "judge", "led", "q"],
  "roots_old": [[o, "SET"]], "roots_new": [[n, "SET"]],
  "watch_old": [o + "/alpha/specs", o + "/alpha/flow", o + "/state"], "watch_new": [n + "/alpha/specs", n + "/alpha/flow", n + "/state"]}))
PY
    # the KB-level requirement: its ledger record equals that of the requirement of a question card of 0.9.1
    py kbreq "$U18o" "$U18n" alpha "$D/k18.json" && report "$D/py.json"
    py k18 "$U18o" "$U18n" alpha "$D/k18.json" && report "$D/py.json"
    ;;
  k19) echo "== k19 (c16): no item lost (each tab)"; need_old; py k19 "$UO" "$U" alpha beta all && report "$D/py.json" ;;
  shots:*) o=${w#shots:}; browse "$U" shots2 "$o" && echo "ok   screenshots in $o" ;;
  *) echo "no check $w" ;;
  esac
done
echo "desk_stores: $OKS ok, $FAILS failed."
[ "$FAILS" = 0 ]
