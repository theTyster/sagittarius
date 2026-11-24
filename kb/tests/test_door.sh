#!/usr/bin/env bash
# Black-box tests for the door (CONTRACT D63 to D69; scientific-method-overhaul c19, c26, c27,
# c17, c42, c44, c46). The harness is a small serial copy of the style of test_project_kb.sh:
# each test runs in a fresh mktemp -d, the summary line is `pass=N fail=N skip=N`, the exit
# status is 0 when every test passes, 1 when one fails, 2 when the suite cannot run.
#
# Usage: kb/tests/test_door.sh [path-to-orbit-kb]      ONLY='<regex>' runs matching ids.
#
# Claims -> tests:
#   c19 the name orbit beside orbit-kb; each 0.7.2 command line of hubflow.py, hubkit.py and the
#       hooks answers in the same form under both names (and as the 0.7.2 tool, when git has it) : DN1 DN2 DN3 DN4
#   c26 one query joins the ledger, a spec KB and the project KB; a write to each store goes
#       through orbit; the files of memory, weeks and bespoke with a digest each; orbit runs a
#       test itself                                                                             : DQ1 DQ2 DL1 DS1 DS2 DR1
#   c27 hubflow.py through the door answers as hubflow.py itself; the goal ref                   : DL2 DL3
#   c44 the 14 cases of purpose_cases.pl; the orphan lists on the scratch hub                    : DP1 DP2
#   c42, c17 a dropped project goal is named on each ticket goal and item; nothing is closed;
#       a ticket goal that names no project goal is listed; no divergence                        : DG1 DG2 DG3
#   c46 s1-record: the JSON of the active ticket and nothing else                                : DS3 DS4
set -u

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
OKB=${1:-${ORBIT_KB_BIN:-$here/../bin/orbit-kb}}
LIB=${ORBIT_KB_TEST_LIB:-$here/../share/orbit-kb}
TMO=${ORBIT_KB_TEST_TIMEOUT:-120}
if [ ! -f "$OKB" ] || [ ! -x "$OKB" ]; then echo "test_door.sh: the orbit-kb CLI is missing: $OKB" >&2; exit 2; fi
OKB=$(cd "$(dirname "$OKB")" && pwd -P)/$(basename "$OKB")
ORB=$(dirname "$OKB")/orbit
if [ -d "$LIB" ]; then LIB=$(cd "$LIB" && pwd -P); fi
if [ ! -f "$LIB/core.pl" ]; then echo "test_door.sh: the library is missing (no core.pl in $LIB)" >&2; exit 2; fi
HF=$here/../../hubkit/hub/.claude/scripts/hubflow.py
FIX=$here/fixtures/door
for tool in swipl python3 sha256sum timeout mktemp grep sed cmp sort head cp; do
    command -v "$tool" >/dev/null 2>&1 || { echo "test_door.sh: required tool not found: $tool" >&2; exit 2; }
done
[ -f "$HF" ] || { echo "test_door.sh: hubflow.py is missing: $HF" >&2; exit 2; }

pass=0 fail=0 skip=0
failed=()
FAILS=()
out="" err="" rc=0
T="" H=""
base=$(mktemp -d "${TMPDIR:-/tmp}/orbit-door-test.XXXXXX") || exit 2
base=$(cd "$base" && pwd -P)
trap 'rm -rf "$base"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
for v in $(compgen -e); do case $v in ORBIT_KB*|CLAUDE_SESSION_ID|CLAUDE_CODE_SESSION_ID|HUB_SESSION|HUBFLOW_*) unset "$v";; esac; done
export ORBIT_KB_LIB="$LIB"
# One cache for the suite: the saved state of each name is built once and then used (DN4 checks it).
export XDG_CACHE_HOME=$base/.cache; mkdir "$XDG_CACHE_HOME"

