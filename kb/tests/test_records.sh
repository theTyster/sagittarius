#!/usr/bin/env bash
# Black-box tests of the records of 0.8.0 (scientific-method-overhaul, stage 1; CONTRACT D50 to D54):
# the goal, the hypotheses under it, their states, predictions, and what a record rests on.
# Claims of the ticket: c1 c2 c3 c4 c21 c37 c38 c43. The test ids name the claim: R<claim>-<what>.
#
# Usage: kb/tests/test_records.sh [path-to-orbit-kb]     ONLY='<regex>' runs the matching groups.
# Exit: 0 all pass, 1 a check failed. Prints `pass=N fail=N`.
#
# A "new" KB (made by orbit-kb 0.8.0 or later) is made through a copy of the library whose
# VERSION file holds 0.8.0 (ORBIT_KB_LIB), so init writes "% Made by orbit-kb 0.8.0.". The tests
# work the same when the VERSION of the repository is 0.8.0. An "old" KB has the line of 0.7.2.
set -u
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
CLI=${1:-${ORBIT_KB_BIN:-$here/../bin/orbit-kb}}
LIB=$(cd "$here/../share/orbit-kb" && pwd -P)
T=$(mktemp -d "${TMPDIR:-/tmp}/records-test.XXXXXX") || exit 2
trap 'rm -rf "$T"' EXIT
cp -rL "$LIB" "$T/lib"; printf '0.8.0\n' > "$T/lib/VERSION"
for v in $(env | sed -n 's/^\(ORBIT_KB[A-Z_]*\)=.*/\1/p'); do unset "$v"; done
unset CLAUDE_CODE_SESSION_ID CLAUDE_SESSION_ID HUB_SESSION
unset CLAUDECODE AI_AGENT   # review U9: in an agent session, judge and adopt --by human need --note
export ORBIT_KB_LIB=$T/lib XDG_CACHE_HOME=$T/.cache ORBIT_KB_NO_CACHE=1
pass=0 fail=0
ok()  { pass=$((pass+1)); echo "PASS $1"; }
bad() { fail=$((fail+1)); echo "FAIL $1: $2"; }
out="" err="" rc=0 K=""
okb() { out=$("$CLI" --dir "$K" "$@" 2>"$T/err" </dev/null); rc=$?; err=$(cat "$T/err"); }
has()  { case "$out" in *"$2"*) ok "$1";; *) bad "$1" "no [$2] in: $(printf '%s' "$out" | head -c 400)";; esac; }
hasnt(){ case "$out" in *"$2"*) bad "$1" "[$2] in: $(printf '%s' "$out" | head -c 400)";; *) ok "$1";; esac; }
ehas() { case "$err" in *"$2"*) ok "$1";; *) bad "$1" "no [$2] on stderr: $(printf '%s' "$err" | head -c 300)";; esac; }
rcis() { [ "$rc" = "$2" ] && ok "$1" || bad "$1" "exit $rc, want $2: $(printf '%s %s' "$out" "$err" | head -c 300)"; }
is()   { [ "$out" = "$2" ] && ok "$1" || bad "$1" "got [$out], want [$2]"; }
want() { [ -z "${ONLY:-}" ] || printf '%s' "$1" | grep -Eq "$ONLY"; }
newkb() { K=$T/$1; "$CLI" init "$K" --request 'Make a replayed import safe' --uses "${2:-build}" >/dev/null 2>&1; }
oldkb() { K=$T/$1; mkdir -p "$K"; printf "uses([%s]).\nrequest(r1, 'r').\n%% Made by orbit-kb 0.7.2.\n" "${2:-build}" > "$K/kb.pl"; }
GOAL="goal(g1, feature, human, 'A replayed import leaves the member records as one clean run would.')"
HA="hypothesis(hya, g1, human, 'Skipping each record ID that was seen before makes a replay safe.')"
HB="hypothesis(hyb, g1, agent, 'Skip only a record that equals the stored one.')"
replay() { # the ticket "replayed imports": goal g1; hya with claim c1 and check k1; preserve claim c2 with k2
    newkb "$1" "${2:-build}"
    okb add "$GOAL" "supports(g1, project(pg1))" 'no_premises(g1)' "$HA" \
        "defeating_case(hya, agent, 'A correction arrives under a seen ID and is discarded.')" \
        "claim(c1, introduce, 'After a replay the member count equals the count of one clean run.')" 'predicts(hya, c1)' \
        'check(k1, c1)' "checks_that(k1, 'the member count after a replay')" \
        "claim(c2, preserve, 'The notification count stays as it is today.')" \
        'check(k2, c2)' "checks_that(k2, 'the notification count')"
}

