#!/usr/bin/env bash
# Black-box tests for the proposals of System 1 in kb/bin/orbit-kb (CONTRACT.md D70, D71;
# scientific-method-overhaul c34, k34). Same style as test_orbit_kb.sh, with its small helpers
# copied: each test runs in a fresh temp directory; facts are read back with a query.
#
# Usage: kb/tests/test_proposals.sh [path-to-orbit-kb]     ONLY='<regex>' runs the tests that match.
# Exit status: 0 when every test passes, 1 when a test fails, 2 when the suite cannot run.
set -u
here=$(cd "$(dirname "$0")" && pwd)
BIN=${1:-${ORBIT_KB_BIN:-$here/../bin/orbit-kb}}
export ORBIT_KB_LIB=${ORBIT_KB_TEST_LIB:-$here/../share/orbit-kb}
[ -x "$BIN" ] && [ -f "$ORBIT_KB_LIB/core.pl" ] || { echo "cannot run: no CLI or library" >&2; exit 2; }
command -v swipl >/dev/null || { echo "cannot run: no swipl" >&2; exit 2; }
unset ORBIT_KB ORBIT_KB_WRITER HUB_SESSION CLAUDE_CODE_SESSION_ID CLAUDE_SESSION_ID
base=$(mktemp -d); trap 'rm -rf "$base"' EXIT
pass=0; fail=0; failed=(); FAILS=()
ok()   { pass=$((pass+1)); echo "PASS $1 $2"; }
bad()  { fail=$((fail+1)); failed+=("$1"); echo "FAIL $1 $2"; local m; for m in "${@:3}"; do echo "     - $m"; done; }
note() { FAILS+=("$*"); }
snip() { printf '%s' "$1" | head -c 300 | tr '\n' '~'; }
okb()  { out=$(cd "$T" && XDG_CACHE_HOME="$T/.cache" "$BIN" --dir "$K" "$@" 2>"$T/err"); rc=$?; err=$(cat "$T/err"); }
rc_is()    { [ "$rc" -eq "$1" ] && return 0; note "${2:+$2: }exit $rc, want $1; out: $(snip "$out") err: $(snip "$err")"; return 1; }
out_has()  { printf '%s\n' "$out" | grep -Eq -- "$1" && return 0; note "${2:+$2: }stdout has no line that matches: $1; out: $(snip "$out")"; return 1; }
any_has()  { printf '%s\n%s\n' "$out" "$err" | grep -Eq -- "$1" && return 0; note "${2:+$2: }no line matches: $1; out: $(snip "$out") err: $(snip "$err")"; return 1; }
is_true()  { okb query "$1"; rc_is 0 "query '$1' must hold"; }
is_false() { okb query "$1"; rc_is 1 "query '$1' must have no answer"; }
answers()  { okb query "$1" -n 0; printf '%s|%s\n' "$rc" "$out"; }
run_test() {  # run_test FUNC ID DESCRIPTION
  [ -n "${ONLY:-}" ] && ! [[ $2 =~ $ONLY ]] && return 0
  T=$(mktemp -d "$base/t.XXXXXX"); K=$T/k; FAILS=()
  ( cd "$T" && "$BIN" init k --request 'Keep the export sorted.' --uses discovery,build >/dev/null 2>&1 ) || note "init failed"
  ( cd "$T" && "$BIN" --dir k add "hypothesis(h1, feature, 'The export is sorted by date.')" "no_premises(h1)" >/dev/null 2>&1 ) || note "setup add failed"
  "$1"
  if [ ${#FAILS[@]} -eq 0 ]; then ok "$2" "$3"; else bad "$2" "$3" "${FAILS[@]}"; fi
}
Q="question(q9, h1, 'Which sort order is wanted?')"

# D70: propose stores proposed(P, system1, FactText, Time), and the note
t_p1() {
  okb propose --from system1 "$Q" --note 'System 1: a request of kind answer'; rc_is 0 "propose"
  any_has 'pr1' "the id is named"
  is_true "proposed(pr1, system1, F, T)"
  is_true "note(pr1, 'System 1: a request of kind answer')"
  is_false "question(q9, _, _)"   # a proposal is not a record
}
# D70: only System 1 proposes; a fact that does not parse is refused; nothing is written
t_p2() {
  okb propose "$Q"; rc_is 2 "no --from"
  okb propose --from agent "$Q"; rc_is 2 "--from agent"
  okb propose --from system1 "question(q9, "; rc_is 2 "a fact that does not parse"
  okb propose --from system1; rc_is 2 "no fact"
  is_false "proposed(_, _, _, _)"
}
# D70 (k34): a proposal changes no answer of done, blocking(X) or discovery_ready
t_p3() {
  local d0 b0 r0
  d0=$(answers done); b0=$(answers 'blocking(X)'); r0=$(answers discovery_ready)
  okb propose --from system1 "$Q"; rc_is 0
  okb propose --from system1 "claim(c9, introduce, 'The export is sorted by date.')"; rc_is 0
  [ "$(answers done)" = "$d0" ] || note "done changed"
  [ "$(answers 'blocking(X)')" = "$b0" ] || note "blocking(X) changed: $b0 -> $(answers 'blocking(X)')"
  [ "$(answers discovery_ready)" = "$r0" ] || note "discovery_ready changed"
  okb lint; any_has . ; printf '%s\n%s\n' "$out" "$err" | grep -Eq 'E[0-9]+' && note "lint reports an error: $(snip "$out")"
}
# D70: the same open proposal is stored once
t_p4() {
  okb propose --from system1 "$Q"; rc_is 0
  okb propose --from system1 "$Q"; rc_is 0; out_has 'pr1 already holds this proposal'
  okb query 'proposed(P, _, _, _)' -n 0; [ "$(printf '%s\n' "$out" | grep -c 'pr')" -eq 1 ] || note "two proposals stored: $(snip "$out")"
  okb propose --from system1 "note(h1, 'another')"; rc_is 0; is_true "proposed(pr2, _, _, _)"
}
# D71: confirm-proposal adds the fact through add and records who confirmed
t_c1() {
  okb propose --from system1 "$Q"; rc_is 0
  okb confirm-proposal pr1 --by human; rc_is 0 "confirm"
  is_true "question(q9, h1, 'Which sort order is wanted?')"
  is_true "proposal_confirmed(pr1, human, T)"
  okb confirm-proposal pr1; rc_is 1 "a second confirm"; any_has 'confirmed already'
}
# D71: the default writer is the agent; an unknown id and a bad --by are refused
t_c2() {
  okb propose --from system1 "$Q"; rc_is 0
  okb confirm-proposal pr7; rc_is 1 "an unknown id"; any_has 'No proposal pr7'
  okb confirm-proposal pr1 --by system1; rc_is 2 "--by system1"
  okb confirm-proposal pr1; rc_is 0; is_true "proposal_confirmed(pr1, agent, T)"
}
# D71: the usual checks of add hold: a fact that add refuses is not written, and the proposal waits
t_c3() {
  okb propose --from system1 "question(q9, no_such_id, 'Which?')"; rc_is 0 "propose keeps the text"
  okb confirm-proposal pr1; rc_is 1 "add refuses the fact"
  is_false "question(q9, _, _)"; is_false "proposal_confirmed(pr1, _, _)"
  okb show proposals; out_has 'waits'
}
# D71: show proposals lists each with its source, its note and its state
t_s1() {
  okb show proposals; rc_is 0; out_has '^No proposals\.$'
  okb propose --from system1 "$Q" --note 'System 1: kind answer; serves no goal'; rc_is 0
  okb propose --from system1 "note(h1, 'second')"; rc_is 0
  okb confirm-proposal pr2; rc_is 0
  okb show proposals; rc_is 0
  out_has '^pr1 \(system1, .*\): question\(q9' ; out_has 'System 1: kind answer; serves no goal'
  out_has 'waits; it blocks nothing\. Confirm: orbit-kb confirm-proposal pr1'
  out_has 'confirmed by the agent'
}
# D71 with the records of 0.8.0 (c34): a goal and a hypothesis that System 1 proposed in the words
# of the human become records of the human on confirm
t_c4() {
  okb propose --from system1 "goal(s1_g1a2b3c4d, change, human, 'The export keeps its rows sorted.')"; rc_is 0
  okb confirm-proposal pr1; rc_is 0 "confirm a goal/4"
  is_true "goal(s1_g1a2b3c4d, change, human, 'The export keeps its rows sorted.')"
  okb propose --from system1 "hypothesis(s1_h1a2b3c4d, s1_g1a2b3c4d, human, 'Sorting in the query is enough.')" --note 'System 1: a request of kind hypothesis'; rc_is 0
  is_false "hypothesis(s1_h1a2b3c4d, _, _, _)"
  okb confirm-proposal pr2 --by human; rc_is 0 "confirm a hypothesis/4"
  is_true "hypothesis(s1_h1a2b3c4d, s1_g1a2b3c4d, human, 'Sorting in the query is enough.')"
  is_true "proposal_confirmed(pr2, human, T)"
}
# D71: the usage line of show names proposals
t_s2() { okb show nothing; rc_is 2; any_has 'proposals'; }
run_test t_p1 P1 "propose stores the proposal with its source and its note; it is no record"
run_test t_p2 P2 "propose is for System 1 only, and refuses a fact that does not parse"
run_test t_p3 P3 "a proposal changes no answer of done, blocking(X) or discovery_ready"
run_test t_p4 P4 "the same open proposal is stored once"
run_test t_c1 C1 "confirm-proposal makes the record and says who confirmed; once"
run_test t_c2 C2 "confirm-proposal: the agent by default; unknown id and bad --by refused"
run_test t_c3 C3 "confirm-proposal keeps the checks of add"
run_test t_s1 S1 "show proposals"
run_test t_c4 C4 "confirm-proposal accepts a goal/4 and a hypothesis/4 proposal"
run_test t_s2 S2 "the usage of show lists proposals"
echo "$pass passed, $fail failed${failed[*]:+: ${failed[*]}}"
[ "$fail" -eq 0 ]
