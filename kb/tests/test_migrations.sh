#!/usr/bin/env bash
# Black-box tests of KB migrations (hub spec KB kb-migrations, hypothesis h4, claims c2 c3 c5 c9 c10
# c12 c14 c15 c16 c17). Each test is written from the words of its claim and its check (k2 ... k17).
# The harness is a copy of the style of test_project_kb.sh: each test runs in a fresh mktemp -d, the
# summary line is `pass=N fail=N skip=N`, exit 0 when every test passes, 1 when one fails, 2 when
# the suite cannot run.
#
# Usage: kb/tests/test_migrations.sh [path-to-orbit-kb]      ONLY='<regex>' runs matching ids.
#
# Claim -> test:
#   c2  a migration adds lines only, each fact with its author; no human-only fact     : MG2
#   c3  all or nothing; refused with the reason; a rerun writes nothing                 : MG3
#   c5  steps with owners and pending queries; a marker marks nothing done              : MG5
#   c9  a closed KB is frozen: no write, not in the hub check, not on the Desk           : MG9
#   c10 a human step blocks no hub check; the KB is not done until the human answers    : MG10
#   c7  an additive migration changes no old verdict                                  : MG7
#   c12 the hub check fails only on a tool or agent step; warns on retired; no marker   : MG12
#   c6, c14 every changed verdict lies in the reach of S; S alone is not enough        : MG14
#   c15 the human sees each verdict of the reach that differs, old engine vs new        : MG15 MGU
#   c19 the kit upgrade previews closed KBs too                                     : MGC
#   c20 project_kb is read from the hub root in a hub                               : MGR
#   c16 the cut-fail clause: first clause only, facts kept, hidden, warned, never blocks : MG16
#   c17 the signature of the version only; lint flags retired, missing, other arity     : MG17
set -u

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
REPO=$(cd "$here/../.." && pwd -P)
dups=$(grep -oE '^t_[A-Za-z0-9_]+\(\)' "${BASH_SOURCE[0]}" | sort | uniq -d)
if [ -n "$dups" ]; then echo "ERROR: test functions defined twice: $(echo $dups)" >&2; exit 2; fi
OKB=${1:-${ORBIT_KB_BIN:-$here/../bin/orbit-kb}}
LIB=${ORBIT_KB_TEST_LIB:-$here/../share/orbit-kb}
TMO=${ORBIT_KB_TEST_TIMEOUT:-120}
if [ ! -f "$OKB" ] || [ ! -x "$OKB" ]; then echo "test_migrations.sh: the orbit-kb CLI is missing: $OKB" >&2; exit 2; fi
OKB=$(cd "$(dirname "$OKB")" && pwd -P)/$(basename "$OKB")
if [ -d "$LIB" ]; then LIB=$(cd "$LIB" && pwd -P); fi
if [ ! -f "$LIB/core.pl" ]; then echo "test_migrations.sh: the library is missing (no core.pl in $LIB)" >&2; exit 2; fi
for tool in swipl python3 sha256sum timeout mktemp grep sed cmp sort head cp diff curl; do
    command -v "$tool" >/dev/null 2>&1 || { echo "test_migrations.sh: required tool not found: $tool" >&2; exit 2; }
done

pass=0 fail=0 skip=0
failed=()
FAILS=()
out="" err="" rc=0
T="" K=""
base=$(mktemp -d "${TMPDIR:-/tmp}/orbit-kb-migrations-test.XXXXXX") || exit 2
base=$(cd "$base" && pwd -P)
trap 'rm -rf "$base"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
for v in $(compgen -e); do case $v in ORBIT_KB*|CLAUDE_SESSION_ID|CLAUDE_CODE_SESSION_ID|HUB_SESSION|HUBFLOW_*) unset "$v";; esac; done
export ORBIT_KB_LIB="$LIB"

ok()  { pass=$((pass+1)); echo "PASS $1 $2"; }
bad() { fail=$((fail+1)); failed+=("$1"); echo "FAIL $1 $2"; local m; for m in "${@:3}"; do echo "     - $m"; done; }
snip() { printf '%s' "$1" | head -c 400 | tr '\n' '~'; }
note() { FAILS+=("$*"); }

okb_in() {
    local d=$1; shift
    ( cd "$d" && exec timeout "$TMO" "$OKB" "$@" ) >"$T/.out" 2>"$T/.err" </dev/null
    rc=$?
    out=$(<"$T/.out"); err=$(<"$T/.err")
}
okb() { okb_in "$T" "$@"; }
anyout() { printf '%s\n%s\n' "$out" "$err"; }
rc_is() { [ "$rc" = "$1" ] && return 0; note "${2:+$2: }exit $rc, want $1 (stdout: $(snip "$out") | stderr: $(snip "$err"))"; return 1; }
out_has() { printf '%s\n' "$out" | grep -Eq -- "$1" && return 0; note "${2:+$2: }stdout lacks /$1/ (stdout: $(snip "$out"))"; return 1; }
out_hasnt() { if printf '%s\n' "$out" | grep -Eq -- "$1"; then note "${2:+$2: }stdout has /$1/, it must not (stdout: $(snip "$out"))"; return 1; fi; return 0; }
any_has() { anyout | grep -Eq -- "$1" && return 0; note "${2:+$2: }output lacks /$1/ (stdout: $(snip "$out") | stderr: $(snip "$err"))"; return 1; }
same_file() { cmp -s "$1" "$2" && return 0; note "${3:+$3: }the file changed ($1)"; return 1; }
q() { okb --dir "$K" query "$@"; }
is_true()  { q "$1"; rc_is 0 "query '$1' must hold"; }
is_false() { q "$1"; rc_is 1 "query '$1' must have no answer"; }
# only_added OLD NEW: every line of OLD is in NEW, in order, unchanged (diff shows only added lines)
only_added() { local d; d=$(diff "$1" "$2" | grep -E '^[<]' ); [ -z "$d" ] && return 0; note "${3:+$3: }a line changed or went: $(snip "$d")"; return 1; }

