#!/usr/bin/env bash
# The Desk UX of 0.9.1 (spec KB desk-speed-orbit-door, checks k13, k14, k15; claims c3, c4, c5), in a
# headless Chromium on scratch hubs. Nothing of a real mindhole or of the real home is read or written.
# usage: kb/tests/test_desk_ux.sh [k13] [k14] [k15] [r10] [shots:OUTDIR:LABEL]        (no argument: k13 k14 k15 r10)
# env: DESK_ROOT   the checkout whose kb/bin/orbit-kb serves the Desk (default: this checkout);
#                  set it to a tree of an older revision to see a check fail (the control)
#      DESK_KEEP=1 keep the scratch directory and print its path
# Exit 0: every check held. 1: one failed. 2: the setup failed (no Chromium, no Node 22).
set -u
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P); REPO=$(cd "$HERE/../.." && pwd -P)
ROOT=${DESK_ROOT:-$REPO}
WANT=${*:-k13 k14 k15 r10}
D=$(mktemp -d "${TMPDIR:-/tmp}/desk-ux.XXXXXX") || exit 2
PIDS=""
cleanup() { for f in "$D"/*/srv.pid; do [ -f "$f" ] && PIDS="$PIDS $(cat "$f")"; done; for p in $PIDS; do kill -- -"$p" 2>/dev/null; kill "$p" 2>/dev/null; done; [ "${DESK_KEEP:-}" = 1 ] && echo "kept: $D" || rm -rf "$D"; }
trap cleanup EXIT
die() { echo "setup: $*"; exit 2; }
CB=$(command -v chromium-browser || command -v chromium || command -v google-chrome) || die "no Chromium"
ND=$(command -v node) && "$ND" -e 'process.exit(typeof WebSocket==="function"?0:1)' || die "no Node 22"
FAILS=0; OKS=0

# mkset DEST: two hubs, each with three KBs and two asks, joined to one Desk store DEST/state
mkset() {
  local dest=$1 n h i f a
  mkdir -p "$dest/home" "$dest/state"
  for n in alpha beta; do
    h="$dest/$n"
    python3 "$REPO/hubkit/tools/hubkit.py" install --hub "$h" >"$D/out" 2>&1 || die "the kit installs no hub ($(tail -1 "$D/out"))"
    ( cd "$h" && { [ -f flow/flow.db ] || python3 .claude/scripts/hubflow.py --hub "$h" init --seed flow/seed.json; } ) >"$D/out" 2>&1 || die "no ledger in $h"
    mkdir -p "$h/specs"; i=0
    for f in discovery-a valid report_review; do cp -r "$REPO/kb/tests/fixtures/$f" "$h/specs/t$i-$f"; i=$((i + 1)); done
    for a in 1 2; do
      ( cd "$h" && python3 .claude/scripts/hubflow.py --hub "$h" --session process add ask --no-kb --title "ux ask $n $a" --note 'The case. A: yes, B: no; default A.' --waits-on me ) >"$D/out" 2>&1 || die "cannot add an ask to $h"
    done
    ( cd "$h" && HOME="$dest/home" DESK_STATE="$dest/state" python3 .claude/scripts/desk.py join --name "$n" ) >"$D/out" 2>&1 || die "$h cannot join the Desk"
  done
}
# start DEST: the Desk of $ROOT on the set DEST; prints its address
start() {
  ( cd "$1/alpha" && HOME="$1/home" DESK_STATE="$1/state" XDG_CACHE_HOME="$1/cache" exec setsid timeout 900 "$ROOT/kb/bin/orbit-kb" serve desk --port 0 ) >"$1/srv.out" 2>"$1/srv.err" </dev/null &
  echo "$!" >"$1/srv.pid"   # start runs in a command substitution: the cleanup finds the server by this file
  local i=0 u
  while [ "$i" -lt 300 ]; do
    u=$(grep -oE 'http://127\.0\.0\.1:[0-9]+' "$1/srv.out" 2>/dev/null | head -n1)
    [ -n "$u" ] && { echo "$u"; return 0; }
    sleep 0.1; i=$((i + 1))
  done
  return 1
}
# browse URL SCENARIO [ARG]: one Chromium for one node scenario; the JSON of the scenario in $D/br.json
browse() {
  local prof="$D/chrome" cpid r
  rm -rf "$prof"; mkdir -p "$prof"
  "$CB" --headless --disable-gpu --no-first-run --no-default-browser-check --user-data-dir="$prof" --remote-debugging-port=0 about:blank >/dev/null 2>&1 &
  cpid=$!
  timeout 120 "$ND" "$HERE/desk_ux.js" "$prof" "$1" "$2" ${3:+"$3"} >"$D/br.json" 2>"$D/br.err"; r=$?
  kill "$cpid" 2>/dev/null; wait "$cpid" 2>/dev/null
  [ $r = 0 ] || { echo "FAIL: the browser run $2 failed: $(tail -c 400 "$D/br.err")"; FAILS=$((FAILS + 1)); return 1; }
}
# report FILE: print each check of the last JSON line and count it
report() {
  local out
  out=$(python3 -I - "$1" <<'PY'
import json, sys
last = [l for l in open(sys.argv[1]).read().splitlines() if l.strip()][-1]
for n, ok, d in json.loads(last)["checks"]:
    print(("ok   " if ok else "FAIL ") + n + ("  [" + d[:300] + "]" if (d and not ok) else ""))
PY
) || { echo "FAIL: no result"; FAILS=$((FAILS + 1)); return; }
  echo "$out"
  OKS=$((OKS + $(grep -c '^ok' <<<"$out"))); FAILS=$((FAILS + $(grep -c '^FAIL' <<<"$out")))
}
check() { if [ "$2" = ok ]; then echo "ok   $1"; OKS=$((OKS + 1)); else echo "FAIL $1  [$3]"; FAILS=$((FAILS + 1)); fi; }
hf() { local h=$1; shift; ( cd "$h" && python3 .claude/scripts/hubflow.py --hub "$h" "$@" ) 2>&1; }
# threads HUB: the ids of the open threads, one per line
threads() { hf "$1" view v_open --format tsv 2>/dev/null | awk -F'\t' 'NR>1 && $2 ~ /thread/ {print $1}' | sort; }
nthreads() { hf "$1" view v_open --format json 2>/dev/null | python3 -I -c "import json,sys; d=json.load(sys.stdin); print(sum(1 for x in d if x.get('kind')=='thread'))"; }
ids_open() { hf "$1" view v_open --format json 2>/dev/null | python3 -I -c "import json,sys; d=json.load(sys.stdin); print(' '.join(sorted(x['id'] for x in d if x.get('kind')=='thread')))"; }

SET="$D/set"; mkset "$SET"
U=$(start "$SET") || die "the Desk does not start ($(head -c 300 "$SET/srv.err"))"
echo "# the Desk of $ROOT at $U"

for w in $WANT; do
  case $w in
  k13) echo "== k13 (c3): a pair of buttons in each lane and sheet"; browse "$U" k13 && report "$D/br.json" ;;
  k14) echo "== k14 (c4): the folds and the place kept after a reload"; browse "$U" k14 && report "$D/br.json" ;;
  r10) echo "== r10 (c18 to c20): the view and the place after an action, the last view, a cold load"; browse "$U" r10 && report "$D/br.json" ;;
  k15)
    echo "== k15 (c5): New requirement"
    browse "$U" k15a && report "$D/br.json"
    A="$SET/alpha"; B="$SET/beta"
    for tab in all alpha; do :; done
    before=$(ids_open "$A"); beforeB=$(ids_open "$B")
    printf '%s' '{"hub":"alpha","text":"An idea for the resume site.\nA second line.","tab":"all","send":false}' >"$D/spec.json"
    browse "$U" k15b "$D/spec.json"
    rev=$(python3 -I -c "import json,sys; l=[x for x in open(sys.argv[1]).read().splitlines() if x.strip()][-1]; d=json.loads(l).get('review',{}); print(1 if d.get('reviewOpen') and d.get('letters') else 0)" "$D/br.json")
    [ "$rev" = 1 ] && check "the review step shows the letter before the send" ok || check "the review step shows the letter before the send" bad "$(tail -c 300 "$D/br.json")"
    [ "$(ids_open "$A")" = "$before" ] && [ "$(ids_open "$B")" = "$beforeB" ] && check "before the send the ledger is unchanged" ok || check "before the send the ledger is unchanged" bad "threads changed"
    printf '%s' '{"hub":"alpha","text":"An idea for the resume site.\nA second line.","tab":"all","send":true}' >"$D/spec.json"
    browse "$U" k15b "$D/spec.json"
    after=$(ids_open "$A"); new=$(comm -13 <(tr ' ' '\n' <<<"$before") <(tr ' ' '\n' <<<"$after") | grep . || true)
    n=$(grep -c . <<<"$new" || true)
    [ "$n" = 1 ] && check "the send adds exactly one open thread to the chosen mindhole" ok || check "the send adds exactly one open thread to the chosen mindhole" bad "new threads: [$new]"
    [ "$(ids_open "$B")" = "$beforeB" ] && check "the other mindhole is unchanged" ok || check "the other mindhole is unchanged" bad "beta changed"
    if [ "$n" = 1 ]; then
      hf "$A" show "$new" --format json >"$D/thread.json"
      python3 -I - "$D/thread.json" <<'PY' && check "owner review, desk_intake's title, note equal to the text, no ref, no link" ok || check "owner review, desk_intake's title, note equal to the text, no ref, no link" bad "$(head -c 600 "$D/thread.json")"
import json, sys
d = json.load(open(sys.argv[1]))
it = d.get("item", d)
text = "An idea for the resume site.\nA second line."
notes = [(e.get("note") or "").replace("\r\n", "\n") for e in (d.get("events") or [])]
note_ok = text in notes
title = "Ty's new requirement: An idea for the resume site. A second line."
ok = it.get("owner_session") == "review" and it.get("title") == title and note_ok and not d.get("refs") and not d.get("links") and it.get("kind") == "thread"
sys.exit(0 if ok else 1)
PY
    fi
    # an empty text sends nothing (the server refuses it too)
    tok=$(curl -s "$U/" | grep -o 'data-token="[^"]*"' | head -1 | sed 's/data-token="//;s/"//')
    code=$(curl -s -o /dev/null -w '%{http_code}' --data-urlencode "token=$tok" --data-urlencode "hub=$A" --data-urlencode "item=new" --data-urlencode "intent=requirement" --data-urlencode "text=   " --data-urlencode "to_0=review" --data-urlencode "letter_0=x" "$U/send")
    [ "$code" = 400 ] && [ "$(ids_open "$A")" = "$after" ] && check "an empty text sent to the server adds nothing (HTTP $code)" ok || check "an empty text sent to the server adds nothing" bad "HTTP $code"
    # intake from the card of an ask still links to the ask
    ask=$(hf "$A" view v_open --format json | python3 -I -c "import json,sys; print([x['id'] for x in json.load(sys.stdin) if x.get('kind')=='ask'][0])")
    pre=$(ids_open "$A")
    curl -s -o /dev/null --data-urlencode "token=$tok" --data-urlencode "hub=$A" --data-urlencode "item=ask:$ask" --data-urlencode "intent=requirement" --data-urlencode "text=From the card of $ask" --data-urlencode "to_0=review" --data-urlencode "letter_0=From the card" "$U/send"
    new2=$(comm -13 <(tr ' ' '\n' <<<"$pre") <(tr ' ' '\n' <<<"$(ids_open "$A")") | grep . || true)
    if [ -n "$new2" ] && hf "$A" show "$new2" --format json | grep -q "$ask"; then check "intake from the card of an ask still links the thread to the ask" ok
    else check "intake from the card of an ask still links the thread to the ask" bad "new=[$new2]"; fi
    ;;
  shots:*) # shots:OUTDIR:LABEL : screenshots of the Desk of $ROOT (the evidence of release 0.9.1)
    o=${w#shots:}; SHOT_LABEL=${o##*:}; export SHOT_LABEL; browse "$U" shots "${o%:*}" && echo "ok   screenshots $SHOT_LABEL in ${o%:*}" ;;
  *) echo "no check $w" ;;
  esac
done
echo "desk_ux: $OKS ok, $FAILS failed."
[ "$FAILS" = 0 ]