if want c1; then
    replay c1; rcis Rc1-add-goal-and-hypothesis 0
    okb show; rcis Rc1-show 0
    first=$(printf '%s\n' "$out" | head -1)
    [ "$first" = "Goal g1 (the human): A replayed import leaves the member records as one clean run would." ] \
        && ok Rc1-show-goal-first || bad Rc1-show-goal-first "first line: $first"
    printf '%s\n' "$out" | awk '/^Goal g1 \(the human\)/{g=NR} /^  Hypothesis hya \(the human, proposed\)/{h=NR} /^Claims:/{c=NR} END{exit !(g && h>g && c>h)}' \
        && ok Rc1-show-hypothesis-under-goal || bad Rc1-show-hypothesis-under-goal "$(printf '%s' "$out" | head -c 300)"
    okb show hypotheses; has Rc1-show-hypotheses "  Hypothesis hya (the human, proposed): Skipping each record ID"
    has Rc1-show-predictions "    Predictions: c1."
    okb report; has Rc1-report-goal "  - Goal g1 (the human): A replayed import"
    has Rc1-report-hypothesis "    - Hypothesis hya (the human, proposed): Skipping"
    okb add "hypothesis(hyz, g9, agent, 'No goal.')"; rcis Rc1-hypothesis-without-goal-refused 1
    printf '%s %s' "$out" "$err" | grep -q 'g9 is not the id of any goal fact' && ok Rc1-refusal-names-goal || bad Rc1-refusal-names-goal "$err"
    printf "hypothesis(hyz, g9, agent, 'No goal.').\n" >> "$K/kb.pl"
    okb lint; rcis Rc1-lint-hypothesis-without-goal 1; has Rc1-lint-names-it "hypothesis/4 argument 2: g9 is not the id of any goal fact"
fi

if want c2; then
    replay c2; okb add "$HB" "defeat(d1, hya, 'A correction arrives under a seen ID and is discarded.')"; rcis Rc2-defeat 0
    okb adopt hyb --by human --note 'go with B'; rcis Rc2-adopt 0
    okb query 'hypothesis_state(H, S)' -n 0; is Rc2-states "H = hya, S = defeated
H = hyb, S = adopted"
    okb query 'hypothesis_current(H)' -n 0; is Rc2-only-adopted-current "H = hyb"
    okb show hypotheses; has Rc2-show-defeated "Hypothesis hya (the human, defeated)"
    has Rc2-case-stays "    Defeated by case d1: A correction arrives under a seen ID and is discarded."
    has Rc2-show-adopted "Hypothesis hyb (the agent, adopted)"
    okb add "hypothesis(hyc, g1, agent, 'B, reworded.')" 'supersedes(hyc, hyb)'; rcis Rc2-supersede 0
    okb query 'hypothesis_state(hyb, S)'; is Rc2-superseded "S = superseded"
    okb query 'defeat(D, hya, T)'; has Rc2-case-on-version "D = d1"
    okb adopt hyc; rcis Rc2-agent-cannot-adopt 1
    okb add "premise(p1, hyc, 'Record IDs are stable.')"; rcis Rc2-premise-on-hypothesis 0
fi