ok()  { pass=$((pass+1)); echo "PASS $1 $2"; }
bad() { fail=$((fail+1)); failed+=("$1"); echo "FAIL $1 $2"; local m; for m in "${@:3}"; do echo "     - $m"; done; }
skp() { skip=$((skip+1)); echo "SKIP $1 $2"; }
snip() { printf '%s' "$1" | head -c 400 | tr '\n' '~'; }
note() { FAILS+=("$*"); }
run_in() { local d=$1; shift; ( cd "$d" && exec timeout "$TMO" "$@" ) >"$T/.out" 2>"$T/.err" </dev/null; rc=$?; out=$(<"$T/.out"); err=$(<"$T/.err"); }
orb() { run_in "$H" "$ORB" "$@"; }
okb() { run_in "$H" "$OKB" "$@"; }
rc_is() { [ "$rc" = "$1" ] && return 0; note "${2:+$2: }exit $rc, want $1 (stdout: $(snip "$out") | stderr: $(snip "$err"))"; return 1; }
out_has() { printf '%s\n' "$out" | grep -Eq -- "$1" && return 0; note "${2:+$2: }stdout lacks /$1/ (stdout: $(snip "$out"))"; return 1; }
out_hasnt() { if printf '%s\n' "$out" | grep -Eq -- "$1"; then note "${2:+$2: }stdout has /$1/, it must not (stdout: $(snip "$out"))"; return 1; fi; return 0; }
err_has() { printf '%s\n' "$err" | grep -Eq -- "$1" && return 0; note "${2:+$2: }stderr lacks /$1/ (stderr: $(snip "$err"))"; return 1; }
sha() { sha256sum "$1" | cut -d' ' -f1; }
hq() { orb hub query "$@"; }

