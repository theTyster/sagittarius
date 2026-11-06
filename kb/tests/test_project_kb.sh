#!/usr/bin/env bash
# Black-box tests for the `project` module of orbit-kb (ticket T06, CONTRACT D23).
#
# The ONLY source of expected behavior is kb/CONTRACT.md (D23). No test reads the CLI or the
# library source. The harness is a small serial copy of the style of test_orbit_kb.sh: each
# test runs in a fresh mktemp -d, the summary line is `pass=N fail=N skip=N`, the exit status
# is 0 when every test passes, 1 when one fails, 2 when the suite cannot run.
#
# Usage: kb/tests/test_project_kb.sh [path-to-orbit-kb]      ONLY='<regex>' runs matching ids.
#
# Requirement map (ticket T06 claims -> tests; names are the D23 items P1 to P7):
#   c1 the module and its facts, `help project`  : PK1 PK2 PK3 PK4 PK5
#   c2 stale pins (file, tracker)                : PS1 PS2 PS3 PS4 PS5
#   c3 one writer: the lock, --take, release     : PW1 PW2 PW3 PW4 PW5 PW6 PW7
#   c4 outbound drafts                           : PD1 PD2 PD3 PD4
#   c5 conflict, supersedes_by_date, blocking    : PC1 PC2 PC3 PC4 PC5 PC6 PC7
#   c6 a spec KB pins a decision (WP1, WP2)      : PX1 PX2 PX3 PX4
set -u

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
dups=$(grep -oE '^t_[A-Za-z0-9_]+\(\)' "${BASH_SOURCE[0]}" | sort | uniq -d)
if [ -n "$dups" ]; then echo "ERROR: test functions defined twice: $(echo $dups)" >&2; exit 2; fi
OKB=${1:-${ORBIT_KB_BIN:-$here/../bin/orbit-kb}}
LIB=${ORBIT_KB_TEST_LIB:-$here/../share/orbit-kb}
TMO=${ORBIT_KB_TEST_TIMEOUT:-120}
if [ ! -f "$OKB" ] || [ ! -x "$OKB" ]; then echo "test_project_kb.sh: the orbit-kb CLI is missing: $OKB" >&2; exit 2; fi
OKB=$(cd "$(dirname "$OKB")" && pwd -P)/$(basename "$OKB")
if [ -d "$LIB" ]; then LIB=$(cd "$LIB" && pwd -P); fi
if [ ! -f "$LIB/core.pl" ]; then echo "test_project_kb.sh: the library is missing (no core.pl in $LIB)" >&2; exit 2; fi
for tool in swipl sha256sum timeout mktemp grep sed cmp sort head cp; do
    command -v "$tool" >/dev/null 2>&1 || { echo "test_project_kb.sh: required tool not found: $tool" >&2; exit 2; }
done

pass=0 fail=0 skip=0
failed=()
FAILS=()
out="" err="" rc=0
T="" K=""
base=$(mktemp -d "${TMPDIR:-/tmp}/orbit-kb-project-test.XXXXXX") || exit 2
base=$(cd "$base" && pwd -P)
trap 'rm -rf "$base"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
for v in $(compgen -e); do case $v in ORBIT_KB*|CLAUDE_SESSION_ID) unset "$v";; esac; done
export ORBIT_KB_LIB="$LIB"