if want c3; then
    newkb c3; okb add "goal(g1, feature, human, 'Dark mode.')" \
        "hypothesis(hy1, g1, agent, 'Dark mode will feel better.')" \
        "hypothesis(hy2, g1, agent, 'With dark mode on, every screen shows a dark scheme.')" \
        "defeating_case(hy2, agent, 'The reports page stays light.')"
    okb query 'not_tempered(H)' -n 0; is Rc3-not-tempered-listed "H = hy1"
    okb query 'tempered(H)' -n 0; is Rc3-tempered "H = hy2"
    okb lint; has Rc3-W13 "W13 hy1"; hasnt Rc3-W13-not-tempered-one "W13 hy2"
    okb add "untempered(hy2, human, 'The case is not admissible.')"
    okb query 'not_tempered(H)' -n 0; is Rc3-untempered-listed "H = hy1
H = hy2"
    okb add "hypothesis(hy3, g1, agent, 'Every screen but reports shows a dark scheme.')" "defeating_case(hy3, agent, 'Settings stays light.')" 'supersedes(hy3, hy2)'
    okb query 'not_tempered(H)' -n 0; is Rc3-untempered-until-superseded "H = hy1"
fi

if want c4; then
    newkb c4; okb add "goal(g1, feature, agent, 'The app has a dark mode.')" "hypothesis(hy1, g1, agent, 'A dark scheme on every screen is a dark mode.')" \
        "hypothesis(hy2, g1, human:ty, 'Follow the system setting.')"
    okb query 'goal(g1, K, A, T)'; has Rc4-goal-author "A = agent"
    okb query 'hypothesis(hy2, G, A, T)'; has Rc4-human-word-for-word "A = human:ty, T = 'Follow the system setting.'"
    okb query 'hypothesis_guess(H)' -n 0; is Rc4-guess "H = hy1"
    okb report; has Rc4-report-guess "  - Hypothesis hy1 (agent-written, not adopted): A dark scheme on every screen is a dark mode."
    hasnt Rc4-human-written-no-guess "not adopted): Follow the system setting"
    okb adopt hy1 --by human
    okb report; hasnt Rc4-adopted-no-guess "agent-written, not adopted"
fi

if want c21; then
    oldkb c21; printf "hypothesis(h5, feature, 'The Desk answers each page and action within one second.').\npremise(p1, h5, 'The Desk runs on this machine.').\nclaim(c1, introduce, 'A GET answers in one second.').\n" >> "$K/kb.pl"
    before=$(cat "$K/kb.pl")
    okb query 'goal(G, K, A, T)' -n 0; is Rc21-old-hypothesis-is-goal "G = h5, K = feature, A = agent, T = 'The Desk answers each page and action within one second.'"
    okb query 'premise(P, h5, T)'; has Rc21-premises-kept "P = p1"
    okb query 'hypothesis(H, G, A, T)'; rcis Rc21-no-hypothesis-written 1
    okb show; rcis Rc21-loads 0; has Rc21-says-none "  No hypothesis: the claims hang on the goal."
    has Rc21-show-goal "Goal h5 (the agent): The Desk answers"
    okb report; has Rc21-report-says-none "    - No hypothesis: the claims hang on the goal."
    okb lint; rcis Rc21-lint-clean 0; hasnt Rc21-no-W14-old "W14"; hasnt Rc21-no-W16-old "W16"
    okb query 'claim_of_goal(C)'; is Rc21-claims-on-goal "C = c1"
    okb query 'current(C)'; is Rc21-claim-current "C = c1"
    [ "$(cat "$K/kb.pl")" = "$before" ] && ok Rc21-nothing-written || bad Rc21-nothing-written "kb.pl changed"
    oldkb c21b; printf "hypothesis(h1, feature, 'Old.').\nhypothesis(h2, feature, 'New.').\nsupersedes(h2, h1).\n" >> "$K/kb.pl"
    okb query 'goal_current(G)' -n 0; is Rc21-superseded-not-goal "G = h2"
fi