REG_FN=() REG_ID=() REG_DESC=()
run_test() {
    local fn=$1 id=$2 desc=$3
    if [ -n "${ONLY:-}" ] && ! [[ $id =~ $ONLY ]]; then return 0; fi
    REG_FN+=("$fn"); REG_ID+=("$id"); REG_DESC+=("$desc")
}
exec_test() {
    local i=$1
    T=$(mktemp -d "$base/${REG_ID[$i]}.XXXXXX") || return 1
    T=$(cd "$T" && pwd -P)
    FAILS=(); out=""; err=""; rc=0; K=""
    XDG_CACHE_HOME=$T/.cache; export XDG_CACHE_HOME; mkdir "$XDG_CACHE_HOME"
    export ORBIT_KB_LIB="$LIB"
    cd "$T" || return 1
    "${REG_FN[$i]}"
    cd "$here" || true
    if [ ${#FAILS[@]} -eq 0 ]; then ok "${REG_ID[$i]}" "${REG_DESC[$i]}"
    else bad "${REG_ID[$i]}" "${REG_DESC[$i]}" "${FAILS[@]}"; fi
    rm -rf "$T"
}

# ---------------------------------------------------------------- builders (invented content)
# fxlib: a copy of the library in $T/lib with the fixture migrations below; ORBIT_KB_LIB points to it.
# The fixture version retires oldkind/2 (replaced by newkind/2), backfills a note on each claim (a tool
# step), and asks the human to approve each claim again (a human step). The real migrations stay.
fxlib() {
    cp -rL "$LIB" "$T/lib" || { note "setup: cannot copy the library"; return 1; }
    cat > "$T/lib/migrations/9.9.9-fixture.pl" <<'EOF'
migration(m_retire, '9.9.9', 'oldkind/2 is retired; newkind/2 replaces it.').
retires(m_retire, oldkind/2, newkind/2).
migration(m_note, '9.9.9', 'Each claim gets a note.').
changes(m_note, [note/2]).
step(m_note, notes, tool, 'a note on each claim').
pending(m_note, notes, C, (claim(C, _, _), not note(C, _))).
writes(m_note, notes, C, [note(C, 'backfilled by the fixture')]).
migration(m_again, '9.9.9', 'The human approves each claim again.').
changes(m_again, [question/3]).
step(m_again, again, human, 'the human approves the claim again').
pending(m_again, again, C, (claim(C, _, _), not cites(C, _))).
asks(m_again, again, C, 'Do you approve claim ~w again?').
EOF
    export ORBIT_KB_LIB="$T/lib"
}
# kb_new DIR: a build KB from stdin, as an older orbit-kb wrote it (made by 0.4.0)
kb_new() { mkdir -p "$1"; cat > "$1/kb.pl"; K=$1; }
kb_old() {  # a KB with a claim, a check with words, and two facts of the retired oldkind/2
    kb_new "$1" <<'EOF'
uses([build]).
request(r1, 'Exports keep their header row').
% Made by orbit-kb 0.4.0.
claim(c1, introduce, 'The export has a header row').
example(c1, 'orders.csv starts with id,total').
check(k1, c1).
checks_that(k1, 'the first line of the export names the columns').
oldkind(o1, 'first').
oldkind(o2, 'second').
EOF
}
plan_seen() { okb --dir "$K" migrate plan "$@"; SEEN=$(printf '%s\n' "$out" | sed -n 's/^Seen: //p' | head -n1); }
# a hub with the ledger: mkhub DIR
mkhub() { mkdir -p "$1/.claude/scripts" "$1/specs"; cp "$REPO/hubkit/hub/.claude/scripts/hubflow.py" "$REPO/hubkit/hub/.claude/scripts/desk.py" "$1/.claude/scripts/"
          cp "$REPO/hubkit/hub/flow/seed.json" "$1/seed.json"
          ( cd "$1" && python3 .claude/scripts/hubflow.py --hub "$1" init --seed seed.json ) >/dev/null 2>&1 || note "setup: hub init failed"; }
hf() { local H=$1; shift; ( cd "$H" && HUBFLOW_ORBIT_KB="$OKB" HUB_SESSION=build python3 .claude/scripts/hubflow.py --hub "$H" "$@" ) >"$T/.out" 2>"$T/.err"; rc=$?; out=$(<"$T/.out"); err=$(<"$T/.err"); }

# ================================================================ c2
t_MG2() {
    fxlib || return; kb_old "$T/k"; cp "$K/kb.pl" "$T/before.pl"
    plan_seen; rc_is 0 "plan" || return
    okb --dir "$K" migrate apply --seen "$SEEN"; rc_is 0 "apply" || return
    only_added "$T/before.pl" "$K/kb.pl" "c2: the migration"
    # each added fact names its migration and the tool version: the line after it is its migration_added
    local added; added=$(diff "$T/before.pl" "$K/kb.pl" | sed -n 's/^> //p' | grep -vE '^%|:- !, fail\.$|^migration_added\(')
    [ -n "$added" ] || note "the migration added no fact"
    local f; while IFS= read -r f; do
        grep -Fxq -- "$f" "$K/kb.pl" || continue
        local n; n=$(grep -nFx -- "$f" "$K/kb.pl" | head -n1 | cut -d: -f1)
        sed -n "$((n+1))p" "$K/kb.pl" | grep -Eq "^migration_added\((m_[a-z]+), '[0-9]+\.[0-9]+\.[0-9]+', " \
            || note "the fact on line $n has no migration_added after it: $f"
    done <<< "$added"
    # the human step: a question, never the human's own record
    grep -Eq "^question\(q[0-9]+, c1, 'Do you approve claim c1 again\?'\)\.$" "$K/kb.pl" || note "the human step raised no question"
    grep -Eq '^(answer\(.*human|attest\(.*approval)' "$K/kb.pl" && note "the migration wrote a human record"
    # a migration that would write a human-only record is refused with no write
    cat > "$T/lib/migrations/9.9.9-human.pl" <<'EOF'
migration(m_bad, '9.9.9', 'Writes the answer of a human itself.').
changes(m_bad, [answer/3]).
step(m_bad, fake, tool, 'answer for the human').
pending(m_bad, fake, Q, (question(Q, _, _), not answered(Q))).
writes(m_bad, fake, Q, [answer(Q, yes, human)]).
EOF
    cp "$K/kb.pl" "$T/mid.pl"
    plan_seen; any_has "only a human may make" "the plan names the human-only record"
    okb --dir "$K" migrate apply --seen "${SEEN:-sha256:none}"; rc_is 1 "apply of a human-only write is refused"
    same_file "$K/kb.pl" "$T/mid.pl" "a refused apply"
    # review a88: a decision of the project module is the human's too
    rm -f "$T/lib/migrations/9.9.9-human.pl"
    cat > "$T/lib/migrations/9.9.9-decide.pl" <<'EOF'
migration(m_decide, '9.9.9', 'Writes a decision itself.').
changes(m_decide, [decision/2]).
step(m_decide, decide, tool, 'a decision for each claim').
pending(m_decide, decide, C, (claim(C, _, _), not note(C, 'decided'))).
writes(m_decide, decide, C, [decision(d1, 'Ship it')]).
EOF
    plan_seen; any_has "decision\(d1, ?'Ship it'\), a record that only a human may make" "a decision is human-only"
    okb --dir "$K" migrate apply --seen "${SEEN:-sha256:none}"; rc_is 1 "apply of a decision is refused"
    same_file "$K/kb.pl" "$T/mid.pl" "a refused apply of a decision"
}

# ================================================================ c3
t_MG3() {
    fxlib || return; kb_old "$T/k"; cp "$K/kb.pl" "$T/before.pl"
    # refused with the reason, no write: no --seen, a stale --seen, a KB made by a newer orbit-kb
    okb --dir "$K" migrate apply; rc_is 1 "apply with no --seen"; any_has "no --seen"; same_file "$K/kb.pl" "$T/before.pl" "no --seen"
    okb --dir "$K" migrate apply --seen sha256:0000; rc_is 1 "apply with a stale --seen"; any_has "changed since it was shown"
    same_file "$K/kb.pl" "$T/before.pl" "a stale --seen"
    kb_new "$T/new" <<'EOF'
uses([build]).
request(r1, 'From the future').
% Made by orbit-kb 99.0.0.
claim(c1, introduce, 'A claim').
oldkind(o1, 'first').
EOF
    cp "$T/new/kb.pl" "$T/new.before"
    okb --dir "$T/new" migrate apply --seen sha256:0000; rc_is 1 "a newer KB"; any_has "newer than this orbit-kb"
    same_file "$T/new/kb.pl" "$T/new.before" "a KB made by a newer orbit-kb"
    # one run, then a second run writes nothing: the digest of two runs is the digest of one
    K=$T/k; plan_seen; okb --dir "$K" migrate apply --seen "$SEEN"; rc_is 0 "the first apply" || return
    cp "$K/kb.pl" "$T/after.pl"
    okb --dir "$K" migrate apply; rc_is 0 "the second apply"; any_has "Nothing to write"
    same_file "$K/kb.pl" "$T/after.pl" "a second run"
    plan_seen; any_has "Nothing to write" "plan after the run"
    # killed at any time: kb.pl is the old file or the whole new one, never half (40 kills)
    # the time of one whole apply sets the kill times: from 5% to 130% of it
    local i ok_old=0 ok_new=0 d t0 t1 full
    cp "$T/before.pl" "$K/kb.pl"; plan_seen
    t0=$(date +%s%N); okb --dir "$K" migrate apply --seen "$SEEN"; t1=$(date +%s%N)
    full=$(( (t1 - t0) / 1000000 ))
    for i in $(seq 1 40); do
        cp "$T/before.pl" "$K/kb.pl"; rm -f "$K/writer.lock"
        plan_seen
        d=$(awk -v i="$i" -v f="$full" 'BEGIN{printf "%.3f", f * (0.05 + (i % 26) * 0.05) / 1000}')
        ( cd "$T" && exec timeout -s KILL "$d" "$OKB" --dir "$K" migrate apply --seen "$SEEN" ) >/dev/null 2>&1
        if cmp -s "$K/kb.pl" "$T/before.pl"; then ok_old=$((ok_old+1))
        elif diff <(grep -v '^% orbit-kb migrate apply' "$K/kb.pl") <(grep -v '^% orbit-kb migrate apply' "$T/after.pl") >/dev/null; then ok_new=$((ok_new+1))
        else note "kill $i after ${d}s left half a run: $(snip "$(diff "$T/before.pl" "$K/kb.pl")")"; break; fi
    done
    [ "$ok_old" -gt 0 ] && [ "$ok_new" -gt 0 ] || note "the kills did not reach both outcomes (old $ok_old, new $ok_new): the check could not fail"
}

# ================================================================ c5
t_MG5() {
    # the real 0.5.0 migration: an agent step, with a work list, done only when W12 is gone
    kb_new "$T/k" <<'EOF'
uses([build]).
request(r1, 'Exports keep their header row').
% Made by orbit-kb 0.4.0.
claim(c1, introduce, 'The export has a header row').
check(k1, c1).
check(k2, c1).
EOF
    cp "$K/kb.pl" "$T/before.pl"
    okb --dir "$K" migrate check; rc_is 1 "an agent step is to do"
    out_has '^todo m_0_5_0_checks_that words agent 2: .* k1 k2$' "the work list of the agent step"
    okb --dir "$K" migrate apply; rc_is 0; any_has "Nothing to write" "the tool writes no agent step"
    same_file "$K/kb.pl" "$T/before.pl" "apply of an agent step"
    # a marker added by hand does not make the step done
    echo "migration_added(m_0_5_0_checks_that, '0.5.0', done)." >> "$K/kb.pl"
    okb --dir "$K" migrate check; rc_is 1 "a stored marker marks nothing done"
    okb --dir "$K" add "checks_that(k1, 'the first line names the columns')"; rc_is 0
    okb --dir "$K" migrate check; rc_is 1 "one check still has no words"; out_has ' 1: .* k2$'
    okb --dir "$K" add "checks_that(k2, 'the export has no empty line')"; rc_is 0
    okb --dir "$K" migrate check; rc_is 0 "the step is done once its pending query has no answer"; out_hasnt '^todo'
    # steps of all three owners (fixture): the tool writes, the agent gets a list, the human a question
    fxlib || return; kb_old "$T/f"
    okb --dir "$K" migrate check; rc_is 1
    out_has "^todo m_retire retire\(oldkind/2\) tool 1"; out_has "^todo m_note notes tool 1: .* c1$"; out_has "^migrating m_again again human 1"
}

# ================================================================ c9, c10, c12: the hub check
hub_two() {  # a hub with spec KBs open and closed that both need every fixture migration and W12
    mkhub "$T/h"
    local s; for s in open closed; do
        kb_new "$T/h/specs/$s" <<'EOF'
uses([build]).
request(r1, 'Exports keep their header row').
% Made by orbit-kb 0.4.0.
claim(c1, introduce, 'The export has a header row').
example(c1, 'orders.csv starts with id,total').
check(k1, c1).
oldkind(o1, 'first').
EOF
    done
    hf "$T/h" add thread --title "build open" --ref kb:open; rc_is 0 "setup: a thread on kb:open" || return 1
    hf "$T/h" add thread --title "build closed" --ref kb:closed; rc_is 0 "setup: a thread on kb:closed" || return 1
    local id; id=$(printf '%s' "$out" | grep -oE 'T-[0-9]+' | head -n1)
    hf "$T/h" close "$id" --reason done --by human --session human --note "shipped"; rc_is 0 "setup: the human closes the closed ticket" || return 1
}
t_MG9() {
    fxlib || return; hub_two || return
    cp "$T/h/specs/closed/kb.pl" "$T/closed.before"
    hf "$T/h" kb-state closed; out_has '^closed$'; hf "$T/h" kb-state open; out_has '^open$'
    hf "$T/h" migrations; rc_is 1 "the open KB has required steps"
    out_has 'kb:open'; out_hasnt 'kb:closed' "the hub check names no closed KB"
    out_has '^# frozen \(closed tickets, not checked\): 1$'
    K=$T/h/specs/closed; plan_seen
    okb --dir "$K" migrate apply --seen "${SEEN:-sha256:none}"; rc_is 1 "apply on a closed KB"; any_has "frozen"
    same_file "$K/kb.pl" "$T/closed.before" "the closed KB"
    # review a93: when the ledger cannot say open or closed, apply fails closed
    K=$T/h/specs/open; plan_seen; cp "$K/kb.pl" "$T/open.before"
    mv "$T/h/flow/flow.db" "$T/flow.db.away"
    okb --dir "$K" migrate apply --seen "$SEEN"; rc_is 1 "apply when kb-state cannot answer"; any_has "may be frozen"
    same_file "$K/kb.pl" "$T/open.before" "a KB whose state the ledger cannot give"
    mv "$T/flow.db.away" "$T/h/flow/flow.db"
    K=$T/h/specs/open; plan_seen; okb --dir "$K" migrate apply --seen "$SEEN"; rc_is 0 "apply on the open KB" || return
    grep -q "Do you approve claim c1 again" "$T/h/specs/open/kb.pl" || note "the open KB has no question"
    # the Desk: the question of the open KB is there, nothing of the closed one
    export DESK_STATE="$T/desk-state"
    ( cd "$T" && exec timeout "$TMO" "$OKB" serve desk --port 0 --hub "$T/h" ) >"$T/.srv.out" 2>"$T/.srv.err" </dev/null &
    local spid=$! url="" i
    for i in $(seq 1 200); do url=$(grep -oE 'http://127\.0\.0\.1:[0-9]+' "$T/.srv.out" 2>/dev/null | head -n1); [ -n "$url" ] && break; sleep 0.05; done
    if [ -z "$url" ]; then note "the Desk did not start: $(snip "$(cat "$T/.srv.err")")"
    else
        curl -s --max-time 30 -o "$T/page.html" "$url/"
        grep -q "Do you approve claim c1 again" "$T/page.html" || note "the Desk does not show the question of the open KB"
        [ "$(grep -o 'Do you approve claim c1 again' "$T/page.html" | wc -l)" -ge 1 ] || true
        # the agent step of the closed KB (its checks have no words) has no fix on the Desk; the open one has
        grep -Fq "fix:words:$T/h/specs/closed" "$T/page.html" && note "the Desk shows the words step of the closed KB"
        grep -Fq "fix:words:$T/h/specs/open" "$T/page.html" || note "the Desk does not show the words step of the open KB"
        grep -Eiq 'retired|WM1' "$T/page.html" && note "the Desk shows a retired-predicate warning"
    fi
    kill "$spid" 2>/dev/null; wait "$spid" 2>/dev/null
    same_file "$T/h/specs/closed/kb.pl" "$T/closed.before" "the closed KB after the run"
}
t_MG10() {
    fxlib || return; hub_two || return
    K=$T/h/specs/open; plan_seen; okb --dir "$K" migrate apply --seen "$SEEN"; rc_is 0 || return
    # the agent step of W12 is required: do it, so only the human step is left
    okb --dir "$K" add "checks_that(k1, 'the first line names the columns')"; rc_is 0
    # review a94: make done hold but for the question, so is_false done can fail
    okb --dir "$K" run k1 -- false >/dev/null; okb --dir "$K" run k1 -- true >/dev/null; rc_is 0 "setup: k1 red, then green"
    hf "$T/h" migrations; rc_is 0 "a human step alone does not fail the hub check"
    out_has '^migrating: kb:open m_again again human 1' "the KB shows as migrating"
    is_true 'to_ask(Q)'; is_false 'done'
    local qid; qid=$(grep -oE "^question\((q[0-9]+), c1, 'Do you approve" "$K/kb.pl" | grep -oE 'q[0-9]+' | head -n1)
    okb --dir "$K" add "answer($qid, yes, human)" --by human; rc_is 0 "the human answers"
    is_false 'to_ask(Q)'
    is_true 'done' "once the human answers, nothing else keeps done false"
}
t_MG12() {
    fxlib || return; hub_two || return
    hf "$T/h" migrations; rc_is 1 "required steps fail the check"
    out_has '^todo: kb:open m_0_5_0_checks_that words agent 1: .* k1$' "names the KB, the migration, the step and the work"
    out_has '^todo: kb:open m_retire'; out_has '^todo: kb:open m_note'
    # a stored done marker does not change it
    echo "migration_added(m_0_5_0_checks_that, '0.5.0', done)." >> "$T/h/specs/open/kb.pl"
    hf "$T/h" migrations; rc_is 1 "a marker does not pass the check"
    K=$T/h/specs/open; plan_seen; okb --dir "$K" migrate apply --seen "$SEEN"; rc_is 0 || return
    okb --dir "$K" add "checks_that(k1, 'the first line names the columns')"; rc_is 0
    okb --dir "$K" add "cites(c1, 'Exports keep their header row')"; rc_is 0
    hf "$T/h" migrations; rc_is 0 "no required step is left: the check passes"
    out_has '^retired: kb:open oldkind/2 1 fact' "it still warns about the retired predicate"
    out_hasnt '^todo'
}

# ================================================================ c14: the reach
t_MG14() {
    fxlib || return
    kb_new "$T/k" <<'EOF'
uses([build]).
request(r1, 'Exports keep their header row').
% Made by orbit-kb 0.5.0.
claim(c1, introduce, 'The export has a header row').
example(c1, 'orders.csv starts with id,total').
cites(c1, 'Exports keep their header row').
check(k1, c1).
checks_that(k1, 'the first line names the columns').
check(k2, c1).
EOF
    # a tool migration that backfills checks_that(k2), declared as S = {checks_that/2} only:
    # lint W12 reads checks_that under not, so it is in the reach, and it changes; current(c1) is not
    # 0.8.0 (scientific-method-overhaul c19): the migration of 0.8.0 declares current/1 as changed, so it goes too
    rm -f "$T/lib/migrations/9.9.9-fixture.pl" "$T/lib/migrations/0.5.0-checks_that.pl" "$T/lib/migrations/0.8.0-scientific-method.pl"
    cat > "$T/lib/migrations/9.9.9-words.pl" <<'EOF'
migration(m_words, '9.9.9', 'Backfill the words of each check.').
changes(m_words, [checks_that/2]).
step(m_words, words, tool, 'words for each check').
pending(m_words, words, K, (check(K, _), not checks_that(K, _))).
writes(m_words, words, K, [checks_that(K, 'backfilled words')]).
EOF
    plan_seen; rc_is 0 "a change within the reach is accepted"
    out_has '^Reach of S \(c14\): .*lint W12' "W12 is in the reach of checks_that/2"
    out_hasnt '^Reach of S \(c14\): .*current/1' "current/1 is not in the reach"
    out_has 'lint W12 \(count\): 1 -> none \(in the reach\)'
    # the mutant: S names only a predicate that W12 does not read: the change is outside, apply refuses
    sed -i 's/changes(m_words, \[checks_that\/2\])/changes(m_words, [note\/2])/' "$T/lib/migrations/9.9.9-words.pl"
    cp "$K/kb.pl" "$T/before.pl"
    plan_seen; rc_is 1 "plan refuses a change outside the reach"
    out_has 'lint W12 \(count\): 1 -> none \(OUTSIDE the reach'
    okb --dir "$K" migrate apply --seen "${SEEN:-sha256:none}"; rc_is 1 "apply refuses"
    same_file "$K/kb.pl" "$T/before.pl" "a refused apply"
}

# ================================================================ c7: an additive migration
t_MG7() {
    fxlib || return
    # 0.8.0 (scientific-method-overhaul c19): the migration of 0.8.0 declares changes of old rules, so it goes too
    rm -f "$T/lib/migrations/9.9.9-fixture.pl" "$T/lib/migrations/0.6.0-project-root.pl" "$T/lib/migrations/0.8.0-scientific-method.pl"   # the additive migration alone
    # the new version adds a fact kind and a rule that only reads it; no old rule reads either
    cat >> "$T/lib/core.pl" <<'EOF'
decl(fact, fx_bounds(atom, text), 'The bounds of the runs of a check (a fixture).', 'check @(1) runs with bounds @(2)').
decl(rule, fx_bounded(atom), 'The check has bounds (a fixture).', 'check @(1) has bounds').
fx_bounded(K) :- fx_bounds(K, _).
EOF
    cat > "$T/lib/migrations/9.9.9-add.pl" <<'EOF'
migration(m_add, '9.9.9', 'Each check gets its bounds (new kind fx_bounds/2).').
changes(m_add, [fx_bounds/2, fx_bounded/1]).
step(m_add, bounds, tool, 'the bounds of each check').
pending(m_add, bounds, K, (check(K, _), not fx_bounds(K, _))).
writes(m_add, bounds, K, [fx_bounds(K, 'n = 3')]).
EOF
    kb_new "$T/k" <<'EOF'
uses([build]).
request(r1, 'Exports keep their header row').
% Made by orbit-kb 0.5.0.
claim(c1, introduce, 'The export has a header row').
example(c1, 'orders.csv starts with id,total').
cites(c1, 'Exports keep their header row').
check(k1, c1).
checks_that(k1, 'the first line names the columns').
check(k2, c1).
checks_that(k2, 'the export has no empty line').
EOF
    plan_seen; rc_is 0 "an additive migration is accepted" || return
    out_has '^Reach of S \(c14\): fx_bounded/1, fx_bounds/2$' "the reach of an additive change holds only the new predicates"
    out_has '^Verdicts: none differs\.$' "no old verdict changes"
    okb --dir "$K" migrate apply --seen "$SEEN"; rc_is 0 "apply"
    is_true 'fx_bounded(k2)'
}

# ================================================================ c15: old engine vs new
t_MG15() {
    # the old engine: a copy of this orbit-kb whose library has no lint W12 (as before 0.5.0)
    mkdir -p "$T/old/bin" "$T/old/share"; cp "$OKB" "$T/old/bin/orbit-kb"; cp -rL "$LIB" "$T/old/share/orbit-kb"
    rm -rf "$T/old/share/orbit-kb/migrations"
    python3 -I - "$T/old/share/orbit-kb/core.pl" <<'PY'
import re, sys
p = sys.argv[1]; s = open(p).read()
s2 = re.sub(r"lint_issue\('W12'.*?not checks_that\(K, _\)\.\n", "", s, flags=re.S)
assert s2 != s; open(p, "w").write(s2)
PY
    kb_new "$T/k" <<'EOF'
uses([build]).
request(r1, 'Exports keep their header row').
% Made by orbit-kb 0.4.0.
claim(c1, introduce, 'The export has a header row').
example(c1, 'orders.csv starts with id,total').
cites(c1, 'Exports keep their header row').
check(k1, c1).
EOF
    plan_seen --old "$T/old/bin/orbit-kb"; rc_is 0 "W12 is declared by the 0.5.0 migration"
    out_has 'Old side: .*old/bin/orbit-kb'
    out_has 'lint W12 \(count\): none -> 1 \(in the reach\)' "the preview shows the verdict that the engine changes"
    out_hasnt 'OUTSIDE'
    # the mutant: the 0.5.0 migration forgets W12 and checks_that: the engine's change is outside
    fxlib || return
    sed -i "s/changes(m_0_5_0_checks_that, \[checks_that\/2, lint('W12')\])/changes(m_0_5_0_checks_that, [])/" "$T/lib/migrations/0.5.0-checks_that.pl"
    rm -f "$T/lib/migrations/9.9.9-fixture.pl"
    grep -q "changes(m_0_5_0_checks_that, \[\])" "$T/lib/migrations/0.5.0-checks_that.pl" || { note "setup: the mutant did not apply"; return; }
    plan_seen --old "$T/old/bin/orbit-kb"; rc_is 1 "an undeclared change of the engine is refused"
    out_has 'lint W12 \(count\): none -> 1 \(OUTSIDE the reach'
    # review a128: a KB that names its project KB by a relative path (as each spec KB of a hub does)
    # gives the same verdicts on both sides, and the plan leaves no shadow directory behind
    export ORBIT_KB_LIB="$LIB"
    mkdir -p "$T/hub/specs"
    okb init "$T/hub/project-kb" --request 'Where the product goes' --uses project >/dev/null; rc_is 0 "setup: the project KB" || return
    kb_new "$T/hub/specs/p" <<'EOF'
uses([build, project]).
request(r1, 'Exports keep their header row').
% Made by orbit-kb 0.5.0.
project_kb('../../project-kb').
claim(c1, introduce, 'The export has a header row').
example(c1, 'orders.csv starts with id,total').
cites(c1, 'Exports keep their header row').
check(k1, c1).
EOF
    # WP2 checks a pin only: pin a decision of the project KB, with the digest that the tool gives
    okb --dir "$T/hub/project-kb" add "decision(d1, 'Exports keep their header')" --by human; rc_is 0 "setup: a decision" || return
    okb --dir "$K" query 'project_decision_digest(d1, D)'; local pd; pd=$(printf '%s\n' "$out" | sed -n 's/^D = //p')
    [ -n "$pd" ] || { note "setup: no digest of d1"; return; }
    okb --dir "$K" add "pins(c1, project, d1, $pd)"; rc_is 0 "setup: the pin" || return
    okb --dir "$K" lint; out_hasnt '^WP2' "setup: the pin resolves in the KB itself"
    plan_seen --old "$OKB"; rc_is 0 "plan on a KB with a relative project_kb"
    out_hasnt 'lint WP2 \(count\)' "the project KB resolves on the new side too"; out_hasnt 'OUTSIDE'
    [ -z "$(ls -a "$T/hub/specs" | grep orbit-mig)" ] || note "plan left a shadow directory in specs/"
}

# ================================================================ c15: the kit upgrade shows the preview
# review a99: a change of verdicts lands when the hub gets the new engine, not at migrate apply. A hub
# installed from an older kit A (no lint W12) is upgraded with this kit B: the dry run shows, for the
# open spec KB, the verdict that B's engine changes; --yes needs the digest of that preview.
mkkit() {  # mkkit DIR: a kit checkout layout with this hubkit, this prompt, this orbit-kb and library
    mkdir -p "$1/kb/bin" "$1/kb/share"; cp -r "$REPO/hubkit" "$REPO/prompt" "$1/"
    cp "$OKB" "$1/kb/bin/orbit-kb"; cp "$REPO/kb/bin/repo-map" "$1/kb/bin/"; cp -rL "$LIB" "$1/kb/share/orbit-kb"
}
t_MGU() {
    mkkit "$T/A"; mkkit "$T/B"
    rm -rf "$T/A/kb/share/orbit-kb/migrations"; echo "% kit A" >> "$T/A/kb/bin/orbit-kb"
    python3 -I - "$T/A/kb/share/orbit-kb/core.pl" <<'PY'
import re, sys
p = sys.argv[1]; s = open(p).read()
s2 = re.sub(r"lint_issue\('W12'.*?not checks_that\(K, _\)\.\n", "", s, flags=re.S)
assert s2 != s; open(p, "w").write(s2)
PY
    python3 -I "$T/A/hubkit/tools/hubkit.py" install --hub "$T/h" --edition formal >/dev/null 2>&1 || { note "setup: install from kit A failed"; return; }
    ( cd "$T/h" && python3 .claude/scripts/hubflow.py --hub "$T/h" init --seed flow/seed.json ) >/dev/null 2>&1
    kb_new "$T/h/specs/open" <<'EOF'
uses([build]).
request(r1, 'Exports keep their header row').
% Made by orbit-kb 0.5.0.
claim(c1, introduce, 'The export has a header row').
example(c1, 'orders.csv starts with id,total').
cites(c1, 'Exports keep their header row').
check(k1, c1).
EOF
    hf "$T/h" add thread --title "build open" --ref kb:open; rc_is 0 "setup: a thread on kb:open" || return
    cp "$T/h/.claude/orbit-kb/bin/orbit-kb" "$T/engine.before"
    K=$T/h
    rc=0; out=$(cd "$T" && python3 -I "$T/B/hubkit/tools/hubkit.py" upgrade --hub "$T/h" 2>&1) || rc=$?
    rc_is 0 "the dry run" || return
    out_has '^migration preview' "the dry run shows the migration preview"
    out_has '^kb:open$'; out_has 'lint W12 \(count\): none -> 1 \(in the reach\)' "the verdict that the new engine changes"
    local dg; dg=$(printf '%s\n' "$out" | sed -n 's/^preview digest: //p')
    [ -n "$dg" ] || { note "no preview digest"; return; }
    rc=0; out=$(cd "$T" && python3 -I "$T/B/hubkit/tools/hubkit.py" upgrade --hub "$T/h" --yes 2>&1) || rc=$?
    rc_is 1 "--yes with no --seen-migrations is refused"; any_has 'seen-migrations'
    same_file "$T/h/.claude/orbit-kb/bin/orbit-kb" "$T/engine.before" "a refused upgrade copies nothing"
    # the mutant: kit B's migration forgets W12: the change is undeclared, and --yes is refused even with the digest
    cp -r "$T/B" "$T/Bm"
    sed -i "s/changes(m_0_5_0_checks_that, \[checks_that\/2, lint('W12')\])/changes(m_0_5_0_checks_that, [])/" "$T/Bm/kb/share/orbit-kb/migrations/0.5.0-checks_that.pl"
    local dm; dm=$(cd "$T" && python3 -I "$T/Bm/hubkit/tools/hubkit.py" upgrade --hub "$T/h" 2>&1 | sed -n 's/^preview digest: //p')
    rc=0; out=$(cd "$T" && python3 -I "$T/Bm/hubkit/tools/hubkit.py" upgrade --hub "$T/h" --yes --seen-migrations "$dm" 2>&1) || rc=$?
    rc_is 1 "an undeclared change of the engine refuses the upgrade"; any_has 'outside the declared reach'
    same_file "$T/h/.claude/orbit-kb/bin/orbit-kb" "$T/engine.before" "the refused upgrade"
    rc=0; out=$(cd "$T" && python3 -I "$T/B/hubkit/tools/hubkit.py" upgrade --hub "$T/h" --yes --seen-migrations "$dg" 2>&1) || rc=$?
    rc_is 0 "--yes with the digest of the preview upgrades"
    cmp -s "$T/h/.claude/orbit-kb/bin/orbit-kb" "$T/B/kb/bin/orbit-kb" || note "the hub did not get the new engine"
}

# ================================================================ c19: closed KBs are previewed too
# Ty, q20: "Include closed KBs". A new engine changes how a closed KB reads too, so the kit upgrade
# previews it; a migration still writes nothing to it (c9).
t_MGC() {
    mkkit "$T/A"; mkkit "$T/B"
    rm -rf "$T/A/kb/share/orbit-kb/migrations"; echo "% kit A" >> "$T/A/kb/bin/orbit-kb"
    python3 -I - "$T/A/kb/share/orbit-kb/core.pl" <<'PY'
import re, sys
p = sys.argv[1]; s = open(p).read()
s2 = re.sub(r"lint_issue\('W12'.*?not checks_that\(K, _\)\.\n", "", s, flags=re.S)
assert s2 != s; open(p, "w").write(s2)
PY
    python3 -I "$T/A/hubkit/tools/hubkit.py" install --hub "$T/h" --edition formal >/dev/null 2>&1 || { note "setup: install from kit A failed"; return; }
    ( cd "$T/h" && python3 .claude/scripts/hubflow.py --hub "$T/h" init --seed flow/seed.json ) >/dev/null 2>&1
    kb_new "$T/h/specs/shut" <<'EOF'
uses([build]).
request(r1, 'Exports keep their header row').
% Made by orbit-kb 0.5.0.
claim(c1, introduce, 'The export has a header row').
example(c1, 'orders.csv starts with id,total').
cites(c1, 'Exports keep their header row').
check(k1, c1).
EOF
    hf "$T/h" add thread --title "build shut" --ref kb:shut; rc_is 0 "setup: a thread on kb:shut" || return
    local id; id=$(printf '%s' "$out" | grep -oE 'T-[0-9]+' | head -n1)
    hf "$T/h" close "$id" --reason done --by human --session human --note "shipped"; rc_is 0 "setup: close the ticket" || return
    cp "$T/h/specs/shut/kb.pl" "$T/shut.before"
    # review a166: KBs of the form before 0.3.0 (W<n>/analyses/<slug>/...) are KBs of the hub too: one
    # open, one closed, at different depths
    local s; for s in "W1/analyses/old/kb" "W2/analyses/gone/impl/kb-build"; do
        mkdir -p "$T/h/$s"; cp "$T/h/specs/shut/kb.pl" "$T/h/$s/kb.pl"; done
    hf "$T/h" add thread --title "build old" --ref kb:old; rc_is 0 "setup: a thread on kb:old" || return
    hf "$T/h" add thread --title "build gone" --ref kb:gone; rc_is 0 "setup: a thread on kb:gone" || return
    id=$(printf '%s' "$out" | grep -oE 'T-[0-9]+' | head -n1)
    hf "$T/h" close "$id" --reason done --by human --session human --note "shipped"; rc_is 0 "setup: close gone" || return
    cp "$T/h/W2/analyses/gone/impl/kb-build/kb.pl" "$T/gone.before"
    # review a166: a hub on kit 0.9.0 has a hubflow with no kb-state; the preview must not need it
    sed -i '/"kb-state": cmd_kb_state/s/, "kb-state": cmd_kb_state//' "$T/h/.claude/scripts/hubflow.py"
    ! grep -q '"kb-state": cmd_kb_state' "$T/h/.claude/scripts/hubflow.py" || { note "setup: kb-state is still in the hub's hubflow"; return; }
    rc=0; out=$(cd "$T" && python3 -I "$T/B/hubkit/tools/hubkit.py" upgrade --hub "$T/h" 2>&1) || rc=$?
    rc_is 0 "the dry run" || return
    out_has '^kb:shut \(closed: previewed; no migration writes to it\)$' "the closed KB is previewed and labeled"
    out_has 'lint W12 \(count\): none -> 1 \(in the reach\)' "the verdict that the new engine changes on the closed KB"
    out_has '^kb:W1/analyses/old/kb$' "an open KB of the old form is previewed"
    out_has '^kb:W2/analyses/gone/impl/kb-build \(closed: previewed; no migration writes to it\)$' "a closed KB of the old form, deeper, is previewed and labeled"
    local dg; dg=$(printf '%s\n' "$out" | sed -n 's/^preview digest: //p')
    rc=0; out=$(cd "$T" && python3 -I "$T/B/hubkit/tools/hubkit.py" upgrade --hub "$T/h" --yes --seen-migrations "$dg" 2>&1) || rc=$?
    rc_is 0 "--yes with the digest upgrades"
    same_file "$T/h/specs/shut/kb.pl" "$T/shut.before" "the closed KB after the upgrade"
    # after the upgrade: the hub check names the open old-form KB; apply refuses the closed old-form KB
    hf "$T/h" migrations; rc_is 1 "the open old-form KB has a required step"
    out_has '^todo: kb:W1/analyses/old/kb m_0_5_0_checks_that' "the hub check names the open old-form KB"
    out_hasnt 'kb:W2/analyses/gone' "the hub check skips the closed old-form KB"
    okb --dir "$T/h/W2/analyses/gone/impl/kb-build" migrate apply --seen sha256:none; rc_is 1 "apply on a closed old-form KB"; any_has "frozen"
    same_file "$T/h/W2/analyses/gone/impl/kb-build/kb.pl" "$T/gone.before" "the closed old-form KB"
}

# ================================================================ c20: project_kb from the hub root
# Ty, q21: "B: resolve from hub root". In a hub, a relative project_kb is read from the hub root, so
# a KB moved inside the hub (W0/analyses/x/kb to specs/x) keeps its link with no write.
t_MGR() {
    mkdir -p "$T/h/flow" "$T/h/specs" "$T/h/W0/analyses/x"; echo '{}' > "$T/h/flow/seed.json"
    okb init "$T/h/project-kb" --request 'Where the product goes' --uses project >/dev/null; rc_is 0 "setup: the project KB" || return
    okb --dir "$T/h/project-kb" add "decision(d1, 'Exports keep their header')" --by human; rc_is 0 "setup: a decision" || return
    kb_new "$T/h/W0/analyses/x/kb" <<'EOF'
uses([build, project]).
request(r1, 'Exports keep their header row').
% Made by orbit-kb 0.5.0.
project_kb('../../../../project-kb').
claim(c1, introduce, 'The export has a header row').
example(c1, 'orders.csv starts with id,total').
cites(c1, 'Exports keep their header row').
check(k1, c1).
checks_that(k1, 'the first line names the columns').
EOF
    okb --dir "$K" query 'project_decision_digest(d1, D)'; local pd; pd=$(printf '%s\n' "$out" | sed -n 's/^D = //p')
    [ -n "$pd" ] || { note "the old-layout KB does not reach its project KB"; return; }
    okb --dir "$K" add "pins(c1, project, d1, $pd)"; rc_is 0 "setup: the pin" || return
    okb --dir "$K" lint; out_hasnt '^WP2' "the old-layout KB resolves its project KB"
    # the old engine: this orbit-kb with the hub-root reading taken out (reads from the KB folder)
    mkdir -p "$T/old/bin" "$T/old/share"; cp "$OKB" "$T/old/bin/orbit-kb"; cp -rL "$LIB" "$T/old/share/orbit-kb"
    sed -i 's/^    (   kb_hub_root(Dir, Hub)$/    (   fail, kb_hub_root(Dir, Hub)/' "$T/old/bin/orbit-kb"
    # an engine with no hub-root reading is old as it is; the guard below checks that the old side loses the link
    # move the KB into specs/, as UPGRADING does (git mv); kb.pl is not touched
    mv "$T/h/W0/analyses/x/kb" "$T/h/specs/x"; K=$T/h/specs/x; cp "$K/kb.pl" "$T/x.before"
    okb --dir "$K" lint; out_hasnt '^WP2' "the moved KB still reaches its project KB, with no write"
    same_file "$K/kb.pl" "$T/x.before" "the move"
    local ol; ol=$(cd "$T" && ORBIT_KB_LIB="$T/old/share/orbit-kb" timeout "$TMO" "$T/old/bin/orbit-kb" --dir "$K" lint 2>&1)
    printf '%s\n' "$ol" | grep -q '^WP2' || note "setup: the old engine should lose the link of the moved KB (the check could not fail)"
    # the preview of the new engine against the old one declares the change: WP2 1 -> none, in the reach
    plan_seen --old "$T/old/bin/orbit-kb"; rc_is 0 "the preview of the hub-root reading"
    out_has 'lint WP2 \(count\): 1 -> none \(in the reach\)' "the changed verdict is declared"; out_hasnt 'OUTSIDE'
    # outside a hub, a relative project_kb is read from the KB folder, as before
    mkdir -p "$T/solo"; cp -r "$T/h/project-kb" "$T/solo/project-kb"
    kb_new "$T/solo/k" <<'EOF'
uses([build, project]).
request(r1, 'Exports keep their header row').
% Made by orbit-kb 0.5.0.
project_kb('../project-kb').
claim(c1, introduce, 'The export has a header row').
EOF
    okb --dir "$T/solo/k" query 'project_decision_digest(d1, D)'; rc_is 0 "a KB outside a hub reads its link from its own folder"
}

# ================================================================ c16: the cut-fail clause
t_MG16() {
    fxlib || return; kb_old "$T/k"
    printf '%s\n' '%% doc: An item that reads the old kind.' 'old_reader(X) :- oldkind(X, _).' > "$K/rules.pl"
    okb --dir "$K" add "cites(c1, 'Exports keep their header row')"; rc_is 0
    okb --dir "$K" run k1 -- false >/dev/null; okb --dir "$K" run k1 -- true >/dev/null; rc_is 0 "setup: run k1 red, then green"
    cp "$K/kb.pl" "$T/before.pl"
    plan_seen; okb --dir "$K" migrate apply --seen "$SEEN"; rc_is 0 "apply" || return
    only_added "$T/before.pl" "$K/kb.pl" "c16"
    local cl fl; cl=$(grep -n '^oldkind(_, _) :- !, fail\.$' "$K/kb.pl" | cut -d: -f1); fl=$(grep -n '^oldkind(o1' "$K/kb.pl" | cut -d: -f1)
    [ -n "$cl" ] && [ -n "$fl" ] && [ "$cl" -lt "$fl" ] || note "the cut-fail clause is not the first clause of oldkind/2 (lines '$cl', '$fl')"
    grep -Eq "^retired\(oldkind/2, '9\.9\.9', newkind/2\)\.$" "$K/kb.pl" || note "no retired/3 fact beside the clause"
    is_false 'oldkind(X, Y)'; is_false 'old_reader(X)'
    okb --dir "$K" lint; out_hasnt '^E7' "no E7 for the first cut-fail clause"
    out_has '^WM1 kb\.pl:[0-9]+: oldkind/2 was retired in orbit-kb 9\.9\.9, replaced by newkind/2\. Its 2 fact\(s\) .*analyze the reach: old_reader/1'
    is_true 'done'
    # a fact added later is hidden and warned about
    okb --dir "$K" add "oldkind(o3, 'third')"; rc_is 0; any_has 'retired in this KB'
    is_false 'oldkind(X, Y)'
    okb --dir "$K" lint; out_has 'Its 3 fact\(s\)'
    is_true 'done'
    # E7: another rule in kb.pl, and a cut-fail clause after a fact of its predicate
    cp "$K/kb.pl" "$T/k.pl"
    echo "note(_, _) :- !, fail." >> "$K/kb.pl"
    okb --dir "$K" lint; out_has '^E7 .*comes after a clause of note/2' "a cut-fail clause after a fact"
    cp "$T/k.pl" "$K/kb.pl"; echo "other(X) :- claim(X, _, _)." >> "$K/kb.pl"
    okb --dir "$K" lint; out_has '^E7 .*This is a rule' "another rule in kb.pl"
}

# ================================================================ c17: the signature
t_MG17() {
    okb signature --check; rc_is 0 "the shipped signature file matches the declarations"
    grep -q '^signature(claim/3)\.$' "$LIB/signature.pl" || note "the signature lacks claim/3"
    grep -Eq '^signature\((oldkind|example)/' "$LIB/signature.pl" && grep -q '^signature(oldkind' "$LIB/signature.pl" && note "the signature lists a retired predicate"
    grep -Ec '^signature\(' "$LIB/signature.pl" | grep -qE '^[1-9][0-9]{2,}$' || note "the signature has fewer than 100 predicates"
    # the mutant: a line less, and the check fails
    cp -rL "$LIB" "$T/lib"; sed -i '/^signature(claim\/3)\.$/d' "$T/lib/signature.pl"
    ORBIT_KB_LIB="$T/lib" okb signature --check; rc_is 1 "a signature file that lacks a declared predicate"
    # lint: a migrated retired predicate, one not yet migrated, claim/2, and a declared local kind
    fxlib || return
    kb_new "$T/k" <<'EOF'
uses([build]).
request(r1, 'Exports keep their header row').
% Made by orbit-kb 0.4.0.
claim(c1, introduce, 'The export has a header row').
gone(_, _) :- !, fail.
retired(gone/2, '9.9.9', 'nothing').
gone(g1, 'one').
oldkind(o1, 'first').
claim(c2, 'a claim with two arguments').
decl(fact, weather(id, text), 'A local kind of this KB.', '').
weather(w1, 'sunny').
EOF
    okb --dir "$K" lint
    out_has "^WM1 kb\.pl:5: gone/2 was retired in orbit-kb 9\.9\.9, replaced by nothing" "the migrated retired predicate"
    out_has '^E2 kb\.pl:8: oldkind/2 is not declared' "the predicate that the signature lacks"
    out_has '^E2 kb\.pl:9: claim/2 is not declared\. claim is declared with arity 3' "the other arity"
    out_hasnt '^(E2|E7|WM1) .*weather' "the KB's own kind gets no signature flag (W2, review a local declaration, is not one)"
    # lint reads no list of retired predicates from the tool: the fixture library retires oldkind/2,
    # and lint still calls it only undeclared (no WM1 until the KB itself retires it)
    out_hasnt '^WM1 .*oldkind'
}

run_test t_MG2 MG2 "c2: a migration adds lines only; each fact names its migration; no human-only fact"
run_test t_MG3 MG3 "c3: refused with the reason and no write; a rerun writes nothing; a kill leaves no half run"
run_test t_MG5 MG5 "c5: steps with owners and pending queries; a stored marker marks nothing done"
run_test t_MG9 MG9 "c9: a closed KB is frozen: no write, not in the hub check, nothing on the Desk"
run_test t_MG10 MG10 "c10: a human step fails no hub check; the KB is not done until the human answers"
run_test t_MG12 MG12 "c12: the hub check fails only on a tool or agent step, warns on a retired predicate, trusts no marker"
run_test t_MG7 MG7 "c7: an additive migration (new kinds and rules only) changes no old verdict"
run_test t_MG14 MG14 "c14: a changed verdict outside the reach of S is refused; W12 is in the reach of checks_that"
run_test t_MG15 MG15 "c15: the preview shows each verdict that the old engine and the new one differ on"
run_test t_MGU MGU "c15: a kit upgrade shows each verdict that the new engine changes and needs the preview digest"
run_test t_MGC MGC "c19: the kit upgrade previews closed KBs too, and writes nothing to them"
run_test t_MGR MGR "c20: in a hub, project_kb is read from the hub root, so a moved KB keeps its link with no write"
run_test t_MG16 MG16 "c16: the cut-fail clause hides old and later facts, lint accepts it first only, WM1 never blocks done"
run_test t_MG17 MG17 "c17: the signature lists the version's own predicates; lint flags retired, missing and other arity"
NT=${#REG_ID[@]}
for ((i = 0; i < NT; i++)); do exec_test "$i"; done
echo "----"
echo "orbit-kb=$OKB lib=$LIB pass=$pass fail=$fail skip=$skip ${failed[*]:-}"
[ $fail = 0 ]