REG_FN=() REG_ID=() REG_DESC=()
run_test() { local fn=$1 id=$2 desc=$3; if [ -n "${ONLY:-}" ] && ! [[ $id =~ $ONLY ]]; then return 0; fi; REG_FN+=("$fn"); REG_ID+=("$id"); REG_DESC+=("$desc"); }
exec_test() {
    local i=$1
    T=$(mktemp -d "$base/${REG_ID[$i]}.XXXXXX") || return 1
    T=$(cd "$T" && pwd -P); H=$T
    FAILS=(); out=""; err=""; rc=0; SKIP=""
    cd "$T" || return 1
    "${REG_FN[$i]}"
    cd "$here" || true
    if [ -n "$SKIP" ]; then skp "${REG_ID[$i]}" "${REG_DESC[$i]} ($SKIP)"
    elif [ ${#FAILS[@]} -eq 0 ]; then ok "${REG_ID[$i]}" "${REG_DESC[$i]}"
    else bad "${REG_ID[$i]}" "${REG_DESC[$i]}" "${FAILS[@]}"; fi
    rm -rf "$T"
}

# mkhub: a scratch hub in $T/hub: the fixture files, the kit's hubflow.py, and a ledger that is
# written through the door (orbit hub ledger). H is the hub root.
mkhub() {
    cp -r "$FIX/hub" "$T/hub"; H=$T/hub
    mkdir -p "$H/.claude/scripts"; cp "$HF" "$H/.claude/scripts/hubflow.py"
    orb hub ledger init;                                                         rc_is 0 "ledger init" || return 1
    orb hub ledger --session build handoff --to review --title "alpha: verify the greeting" --ref kb:alpha; rc_is 0 "handoff" || return 1
    orb hub ledger --session build add thread --title "beta: keep it quiet" --owner build --ref kb:beta;     rc_is 0 "thread" || return 1
    orb hub ledger --session build add hold --title "work the logo candidates" --owner build;               rc_is 0 "hold" || return 1
    orb hub ledger --session build add hold --title "a hold that names its goal" --owner build --ref goal:pg2; rc_is 0 "hold with a goal ref" || return 1
}

# ---------------------------------------------------------------- c19: the name
# The command lines that hubflow.py (query blocking -n 0, a read-only query, migrate check),
# hubkit.py (version, migrate plan) and the hooks (lint) send at 0.7.2.
dn_lines() { cat <<'L'
--dir KB query blocking(X) -n 0
--dir KB query claim(C,L,T) -n 0
--dir KB query done
--dir KB query nosuch(X)
--dir KB migrate check
--dir KB lint
--dir KB show open
--dir KB show blocking
--dir KB report
help query
L
}
t_DN1() {
    cp -r "$FIX/hub/specs/beta" "$T/KB"
    local line o1 r1
    while IFS= read -r line; do
        # shellcheck disable=SC2086
        run_in "$T" "$OKB" $line; o1=$out; r1=$rc
        # shellcheck disable=SC2086
        run_in "$T" "$ORB" $line
        [ "$rc" = "$r1" ] || note "'$line': exit $rc as orbit, $r1 as orbit-kb"
        [ "$(printf '%s' "$out" | sed 's/orbit-kb/orbit/g')" = "$(printf '%s' "$o1" | sed 's/orbit-kb/orbit/g')" ] || note "'$line': stdout differs between the two names (orbit: $(snip "$out") | orbit-kb: $(snip "$o1"))"
    done < <(dn_lines)
}
t_DN2() {
    run_in "$T" "$OKB" version; rc_is 0; out_has '^orbit-kb [0-9]+\.[0-9]+\.[0-9]+$' "orbit-kb version keeps its form"
    run_in "$T" "$ORB" version; rc_is 0; out_has '^orbit [0-9]+\.[0-9]+\.[0-9]+$' "orbit version"
    run_in "$T" "$OKB" help; rc_is 0; out_has '^orbit-kb [0-9.]+: write, check' "help as orbit-kb"; out_has 'Usage: orbit-kb \[--dir DIR\]'
    out_hasnt '(^| )orbit (init|add|query|help) ' "help as orbit-kb names orbit-kb"
    run_in "$T" "$ORB" help; rc_is 0; out_has '^orbit [0-9.]+: write, check' "help as orbit"; out_has 'Usage: orbit \[--dir DIR\]'
    run_in "$T" "$ORB" nosuchcommand; rc_is 2; err_has 'Run `orbit help` for usage' "a usage error as orbit"
    run_in "$T" "$OKB" nosuchcommand; rc_is 2; err_has 'Run `orbit-kb help` for usage' "a usage error as orbit-kb"
    run_in "$T" "$OKB" hub stores --hub "$FIX/hub"; rc_is 0 "the new commands answer under the old name too"
}
# The same form as the 0.7.2 tool itself, on a KB of 0.7.2 (git has the release commit e89d488).
t_DN3() {
    local repo=$here/../..
    if ! git -C "$repo" cat-file -e e89d488:kb/bin/orbit-kb 2>/dev/null; then SKIP="git does not have the 0.7.2 release commit e89d488"; return; fi
    mkdir "$T/old" && git -C "$repo" archive e89d488 kb/bin kb/share VERSION | tar -x -C "$T/old" || { note "cannot unpack 0.7.2"; return; }
    cp -r "$FIX/hub/specs/beta" "$T/KB"
    local line o1 r1
    while IFS= read -r line; do
        case $line in *report*|*show*|*lint*|help*) continue;; esac   # the texts of show, report and lint change with c1, c2 (other tests)
        # shellcheck disable=SC2086
        ( cd "$T" && ORBIT_KB_LIB=$T/old/kb/share/orbit-kb timeout "$TMO" "$T/old/kb/bin/orbit-kb" $line ) >"$T/.o1" 2>/dev/null </dev/null; r1=$?; o1=$(<"$T/.o1")
        for bin in "$OKB" "$ORB"; do
            # shellcheck disable=SC2086
            run_in "$T" "$bin" $line
            [ "$rc" = "$r1" ] || note "'$line' as $(basename "$bin"): exit $rc, 0.7.2 gave $r1"
            [ "$out" = "$o1" ] || note "'$line' as $(basename "$bin"): stdout differs from 0.7.2 (now: $(snip "$out") | 0.7.2: $(snip "$o1"))"
        done
    done < <(dn_lines)
}
t_DN4() {
    local n
    for bin in "$OKB" "$ORB"; do
        run_in "$T" "$bin" version; run_in "$T" "$bin" version; rc_is 0
        n=$(basename "$bin"); out_has "^$n [0-9]" "the second call of $n"
    done
    n=$(find "$XDG_CACHE_HOME/orbit-kb" -name 'state-*.qs' | wc -l)
    [ "$n" -ge 2 ] || note "want a saved state for each name, found $n state file(s)"
    [ -L "$ORB" ] || note "$ORB is not a link to orbit-kb"
}

# ---------------------------------------------------------------- c26: the door
t_DQ1() {
    mkhub || return
    hq "item(I, handoff, open, _, _), item_ref(I, kb, S), ticket_goal(S, G), ticket_supports(S, G, PG), project_fact(goal(PG, _, _, Text)), ticket_fact(S, blocking(B))" -n 0
    rc_is 0 "the join of the ledger, a spec KB and the project KB" || return
    out_has "^I = 'H-0001', S = alpha, G = g1, PG = pg1, Text = 'Agents deliver results that the human wants.', B = under\(c1\)$"
    hq "item(I, K, St, Ti, O)" -n 0; rc_is 0; [ "$(printf '%s\n' "$out" | wc -l)" = 4 ] || note "want 4 items, got: $(snip "$out")"
    hq "item(I, K, St, Ti, O)"; [ "$(printf '%s\n' "$out" | wc -l)" = 1 ] || note "the default is one answer, as query"
    hq "ticket(S, D)" -n 0; out_has "^S = alpha, D = 'specs/alpha'$"; out_has "^S = beta, D = 'specs/beta'$"
    hq "ticket_fact(alpha, claim(C, L, _))" -n 0; out_has '^C = c1, L = introduce$'
    hq "project_fact(hypothesis(Hy, pg1, _, _))"; out_has '^Hy = ph1$'
    hq "item_ref(I, goal, PG)" -n 0; out_has "^I = 'K-0002', PG = pg2$"
    hq "nosuch(X)"; rc_is 2 "an unknown predicate is a usage error"
    hq "item(nope, _, _, _, _)"; rc_is 1 "no answer is exit 1"; out_has '^false$'
}
t_DQ2() {
    mkhub || return
    mkdir -p "$H/W0/deep/er"
    run_in "$H/W0/deep/er" "$ORB" hub query "ticket(S, _)" -n 0; rc_is 0 "the hub root is found from below"; out_has '^S = alpha$'
    run_in "$T" "$ORB" hub query "ticket(S, _)" -n 0 --hub "$H"; rc_is 0 "--hub DIR"; out_has '^S = beta$'
    run_in "$T" "$ORB" hub query "ticket(S, _)"; rc_is 2 "no hub"; err_has 'No hub found'
}
t_DL1() {   # a write to each store goes through orbit
    mkhub || return
    [ -f "$H/flow/flow.db" ] && [ -s "$H/flow/jsonl/item.jsonl" ] || note "orbit hub ledger init and add made no ledger"
    orb --dir "$H/specs/alpha" add "note(c1, 'written through orbit')"; rc_is 0 "a write to a spec KB"
    hq "ticket_fact(alpha, note(c1, N))"; out_has "written through orbit"
    orb --dir "$H/project-kb" add "decision(d1, 'The door is orbit.')" --by human; rc_is 0 "a write to the project KB"
    hq "project_fact(decision(d1, D))"; out_has "The door is orbit"
    orb hub ledger --session build note H-0001 "a note through the door"; rc_is 0 "a note in the ledger"
    grep -q "a note through the door" "$H/flow/jsonl/event.jsonl" || note "the note is not in the ledger"
}
t_DL2() {   # c27: the door prints what hubflow.py prints, with its exit code and its stdin
    mkhub || return
    local a
    for a in "view open" "view inbox --session review" "show H-0001" "check" "view nosuchview" "nosuchcommand" "close Z-9999 --reason done"; do
        # shellcheck disable=SC2086
        ( cd "$H" && HUB_SESSION=build python3 .claude/scripts/hubflow.py $a ) >"$T/.o1" 2>"$T/.e1" </dev/null; local r1=$?
        # shellcheck disable=SC2086
        ( cd "$H" && HUB_SESSION=build "$ORB" hub ledger $a ) >"$T/.o2" 2>"$T/.e2" </dev/null; local r2=$?
        [ "$r1" = "$r2" ] || note "'$a': exit $r2 through the door, $r1 from hubflow.py"
        cmp -s "$T/.o1" "$T/.o2" || note "'$a': stdout differs ($(head -c 200 "$T/.o2" | tr '\n' '~'))"
        cmp -s "$T/.e1" "$T/.e2" || note "'$a': stderr differs ($(head -c 200 "$T/.e2" | tr '\n' '~'))"
    done
    printf '%s\n' '{"kind": "thread", "title": "from stdin through the door", "owner": "build"}' > "$T/in.jsonl"
    ( cd "$H" && "$ORB" hub ledger --session build import /dev/stdin --yes < "$T/in.jsonl" ) >"$T/.o" 2>"$T/.e"; rc=$?
    [ "$rc" = 0 ] || note "import from stdin: exit $rc ($(head -c 300 "$T/.e" | tr '\n' '~'))"
    grep -q "from stdin through the door" "$H/flow/jsonl/item.jsonl" || note "stdin did not reach hubflow.py"
    ( cd "$H" && HUB_SESSION=review "$ORB" hub ledger accept H-0001 ) >"$T/.o" 2>"$T/.e" || note "HUB_SESSION did not reach hubflow.py: $(head -c 200 "$T/.e")"
}
t_DL3() {   # the goal ref: the one new ledger form
    mkhub || return
    orb hub ledger show K-0002; rc_is 0; out_has 'goal:pg2' "show prints the goal ref like other refs"
    orb hub ledger --session build ref K-0001 add goal:pg1; rc_is 0 "ref add goal:"
    orb hub ledger view open; out_has 'goal:pg1'
    orb hub ledger --session build ref K-0001 add "goal:not an id"; rc_is 1 "a goal ref is an id"; err_has 'goal ref'
    orb hub ledger --session build ref K-0001 add "goal:Pg1"; rc_is 1 "a goal ref starts with a lowercase letter"
    orb hub ledger check; rc_is 0 "hubflow check after the goal refs"
}
t_DS1() {
    mkhub || return
    orb hub stores; rc_is 0 || return
    out_has '^spec +2 spec KBs'; out_has '^project +4 facts \(project-kb\)'; out_has '^ledger +4 items, 4 open, 3 refs, 0 links'
    out_has '^memory +5 files'; out_has '^weeks +2 files'; out_has '^bespoke +2 files'; out_has '^tracker +0 pointers'
    [ "$(printf '%s\n' "$out" | wc -l)" = 7 ] || note "want the seven stores, one line each"
}
t_DS2() {
    mkhub || return
    orb hub files memory; rc_is 0
    local f
    for f in CLAUDE.md HUB-CORE.md HEURISTICS.md TECHNOLOGIES.md EXTRA.md; do out_has "^sha256:$(sha "$H/$f")  $f$" "memory lists $f with its sha256"; done
    out_hasnt 'NOTME.md' "a root file that no import names is not a memory file"
    orb hub files weeks; out_has "^sha256:$(sha "$H/W0/WEEK.md")  W0/WEEK.md$"; out_has "^sha256:$(sha "$H/W0/reports/r1.md")  W0/reports/r1.md$"
    orb hub files bespoke; out_has "^sha256:$(sha "$H/tools/mytool.sh")  tools/mytool.sh$"; out_has "  .claude/skills/my-skill/SKILL.md$"
    out_hasnt 'hub-flow' "a skill that the kit shipped is not bespoke"
    hq "store_file(weeks, P, D)" -n 0; out_has "^P = 'W0/WEEK.md', D = 'sha256:$(sha "$H/W0/WEEK.md")'$"
    orb hub files nosuch; rc_is 2
}
t_DR1() {   # orbit runs the experiment and writes the result itself
    mkhub || return
    orb --dir "$H/specs/alpha" run k1 -- sh -c 'echo no greeting; exit 1'; rc_is 1 "a failing run"
    hq "ticket_fact(alpha, attest(A, test_result, _, result(k1, N, R), script, _))" -n 0; out_has 'N = 1, R = fail' "the tool wrote the result of the run"
    if command -v z3 >/dev/null 2>&1; then
        printf '(declare-const x Int)\n(assert (> x 0))\n(check-sat)\n' > "$H/specs/alpha/m.smt2"
        orb --dir "$H/specs/alpha" run k1 -- z3 -T:5 "$H/specs/alpha/m.smt2"; rc_is 0 "a z3 run with a time limit"
        hq "ticket_fact(alpha, attest(A, test_result, _, result(k1, 2, R), script, _))"; out_has 'R = pass' "the tool wrote the result of the solver run"
    fi
}

# ---------------------------------------------------------------- c44, c42, c17: purpose
t_DP1() {
    mkdir "$T/cases"
    local n i line g
    n=$(swipl -q "$FIX/cases_to_facts.pl" -- "$FIX/purpose_cases.pl" "$T/cases" 2>"$T/.e") || { note "cases_to_facts failed: $(head -c 300 "$T/.e")"; return; }
    [ "$n" = 14 ] || note "want the 14 cases of purpose_cases.pl, found $n"
    for ((i = 1; i <= n; i++)); do
        while IFS= read -r line; do
            case $line in '#'*) continue;; esac
            if [ "${line#not }" != "$line" ]; then g=${line#not }
                run_in "$T" "$ORB" hub query "$g" --facts "$T/cases/case$i.pl"
                [ "$rc" = 1 ] || note "case $i ($(head -1 "$T/cases/case$i.pl")): '$g' must have no answer: exit $rc ($(snip "$out$err"))"
            else
                run_in "$T" "$ORB" hub query "$line" --facts "$T/cases/case$i.pl"
                [ "$rc" = 0 ] || note "case $i ($(head -1 "$T/cases/case$i.pl")): '$line' must hold: exit $rc ($(snip "$out$err"))"
            fi
        done < "$T/cases/case$i.expect"
    done
}
t_DP2() {
    mkhub || return
    orb hub orphans; rc_is 0 || return
    out_has '^Open items of the ledger: 4\.$'
    out_has '^Orphans \(2\):'; out_has '^Over \(0\):'; out_has '^Reports on a done ticket \(0\):'
    out_has "^- T-0001 .*its chain ends at the goal h1 of ticket beta, which names no live project goal"
    out_has "^- K-0001 .*its chain ends at nothing"
    out_hasnt '^- H-0001' "a handoff whose ticket goal supports a live project goal has a purpose"
    out_hasnt '^- K-0002' "an item that names its goal directly has a purpose"
    out_has '^Ticket goals with no live project goal \(1\)'; out_has '^- beta h1: it names no project goal$'
    [ "$(printf '%s\n' "$out" | grep -c '^- [A-Z]-[0-9]')" = 2 ] || note "each orphan is listed once"
    hq "ticket_goal_unsupported(S, G)" -n 0; out_has '^S = beta, G = h1$'; out_hasnt 'alpha'
    # a new ask that blocks a dropped thread is an orphan, and its chain ends at a dropped item
    orb hub ledger --session build add ask --title "an ask on a dropped thread" --waits-on me --no-kb --note "the case, the options, the default"; rc_is 0 "add ask"
    orb hub ledger --session build add thread --title "a thread that nobody wants" --owner build --ref kb:alpha
    orb hub ledger --session build link A-0001 T-0002 blocks; rc_is 0 "link"
    hq "has_purpose('A-0001')"; rc_is 0 "a link to a live item passes its purpose on"
    orb hub ledger --session build --by human close T-0002 --reason dropped --note "not wanted"; rc_is 0 "drop the thread"
    hq "ends_at('A-0001', E)"; out_has '^E = a_dropped_item$'
}
t_DG1() {   # c42, c17: drop a project goal
    mkhub || return
    orb --dir "$H/project-kb" drop-goal pg1 --note "we stop this"; rc_is 1 "an agent does not drop a goal"
    orb --dir "$H/project-kb" drop-goal pg9 --by human --note "x"; rc_is 1 "an unknown goal"
    orb --dir "$H/project-kb" add "dropped(pg1, human, '2026-11-24T00:00:00Z', 'by hand')" --by human; rc_is 1 "add refuses dropped/4"
    orb --dir "$H/project-kb" drop-goal pg1 --by human --note "Ty: we stop this"; rc_is 0 "drop-goal" || return
    okb --dir "$H/project-kb" query "dropped(pg1, By, _, Text)"; out_has "^By = human, Text = 'Ty: we stop this'$"
    okb --dir "$H/project-kb" query "attest(A, divergence, _, _, _, _)"; rc_is 1 "no divergence is recorded"
    orb hub orphans; rc_is 0
    out_has '^Orphans \(3\):'; out_has "^- H-0001 .*its chain ends at the dropped project goal pg1"
    out_has '^- alpha g1: it rests on the dropped project goal pg1$'
    out_has '^Dropped project goals \(1\)'; out_has '^- pg1: dropped by human at .*: Ty: we stop this$'
    out_has '^  - the goal g1 of ticket alpha rested on it$'; out_has '^  - the open item H-0001 rested on it$'
    orb hub ledger view open; [ "$(printf '%s\n' "$out" | grep -c '^| [A-Z]-')" = 4 ] || note "nothing is closed: want 4 open items"
    okb --dir "$H/specs/alpha" query "goal_rests_on_dropped(G, PG)"; rc_is 0 "the spec KB names the dropped goal"; out_has '^G = g1, PG = pg1$'
    okb --dir "$H/specs/alpha" query "blocking(X)" -n 0; out_hasnt 'dropped' "a dropped goal blocks nothing"
}
t_DG2() {   # a supports to a project goal that does not exist is a lint finding
    mkhub || return
    okb --dir "$H/specs/alpha" lint; out_hasnt 'WP10'
    sed -i 's/supports(g1, project(pg1))/supports(g1, project(pg7))/' "$H/specs/alpha/kb.pl"
    okb --dir "$H/specs/alpha" lint; out_has 'WP10' "lint names a project goal that the project KB does not hold"
    orb hub orphans; out_has '^- alpha g1: it names the project goal pg7, which the project KB does not hold$'
}
t_DG3() {   # a ticket goal that contradicts a project goal is a question for the human
    mkhub || return
    orb --dir "$H/specs/alpha" add "contradicts(g1, project(pg2))"; rc_is 0 "add contradicts" || return
    okb --dir "$H/specs/alpha" query "blocking(X)" -n 0; out_has '^X = goal_contradicts\(g1, pg2\)$' "it blocks until a human answers"
    orb --dir "$H/specs/alpha" add "question(q9, g1, 'The goal contradicts project goal pg2. Which one stands?')"; rc_is 0
    okb --dir "$H/specs/alpha" query "blocking(X)" -n 0; out_has 'goal_contradicts'
    orb --dir "$H/specs/alpha" add "answer(q9, 'The ticket goal stands for this ticket.', human)" --by human; rc_is 0 "the human answers"
    okb --dir "$H/specs/alpha" query "blocking(X)" -n 0; out_hasnt 'goal_contradicts' "answered: it blocks no more"
}

# ---------------------------------------------------------------- c46: s1-record
jsonq() { printf '%s' "$out" | python3 -c "import json,sys; d=json.load(sys.stdin); print($1)" 2>&1; }
t_DS3() {
    mkhub || return
    orb s1-record --session review --json; rc_is 0 || return
    [ "$(printf '%s\n' "$out" | wc -l)" = 1 ] || note "one JSON object on one line, and nothing else"
    [ "$(jsonq 'sorted(d)')" = "['goal', 'goal_sentences', 'hypotheses', 'questions', 'sent', 'ticket']" ] || note "the keys: $(jsonq 'sorted(d)')"
    [ "$(jsonq 'd["ticket"]')" = alpha ] || note "the active ticket of review is alpha (its handoff): $(jsonq 'd["ticket"]')"
    [ "$(jsonq 'd["goal"]')" = "{'id': 'g1', 'author': 'human', 'text': 'Alpha greets the user.'}" ] || note "goal: $(jsonq 'd["goal"]')"
    [ "$(jsonq '[(h["id"], h["author"], h["state"], h["defeating_case"], h["predictions"]) for h in d["hypotheses"]]')" = "[('hy1', 'agent', 'proposed', 'A user who starts alpha and sees no greeting.', [{'id': 'c1', 'text': 'Alpha prints a greeting at start.'}])]" ] || note "hypotheses: $(jsonq 'd["hypotheses"]')"
    [ "$(jsonq 'd["questions"]')" = "[{'id': 'q1', 'text': 'Which greeting does alpha print?'}]" ] || note "questions: $(jsonq 'd["questions"]')"
    [ "$(jsonq 'sorted(g["id"] for g in d["goal_sentences"])')" = "['alpha:g1', 'beta:h1', 'pg1', 'pg2']" ] || note "goal sentences: $(jsonq 'd["goal_sentences"]')"
    [ "$(jsonq 'd["sent"]')" = "['goal:g1', 'hypothesis:hy1', 'claim:c1', 'question:q1', 'goal_sentence:pg1', 'goal_sentence:pg2', 'goal_sentence:alpha:g1', 'goal_sentence:beta:h1']" ] || note "sent: $(jsonq 'd["sent"]')"
    printf '%s' "$out" | grep -q 'verify the greeting\|Track the work\|Make alpha greet' && note "the record holds a ledger title, a request or a project fact: only the record of c46 may be sent"
    run_in "$H" env HUB_SESSION=build "$ORB" s1-record --json; [ "$(jsonq 'd["ticket"]')" = beta ] || note "HUB_SESSION names the session: build owns the beta thread: $(jsonq 'd["ticket"]')"
    orb s1-record --session build --dir "$H/specs/alpha" --json; [ "$(jsonq 'd["ticket"]')" = alpha ] || note "--dir overrides the ledger"
}
t_DS4() {
    mkhub || return
    orb s1-record --session discovery --json; rc_is 0
    [ "$(jsonq '(d["ticket"], d["goal"], d["hypotheses"], d["questions"], d["sent"][:1])')" = "(None, None, [], [], ['goal_sentence:pg1'])" ] || note "no active ticket: $(snip "$out")"
    orb s1-record --json; rc_is 0; [ "$(jsonq 'd["ticket"]')" = None ] || note "no session: no ticket"
}

run_test t_DN1 DN1 "c19: each 0.7.2 command line answers in the same form under orbit and orbit-kb"
run_test t_DN2 DN2 "c19: version, help and a usage error name the tool as it was called; orbit-kb keeps its texts"
run_test t_DN3 DN3 "c19: query, migrate check and version answer as the 0.7.2 tool itself does, under both names"
run_test t_DN4 DN4 "c19: the saved state starts under both names; kb/bin/orbit is a link"
run_test t_DQ1 DQ1 "c26: one query joins a ledger item, its ticket and a project goal, with what blocks"
run_test t_DQ2 DQ2 "c26: the hub root: from below, --hub, none"
run_test t_DL1 DL1 "c26: a write to the ledger, to a spec KB and to the project KB goes through orbit"
run_test t_DL2 DL2 "c27: hubflow.py through the door: the same stdout, stderr, exit code, stdin and session"
run_test t_DL3 DL3 "c44: the goal ref of a ledger item (the one new ledger form)"
run_test t_DS1 DS1 "c26: hub stores lists the seven stores with counts"
run_test t_DS2 DS2 "c26: hub files lists memory, weeks and bespoke with a sha256 each"
run_test t_DR1 DR1 "c26: orbit runs a test and a z3 run with a time limit, and writes each result itself"
run_test t_DP1 DP1 "c44: the 14 cases of purpose_cases.pl give the answers that the cases name"
run_test t_DP2 DP2 "c44: hub orphans: three lists apart, each orphan once, with where its chain ends"
run_test t_DG1 DG1 "c42, c17: a dropped project goal is named on each ticket goal and item; nothing is closed; no divergence"
run_test t_DG2 DG2 "c17: a supports to a project goal that does not exist is a lint finding (WP10)"
run_test t_DG3 DG3 "c17: a ticket goal that contradicts a project goal blocks until a human answers a question about it"
run_test t_DS3 DS3 "c46: s1-record prints the record of the active ticket as one JSON object, and nothing else"
run_test t_DS4 DS4 "c46: s1-record with no active ticket: null and empty lists"
NT=${#REG_ID[@]}
for ((i = 0; i < NT; i++)); do exec_test "$i"; done
echo "----"
echo "orbit-kb=$OKB lib=$LIB pass=$pass fail=$fail skip=$skip ${failed[*]:-}"
[ $fail = 0 ]