if want c37; then
    replay c37; okb add "$HB" "claim(c3, introduce, 'Each changed record goes to review.')" 'predicts(hyb, c3)' \
        "hypothesis(hyc, g1, agent, 'Hash each record.')"
    okb adopt hya --by human; okb adopt hyb --by human
    okb query 'hypothesis_state(H, adopted)' -n 0; is Rc37-two-adopted "H = hya
H = hyb"
    okb query 'under(C)' -n 0; out=$(printf '%s\n' "$out" | sort); is Rc37-claims-of-each-hold-up "C = c1
C = c2
C = c3"
    okb add "defeat(d1, hya, 'The corrected address of member 12 was dropped.')"
    okb query 'under(C)' -n 0; is Rc37-defeated-claims-leave "C = c2
C = c3"
    okb show open; hasnt Rc37-open-list "c1"
    okb query 'hypothesis_state(hyb, S)'; is Rc37-other-still-adopted "S = adopted"
    okb retire hyc --reason 'Slower than B.'; rcis Rc37-agent-retires-own 0
    okb query 'hypothesis_state(hyc, S)'; is Rc37-retired "S = retired"
    okb retire hyb --reason 'no'; rcis Rc37-agent-cannot-retire-adopted 1
    printf '%s' "$err" | grep -q 'An agent cannot retire hypothesis hyb: a human adopted it' && ok Rc37-refusal-says-why || bad Rc37-refusal-says-why "$err"
    okb retire hya --reason 'no'; rcis Rc37-agent-cannot-retire-human-written 1
    okb attest retirement hyb "retired('no')"; rcis Rc37-attest-refused-too 1
    okb add "attest(a99, retirement, hyb, retired(no), agent, '2026-11-24T00:00:00Z')"; rcis Rc37-add-refused-too 1
    okb retire hyb --reason 'Ty changed his mind.' --by human; rcis Rc37-human-retires 0
    okb query 'hypothesis_state(hyb, S)'; is Rc37-human-retired "S = retired"
    # adoption_cited: the reading of the agent adopts nothing alone; a later human GO adopts it.
    newkb c37d discovery; okb add "$GOAL" "hypothesis(hy1, g1, agent, 'A.')" "hypothesis(hy2, g1, agent, 'B.')" "hypothesis(hy3, g1, agent, 'C.')" \
        "adoption_cited(hy1, 'Ty: go with A')"
    okb query 'hypothesis_state(hy1, S)'; is Rc37-cited-alone-proposed "S = proposed"
    okb show hypotheses; has Rc37-cited-header "  Hypothesis hy1 (the agent, proposed): A."
    has Rc37-cited-printed "    Cited as adopted (the agent's reading of the human's words): 'Ty: go with A'. The human adopts it with Adopt on the Desk, or with: orbit-kb adopt hy1 --by human"
    okb report; has Rc37-cited-printed-report "      - Cited as adopted (the agent's reading of the human's words): 'Ty: go with A'."
    okb retire hy1 --reason no; rcis Rc37-agent-cannot-retire-cited 1
    printf "attest(v1, vote, r1, vote(1, go), agent, '2026-11-24T00:00:00Z').\nattest(v2, vote, r1, vote(1, go), human, '2026-11-24T00:01:00Z').\nadoption_cited(hy3, 'after the vote').\n" >> "$K/kb.pl"
    okb query 'hypothesis_state(H, S)' -n 0; is Rc37-go-adopts-only-cited-before "H = hy1, S = adopted
H = hy2, S = proposed
H = hy3, S = proposed"
fi

if want c38; then
    replay c38
    okb add 'predicts(hya, c2)'; rcis Rc38-predicts-preserve-refused 1
    printf '%s' "$err" | grep -q 'c2 is a preserve claim. A preserve claim is always a claim of the goal' && ok Rc38-refusal-says-so || bad Rc38-refusal-says-so "$err"
    okb query 'claim_of_goal(C)'; is Rc38-preserve-on-goal "C = c2"
    okb rests k1; rcis Rc38-rests 0
    has Rc38-up-claim "  claim c1 (introduce): After a replay"
    has Rc38-up-hypothesis "    hypothesis hya (human, proposed)"
    has Rc38-up-goal "      goal g1 (human)"
    has Rc38-up-project "        project goal pg1"
    okb query 'rests_up(k1, X)' -n 0; is Rc38-rests-up "X = c1