# kbq: read the terms of a kb.pl with swipl, then run a goal (as test_orbit_kb.sh does).
cat > "$base/kbq.pl" <<'PROLOG'
:- initialization(main, main).
:- op(900, fy, not).
:- op(950, xfx, ::).
:- op(1200, fx, #).
:- op(1150, fx, [table, show, pred]).
:- op(350, fx, [include, compute, abducible]).
:- op(700, xfx, [#=, #<>, #<, #>, #=<, #>=]).
:- dynamic kb_t/2.
main([File, GoalText]) :-
    load_kb(File),
    catch(term_string(Goal, GoalText), E, (print_message(error, E), halt(3))),
    (   catch(call(Goal), E2, (print_message(error, E2), halt(3))) -> halt(0) ; halt(1) ).
kb(T) :- kb_t(_, T).
kb_line(L, T) :- kb_t(L, T).
load_kb(File) :-
    open(File, read, S),
    repeat,
      catch(read_term(S, T, [term_position(P)]), _, T = '$syntax_error'),
      (   T == end_of_file -> !, close(S)
      ;   T == '$syntax_error' -> fail
      ;   stream_position_data(line_count, P, L), assertz(kb_t(L, T)), fail ).
PROLOG
kbq() { swipl -q "$base/kbq.pl" -- "$@" 2>/dev/null; }

ok()  { pass=$((pass+1)); echo "PASS $1 $2"; }
bad() { fail=$((fail+1)); failed+=("$1"); echo "FAIL $1 $2"; local m; for m in "${@:3}"; do echo "     - $m"; done; }
snip() { printf '%s' "$1" | head -c 300 | tr '\n' '~'; }
note() { FAILS+=("$*"); }

# okb_in DIR ARGS...: run the CLI in DIR. Sets out, err, rc. Variables for the CLI go in the
# environment of the caller of okb (for example: ORBIT_KB_WRITER=ann okb ...).
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
any_hasi() { anyout | grep -Eiq -- "$1" && return 0; note "${2:+$2: }output lacks /$1/ (stdout: $(snip "$out") | stderr: $(snip "$err"))"; return 1; }
same_file() { cmp -s "$1" "$2" && return 0; note "${3:+$3: }the file changed ($1)"; return 1; }
has_goal() { kbq "$1" "$2" >/dev/null && return 0; note "${3:+$3: }${1##*/}: no match for: $2"; return 1; }
has_fact() { has_goal "$1" "kb($2)" "${3:-}"; }
no_fact()  { kbq "$1" "kb($2)" >/dev/null || return 0; note "${3:+$3: }${1##*/} has a fact that matches $2, it must not"; return 1; }
sha() { sha256sum "$1" | cut -d' ' -f1; }

q() { okb --dir "$K" query "$@"; }
is_true()  { q "$1"; rc_is 0 "query '$1' must hold"; }
is_false() { q "$1"; rc_is 1 "query '$1' must have no answer"; }
is_set() {  # is_set GOAL "ANSWER|ANSWER": all answers (-n 0), no more, no less. "" means none.
    q "$1" -n 0
    if [ -z "$2" ]; then rc_is 1 "query '$1' -n 0 must have no answer"; return; fi
    rc_is 0 "query '$1' -n 0" || return 1
    local got; got=$(printf '%s\n' "$out" | LC_ALL=C sort | paste -sd'|')
    [ "$got" = "$2" ] || note "query '$1' -n 0: answers [$got], want [$2]"
}

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
    cd "$T" || return 1
    "${REG_FN[$i]}"
    cd "$here" || true
    if [ ${#FAILS[@]} -eq 0 ]; then ok "${REG_ID[$i]}" "${REG_DESC[$i]}"
    else bad "${REG_ID[$i]}" "${REG_DESC[$i]}" "${FAILS[@]}"; fi
    rm -rf "$T"
}

# ---------------------------------------------------------------- builders (invented content)
# The sha256 of a text, as the contract defines decision_digest (no newline).
tdigest() { printf '%s' "$1" | sha256sum | awk '{print "sha256:"$1}'; }
H1=sha256:1111111111111111111111111111111111111111111111111111111111111111
H2=sha256:2222222222222222222222222222222222222222222222222222222222222222
T1=2026-03-01T09:00:00Z   # a pin was recorded
T2=2026-03-02T09:00:00Z   # later
T3=2026-03-03T09:00:00Z   # later still
T4=2026-03-04T09:00:00Z

# pk_init DIR: a project KB with a few decisions made through the CLI.
pk_init() {
    okb init "$1" --request 'Where the widget product goes' --uses project >/dev/null 2>&1 || note "setup: init failed: $(snip "$err")"
    K=$1
}
padd() { okb --dir "$K" add "$@"; }   # add to $K; callers check rc
# pk_basic: decision d1 resting on a tracker pin p1 (pinned at T1).
pk_basic() {
    pk_init "$T/pk"
    padd "decision(d1, 'Export goes through the queue')" "decided_by(d1, ann, '$T1')" \
         "reason(d1, 'The queue already handles retries')" "pin(p1, tracker, 'gh:acme/widgets#12', '$H1', '$T1')" \
         "concerns(d1, p1)" >/dev/null || true
    [ "$rc" = 0 ] || note "setup: pk_basic failed: $(snip "$out$err")"
}
# a newer record of the same tracker item
tracker_changed() {  # tracker_changed ID TIME
    padd "pin($1, tracker, 'gh:acme/widgets#12', '$H2', '$2')" >/dev/null
    [ "$rc" = 0 ] || note "setup: tracker_changed failed: $(snip "$out$err")"
}
stage() {  # stage DRAFT TIME
    padd "draft($1, p1, 'Retitle the issue to match the queue decision', '$2')" >/dev/null
    [ "$rc" = 0 ] || note "setup: stage failed: $(snip "$out$err")"
}

# ================================================================ c1: the module and its facts
t_PK1() { pk_init "$T/pk"; head -n1 "$K/kb.pl" | grep -Fq 'uses([project])' || note "kb.pl does not start with uses([project])"
          padd "decision(d1, 'Export goes through the queue')" "decided_by(d1, ann, '$T1')" \
               "reason(d1, 'The queue already handles retries')" "repo(web, 'git.example.test/acme/web')" \
               "analysis(d1, 'analysis/export.md')" "pin(p1, tracker, 'gh:acme/widgets#12', '$H1', '$T1')" \
               "draft(dr1, p1, 'Retitle the issue', '$T2')"; rc_is 0 "every fact of the module is accepted"
          has_fact "$K/kb.pl" "decision(d1, _)"; has_fact "$K/kb.pl" "decided_by(d1, ann, _)"; has_fact "$K/kb.pl" "reason(d1, _)"
          has_fact "$K/kb.pl" "repo(web, _)"; has_fact "$K/kb.pl" "analysis(d1, _)"; has_fact "$K/kb.pl" "pin(p1, tracker, _, _, _)"
          has_fact "$K/kb.pl" "draft(dr1, p1, _, _)"
          no_fact "$K/kb.pl" "first_use(_, _, _)" "the module declares them: no first use"
          okb --dir "$K" lint; rc_is 0 "lint is clean"; }
t_PK2() { pk_basic; K=$T/pk
          padd "decided_by(d9, ann, '$T1')"; rc_is 1 "a decider of no decision"; any_has 'E4|d9' "E4 names the dangling id"
          padd "reason(d9, 'x')"; rc_is 1 "a reason of no decision"
          padd "analysis(d9, 'a.md')"; rc_is 1 "an analysis of no decision"
          padd "draft(dr1, p9, 'x', '$T2')"; rc_is 1 "a draft of no pin"; any_has 'E4|p9' "E4 names the dangling pin"
          padd "decision(d1, 'Another')"; rc_is 1 "a duplicate decision id"; any_has 'E5' "E5" ; }
t_PK3() { pk_basic; K=$T/pk
          padd "pin(p2, branch, 'gh:acme/widgets#13', '$H1', '$T1')"; rc_is 1 "a pin kind outside file|tracker"; any_has 'E3' "E3"
          padd "pin(p2, tracker, 'gh:acme/widgets#13', 'abc', '$T1')"; rc_is 1 "a digest that is no sha256:HEX"; any_has 'E3' "E3"
          padd "pin(p2, tracker, 'gh:acme/widgets#13', '$H1', 'yesterday')"; rc_is 1 "a ChangedAt that is no time"; any_has 'E3' "E3"
          padd "decided_by(d1, ann, 'noon')"; rc_is 1 "a decision time that is no time"; }
t_PK4() { pk_basic; K=$T/pk
          local want; want=$(tdigest 'Export goes through the queue')
          q 'decision_digest(d1, D)'; rc_is 0 "decision_digest(d1, D)"; out_has "D = '?$want'?" "the sha256 of the decision text"
          is_set 'decision(X, Y)' "X = d1, Y = 'Export goes through the queue'"; }
t_PK5() { okb help project; rc_is 0 "help project"
          local n; for n in decision decided_by reason repo analysis pin draft pins stale_pin outbound conflict supersedes_by_date; do
              out_has "(^|[^a-z_])$n([^a-z_]|\$)" "help project documents $n"; done
          out_has 'ORBIT_KB_WRITER' "help project documents the writer lock"; out_has '--take' "help project documents --take"
          out_has 'release' "help project documents release"
          okb help; rc_is 0 "general help"; out_has 'project' "the general help lists the topic"; }

# ================================================================ c2: stale pins
t_PS1() { pk_basic; K=$T/pk
          mkdir -p "$T/world"; printf 'def export(): pass\n' > "$T/world/export.py"
          okb --dir "$K" subject s1 "$T/world/export.py"; rc_is 0 "subject computes the digest"
          local d; d=$(printf '%s\n' "$out" | grep -Eo 'sha256:[0-9a-f]{64}' | head -n1); [ "$d" = "sha256:$(sha "$T/world/export.py")" ] || note "subject printed $d"
          padd "pin(pf, file, s1, '$d', '$T1')"; rc_is 0 "a file pin of the subject"
          is_false 'stale_pin(pf)'
          printf 'def export(): return 1\n' > "$T/world/export.py"
          is_true 'stale_pin(pf)'; is_set 'stale_pin(P)' 'P = pf'; }
t_PS2() { pk_basic; K=$T/pk
          printf 'one\n' > "$T/f.txt"; okb --dir "$K" subject s1 "$T/f.txt" >/dev/null
          local d="sha256:$(sha "$T/f.txt")"; padd "pin(pf, file, s1, '$d', '$T1')" >/dev/null
          printf 'two\n' > "$T/f.txt"; okb --dir "$K" subject s1 "$T/f.txt" >/dev/null   # refreshes the subject, not the pin
          is_true 'stale_pin(pf)' "the pin keeps its own digest"
          printf 'one\n' > "$T/f.txt"; is_false 'stale_pin(pf)' "the file is as pinned again"; }
t_PS3() { pk_basic; K=$T/pk
          printf 'x\n' > "$T/f.txt"; okb --dir "$K" subject s1 "$T/f.txt" >/dev/null
          local d="sha256:$(sha "$T/f.txt")"; padd "pin(pf, file, s1, '$d', '$T1')" >/dev/null
          rm "$T/f.txt"; is_true 'stale_pin(pf)' "a missing file is stale"; }
t_PS4() { pk_basic; K=$T/pk
          is_false 'stale_pin(p1)' "one record of the item"
          tracker_changed p2 "$T2"
          is_set 'stale_pin(P)' 'P = p1' ; is_false 'stale_pin(p2)' "the newest record is not stale"; }
t_PS5() { pk_basic; K=$T/pk
          padd "pin(p2, tracker, 'gh:acme/widgets#99', '$H2', '$T3')" >/dev/null
          is_false 'stale_pin(p1)' "a newer record of ANOTHER item does not stale p1"
          padd "pin(p3, tracker, 'gh:acme/widgets#12', '$H2', '$T1')" >/dev/null
          is_false 'stale_pin(p1)' "an equal ChangedAt does not make a pin stale"; is_false 'stale_pin(p3)'; }

# ================================================================ c3: one writer
t_PW1() { pk_init "$T/pk"
          ORBIT_KB_WRITER=ann padd "decision(d1, 'Export goes through the queue')"; rc_is 0 "the first writer"
          [ -f "$K/writer.lock" ] || note "no writer.lock after the first write"
          grep -q '^ann ' "$K/writer.lock" 2>/dev/null || note "writer.lock does not name ann: $(cat "$K/writer.lock" 2>/dev/null)"
          grep -Eq '^ann [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{8}Z$' "$K/writer.lock" 2>/dev/null || note "writer.lock is not 'WRITER TIME'"; }
t_PW2() { pk_init "$T/pk"
          ORBIT_KB_WRITER=ann padd "decision(d1, 'First')" >/dev/null; cp "$K/kb.pl" "$T/.before"; cp "$K/writer.lock" "$T/.lock.before"
          ORBIT_KB_WRITER=bob padd "decision(d2, 'Second')"; rc_is 2 "a second writer"
          any_has 'ann' "the message names the holder"; any_has '--take' "the message names --take"
          same_file "$K/kb.pl" "$T/.before" "kb.pl after the refusal"; same_file "$K/writer.lock" "$T/.lock.before" "the lock after the refusal"; }
t_PW3() { pk_init "$T/pk"
          ORBIT_KB_WRITER=ann padd "decision(d1, 'First')" >/dev/null
          ORBIT_KB_WRITER=ann padd "decision(d2, 'Second')"; rc_is 0 "the holder writes again"
          ORBIT_KB_WRITER=bob okb --dir "$K" query 'decision(X, Y)' -n 0; rc_is 0 "a read does not need the lock"
          ORBIT_KB_WRITER=bob okb --dir "$K" lint; rc_is 0 "lint does not need the lock"; }
t_PW4() { pk_init "$T/pk"
          ORBIT_KB_WRITER=ann padd "decision(d1, 'First')" >/dev/null
          ORBIT_KB_WRITER=bob padd "decision(d2, 'Second')" --take; rc_is 0 "--take"
          has_fact "$K/kb.pl" "decision(d2, _)" "the fact is written"
          has_goal "$K/kb.pl" "kb(writer_takeover(ann, bob, T)), atom_length(T, 20)" "the takeover is recorded: from, to, when"
          has_goal "$K/kb.pl" "kb_line(A, writer_takeover(ann, bob, _)), kb_line(B, decision(d2, _)), A < B" "the takeover comes before the fact"
          grep -q '^bob ' "$K/writer.lock" || note "writer.lock does not name bob"
          ORBIT_KB_WRITER=bob padd "decision(d3, 'Third')"; rc_is 0 "bob holds the lock now"
          ORBIT_KB_WRITER=ann padd "decision(d4, 'Fourth')"; rc_is 2 "ann is the second writer now"; any_has 'bob' "names bob"; }
t_PW5() { pk_init "$T/pk"
          ORBIT_KB_WRITER=ann padd "decision(d1, 'First')" >/dev/null
          ORBIT_KB_WRITER=ann padd "decision(d2, 'Second')" --take; rc_is 0 "--take by the holder"
          kbq "$K/kb.pl" "kb(writer_takeover(_, _, _))" && note "a takeover was recorded when the writer already held the lock"
          local t2; t2=$(mktemp -d "$base/free.XXXXXX"); pk_init "$t2/pk"
          ORBIT_KB_WRITER=bob padd "decision(d1, 'First')" --take; rc_is 0 "--take on a free lock"
          kbq "$K/kb.pl" "kb(writer_takeover(_, _, _))" && note "a takeover was recorded for a free lock"; true; }
t_PW6() { pk_init "$T/pk"
          ORBIT_KB_WRITER=ann padd "decision(d1, 'First')" >/dev/null
          ORBIT_KB_WRITER=bob okb --dir "$K" subject s1 "$here/test_project_kb.sh"; rc_is 2 "subject is a write too"; any_has 'ann' "names the holder"
          ORBIT_KB_WRITER=bob okb --dir "$K" uses build; rc_is 2 "uses is a write too"; any_has 'ann' "names the holder"
          ORBIT_KB_WRITER=bob okb --dir "$K" release; rc_is 2 "release by another writer"; any_has 'ann' "names the holder"
          [ -f "$K/writer.lock" ] || note "the lock went away"
          ORBIT_KB_WRITER=ann okb --dir "$K" release; rc_is 0 "release by the holder"
          [ ! -e "$K/writer.lock" ] || note "writer.lock still exists after release"
          ORBIT_KB_WRITER=bob padd "decision(d2, 'Second')"; rc_is 0 "bob writes after the release"
          ORBIT_KB_WRITER=bob okb --dir "$K" release; rc_is 0 "release by the holder, again"
          okb --dir "$K" release; rc_is 0 "release with no lock"; }
t_PW7() { pk_init "$T/pk"
          padd "decision(d1, 'No writer is named')"; rc_is 0 "no ORBIT_KB_WRITER: no lock"
          [ ! -e "$K/writer.lock" ] || note "a lock was taken without a writer"
          CLAUDE_SESSION_ID=sess-7 padd "decision(d2, 'A session id')" >/dev/null; rc_is 0 "the session id is the writer"
          grep -q '^sess-7 ' "$K/writer.lock" 2>/dev/null || note "writer.lock does not name the session id"
          ORBIT_KB_WRITER=ann CLAUDE_SESSION_ID=sess-7 padd "decision(d3, 'The variable wins')"; rc_is 2 "ORBIT_KB_WRITER wins over the session id"
          local k2=$T/spec; okb init "$k2" --request 'plain' --uses build >/dev/null 2>&1
          ORBIT_KB_WRITER=ann okb --dir "$k2" add "claim(c1, introduce, 'x')" "cites(c1, 'x')" >/dev/null
          ORBIT_KB_WRITER=bob okb --dir "$k2" add "claim(c2, introduce, 'y')" "cites(c2, 'y')"; rc_is 0 "a KB without project has no lock"
          [ ! -e "$k2/writer.lock" ] || note "a KB without project got a lock"; }

# ================================================================ c4: outbound drafts
t_PD1() { pk_basic; K=$T/pk; grep -E '^pin\(' "$K/kb.pl" > "$T/.pins.before"
          stage dr1 "$T2"
          grep -E '^pin\(' "$K/kb.pl" > "$T/.pins.after"; same_file "$T/.pins.before" "$T/.pins.after" "a draft never edits the pin"
          is_false 'stale_pin(p1)' "a draft does not change the pin"
          has_fact "$K/kb.pl" "draft(dr1, p1, _, _)"; }
t_PD2() { pk_basic; K=$T/pk; is_false 'outbound(D)' "no draft yet"
          stage dr1 "$T2"; is_set 'outbound(D)' 'D = dr1'
          stage dr2 "$T3"; is_set 'outbound(D)' 'D = dr1|D = dr2'; }
t_PD3() { pk_basic; K=$T/pk; stage dr1 "$T2"; stage dr2 "$T3"
          padd "pushed(dr1, '$T4')"; rc_is 0 "pushed(Draft, Time)"
          is_set 'outbound(D)' 'D = dr2' "a pushed draft leaves outbound"
          has_fact "$K/kb.pl" "draft(dr1, p1, _, _)" "the draft stays in kb.pl"
          padd "pushed(dr9, '$T4')"; rc_is 1 "pushed of no draft"; }
t_PD4() { pk_basic; K=$T/pk; stage dr1 "$T2"
          q 'outbound(D)' --why; rc_is 0 "outbound --why"; out_has 'dr1' "names the draft"
          okb --dir "$K" whynot 'outbound(dr1)'; rc_is 0 "whynot"; out_has '^holds' "holds"
          padd "pushed(dr1, '$T4')" >/dev/null
          okb --dir "$K" whynot 'outbound(dr1)'; out_has '^absent' "absent once pushed"; }

# ================================================================ c5: conflict and supersedes_by_date
# pin p1 at T1. Tracker changed at T2 (p2). Draft staged at T3 (after both): a conflict.
t_PC1() { pk_basic; K=$T/pk; tracker_changed p2 "$T2"; stage dr1 "$T3"
          is_true 'conflict(dr1)'; is_set 'conflict(D)' 'D = dr1'
          is_false 'supersedes_by_date(dr1, S)' "a conflict is not decided by date"
          is_false 'outbound(dr1)' "a conflicting draft is not outbound"
          is_false 'dropped(dr1, S)' "nothing is dropped while it is open"; }
# tracker unchanged since the pin: the draft is later and wins
t_PC2() { pk_basic; K=$T/pk; stage dr1 "$T2"
          is_false 'conflict(dr1)'; is_set 'supersedes_by_date(D, S)' 'D = dr1, S = draft'
          is_true 'outbound(dr1)'; is_false 'dropped(dr1, S)' "the draft wins: nothing dropped (the tracker did not change)"; }
# draft staged before the pin's ChangedAt, tracker changed later: the tracker is later and wins
t_PC3() { pk_basic; K=$T/pk; tracker_changed p2 "$T3"
          padd "draft(dr1, p1, 'An old edit', '2026-02-28T09:00:00Z')" >/dev/null
          is_false 'conflict(dr1)'; is_set 'supersedes_by_date(D, S)' 'D = dr1, S = tracker'
          is_set 'dropped(D, S)' 'D = dr1, S = draft' "the dropped edit is recorded"
          is_false 'outbound(dr1)' "a dropped draft is not pushed"
          has_fact "$K/kb.pl" "draft(dr1, _, _, _)" "the draft is still in kb.pl, never lost"; }
# the boundary: staged exactly at the pin's ChangedAt is not after it
t_PC4() { pk_basic; K=$T/pk; tracker_changed p2 "$T3"; stage dr1 "$T1"
          is_false 'conflict(dr1)' "staged at ChangedAt is not after it"; is_set 'supersedes_by_date(D, S)' 'D = dr1, S = tracker'; }
# the third case: the tracker changed after the pin, the draft staged after the pin AND after the tracker change
t_PC5() { pk_basic; K=$T/pk; tracker_changed p2 "$T2"; tracker_changed p3 "$T3"; stage dr1 "$T4"
          is_true 'conflict(dr1)' "after the pin, tracker changed twice"
          is_set 'conflict(D)' 'D = dr1|D = dr2' "dr2 is staged after the pin, and the tracker changed after it too"; }
# a human resolves: the conflict goes, the other side is recorded as dropped
t_PC6() { pk_basic; K=$T/pk; tracker_changed p2 "$T2"; stage dr1 "$T3"
          padd "resolved(dr1, draft, '$T4')"; rc_is 0 "resolved(Draft, Side, Time)"
          is_false 'conflict(dr1)' "resolved"; is_set 'dropped(D, S)' 'D = dr1, S = tracker'; is_true 'outbound(dr1)' "the draft wins and can go out"
          stage dr2 "$T3"; padd "resolved(dr2, tracker, '$T4')" >/dev/null
          is_set 'dropped(D, S)' 'D = dr1, S = tracker|D = dr2, S = draft'; is_false 'outbound(dr2)' "a dropped draft is not outbound"
          padd "resolved(dr1, nobody, '$T4')"; rc_is 1 "a side outside draft|tracker"; }
# a conflict blocks the spec KBs that pin the decision
t_PC7() { pk_basic; tracker_changed p2 "$T2"; stage dr1 "$T3"
          local pk=$K spec=$T/spec dd; dd=$(tdigest 'Export goes through the queue')
          okb init "$spec" --request 'Build the export' --uses build,project >/dev/null 2>&1 || note "setup: spec init failed: $(snip "$err")"
          K=$spec
          padd "project_kb('../pk')" "claim(c1, introduce, 'Export uses the queue')" "cites(c1, 'Build the export')" "check(k1, c1)" \
               "pins(c1, project, d1, '$dd')" >/dev/null; rc_is 0 "the spec KB pins decision d1"
          is_true 'blocking(project_conflict(dr1))' "the conflict blocks the spec KB that pins d1"
          okb --dir "$K" show blocking; out_has 'project_conflict.*dr1' "show blocking names it"
          is_false 'done' "done waits"
          # the same conflict does not block a spec KB that pins no decision it rests on
          local other=$T/other; okb init "$other" --request 'Build something else' --uses build,project >/dev/null 2>&1; K=$other
          padd "project_kb('../pk')" >/dev/null
          padd "claim(c1, introduce, 'Other')" "cites(c1, 'Build something else')" >/dev/null
          is_false 'blocking(project_conflict(D))' "a spec KB that pins nothing is not blocked"
          # resolving the conflict frees the spec KB
          K=$pk; padd "resolved(dr1, draft, '$T4')" >/dev/null; K=$spec
          is_false 'blocking(project_conflict(D))' "resolved: nothing blocks"; }

# ================================================================ c6: a spec KB pins a decision
spec_with_pin() {  # spec_with_pin: $T/pk (decision d1) and $T/spec with pins(c1, project, d1, DIGEST)
    pk_basic; SPEC_PK=$K
    local dd; dd=$(tdigest 'Export goes through the queue')
    okb init "$T/spec" --request 'Build the export' --uses build,project >/dev/null 2>&1 || note "setup: spec init failed: $(snip "$err")"
    K=$T/spec
    padd "project_kb('../pk')" "claim(c1, introduce, 'Export uses the queue')" "cites(c1, 'Build the export')" "check(k1, c1)" \
         "pins(c1, project, d1, '$dd')" >/dev/null || true
    [ "$rc" = 0 ] || note "setup: pins failed: $(snip "$out$err")"
}
t_PX1() { spec_with_pin; okb --dir "$K" lint; rc_is 0 "matching digest: lint is clean"; out_hasnt '^WP[12]' "no WP1, no WP2"
          is_true 'pins(c1, project, d1, D)'; }
t_PX2() { spec_with_pin
          sed -i "s/Export goes through the queue/Export goes through the batch job/" "$SPEC_PK/kb.pl"   # the decision changed
          okb --dir "$K" lint; rc_is 0 "a warning is not an error"; out_has '^WP1 c1:' "WP1 names the claim"
          okb --dir "$K" lint --strict; rc_is 1 "--strict"
          q 'project_decision_digest(d1, D)'; rc_is 0 "the digest now"; out_has "$(tdigest 'Export goes through the batch job' | cut -c8-20)" "the digest of the new text"; }
t_PX3() { spec_with_pin
          padd "pins(c2, project, d77, '$H1')" >/dev/null 2>&1; rc_is 1 "pins of a claim that does not exist"
          padd "claim(c2, preserve, 'Other')" "cites(c2, 'Build the export')" "pins(c2, project, d77, '$H1')" >/dev/null; rc_is 0
          okb --dir "$K" lint; rc_is 0; out_has '^WP2 c2:' "WP2: no such decision in the project KB"
          sed -i "/^project_kb(/d" "$K/kb.pl"
          okb --dir "$K" lint; out_has '^WP2 c1:' "WP2: no project_kb fact"; }
t_PX4() { spec_with_pin
          padd "pins(c1, repo, d1, '$H1')"; rc_is 1 "the second argument is project"; any_has 'E3' "E3"
          padd "pins(c1, project, d1, 'nothex')"; rc_is 1 "a digest that is no sha256:HEX"; any_has 'E3' "E3"; }

# ================================================================ run
run_test t_PK1 PK1 "T06 c1: init --uses project; every fact of the module is accepted"
run_test t_PK2 PK2 "T06 c1: dangling refs and duplicate ids are refused (E4, E5)"
run_test t_PK3 PK3 "T06 c1: pin kind, digest and time are typed (E3)"
run_test t_PK4 PK4 "T06 c1: decision_digest is the sha256 of the decision text"
run_test t_PK5 PK5 "T06 c1: help project documents each predicate, the lock and release"
run_test t_PS1 PS1 "T06 c2: a file pin goes stale when the file's digest changes"
run_test t_PS2 PS2 "T06 c2: a file pin keeps its own digest when the subject is refreshed"
run_test t_PS3 PS3 "T06 c2: a file pin whose file is missing is stale"
run_test t_PS4 PS4 "T06 c2: a tracker pin is stale when a newer ChangedAt is recorded for the same source"
run_test t_PS5 PS5 "T06 c2: another source, or an equal ChangedAt, does not make a tracker pin stale"
run_test t_PW1 PW1 "T06 c3: a write by ORBIT_KB_WRITER creates writer.lock naming the writer"
run_test t_PW2 PW2 "T06 c3: a second writer's add exits 2 naming the holder and writes nothing"
run_test t_PW3 PW3 "T06 c3: the holder writes again; reads and lint need no lock"
run_test t_PW4 PW4 "T06 c3: --take replaces the holder and records writer_takeover"
run_test t_PW5 PW5 "T06 c3: --take records no takeover when the lock is free or already held"
run_test t_PW6 PW6 "T06 c3: subject and uses are locked; release frees the lock for its holder only"
run_test t_PW7 PW7 "T06 c3: no writer, no lock; the session id is the fallback; a KB without project has no lock"
run_test t_PD1 PD1 "T06 c4: a draft never edits the pin"
run_test t_PD2 PD2 "T06 c4: outbound lists the drafts not yet pushed"
run_test t_PD3 PD3 "T06 c4: a pushed draft leaves outbound and stays in kb.pl"
run_test t_PD4 PD4 "T06 c4: why and whynot work on outbound"
run_test t_PC1 PC1 "T06 c5: conflict when the tracker and the draft both changed after the pin"
run_test t_PC2 PC2 "T06 c5: supersedes_by_date picks the draft when the tracker did not change"
run_test t_PC3 PC3 "T06 c5: supersedes_by_date picks the tracker when it is later; the draft is dropped and recorded"
run_test t_PC4 PC4 "T06 c5: a draft staged exactly at ChangedAt is not after it"
run_test t_PC5 PC5 "T06 c5: conflict with several tracker changes"
run_test t_PC6 PC6 "T06 c5: resolved ends a conflict and records the dropped side"
run_test t_PC7 PC7 "T06 c5: a conflict blocks the spec KB that pins the decision, and no other"
run_test t_PX1 PX1 "T06 c6: a matching pins/4 digest lints clean"
run_test t_PX2 PX2 "T06 c6: a changed decision gives WP1 (a warning; --strict fails)"
run_test t_PX3 PX3 "T06 c6: a pin that cannot be checked gives WP2"
run_test t_PX4 PX4 "T06 c6: pins/4 is typed"

NT=${#REG_ID[@]}
for ((i = 0; i < NT; i++)); do exec_test "$i"; done
echo "----"
echo "orbit-kb=$OKB lib=$LIB pass=$pass fail=$fail skip=$skip ${failed[*]:-}"
[ $fail = 0 ]