X = hya
X = g1
X = project(pg1)"
    okb rests k2; has Rc38-preserve-rests-on-goal "    goal g1 (human)"
    okb rests g1; has Rc38-down "      check k1 of claim c1"
    okb add "defeat(d1, hya, 'A correction is discarded.')"
    okb query 'current(C)' -n 0; is Rc38-defeated-claim-not-current "C = c2"
    okb query 'blocking(X)' -n 0; has Rc38-preserve-holds-up "X = under(c2)"; hasnt Rc38-defeated-holds-nothing "c1"
    okb show claims; has Rc38-show-why "State: not current (its hypothesis hya is defeated)."
    okb lint; has Rc38-W14-none "Summary"; hasnt Rc38-supported-no-W14 "W14"
    newkb c38b; okb add "$GOAL" "$HA" "$HB" "claim(c1, introduce, 'One.')" 'predicts(hya, c1)' 'predicts(hyb, c1)' "claim(c5, introduce, 'Unplaced.')" "claim(c6, preserve, 'Stays.')"
    okb lint; has Rc38-W15 "W15 c1"; has Rc38-W16 "W16 c5"; hasnt Rc38-W16-not-preserve "W16 c6"; has Rc38-W14 "W14 g1"
fi

if want c43; then
    oldkb c43; printf "hypothesis(h5, feature, 'The Desk answers within one second.').\n" >> "$K/kb.pl"
    okb query 'hypothesis(H, K, T)'; rcis Rc43-old-query-exit 0; is Rc43-old-query-answer "H = h5, K = feature, T = 'The Desk answers within one second.'"
    ehas Rc43-note "note: hypothesis/3 is the 0.7.2 form of the goal. Ask goal(G, Kind, Author, Text); a hypothesis of a goal is hypothesis(H, Goal, Author, Text)."
    okb add "hypothesis(hy1, h5, agent, 'Keep the page in memory between two GETs.')"; rcis Rc43-hypothesis-under-old-goal 0
    okb query 'hypothesis(H, K, T)' -n 0; is Rc43-never-the-new-sense "H = h5, K = feature, T = 'The Desk answers within one second.'"
    replay c43b
    okb query 'hypothesis(H, K, T)' -n 0; rcis Rc43-new-kb-not-silent 0; is Rc43-new-kb-gives-goal "H = g1, K = feature, T = 'A replayed import leaves the member records as one clean run would.'"
    okb add "hypothesis(h9, feature, 'The 0.7.2 form.')"; rcis Rc43-old-add-exit 0; is Rc43-old-add-stdout "hypothesis(h9, feature, 'The 0.7.2 form.')."
    ehas Rc43-add-note "note: hypothesis/3 is the 0.7.2 form of the goal."
    okb add 'supersedes(g1, h9)'; rcis Rc43-goal-supersedes-old-form 0
    okb show hypothesis; rcis Rc43-show-hypothesis 0; has Rc43-show-hypothesis-072 "Hypothesis:"; ehas Rc43-show-note "note: hypothesis/3"
    okb query 'goal(G, K, A, T)' >/dev/null; [ -z "$err" ] && ok Rc43-goal-query-no-note || bad Rc43-goal-query-no-note "$err"
    K2=$T/c43s; "$CLI" shift "$K2" --request 'r' --hypothesis 'The page is dark.' --no-premises --claim 'It is dark.' --example 'Open it.' --check k1 --checks-that 'dark' >"$T/o" 2>"$T/e"; rc=$?
    rcis Rc43-shift-works 0; grep -q "^hypothesis(h1, feature, 'The page is dark.').$" "$T/o" && ok Rc43-shift-stdout || bad Rc43-shift-stdout "$(cat "$T/o")"
fi

if want p2; then   # second pass: W10/W11 wording, W19, W20, the not-tempered line
    newkb p2; okb add "$GOAL" "$HA" "$HB" "defeat(d1, hyb, 'Bad.')"
    okb lint; has Rp2-W10-goal "W10 g1: This goal has no premise"; has Rp2-W10-hypothesis "W10 hya: This hypothesis has no premise"
    hasnt Rp2-W10-not-defeated "W10 hyb"
    okb show hypotheses; has Rp2-hint-goal "no_premises(G) for this goal"; has Rp2-hint-hypothesis "no_premises(H) for this hypothesis"
    [ "$(printf '%s\n' "$out" | grep -c 'Not tempered')" = 1 ] && ok Rp2-not-tempered-only-current || bad Rp2-not-tempered-only-current "$out"
    okb add "premise(p1, g1, 'P.')" 'no_premises(g1)'; okb lint; has Rp2-W11-goal "W11 g1: This goal has a premise"
    printf "attest(a90, retirement, hya, retired(no), agent, '2026-11-24T00:00:00Z').\n" >> "$K/kb.pl"
    okb lint; has Rp2-W19 "W19 a90"; okb query 'hypothesis_state(hya, S)'; is Rp2-ignored-retirement "S = proposed"
    oldkb p2o; printf "hypothesis(h1, feature, 'Old.').\n" >> "$K/kb.pl"; okb lint; has Rp2-W10-old-wording "W10 h1: This hypothesis has no premise"
    mkdir -p "$T/pk"; printf "uses([project]).\n%% Made by orbit-kb 0.8.0.\ngoal(pg1, feature, human, 'Agents deliver what the human wants.').\n" > "$T/pk/kb.pl"
    newkb p2s build,project; okb add "project_kb('$T/pk')" "$GOAL" 'no_premises(g1)' 'supports(g1, project(pg1))'; rcis Rp2-supports-add 0
    okb lint; hasnt Rp2-W20-none "W20"
    okb rests g1; has Rp2-rests-project-text "project goal pg1: Agents deliver what the human wants."
    okb add "goal(g2, feature, human, 'Two.')" 'supports(g2, project(pg9))'; okb lint; has Rp2-W20 "W20 g2"
fi

if want p3; then   # the findings of review on the views: B3 to B7
    newkb p3 build; okb add "goal(g1, feature, human:ty, 'A replayed import is safe.')" 'no_premises(g1)' \
        "hypothesis(hy1, g1, human:ty, 'Skip seen IDs.')" "hypothesis(hy5, g1, agent:astra, 'Hash each record.')" \
        "adoption_cited(hy5, 'sounds right')" "claim(c1, preserve, 'Stays.')" 'check(k1, c1)' "checks_that(k1, 'it stays')"
    okb show hypotheses; has Rp3-B4-goal "Goal g1 (Ty): A replayed import is safe."
    has Rp3-B4-human-name "  Hypothesis hy1 (Ty, proposed): Skip seen IDs."
    has Rp3-B4-agent-name "  Hypothesis hy5 (Astra (agent), proposed): Hash each record."
    has Rp3-B4-citation "    Cited as adopted (the agent's reading of Ty's words): 'sounds right'. Ty adopts it with Adopt on the Desk, or with: orbit-kb adopt hy5 --by human"
    okb query 'hypothesis(hy5, G, A, T)'; has Rp3-B4-query-keeps-value "A = agent:astra"
    okb report; has Rp3-guess "  - Hypothesis hy5 (Astra, agent-written, not adopted): Hash each record."
    okb show blocking; line=$(printf '%s\n' "$out" | grep '^- goal_unjudged g1')
    case "$line" in *"Ty records it on the Desk (Goal satisfied), or with: orbit-kb judge g1 satisfied --by human: A replayed import is safe.") ok Rp3-B6-ends-with-goal-text;; *) bad Rp3-B6-ends-with-goal-text "$line";; esac
    okb show open; has Rp3-B6-show-open "orbit-kb judge g1 satisfied --by human: A replayed import is safe."
    printf "hypothesis(hy9, g9, agent, 'No goal.').\n" >> "$K/kb.pl"; n=$(grep -n '^hypothesis(hy9' "$K/kb.pl" | cut -d: -f1)
    okb lint; has Rp3-B7-id-in-line "E4 kb.pl:$n hy9: hypothesis/4 argument 2: g9 is not the id of any goal fact."
    oldkb p3b discovery; printf "hypothesis(h2, feature, '%s').\nno_premises(h2).\n" "$(printf 'x%.0s' $(seq 1 130))" >> "$K/kb.pl"
    printf 'log\n' > "$K/e.log"; okb subject e1 e.log; okb add 'discovery_evidence(e1, system)'
    okb attest reproduction e1 'result(h2, reproduced)' --id a7; rcis Rp3-B3-reproduction 0
    okb add "goal(g1, feature, human:ty, 'In the words of Ty.')" 'no_premises(g1)' 'supersedes(g1, h2)'
    okb show hypotheses; has Rp3-B5-heading "Earlier statements of the goal:"
    has Rp3-B5-line "- h2 (the agent, superseded by g1): $(printf 'x%.0s' $(seq 1 100))"
    hasnt Rp3-B5-cut "$(printf 'x%.0s' $(seq 1 101))"
    [ "$(printf '%s\n' "$out" | grep -c 'No hypothesis: the claims hang on the goal.')" = 1 ] && ok Rp3-B5-no-hypothesis-once || bad Rp3-B5-no-hypothesis-once "$out"
    okb lint; has Rp3-B3-WD7-says-goal "WD7 g1: No result from the current system exists for this goal."
    okb show open; has Rp3-B3-untouched-says-goal "goal g1 has no result from the current system"
    okb add 'carried(a7, g1)'; rcis Rp3-B3-carry 0
    okb query 'discovery_hypothesis_touched(g1)'; rcis Rp3-B3-carried-reproduction-counts 0
    okb lint; hasnt Rp3-B3-no-WD7 "WD7"
fi

if want u1; then   # review U1: the tool names itself as it was called (argv0) in every next-step line
    ORBIT=$(dirname "$CLI")/orbit
    newkb u1 build; okb add "goal(g1, feature, human, 'Dark.')" 'no_premises(g1)' "hypothesis(hy1, g1, agent, 'A switch.')" \
        "adoption_cited(hy1, 'yes')" "claim(c1, introduce, 'Dark.')" 'predicts(hy1, c1)' 'check(k1, c1)' "checks_that(k1, 'dark')"
    okb run k1 -- false; okb add "change(x1, 'made it')" 'serves(x1, c1)'; okb run k1 -- false
    a=$(sed -n 's/^attest(\(a[0-9]*\), test_result.*/\1/p' "$K/kb.pl" | tail -1)
    okb show open; has Ru1-kb-locate "orbit-kb locate $a "; has Ru1-kb-judge "or with: orbit-kb judge g1 satisfied"
    hasnt Ru1-kb-no-bare-orbit "with: orbit judge"
    okb show hypotheses; has Ru1-kb-adopt "or with: orbit-kb adopt hy1 --by human"
    oo() { out=$("$ORBIT" --dir "$K" "$@" 2>"$T/err" </dev/null); rc=$?; err=$(cat "$T/err"); }
    oo show open; has Ru1-orbit-locate "orbit locate $a "; has Ru1-orbit-judge "or with: orbit judge g1 satisfied"
    hasnt Ru1-orbit-no-orbit-kb "orbit-kb"
    oo show hypotheses; has Ru1-orbit-adopt "or with: orbit adopt hy1 --by human"; hasnt Ru1-orbit-hyp-no-orbit-kb "orbit-kb"
    oo locate "$a" hypothesis:hy1 --evidence 'the switch does nothing'
    case "$err" in *"orbit confirm LOCATION"*) ok Ru1-orbit-locate-note;; *) bad Ru1-orbit-locate-note "$err";; esac
    oo show open; has Ru1-orbit-confirm "orbit confirm "; hasnt Ru1-orbit-open-no-orbit-kb "orbit-kb"
    oo report; hasnt Ru1-orbit-report-no-orbit-kb "orbit-kb "
    okb show open; has Ru1-kb-confirm "orbit-kb confirm "
fi

if want u4; then   # review U4: lists of ids sort by number (c1, c2, c10), not as text (c1, c10, c2)
    newkb u4 build; set -- "goal(g1, feature, human, 'G.')" 'no_premises(g1)' "hypothesis(hy1, g1, agent, 'H.')"
    for i in 10 2 11 1; do set -- "$@" "claim(c$i, introduce, 'C$i.')" "predicts(hy1, c$i)" "check(k$i, c$i)" "checks_that(k$i, 'x')"; done
    okb add "$@"; rcis Ru4-add 0
    okb show hypotheses; has Ru4-show-hypotheses "    Predictions: c1, c2, c10, c11."
    okb show; has Ru4-show "    Predictions: c1, c2, c10, c11."
    for i in 10 2 11 1; do okb run "k$i" -- true; done
    okb report; has Ru4-report "      - Predictions: c1, c2, c10, c11."
    has Ru4-report-review "Not independently verified: c1, c2, c10, c11."
    okb add "claim(c3, introduce, 'C3.')" 'supersedes(c3, c1)' "claim(c20, introduce, 'C20.')" 'supersedes(c20, c1)'
    okb show; has Ru4-superseded-by "superseded by c3, c20."
    set --
fi

if want u9; then   # review U9: --note keeps the words of the human; an agent session needs them
    newkb u9 build; okb add "$GOAL" 'no_premises(g1)' "$HA" "$HB"
    okb adopt hya --by human --note 'Ty: go with A'; rcis Ru9-adopt-note 0
    okb query "attest(A, adoption, hya, adopted, human, _), note(A, W)"; has Ru9-adopt-note-on-attestation "W = 'Ty: go with A'"
    okb judge g1 satisfied --by human --note 'Ty: that is what I wanted'; rcis Ru9-judge-note 0
    okb query "attest(A, judgment, g1, satisfied, human, _), note(A, W)"; has Ru9-judge-note-on-attestation "W = 'Ty: that is what I wanted'"
    for v in CLAUDECODE AI_AGENT CLAUDE_CODE_SESSION_ID; do
        cp "$K/kb.pl" "$T/u9.pl"
        out=$(env "$v=1" "$CLI" --dir "$K" judge g1 not-satisfied --by human 2>"$T/err" </dev/null); rc=$?; err=$(cat "$T/err")
        rcis "Ru9-judge-refused-$v" 1; ehas "Ru9-judge-says-note-$v" "add --note with the words of the human"
        cmp -s "$K/kb.pl" "$T/u9.pl" && ok "Ru9-judge-wrote-nothing-$v" || bad "Ru9-judge-wrote-nothing-$v" "kb.pl changed"
        out=$(env "$v=1" "$CLI" --dir "$K" adopt hyb --by human 2>"$T/err" </dev/null); rc=$?; err=$(cat "$T/err")
        rcis "Ru9-adopt-refused-$v" 1; ehas "Ru9-adopt-says-note-$v" "add --note with the words of the human"
    done
    out=$(env CLAUDECODE=1 "$CLI" --dir "$K" judge g1 case 'a replay twice' wanted --by human --note 'Ty: yes' 2>"$T/err" </dev/null); rc=$?
    rcis Ru9-agent-session-with-note 0
    okb adopt hyb --by human; rcis Ru9-no-agent-session-no-note 0
fi

echo "pass=$pass fail=$fail"
[ "$fail" = 0 ]
