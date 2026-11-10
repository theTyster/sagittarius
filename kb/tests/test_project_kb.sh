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
#      (T43 c3, Ty's u123, amends c5: when both sides changed after the pin the dates decide and
#      nothing blocks. PK5, PC1, PC5, PC6, PC7, PB5, PB11 and PT4 are amended; each says so.)
#   c6 a spec KB pins a decision (WP1, WP2)      : PX1 PX2 PX3 PX4
#   T18 c2 help codes lists WP1 to WP4           : PK6
#   T18 c3 the README documents the module       : PK7
#   T27 c1 writer identity (CLAUDE_CODE_SESSION_ID) : PW8
#   T27 c2 one writer for every KB, as a lease     : PW9 (PW7 drops its last case: a KB without project has a lock now)
#   T27 c3 the handoff texts (release, lease)      : PH1
#   T27 c10 the request is pinned (--source)       : PR1
# Ticket T37 (fixes found when T27 was verified; CONTRACT D23 P9 and D26 S12 amended):
#   c2 a write command re-checks the lease before it writes : PW10
#   c3 the request pin reads nested tracker JSON (ADO, Jira, Plane); a state move is no change : PR2
# Ticket T23 (CONTRACT D27, the project KB reasons over the domain):
#   c1 two sides: definition/2, concerns, help     : PT1
#   c2 product rules, pinned by spec claims        : PT2
#   c3 relations: supersedes, rests_on, contradiction, impact : PT3A PT3B PT3C PT3D
#   c4 origin: proposed, ratified_by, only ratified decisions block : PT4
#   c5 analyses in the project KB, week reports pinned : PT5
#   c6 dangling references (E4), help codes        : PT6
#   c7 D27 notes the Lean limit (burn_model untouched: kb/tests/burn_model/check.sh) : PT7
#   c8 pin-item keeps the pinned text; show pin    : PT8
#   T39 c2 a CI or tracker run is pinned (help build recipe)  : PE1
#   c9 project archive --superseded-before         : PT9
# Ticket T34 (fixes of the project KB found when T23 was verified; CONTRACT D27 R10):
#   c1 archive leaves no dangling reference; lint is clean after it : PF1
#   c2 archive and impact find a spec KB outside the parent directory : PF2
#   c3 --superseded-before takes only a real date  : PF3
#   c4 pin-item --kind file keeps no copy; show pin reports a mismatch : PF4
#   c5 self-relations are refused (EP2); a depends_on cycle is WP7 : PF5
#   c6 an agent's ratified_by is refused at add (any case); help states the trust limit : PF6
#   c1 (divergence a21) the removal closes over references: a fact that names a removed fact goes too : PF7
# T38 (fixes found when T34 was verified; CONTRACT D27 R10):
#   c6 archive warns and names --root when a pinning spec KB may be unseen : PF8
#   c7 the refusal path of archive                                          : PF9
#   c8 archive prunes spec_kbs.txt under the lock                           : PF10
#   c9 pin-item --kind file digests the pinned file                         : PF11
# T40 (fixes found when T38 was verified; CONTRACT D28 T38, D27 R10):
#   c2 show pin of a pin taken before byte digests; the re-pin recipe       : PF12
#   c3 spec_kbs.txt: register under the project KB lock; two looks to prune : PF13 (PF10 amended)
#   c5 archive --root warns about a registered spec KB outside the root     : PF14
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
for v in $(compgen -e); do case $v in ORBIT_KB*|CLAUDE_SESSION_ID|CLAUDE_CODE_SESSION_ID|HUB_SESSION) unset "$v";; esac; done
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
          # T43 c3 amended: conflict is gone from the list (no draft is a conflict now); dropped is in it
          local n; for n in decision decided_by reason repo analysis pin draft pins stale_pin outbound dropped supersedes_by_date; do
              out_has "(^|[^a-z_])$n([^a-z_]|\$)" "help project documents $n"; done
          out_has 'ORBIT_KB_WRITER' "help project documents the writer lock"; out_has '--take' "help project documents --take"
          out_has 'release' "help project documents release"
          okb help; rc_is 0 "general help"; out_has 'project' "the general help lists the topic"; }
# PK6 (T18 c2): the prompt sends an agent to `help codes` for every lint code, so it lists the
# codes of the project module too (D23: WP1, WP2, WP3, WP4), each on a line of its own.
t_PK6() { okb help codes; rc_is 0 "help codes"
          local c; for c in WP1 WP2 WP3 WP4; do out_has "^ *$c +[a-zA-Z]" "help codes lists $c with its text"; done; }
# PK7 (T18 c3): the README of orbit-kb documents the project module: the lint table has WP1 to
# WP4, the command reference has draft, pin-item and release, and Locking names the writer lock.
# readme_part START END: the lines of README.md from the line that matches START up to (not
# including) the next line that matches END.
readme_part() { awk -v s="$1" -v e="$2" 'on && $0 ~ e {exit} $0 ~ s {on=1} on' "$LIB/README.md"; }
t_PK7() { [ -f "$LIB/README.md" ] || { note "no README.md in $LIB"; return; }
          local lint cmds lock c bt='`'
          lint=$(readme_part '^## [0-9]+[.] Lint codes' '^## ')
          for c in WP1 WP2 WP3 WP4; do printf '%s\n' "$lint" | grep -Eq "^[|] $c [|] [A-Za-z]" || note "the README lint table has no row $c"; done
          cmds=$(readme_part '^## [0-9]+[.] Command reference' '^## ')
          for c in 'draft blocking' 'draft outbound' 'pin-item' 'release'; do
              printf '%s\n' "$cmds" | grep -E '^### `' | grep -Fq -- "$c" || note "the README command reference has no heading for $c"; done
          lock=$(readme_part '^### Locking' '^##? ')
          for c in writer.lock ORBIT_KB_WRITER CLAUDE_SESSION_ID --take release; do
              printf '%s\n' "$lock" | grep -Fq -- "$c" || note "README Locking does not name $c"; done
          for c in add subject attest run prove uses pin-item; do
              printf '%s\n' "$lock" | grep -Fq -- "$bt$c$bt" || note "README Locking does not list the locked command $c"; done; }

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
          # T27 c2: a KB without project has the lock too now (PW9); the case "a KB without project has no lock" is gone.
          true; }

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
# pin p1 at T1. Tracker changed at T2 (p2). Draft staged at T3 (after both).
# T43 c3 amended (was: a conflict, not decided by date, not outbound, nothing dropped): the draft is
# later and wins; the tracker text is dropped.
t_PC1() { pk_basic; K=$T/pk; tracker_changed p2 "$T2"; stage dr1 "$T3"
          is_set 'supersedes_by_date(D, S)' 'D = dr1, S = draft' "both changed: the later edit (the draft) wins"
          is_true 'outbound(dr1)' "the draft that won is outbound"
          is_set 'dropped(D, S)' 'D = dr1, S = tracker' "the tracker text is dropped"; }
# tracker unchanged since the pin: the draft is later and wins
t_PC2() { pk_basic; K=$T/pk; stage dr1 "$T2"
          is_set 'supersedes_by_date(D, S)' 'D = dr1, S = draft'   # T43 c3 amended: is_false 'conflict(dr1)' dropped (conflict/1 is gone)
          is_true 'outbound(dr1)'; is_false 'dropped(dr1, S)' "the draft wins: nothing dropped (the tracker did not change)"; }
# draft staged before the pin's ChangedAt, tracker changed later: the tracker is later and wins
t_PC3() { pk_basic; K=$T/pk; tracker_changed p2 "$T3"
          padd "draft(dr1, p1, 'An old edit', '2026-02-28T09:00:00Z')" >/dev/null
          is_set 'supersedes_by_date(D, S)' 'D = dr1, S = tracker'   # T43 c3 amended: is_false 'conflict(dr1)' dropped (conflict/1 is gone)
          is_set 'dropped(D, S)' 'D = dr1, S = draft' "the dropped edit is recorded"
          is_false 'outbound(dr1)' "a dropped draft is not pushed"
          has_fact "$K/kb.pl" "draft(dr1, _, _, _)" "the draft is still in kb.pl, never lost"; }
# the boundary: staged exactly at the pin's ChangedAt is not after it
t_PC4() { pk_basic; K=$T/pk; tracker_changed p2 "$T3"; stage dr1 "$T1"   # T43 c3 amended: is_false 'conflict(dr1)' dropped (conflict/1 is gone)
          is_set 'supersedes_by_date(D, S)' 'D = dr1, S = tracker'; }
# the third case: the tracker changed after the pin, the draft staged after the pin AND after the tracker change
# T43 c3 amended (was: both are conflicts): the latest tracker change (T3) is the one that counts.
t_PC5() { pk_basic; K=$T/pk; tracker_changed p2 "$T2"; tracker_changed p3 "$T3"; stage dr1 "$T4"
          is_set 'supersedes_by_date(D, S)' 'D = dr1, S = draft' "after the pin, the tracker changed twice; the draft is later than both"
          stage dr2 "$T2"
          is_set 'supersedes_by_date(D, S)' 'D = dr1, S = draft|D = dr2, S = tracker' "dr2 is later than the first tracker change, not the latest"; }
# a human resolves: the other side is recorded as dropped, also against the dates
# (T43 c3 amended: the assertion that the conflict goes is dropped; no draft is a conflict now)
t_PC6() { pk_basic; K=$T/pk; tracker_changed p2 "$T2"; stage dr1 "$T3"
          padd "resolved(dr1, draft, '$T4')"; rc_is 0 "resolved(Draft, Side, Time)"
          is_false 'supersedes_by_date(dr1, S)' "resolved: the dates do not decide"; is_set 'dropped(D, S)' 'D = dr1, S = tracker'; is_true 'outbound(dr1)' "the draft wins and can go out"
          stage dr2 "$T3"; padd "resolved(dr2, tracker, '$T4')" >/dev/null
          is_set 'dropped(D, S)' 'D = dr1, S = tracker|D = dr2, S = draft'; is_false 'outbound(dr2)' "a dropped draft is not outbound"
          padd "resolved(dr1, nobody, '$T4')"; rc_is 1 "a side outside draft|tracker"; }
# T43 c3 amended (was: a conflict blocks the spec KBs that pin the decision, until resolved): a
# draft whose pin both sides changed blocks no spec KB.
t_PC7() { pk_basic; tracker_changed p2 "$T2"; stage dr1 "$T3"
          local pk=$K spec=$T/spec dd; dd=$(tdigest 'Export goes through the queue')
          okb init "$spec" --request 'Build the export' --uses build,project >/dev/null 2>&1 || note "setup: spec init failed: $(snip "$err")"
          K=$spec
          padd "project_kb('../pk')" "claim(c1, introduce, 'Export uses the queue')" "cites(c1, 'Build the export')" "check(k1, c1)" \
               "pins(c1, project, d1, '$dd')" >/dev/null; rc_is 0 "the spec KB pins decision d1"
          is_false 'blocking(project_conflict(D))' "both changed: the draft blocks no spec KB that pins d1"
          okb --dir "$K" show blocking; out_hasnt 'project_conflict' "show blocking names no conflict"
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

# ================================================================ review fixes (after the first green)
# PB1-PB4: a project_kb that cannot be used is WP2, never a crash (CONTRACT: a broken source never exits 1).
spec_pointing() {  # spec_pointing TARGET: a build+project spec KB at $T/spec, project_kb(TARGET), one pinned claim
    okb init "$T/spec" --request 'Build the export' --uses build >/dev/null 2>&1 || note "setup: init failed"
    okb --dir "$T/spec" uses project >/dev/null 2>&1 || note "setup: uses project failed"
    K=$T/spec
    padd "project_kb('$1')" "claim(c1, introduce, 'Export uses the queue')" "cites(c1, 'Build the export')" \
         "pins(c1, project, d1, '$H1')" >/dev/null; [ "$rc" = 0 ] || note "setup: add failed: $(snip "$out$err")"
}
pb_broken_target() {  # pb_broken_target: the checks that every broken target must pass
    okb --dir "$K" lint; rc_is 0 "lint does not crash"; out_has '^WP2 c1:' "WP2 for the pin that cannot be read"
    any_hasnt_main
    q 'claim(X, Y, Z)'; rc_is 0 "a query still works"
    okb --dir "$K" show blocking; rc_is 0 "show blocking still works"
    okb --dir "$K" report; rc_is 0 "report still works"
}
any_hasnt_main() { anyout | grep -Eq 'user:main|^ERROR' && note "the CLI crashed: $(snip "$out$err")"; return 0; }
t_PB1() { mkdir -p "$T/x"; spec_pointing '../nowhere'; pb_broken_target; }
t_PB2() { mkdir -p "$T/empty"; spec_pointing '../empty'; pb_broken_target; }
t_PB3() { okb init "$T/plain" --request 'No project module here' --uses build >/dev/null 2>&1
          spec_pointing '../plain'; pb_broken_target; }
t_PB4() { spec_pointing '.'; pb_broken_target; }

# PB12: two project_kb facts: only the first is read, so lint warns (WP4).
t_PB12() { spec_with_pin
           okb --dir "$K" lint; rc_is 0; out_hasnt '^WP4' "one project_kb: no WP4"
           padd "project_kb('../other')" >/dev/null; rc_is 0 "a second project_kb is added"
           okb --dir "$K" lint; rc_is 0 "a warning is not an error"; out_has '^WP4' "WP4 names the extra project_kb"
           okb --dir "$K" lint --strict; rc_is 1 "--strict"; }

# PB5: a project KB that does not load clean is never silent.
t_PB5() { pk_basic; tracker_changed p2 "$T2"; stage dr1 "$T3"
          local pk=$K; spec_with_conflict_pin "$pk"
          is_false 'blocking(project_conflict(D))' "clean project KB: nothing blocks (T43 c3 amended: was the conflict blocks)"
          printf 'this is not (valid.\n' >> "$pk/kb.pl"
          okb --dir "$K" lint; rc_is 0 "lint is not an error in the spec KB"; out_has '^WP3' "WP3 names the broken project KB"
          is_true 'blocking(project_kb_unclean)' "the broken project KB blocks"
          is_false 'done' "done waits"
          okb --dir "$K" show blocking; rc_is 0; out_has 'project_kb_unclean' "show blocking names it"; }
spec_with_conflict_pin() {  # spec_with_conflict_pin PKDIR: a spec KB that pins d1 of PKDIR, and concerns(d1, p1) is in PKDIR
    local dd; dd=$(tdigest 'Export goes through the queue')
    okb init "$T/spec" --request 'Build the export' --uses build,project >/dev/null 2>&1 || note "setup: spec init failed"
    K=$T/spec
    padd "project_kb('../pk')" "claim(c1, introduce, 'Export uses the queue')" "cites(c1, 'Build the export')" "check(k1, c1)" \
         "pins(c1, project, d1, '$dd')" >/dev/null; [ "$rc" = 0 ] || note "setup: spec add failed: $(snip "$out$err")"
}

# PB6: --take on a rejected add moves nothing.
t_PB6() { pk_init "$T/pk"
          ORBIT_KB_WRITER=ann padd "decision(d1, 'First')" >/dev/null; cp "$K/writer.lock" "$T/.lock.before"; cp "$K/kb.pl" "$T/.kb.before"
          ORBIT_KB_WRITER=bob padd "decided_by(d99, bob, '$T1')" --take; rc_is 1 "the add is rejected (dangling ref)"
          same_file "$K/writer.lock" "$T/.lock.before" "the lock did not move"; same_file "$K/kb.pl" "$T/.kb.before" "kb.pl is unchanged"
          ORBIT_KB_WRITER=bob padd "decision(d2, 'Second')" --take; rc_is 0 "an accepted add with --take takes the lock"
          has_goal "$K/kb.pl" "kb(writer_takeover(ann, bob, _))" "the takeover is recorded when the add is accepted"; }

# PB7: writer names with a space; an empty or malformed lock.
t_PB7() { pk_init "$T/pk"
          ORBIT_KB_WRITER='ann smith' padd "decision(d1, 'First')" >/dev/null; rc_is 0 "a writer name with a space"
          ORBIT_KB_WRITER=bob padd "decision(d2, 'Second')"; rc_is 2 "another writer"; any_has 'ann smith' "the whole name is the holder"
          ORBIT_KB_WRITER='ann smith' padd "decision(d3, 'Third')"; rc_is 0 "the same writer goes on"
          ORBIT_KB_WRITER='bob jones' padd "decision(d4, 'Fourth')" --take; rc_is 0 "--take with a spaced name"
          has_goal "$K/kb.pl" "kb(writer_takeover('ann smith', 'bob jones', _))" "both names are kept whole"
          ORBIT_KB_WRITER='ann smith' padd "decision(d5, 'Fifth')"; rc_is 2 "the old holder is a second writer"; any_has 'bob jones' "names the new holder"; }
t_PB8() { pk_init "$T/pk"
          : > "$K/writer.lock"
          ORBIT_KB_WRITER=ann padd "decision(d1, 'First')"; rc_is 2 "an empty lock is an error"
          any_hasi 'empty|malformed|cannot read' "the message says what is wrong"; any_has 'Fix' "the message has a fix line"
          printf 'garbage\n' > "$K/writer.lock"
          ORBIT_KB_WRITER=ann padd "decision(d1, 'First')"; rc_is 2 "a lock with no time is an error"; any_has 'Fix' "the fix line"
          ORBIT_KB_WRITER=ann okb --dir "$K" release; rc_is 2 "release does not guess either"; any_has 'Fix' "the fix line"; }

# PB9: WP1 clears after a re-pin; the old pins fact stays (append-only).
t_PB9() { spec_with_pin
          sed -i "s/Export goes through the queue/Export goes through the batch job/" "$SPEC_PK/kb.pl"
          okb --dir "$K" lint; out_has '^WP1 c1:' "WP1 fires on the old digest"
          local nd; nd=$(tdigest 'Export goes through the batch job')
          padd "pins(c1, project, d1, '$nd')"; rc_is 0 "the new digest is pinned"
          okb --dir "$K" lint; rc_is 0; out_hasnt '^WP1' "WP1 is cleared by the newest pin"
          has_fact "$K/kb.pl" "pins(c1, project, d1, _)" "the pins facts stay in kb.pl"
          local n; n=$(grep -c '^pins(c1' "$K/kb.pl"); [ "$n" = 2 ] || note "want 2 pins facts, have $n"
          sed -i "s/Export goes through the batch job/Export goes through a stream/" "$SPEC_PK/kb.pl"
          okb --dir "$K" lint; out_has '^WP1 c1:' "WP1 fires again when the decision changes again"; }

# PB10: the term-order builtins bind nothing, so E14 applies as for \=.
e14_rules() {  # e14_rules BODYTAIL
    mkdir -p "$T/e"
    printf "uses([]).\nrequest(r1, 'x').\ndecl(fact, q(atom), 'A q.', '').\ndecl(rule, p(atom), 'A p.', '').\nq(a).\n" > "$T/e/kb.pl"
    printf 'p(X) :- not q(X), %s.\n' "$1" > "$T/e/rules.pl"
    okb --dir "$T/e" lint
}
t_PB10() { local b
           for b in 'X \= a' "X \\== a" 'X == a' 'X @< a' 'X @> a' 'X @=< a' 'X @>= a'; do
               e14_rules "$b"; rc_is 1 "lint with $b"; out_has '^E14 ' "E14 with $b"
           done; }

# PB11: show blocking follows D22: "- KIND ID: SENTENCE: TEXT".
t_PB11() { pk_basic; tracker_changed p2 "$T2"; stage dr1 "$T3"; spec_with_conflict_pin "$K"
           okb --dir "$K" show blocking; rc_is 0
           # T43 c3 amended (was: the line "- project_conflict dr1: SENTENCE: TEXT"): no draft blocks now
           out_hasnt 'project_conflict' "no conflict line"
           printf 'this is not (valid.\n' >> "$T/pk/kb.pl"
           okb --dir "$K" show blocking; out_has '^- project_kb_unclean: .+' "the unclean item has a sentence"; }


# ================================================================ T27 c1: writer identity
t_PW8() { pk_init "$T/pk"
          CLAUDE_CODE_SESSION_ID=cc-1 padd "decision(d1, 'A Claude Code session')"; rc_is 0 "only CLAUDE_CODE_SESSION_ID"
          grep -Eq '^cc-1 [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{8}Z$' "$K/writer.lock" 2>/dev/null || note "writer.lock is not 'cc-1 TIME': $(cat "$K/writer.lock" 2>/dev/null)"
          CLAUDE_CODE_SESSION_ID=cc-2 CLAUDE_SESSION_ID=cc-1 padd "decision(d2, 'Two ids')"; rc_is 2 "CLAUDE_CODE_SESSION_ID wins over CLAUDE_SESSION_ID"; any_has 'cc-1' "names the holder"
          CLAUDE_SESSION_ID=cc-1 HUB_SESSION=hub-x padd "decision(d3, 'Older id')"; rc_is 0 "CLAUDE_SESSION_ID wins over HUB_SESSION"
          ORBIT_KB_WRITER=cc-1 CLAUDE_CODE_SESSION_ID=cc-9 padd "decision(d4, 'The variable')"; rc_is 0 "ORBIT_KB_WRITER wins over CLAUDE_CODE_SESSION_ID"
          CLAUDE_CODE_SESSION_ID=cc-1 okb --dir "$K" release >/dev/null; rc_is 0 "release by the holder"
          HUB_SESSION=hub-x padd "decision(d5, 'A hub session')"; rc_is 0 "only HUB_SESSION"
          grep -q '^hub-x ' "$K/writer.lock" 2>/dev/null || note "writer.lock does not name hub-x: $(cat "$K/writer.lock" 2>/dev/null)"; }

# ================================================================ T27 c2: one writer for every KB, a lease
t_PW9() { K=$T/spec; okb init "$K" --request 'plain' --uses build >/dev/null 2>&1
          ORBIT_KB_WRITER=ann okb --dir "$K" add "claim(c1, introduce, 'x')" "cites(c1, 'x')"; rc_is 0 "ann writes a spec KB"
          grep -q '^ann ' "$K/writer.lock" 2>/dev/null || note "a spec KB took no lock"
          cp "$K/kb.pl" "$T/.before"
          ORBIT_KB_WRITER=bob okb --dir "$K" add "claim(c2, introduce, 'y')" "cites(c2, 'y')"; rc_is 2 "a second writer of a spec KB"; any_has 'ann' "names the holder"
          same_file "$K/kb.pl" "$T/.before" "kb.pl after the refusal"
          # the holder's write renews the lease: the time is the time of the last write
          printf 'ann 2020-01-01T00:00:00Z\n' > "$K/writer.lock"
          ORBIT_KB_WRITER=ann ORBIT_KB_LEASE=1000000000 okb --dir "$K" add "note(c1, 'renew')"; rc_is 0 "the holder writes"
          grep -q '^ann 2020-' "$K/writer.lock" && note "the holder's write did not renew the time of the lease"
          # a lease that did not lapse stays held
          printf 'ann 2020-01-01T00:00:00Z\n' > "$K/writer.lock"
          ORBIT_KB_WRITER=bob ORBIT_KB_LEASE=1000000000 okb --dir "$K" add "note(c1, 'not lapsed')"; rc_is 2 "a lease that did not lapse"
          # the default lease is 30 minutes: an old lock lapses, and the next writer takes it
          ORBIT_KB_WRITER=bob okb --dir "$K" add "note(c1, 'bob after the lapse')"; rc_is 0 "bob takes a lapsed lease"
          has_goal "$K/kb.pl" "kb(writer_takeover(ann, bob, T)), atom_length(T, 20)" "the takeover is recorded"
          has_goal "$K/kb.pl" "kb_line(A, writer_takeover(ann, bob, _)), kb_line(B, note(c1, 'bob after the lapse')), A < B" "the takeover comes before the fact"
          grep -q '^bob ' "$K/writer.lock" || note "writer.lock does not name bob"
          ORBIT_KB_WRITER=ann okb --dir "$K" add "note(c1, 'ann again')"; rc_is 2 "the former holder is refused"; any_has 'bob' "names the new holder"
          ORBIT_KB_WRITER=bob okb --dir "$K" release; rc_is 0 "bob releases"
          ORBIT_KB_WRITER=ann okb --dir "$K" add "note(c1, 'ann after the release')"; rc_is 0 "ann writes after the release"
          # a fresh lease of another writer is not lapsed
          printf 'bob %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$K/writer.lock"
          ORBIT_KB_WRITER=ann okb --dir "$K" add "note(c1, 'too soon')"; rc_is 2 "a fresh lease"
          # a short lease: ORBIT_KB_LEASE=0 lapses at once
          ORBIT_KB_WRITER=ann ORBIT_KB_LEASE=0 okb --dir "$K" add "note(c1, 'short lease')"; rc_is 0 "ORBIT_KB_LEASE=0"
          ORBIT_KB_LEASE=soon ORBIT_KB_WRITER=ann okb --dir "$K" add "note(c1, 'bad lease')"; rc_is 2 "a lease that is not a number"
          okb help project; out_has 'ORBIT_KB_LEASE' "help project names ORBIT_KB_LEASE"; out_has 'CLAUDE_CODE_SESSION_ID' "help project names CLAUDE_CODE_SESSION_ID"; }

# ================================================================ T27 c3: the handoff texts
t_PH1() { local P=$here/../../prompt gives
          gives=$(grep -E '^- \*\*Gives:\*\*' -A3 "$P/panes/build.md")
          printf '%s\n' "$gives" | grep -Fq 'orbit-kb release' || note "panes/build.md Gives does not say orbit-kb release"
          grep -Fq 'orbit-kb release' "$P/PANES.md" || note "PANES.md does not say orbit-kb release"
          grep -Eiq 'first write takes the (writer )?lock' "$P/PANES.md" || note "PANES.md does not say the receiver's first write takes the lock"
          grep -Eiq 'own lease' "$P/panes/review.md" || note "panes/review.md does not say review writes under its own lease"; }

# ================================================================ T27 c10: the request is pinned
t_PR1() { local J=$T/item.json S=$T/spec
          printf '{"title": "Export must be daily", "body": "Send the export each day.", "acceptance_criteria": "One file per day", "state": "open", "column": "Todo"}\n' > "$J"
          okb init "$S" --request-file "$J" --source 'gh:acme/widgets#3' --uses build; rc_is 0 "init --source"
          K=$S
          has_goal "$S/kb.pl" "kb(request(r1, T)), sub_atom(T, _, _, _, 'Export must be daily'), sub_atom(T, _, _, _, 'Send the export each day.'), sub_atom(T, _, _, _, 'One file per day')" "the request text is the title, the description and the acceptance criteria"
          no_fact "$S/kb.pl" "request(r1, T)), sub_atom(T, _, _, _, 'Todo'" "the request text holds no state"
          has_goal "$S/kb.pl" "kb(request_pin(r1, 'gh:acme/widgets#3', D, T)), sub_atom(D, 0, 7, _, 'sha256:'), atom_length(T, 20)" "a pin of the request: ref, digest, date"
          local want; want=$(swipl -q -g "open('$S/kb.pl', read, S), repeat, read(S, X), (X = request(r1, T) -> write(T), halt ; X == end_of_file -> halt(1) ; fail)" 2>/dev/null)
          has_goal "$S/kb.pl" "kb(request_pin(r1, _, '$(tdigest "$want")', _))" "the digest is the sha256 of the request text"
          is_false 'request_stale(r1)'
          # a column move is not a change of the text
          sed -i 's/"Todo"/"Done"/; s/"open"/"closed"/' "$J"
          okb --dir "$S" pin-request --request-file "$J"; rc_is 0 "pin-request after a column move"
          is_false 'request_stale(r1)'; is_false 'blocking(request_stale(r1))'
          # a changed text makes the request stale: a W lint and a blocking item
          sed -i 's/Send the export each day./Send the export each hour./' "$J"
          okb --dir "$S" pin-request --request-file "$J"; rc_is 0 "pin-request after a text change"
          is_true 'request_stale(r1)'; is_true 'blocking(request_stale(r1))'
          okb --dir "$S" lint; out_has '^W8 r1' "a W-lint names the stale request"
          okb --dir "$S" show blocking; out_has 'request_stale r1' "show blocking lists it"
          okb --dir "$S" pin-request --request-file "$J" --accept; rc_is 2 "--accept needs --by human"
          is_true 'request_stale(r1)'
          okb --dir "$S" pin-request --request-file "$J" --accept --by human; rc_is 0 "a human accepts the new text"
          is_false 'request_stale(r1)'; is_false 'blocking(request_stale(r1))'
          has_goal "$S/kb.pl" "kb(request_accepted(r1, _, T)), sub_atom(T, _, _, _, 'each hour')" "the accepted text is kept"
          # without --source the KB owns the request: no pin, and pin-request has nothing to pin
          okb init "$T/own" --request 'Plain words' --uses build; rc_is 0
          no_fact "$T/own/kb.pl" "request_pin(_, _, _, _)" "no pin without --source"
          okb --dir "$T/own" pin-request --request-file "$J"; rc_is 1 "pin-request without a source"; }

# ================================================================ T37 c2: a takeover during a long run stops the old holder
t_PW10() { K=$T/spec; okb init "$K" --request 'plain' --uses build >/dev/null 2>&1
          ORBIT_KB_WRITER=ann okb --dir "$K" add "claim(c1, introduce, 'x')" "cites(c1, 'x')" "check(k1, c1)"; rc_is 0 "ann sets up the KB"
          ( cd "$T" && ORBIT_KB_WRITER=ann timeout "$TMO" "$OKB" --dir "$K" run k1 -- sleep 4 ) >"$T/.run.out" 2>"$T/.run.err" </dev/null &
          local rp=$!
          sleep 1.5
          # bob's lease is 0 minutes: ann's lease lapses at once, and bob takes the lock during the run
          ORBIT_KB_WRITER=bob ORBIT_KB_LEASE=0 okb --dir "$K" add "note(c1, 'bob took over')"; rc_is 0 "bob takes the lapsed lease during the run"
          wait "$rp"; local rrc=$?
          [ "$rrc" = 2 ] || note "ann's run after the takeover: exit $rrc, want 2 ($(snip "$(cat "$T/.run.err")"))"
          grep -Fq 'bob' "$T/.run.err" || note "the refusal does not name the new holder: $(snip "$(cat "$T/.run.err")")"
          no_fact "$K/kb.pl" "attest(_, test_result, k1, _, _, _)" "ann's result was written after the takeover"
          ls "$K"/runs/*.log >/dev/null 2>&1 && note "a run log was left after the refused run"; return 0; }

# ================================================================ T37 c3: the pin reads the nested JSON of the trackers in use
t_PR2() { local S J want
          printf '{"id": 7, "fields": {"System.Title": "Export must be daily", "System.Description": "Send the export each day.", "Microsoft.VSTS.Common.AcceptanceCriteria": "One file per day", "System.State": "Active", "System.BoardColumn": "Todo"}}\n' > "$T/ado.json"
          printf '{"key": "WID-3", "fields": {"summary": "Export must be daily", "description": "Send the export each day.", "status": {"name": "To Do"}}}\n' > "$T/jira.json"
          printf '{"id": "9f2", "name": "Export must be daily", "description_html": "<p>Send the export each day.</p>", "state": "uuid-todo"}\n' > "$T/plane.json"
          for J in ado jira plane; do
              S=$T/$J; okb init "$S" --request-file "$T/$J.json" --source "$J:acme/widgets#3" --uses build; rc_is 0 "$J: init --source"
              has_goal "$S/kb.pl" "kb(request(r1, T)), sub_atom(T, _, _, _, 'Export must be daily'), sub_atom(T, _, _, _, 'Send the export each day.')" "$J: the request text is the title and the description"
              no_fact "$S/kb.pl" "request(r1, T)), sub_atom(T, _, _, _, 'Todo'" "$J: the request text holds no column"
              no_fact "$S/kb.pl" "request(r1, T)), sub_atom(T, _, _, _, 'fields'" "$J: the request text is not the raw JSON"
          done
          has_goal "$T/ado/kb.pl" "kb(request(r1, T)), sub_atom(T, _, _, _, 'One file per day')" "ado: the acceptance criteria"
          # a State or BoardColumn move is no change
          sed -i 's/"Todo"/"Doing"/; s/"Active"/"Resolved"/' "$T/ado.json"
          sed -i 's/"To Do"/"Done"/' "$T/jira.json"
          sed -i 's/uuid-todo/uuid-done/' "$T/plane.json"
          for J in ado jira plane; do
              okb --dir "$T/$J" pin-request --request-file "$T/$J.json"; rc_is 0 "$J: pin-request after a state move"
              okb --dir "$T/$J" query 'request_stale(r1)'; rc_is 1 "$J: a state move is no change"
          done
          # a text change is a change
          sed -i 's/each day/each hour/' "$T/jira.json"
          okb --dir "$T/jira" pin-request --request-file "$T/jira.json"; rc_is 0
          okb --dir "$T/jira" query 'request_stale(r1)'; rc_is 0 "jira: a text change makes the request stale"; return 0; }

# ================================================================ T23: the project KB reasons (D27)
# Fixtures are invented: the widget product of acme. Ids: d* decisions, df* definitions, ru* rules (r1 is the request id).

# t23_pk: a project KB at $T/pk with the facts given (K stays at the project KB).
t23_pk() { pk_init "$T/pk"; [ $# -eq 0 ] && return 0; padd "$@" >/dev/null; [ "$rc" = 0 ] || note "setup: project facts failed: $(snip "$out$err")"; }
# t23_spec NAME ITEM [ITEM2]: a build+project spec KB at $T/NAME, whose claim c1 pins ITEM of
# ../pk with its digest now (read through project_decision_digest). K is left at the spec KB.
t23_spec() {
    local name=$1 item=$2 d
    okb init "$T/$name" --request "Build $name" --uses build,project >/dev/null 2>&1 || note "setup: init $name failed: $(snip "$err")"
    K=$T/$name
    padd "project_kb('../pk')" "claim(c1, preserve, 'The $name work holds')" "cites(c1, 'Build $name')" "check(k1, c1)" >/dev/null
    [ "$rc" = 0 ] || note "setup: $name facts failed: $(snip "$out$err")"
    okb --dir "$K" query "project_decision_digest($item, D)"
    d=$(printf '%s\n' "$out" | sed -n "s/^D = '\{0,1\}\(sha256:[0-9a-f]*\)'\{0,1\}\$/\1/p" | head -n1)
    [ -n "$d" ] || { note "setup: no project_decision_digest for $item in $name (stdout: $(snip "$out"))"; d=$H1; }
    padd "pins(c1, project, $item, '$d')" >/dev/null; [ "$rc" = 0 ] || note "setup: $name pins $item failed: $(snip "$out$err")"
}

# PT1 (c1): two sides. definition/2 states how the system is; concerns/2 takes a definition too.
t_PT1() { t23_pk
          padd "definition(df1, 'Exports run nightly from the batch host')" "decision(d1, 'Export goes through the queue')" \
               "pin(p1, tracker, 'gh:acme/widgets#12', '$H1', '$T1')" "concerns(df1, p1)" "concerns(d1, p1)"
          rc_is 0 "definition and concerns of a definition are accepted"
          has_fact "$K/kb.pl" "definition(df1, _)"; has_fact "$K/kb.pl" "concerns(df1, p1)"
          padd "definition(df1, 'Another text')"; rc_is 1 "a duplicate definition id"; any_has 'E5' "E5"
          okb --dir "$K" lint; rc_is 0 "lint is clean"
          is_set 'definition(X, _)' "X = df1"
          okb help project; rc_is 0 "help project"
          printf '%s\n' "$out" | head -n 3 | grep -Fq 'Two sides: Decisions about future work and definitions about the current system.' \
              || note "help project does not open with Ty's two-sides sentence (head: $(snip "$(printf '%s\n' "$out" | head -n 3)"))"
          out_has 'Where the product is and where it is going' "the second half of the sentence"
          out_has '(^|[^a-z_])definition\(' "help project documents definition"; }

# PT2 (c2): product rules, pinned by a spec claim; WP1 and WP2 cover them.
t_PT2() { t23_pk "rule(ru1, 'Every export is logged')" "decision(d1, 'Export goes through the queue')"
          has_fact "$K/kb.pl" "rule(ru1, _)"
          okb --dir "$K" lint; rc_is 0 "a project KB with a rule lints clean"
          t23_spec spec ru1
          q 'project_decision_digest(ru1, D)'; rc_is 0 "the digest of a rule of the project KB"
          out_has "$(tdigest 'Every export is logged' | cut -c8-30)" "the sha256 of the rule text"
          okb --dir "$K" lint; rc_is 0; out_hasnt '^WP[12]' "a matching rule pin lints clean"
          sed -i "s/Every export is logged/Every export is logged twice/" "$T/pk/kb.pl"
          okb --dir "$K" lint; rc_is 0 "a warning"; out_has '^WP1 c1:' "WP1: the rule changed after the claim pinned it"
          padd "claim(c2, preserve, 'Other')" "cites(c2, 'Build spec')" "pins(c2, project, ru9, '$H1')" >/dev/null; rc_is 0
          okb --dir "$K" lint; out_has '^WP2 c2:' "WP2: no such rule in the project KB"
          okb help project; out_has '(^|[^a-z_])rule\(' "help project documents rule"; }

# PT3A (c3): supersedes between decisions or definitions; current_fact; a cycle is E15.
t_PT3A() { t23_pk "decision(d1, 'Export goes through the queue')" "decision(d2, 'Export goes through the stream')" \
                  "definition(df1, 'Exports run nightly')" "definition(df2, 'Exports run hourly')" "rule(ru1, 'Every export is logged')"
           padd "supersedes(d2, d1)" "supersedes(df2, df1)"; rc_is 0 "supersedes between decisions and between definitions"
           is_set 'current_fact(X)' "X = d2|X = df2|X = ru1"
           padd "supersedes(d1, df1)"; rc_is 1 "a decision cannot replace a definition"; any_has 'E4' "E4"
           padd "supersedes(d1, d2)"; rc_is 1 "a cycle is refused"; any_has 'E15' "E15"
           printf 'supersedes(d1, d2).\n' >> "$K/kb.pl"
           okb --dir "$K" lint; rc_is 1 "a supersede cycle of decisions is a lint error"; out_has '^E15 ' "E15"; }

# PT3B (c3): depends_on between any two kinds; rests_on is its transitive closure.
t_PT3B() { t23_pk "decision(d1, 'Export goes through the queue')" "definition(df1, 'The queue runs on the batch host')" \
                  "rule(ru1, 'Every export is logged')" "decision(d2, 'Retry an export three times')"
           padd "depends_on(d1, df1)" "depends_on(df1, ru1)" "depends_on(d2, d1)"; rc_is 0 "depends_on between any two kinds"
           is_set 'rests_on(d1, X)' "X = df1|X = ru1"
           is_set 'rests_on(d2, X)' "X = d1|X = df1|X = ru1"
           is_set 'rests_on(X, ru1)' "X = d1|X = d2|X = df1"
           is_false 'rests_on(ru1, _)'
           okb --dir "$K" lint; rc_is 0 "lint is clean"; }

# PT3C (c3): excludes and contradiction; it blocks only a spec KB that pins a side directly; one
# that reaches a side through rests_on gets WP5 and no blocking item.
t_PT3C() { t23_pk "decision(d1, 'Export goes through the queue')" "definition(df1, 'There is no queue')" \
                  "decision(d3, 'Retry an export three times')" "depends_on(d3, d1)" "rule(ru1, 'Every export is logged')" \
                  "excludes(d1, df1)"
           is_set 'contradiction(X, Y)' "X = d1, Y = df1"
           okb --dir "$K" lint; rc_is 0 "a contradiction is not a lint error of the project KB"
           t23_spec direct d1
           is_true 'blocking(project_contradiction(d1))' "a spec KB that pins d1 directly is blocked"
           okb --dir "$K" show blocking; out_has '^- project_contradiction d1: .+' "show blocking names it with a sentence"
           is_false 'done' "done waits"
           t23_spec side df1
           is_true 'blocking(project_contradiction(df1))' "the other side blocks a spec KB that pins it"
           t23_spec through d3
           is_false 'blocking(project_contradiction(_))' "a spec KB that reaches d1 through rests_on is not blocked"
           okb --dir "$K" lint; rc_is 0 "only a warning"; out_has '^WP5 c1:' "WP5 names the claim"
           t23_spec apart ru1
           is_false 'blocking(project_contradiction(_))' "a spec KB that pins an unrelated rule is not blocked"
           okb --dir "$K" lint; out_hasnt '^WP5' "and has no WP5"
           K=$T/pk; padd "definition(df2, 'A queue exists')" "supersedes(df2, df1)" >/dev/null
           is_false 'contradiction(_, _)' "a superseded side ends the contradiction"
           K=$T/direct; is_false 'blocking(project_contradiction(_))' "nothing blocks after the supersede"
           K=$T/through; okb --dir "$K" lint; out_hasnt '^WP5' "and WP5 is gone"; }

# PT3D (c3): impact(X, SpecKB) and `orbit-kb project impact X`.
t_PT3D() { t23_pk "decision(d1, 'Export goes through the queue')" "decision(d3, 'Retry an export three times')" \
                  "rule(ru1, 'Every export is logged')" "rule(ru2, 'Exports are signed')" "depends_on(d3, d1)" "depends_on(d1, ru1)"
           t23_spec direct d1; t23_spec through d3; t23_spec apart ru2
           K=$T/pk
           is_set 'impact(ru1, S)' "S = '$T/direct'|S = '$T/through'"
           okb --dir "$K" project impact ru1; rc_is 0 "project impact"
           out_has "$T/direct" "the spec KB that pins d1, which rests on ru1"
           out_has "$T/through" "the spec KB that pins d3, which rests on ru1 through d1"
           out_hasnt "$T/apart" "not a spec KB that pins an unrelated rule"
           okb --dir "$K" project impact d1; rc_is 0
           printf '%s\n' "$out" | grep -F "$T/direct" | grep -Eqv 'rests on' || note "d1 is pinned directly by direct: $(snip "$out")"
           printf '%s\n' "$out" | grep -F "$T/through" | grep -Eq 'rests on' || note "through reaches d1 through rests_on, and the line says so: $(snip "$out")"
           okb --dir "$K" project impact ru2; rc_is 0; out_has "$T/apart"
           okb --dir "$K" project impact d9; rc_is 2 "an id that is no decision, definition or rule"
           okb --dir "$K" add "decision(d4, 'Nobody pins this')" >/dev/null
           okb --dir "$K" project impact d4; rc_is 0; out_has 'No spec KB' "nothing is impacted"
           okb help project; out_has 'project impact' "help project documents project impact"; }

# PT4 (c4): origin. A decision by an agent is proposed until a human ratifies it; only ratified
# decisions block; an agent may not ratify.
t_PT4() { t23_pk "decision(d1, 'Export goes through the queue')" "decided_by(d1, 'agent:build', '$T1')" \
                 "decision(d2, 'Retry an export three times')" "decided_by(d2, 'product owner', '$T1')" \
                 "definition(df1, 'There is no queue')" "excludes(d1, df1)" \
                 "rule(ru1, 'Every export is logged')" "decided_by(ru1, ann, '$T1')"
          rc_is 0 "decided_by accepts a person, a role, and a rule"
          is_set 'proposed(X)' "X = d1"
          t23_spec spec d1
          is_false 'blocking(project_contradiction(_))' "a proposed decision does not block"
          K=$T/pk; padd "ratified_by(d1, ann, '$T2')"; rc_is 0 "a human ratifies"
          is_false 'proposed(_)' "ratified: no longer proposed"
          K=$T/spec; is_true 'blocking(project_contradiction(d1))' "a ratified decision blocks"
          K=$T/pk; padd "ratified_by(d2, 'agent:review', '$T2')"
          if [ "$rc" = 0 ]; then okb --dir "$K" lint; rc_is 1 "an agent that ratifies is a lint error"; out_has '^EP1 ' "EP1"
          else any_has 'EP1' "the add is refused with EP1"; fi
          # a draft conflict on a proposed decision does not block either
          rm -rf "$T/pk" "$T/spec"; t23_pk "decision(d5, 'Export goes through the queue')" "decided_by(d5, agent, '$T1')" \
                 "pin(p1, tracker, 'gh:acme/widgets#12', '$H1', '$T1')" "concerns(d5, p1)" \
                 "pin(p2, tracker, 'gh:acme/widgets#12', '$H2', '$T2')" "draft(dr1, p1, 'Retitle the issue', '$T3')"
          # T43 c3 amended (was: it blocks after the ratification): a draft blocks nothing, ratified or not
          t23_spec spec d5
          is_false 'blocking(project_conflict(_))' "a draft on a proposed decision does not block"
          K=$T/pk; padd "ratified_by(d5, ann, '$T3')" >/dev/null
          K=$T/spec; is_false 'blocking(project_conflict(_))' "after the ratification it does not block either"
          okb help project; out_has 'ratified_by' "help project documents ratified_by"; out_has 'proposed' "and proposed"; }

# PT5 (c5): analyses live in the project KB; a path outside it is WP6; a week's report is a file pin.
t_PT5() { t23_pk "decision(d1, 'Export goes through the queue')" "definition(df1, 'Exports run nightly')" "rule(ru1, 'Every export is logged')"
          mkdir -p "$K/analyses" "$T/weeks/w45"; printf 'why\n' > "$K/analyses/export.md"; printf 'raw report\n' > "$T/weeks/w45/report.md"
          padd "analysis(d1, 'analyses/export.md')" "analysis(df1, 'analyses/export.md')" "analysis(ru1, 'analyses/export.md')"
          rc_is 0 "analysis attaches to a decision, a definition and a rule"
          okb --dir "$K" lint; rc_is 0; out_hasnt '^WP6' "a path under the project KB is fine"
          okb --dir "$K" subject s1 "$T/weeks/w45/report.md" >/dev/null; rc_is 0 "a week's report is a subject"
          local d; d=$(sha "$T/weeks/w45/report.md")
          padd "pin(p1, file, s1, 'sha256:$d', '$T1')" "concerns(df1, p1)"; rc_is 0 "a file pin of the report"
          okb --dir "$K" lint; rc_is 0; out_hasnt '^WP6' "a file pin outside the KB is not an analysis"
          padd "analysis(d1, '../weeks/w45/report.md')" "analysis(ru1, '/var/tmp/notes.md')"; rc_is 0
          okb --dir "$K" lint; rc_is 0 "a warning"
          out_has '^WP6 .*weeks/w45/report.md' "WP6 names a relative path outside the project KB"
          out_has '^WP6 .*/var/tmp/notes.md' "WP6 names an absolute path outside the project KB"
          okb help project; out_has 'analyses/' "help project says where analyses live"
          out_has '[Ww]eeks? own' "help project says the weeks own raw reports and transcripts"; out_has 'transcript' "names transcripts"; }

# PT6 (c6): every new relation refuses a dangling reference with E4; help codes says so.
t_PT6() { t23_pk "decision(d1, 'Export goes through the queue')" "definition(df1, 'Exports run nightly')" \
                 "rule(ru1, 'Every export is logged')" "pin(p1, tracker, 'gh:acme/widgets#12', '$H1', '$T1')"
          local f
          for f in "depends_on(d1, x9)" "depends_on(x9, d1)" "excludes(d1, x9)" "excludes(x9, ru1)" "supersedes(x9, d1)" \
                   "supersedes(df1, x9)" "ratified_by(x9, ann, '$T1')" "decided_by(x9, ann, '$T1')" "analysis(x9, 'analyses/a.md')" \
                   "concerns(x9, p1)" "concerns(df1, p9)"; do
              padd "$f"; rc_is 1 "$f is refused" && any_has 'E4' "$f: E4"
          done
          for f in "depends_on(d1, p1)" "excludes(d1, p1)"; do padd "$f"; rc_is 1 "$f: a pin is no decision, definition or rule" && any_has 'E[34]' "$f: E3 or E4"; done
          printf 'depends_on(ru1, x9).\n' >> "$K/kb.pl"
          okb --dir "$K" lint; rc_is 1 "a dangling depends_on written by hand"; out_has '^E4 ' "lint E4"
          okb help codes; rc_is 0
          printf '%s\n' "$out" | grep -E '^ *E4' | grep -q 'depends_on' || note "help codes: the E4 line names depends_on"
          printf '%s\n' "$out" | grep -E '^ *E4' | grep -q 'excludes' || note "help codes: the E4 line names excludes"
          printf '%s\n' "$out" | grep -E '^ *E4' | grep -q 'ratified_by' || note "help codes: the E4 line names ratified_by"
          local c; for c in WP5 WP6 EP1; do out_has "^ *$c +[a-zA-Z]" "help codes lists $c"; done
          local lint; lint=$(readme_part '^## [0-9]+[.] Lint codes' '^## ')
          for c in WP5 WP6 EP1; do printf '%s\n' "$lint" | grep -Eq "^[|] $c [|] [A-Za-z]" || note "the README lint table has no row $c"; done; }

# PT7 (c7): CONTRACT D27 notes again that the Lean model of done has no project clause.
t_PT7() { local c=$here/../CONTRACT.md d
          [ -f "$c" ] || { note "no CONTRACT.md at $c"; return; }
          d=$(grep -F '**D27' "$c")
          [ -n "$d" ] || { note "CONTRACT.md has no D27"; return; }
          awk '/\*\*D27/{on=1} on' "$c" | head -n 30 | grep -q 'burn_model' || note "D27 names the burn_model"
          awk '/\*\*D27/{on=1} on' "$c" | head -n 30 | grep -Eq 'OPEN.md item 5|limit' || note "D27 notes the limit"; }

# PE1 (T39 c2, u89): a run result of CI or the tracker is pinned in the spec KB with the commands that exist
# (pin-item, run, a check that reads the pin); the claim counts it like a local run; help build says how.
t_PE1() { okb init "$T/ek" --request 'CI must pass' --uses build,project >/dev/null 2>&1 || note "setup: init failed"; K=$T/ek
          padd "claim(c1, introduce, 'The CI run of the widget job passes')" "cites(c1, 'CI must pass')" "check(k1, c1)" >/dev/null; rc_is 0 "setup"
          printf 'run 42 of widgets\nconclusion: failure\n' > "$T/ci42.txt"
          okb --dir "$K" pin-item ci42 'ci:acme/widgets/runs/42' --text-file "$T/ci42.txt" --changed-at "$T1"; rc_is 0 "pin the failed run"
          out_has 'sha256:' "pin-item prints the digest"
          local chk="$OKB --dir $K show pin ci42 | grep -q 'conclusion: success'"
          okb --dir "$K" run k1 -- sh -c "$chk"; rc_is 1 "the check on the failed run fails (red)"
          is_false 'fulfilled(c1)'
          printf 'run 43 of widgets\nconclusion: success\n' > "$T/ci43.txt"
          okb --dir "$K" pin-item ci43 'ci:acme/widgets/runs/43' --text-file "$T/ci43.txt" --changed-at "$T2"; rc_is 0 "pin the green run"
          okb --dir "$K" show pin ci43; rc_is 0 "show pin"; out_has 'ci:acme/widgets/runs/43' "the source ref"; out_has 'sha256:' "the digest"; out_has "$T2" "the time"
          chk="$OKB --dir $K show pin ci43 | grep -q 'conclusion: success'"
          okb --dir "$K" run k1 -- sh -c "$chk"; rc_is 0 "the check on the green run passes"
          is_true 'was_red(k1)'; is_true 'fulfilled(c1)'
          okb --dir "$K" lint; rc_is 0 "lint is clean"
          okb help build; out_has 'CI' "help build names a CI run"; out_has 'pin-item' "and pin-item"; out_has 'show pin' "and the check that reads the pin"; }

# PT8 (c8): pin-item keeps the pinned text at pins/HEX.txt; show pin ID prints it.
t_PT8() { t23_pk; printf 'Title: Sort orders\nBody: sort by date\n' > "$T/item.txt"
          local h; h=$(sha "$T/item.txt")
          okb --dir "$K" pin-item p1 'gh:acme/widgets#12' --text-file "$T/item.txt" --changed-at "$T1"; rc_is 0 "pin-item"
          [ -f "$K/pins/$h.txt" ] || note "no pins/$h.txt"
          [ -f "$K/pins/$h.txt" ] && { same_file "$K/pins/$h.txt" "$T/item.txt" "the kept text is the pinned bytes"; [ "$(sha "$K/pins/$h.txt")" = "$h" ] || note "the name is its own sha256"; }
          okb --dir "$K" show pin p1; rc_is 0 "show pin"; out_has '^Body: sort by date$' "show pin prints the text"; out_has 'gh:acme/widgets#12' "and the source"
          okb --dir "$K" pin-item p2 'gh:acme/widgets#12' --text-file "$T/item.txt" --changed-at "$T2"; rc_is 0
          [ "$(ls "$K/pins" | wc -l)" = 1 ] || note "the same text is kept once: $(ls "$K/pins" | tr '\n' ' ')"
          printf 'Other text\n' > "$T/other.txt"
          okb --dir "$K" pin-item p1 'gh:acme/widgets#13' --text-file "$T/other.txt" --changed-at "$T2"; rc_is 1 "a duplicate pin id"
          [ -f "$K/pins/$(sha "$T/other.txt").txt" ] && note "a refused pin-item kept its text"
          padd "pin(p3, tracker, 'gh:acme/widgets#14', '$H1', '$T1')" >/dev/null
          okb --dir "$K" show pin p3; rc_is 1 "a pin with no kept text"; any_hasi 'no text' "says so"
          okb --dir "$K" show pin p9; rc_is 2 "no such pin"
          okb help project; out_has 'pins/' "help project documents the kept text"; out_has 'show pin' "and show pin"; }

# PT9 (c9): project archive --superseded-before DATE removes what nothing keeps.
t_PT9() { t23_pk "decision(d1, 'Old export')" "decision(d2, 'New export')" "decided_by(d2, ann, '$T2')" "supersedes(d2, d1)" \
                 "reason(d1, 'It was simple')" \
                 "decision(d3, 'Old retry')" "decision(d4, 'New retry')" "decided_by(d4, ann, '$T2')" "supersedes(d4, d3)" \
                 "decision(d5, 'Old log')" "decision(d6, 'New log')" "decided_by(d6, ann, '$T2')" "supersedes(d6, d5)" \
                 "decision(d7, 'Audit')" "depends_on(d7, d5)" \
                 "decision(d8, 'Old sign')" "decision(d9, 'New sign')" "decided_by(d9, ann, '$T4')" "supersedes(d9, d8)" \
                 "definition(df1, 'Exports run nightly')" "definition(df2, 'Exports run hourly')" "decided_by(df2, ann, '$T2')" "supersedes(df2, df1)" \
                 "rule(ru1, 'Every export is logged')" "rule(ru2, 'Every export is logged and signed')" "decided_by(ru2, ann, '$T2')" "supersedes(ru2, ru1)" \
                 "decision(d12, 'Old base')" "decision(d13, 'Old middle')" "decision(d15, 'New base')" "decided_by(d15, ann, '$T2')" \
                 "supersedes(d15, d12)" "supersedes(d15, d13)" "depends_on(d13, d12)" "decision(d14, 'Top')" "depends_on(d14, d13)" \
                 "decision(d10, 'Old cache')" "decision(d11, 'New cache')" "decided_by(d11, ann, '$T2')" "supersedes(d11, d10)"
          t23_spec openspec d3
          t23_spec donespec d10; okb --dir "$K" run k1 -- true >/dev/null 2>&1
          is_true 'done' "setup: donespec is done"
          K=$T/pk
          okb --dir "$K" project archive; rc_is 2 "--superseded-before is required"
          okb --dir "$K" project archive --superseded-before soon; rc_is 2 "a DATE that is not a time"
          okb --dir "$K" project archive --superseded-before "$T3"; rc_is 0 "archive"
          local x; for x in d1 df1 ru1 d10; do out_has "(^|[^a-z0-9])$x([^a-z0-9]|\$)" "the output names $x"; done
          for x in "decision(d1, _)" "reason(d1, _)" "supersedes(d2, d1)" "definition(df1, _)" "rule(ru1, _)" "decision(d10, _)" "supersedes(d11, d10)"; do
              no_fact "$K/kb.pl" "$x" "archived"; done
          for x in "decision(d2, _)" "decision(d3, _)" "decision(d5, _)" "decision(d8, _)" "decision(d12, _)" "decision(d13, _)" \
                   "supersedes(d4, d3)" "supersedes(d6, d5)" "depends_on(d7, d5)" "definition(df2, _)" "rule(ru2, _)"; do
              has_fact "$K/kb.pl" "$x" "kept"; done
          okb --dir "$K" lint; rc_is 0 "the project KB lints clean after the archive"
          okb --dir "$K" project archive --superseded-before "$T3"; rc_is 0 "a second archive"; out_has 'Nothing' "removes nothing more"
          okb help project; out_has 'project archive' "help project documents project archive"
          local cmds; cmds=$(readme_part '^## [0-9]+[.] Command reference' '^## ')
          printf '%s\n' "$cmds" | grep -E '^### `' | grep -Fq 'project impact' || note "the README command reference has no heading for project impact"
          printf '%s\n' "$cmds" | grep -E '^### `' | grep -Fq 'project archive' || note "the README command reference has no heading for project archive"; }

# ================================================================ T34
# PF1 (T34 c1): archive removes every fact that names an archived id (a note, an attestation
# about it, a local fact with a ref argument), so lint is clean after it.
t_PF1() { t23_pk "decision(d1, 'Old export')" "decision(d2, 'New export')" "decided_by(d2, ann, '$T2')" "supersedes(d2, d1)" \
                 "note(d1, 'Kept for the history')" "decision(d3, 'Retry an export three times')" "note(d3, 'Stays')"
          okb --dir "$K" attest disclosure d1 "other('The old export was a guess')"; rc_is 0 "setup: an attestation about d1"
          printf "decl(fact, tag(ref(decision), text), 'A tag of a decision.', '').\n" >> "$K/kb.pl"   # setup: a local fact kind (as an older KB has it)
          padd "tag(d1, 'legacy')" "tag(d3, 'current')" >/dev/null; rc_is 0 "setup: tags"
          okb --dir "$K" lint; rc_is 0 "setup: lint is clean before the archive"
          okb --dir "$K" project archive --superseded-before "$T3"; rc_is 0 "archive"; out_has '(^|[^a-z0-9])d1([^a-z0-9]|$)' "names d1"
          no_fact "$K/kb.pl" "decision(d1, _)" "d1 is archived"
          no_fact "$K/kb.pl" "note(d1, _)" "the note about d1 goes with it"
          no_fact "$K/kb.pl" "attest(_, _, d1, _, _, _)" "the attestation about d1 goes with it"
          no_fact "$K/kb.pl" "tag(d1, _)" "the local fact that names d1 goes with it"
          has_fact "$K/kb.pl" "note(d3, _)" "a note about a kept id stays"; has_fact "$K/kb.pl" "tag(d3, _)" "a tag of a kept id stays"
          okb --dir "$K" lint; rc_is 0 "lint is clean after the archive"; out_hasnt '^E[0-9A-Z]' "no error"
          okb help project; out_has 'note' "help project says that archive removes notes and other facts that name the id"; }

# PF2 (T34 c2): a spec KB outside the parent directory of the project KB, that names it by an
# absolute path, is found by project impact and keeps its pin through project archive.
t_PF2() { t23_pk "decision(d1, 'Old export')" "decision(d2, 'New export')" "decided_by(d2, ann, '$T2')" "supersedes(d2, d1)"
          local o d; o=$(mktemp -d "$base/PF2out.XXXXXX"); o=$(cd "$o" && pwd -P)
          okb init "$o/spec" --request 'Build far away' --uses build,project >/dev/null 2>&1 || note "setup: init far spec failed"
          K=$o/spec
          d=$(tdigest 'Old export')
          padd "project_kb('$T/pk')" "claim(c1, preserve, 'The far work holds')" "cites(c1, 'Build far away')" \
                          "check(k1, c1)" "pins(c1, project, d1, '$d')" >/dev/null; rc_is 0 "setup: the far spec KB pins d1"
          okb --dir "$K" lint; out_hasnt '^WP[12]' "setup: the pin matches"
          K=$T/pk
          okb --dir "$K" project impact d1; rc_is 0 "project impact"; out_has "$o/spec" "impact finds the spec KB outside the parent directory"
          is_set 'impact(d1, S)' "S = '$o/spec'"
          okb --dir "$K" project archive --superseded-before "$T3"; rc_is 0 "archive"; out_has 'Nothing' "the open far spec KB keeps d1"
          has_fact "$K/kb.pl" "decision(d1, _)" "d1 stays"
          local lean=$here/../proofs/project_archive/ProjectArchive.lean
          grep -q 'registry' "$lean" || note "the Lean model says that pinned covers the registry of pinning spec KBs"
          grep -Eq 'does not cover the walk|not cover .*walk' "$lean" || note "the Lean model says that the proof does not cover the walk"
          okb help project; out_has 'spec_kbs' "help project documents the registry"; }

# PF3 (T34 c3): --superseded-before takes only a real date or time.
t_PF3() { t23_pk "decision(d1, 'Old export')" "decision(d2, 'New export')" "decided_by(d2, ann, '$T2')" "supersedes(d2, d1)"
          cp "$K/kb.pl" "$T/kb.before"
          local x; for x in 2026-13-45 2026-02-30 2026-04-31 2026-00-10 2026-02-29T00:00:00Z 2026-03-03T25:00:00Z 2026-03-03T10:60:00Z; do
              okb --dir "$K" project archive --superseded-before "$x"; rc_is 2 "$x is not a real date" && any_has "$x" "the message names $x"
          done
          same_file "$K/kb.pl" "$T/kb.before" "nothing was written"
          okb --dir "$K" project archive --superseded-before 2024-02-29; rc_is 0 "a leap day is a real date"; out_has 'Nothing'
          okb --dir "$K" project archive --superseded-before 2026-03-03; rc_is 0 "a real date"; no_fact "$K/kb.pl" "decision(d1, _)"; }

# PF4 (T34 c4): pin-item --kind file keeps the digest and the path only; show pin checks the
# kept text of a tracker pin against its digest.
t_PF4() { t23_pk; mkdir -p "$T/weeks/w45"; printf 'raw report of week 45\n' > "$T/weeks/w45/report.md"
          local h; h=$(sha "$T/weeks/w45/report.md")
          okb --dir "$K" pin-item p1 "$T/weeks/w45/report.md" --kind file --text-file "$T/weeks/w45/report.md" --changed-at "$T1"
          rc_is 0 "pin-item --kind file"
          has_fact "$K/kb.pl" "pin(p1, file, _, 'sha256:$h', _)" "the pin keeps the digest"
          [ -e "$K/pins/$h.txt" ] && note "a file pin kept a copy of the week file"
          [ -d "$K/pins" ] && [ -n "$(ls -A "$K/pins")" ] && note "pins/ holds a copy: $(ls "$K/pins" | tr '\n' ' ')"
          okb --dir "$K" show pin p1; rc_is 1 "a file pin has no kept text"; any_has "weeks/w45/report.md" "show pin names the path of the file"
          printf 'Title: Sort orders\n' > "$T/item.txt"; local h2; h2=$(sha "$T/item.txt")
          okb --dir "$K" pin-item p2 'gh:acme/widgets#12' --text-file "$T/item.txt" --changed-at "$T1"; rc_is 0 "a tracker pin keeps its text"
          [ -f "$K/pins/$h2.txt" ] || note "no pins/$h2.txt for the tracker pin"
          okb --dir "$K" show pin p2; rc_is 0 "the kept text matches"; out_hasnt '[Mm]ismatch|does not match'
          printf 'Title: Sort orders (edited)\n' > "$K/pins/$h2.txt"
          okb --dir "$K" show pin p2; rc_is 1 "an edited kept text"; any_hasi 'mismatch|does not match' "show pin reports the mismatch"
          okb help project; out_has 'never a copy|no copy|keeps no copy' "help project says a file pin keeps no copy"; }

# PF5 (T34 c5): a fact cannot depend on or exclude itself (EP2); a depends_on cycle is WP7.
t_PF5() { t23_pk "decision(d1, 'Export goes through the queue')" "definition(df1, 'The queue runs on the batch host')"
          local f; for f in "depends_on(d1, d1)" "excludes(d1, d1)" "excludes(df1, df1)"; do
              padd "$f"; rc_is 1 "$f is refused" && any_has 'EP2' "$f: EP2"; no_fact "$K/kb.pl" "$f" "$f is not written"
          done
          padd "depends_on(d1, df1)" "depends_on(df1, d1)"; rc_is 0 "a cycle of two is accepted at add"
          okb --dir "$K" lint; rc_is 0 "a depends_on cycle is a warning"; out_has '^WP7 ' "WP7"
          printf 'excludes(d1, d1).\n' >> "$K/kb.pl"
          okb --dir "$K" lint; rc_is 1 "a self-exclusion written by hand is a lint error"; out_has '^EP2 ' "EP2"
          okb help codes; out_has '^ *EP2 +[a-zA-Z]' "help codes lists EP2"; out_has '^ *WP7 +[a-zA-Z]' "help codes lists WP7"
          local lint; lint=$(readme_part '^## [0-9]+[.] Lint codes' '^## ')
          for f in EP2 WP7; do printf '%s\n' "$lint" | grep -Eq "^[|] $f [|] [A-Za-z]" || note "the README lint table has no row $f"; done; }

# PF6 (T34 c6): add refuses ratified_by by an agent, in any case; help project states the trust limit.
t_PF6() { t23_pk "decision(d1, 'Export goes through the queue')" "decided_by(d1, 'Agent:build', '$T1')"
          is_set 'proposed(X)' "X = d1"
          local w; for w in agent 'agent:review' 'Agent:review' 'AGENT' 'AGENT:Review'; do
              padd "ratified_by(d1, '$w', '$T2')"; rc_is 1 "ratified_by by $w is refused" && any_has 'EP1' "$w: EP1"
          done
          no_fact "$K/kb.pl" "ratified_by(_, _, _)" "nothing was written"
          padd "ratified_by(d1, ann, '$T2')"; rc_is 0 "a human ratifies"; is_false 'proposed(_)'
          okb help project; out_has 'self-declared' "help project says that Who is self-declared"; }

# PF7 (T34 c1, divergence a21): the removal closes over references. An attestation about d1 goes
# with d1, and so does every fact that names the attestation (its actor record, a local fact),
# and every fact that names those, until nothing changes. Lint is clean after the archive.
t_PF7() { t23_pk "decision(d1, 'Old export')" "decision(d2, 'New export')" "decided_by(d2, ann, '$T2')" "supersedes(d2, d1)" \
                 "decision(d3, 'Retry an export three times')"
          okb --dir "$K" attest disclosure d1 "other('The old export was a guess')" --id a90; rc_is 0 "setup: an attestation about d1"
          okb --dir "$K" attest disclosure d3 "other('Retry is fine')" --id a91; rc_is 0 "setup: an attestation about d3"
          printf "decl(fact, seen(id, ref, text), 'A reader saw a record.', '').\ndecl(fact, ack(ref, text), 'A reader acknowledged a record.', '').\n" >> "$K/kb.pl"   # setup: a fact with an id, and a fact, that name any id
          padd "seen(sn1, a90, 'Read by ann')" "ack(sn1, 'ok')" "seen(sn2, a91, 'Read by ann')" "ack(sn2, 'ok')" >/dev/null; rc_is 0 "setup: a chain a90 <- sn1 <- ack"
          okb --dir "$K" lint; rc_is 0 "setup: lint is clean before the archive"
          okb --dir "$K" project archive --superseded-before "$T3"; rc_is 0 "archive"
          no_fact "$K/kb.pl" "decision(d1, _)" "d1 is archived"
          no_fact "$K/kb.pl" "attest(a90, _, _, _, _, _)" "the attestation about d1 goes"
          no_fact "$K/kb.pl" "actor(a90, _, _)" "a fact that names the attestation goes"
          no_fact "$K/kb.pl" "seen(sn1, _, _)" "a fact that names the attestation goes"
          no_fact "$K/kb.pl" "ack(sn1, _)" "a fact that names a removed fact goes, at any depth"
          for x in "attest(a91, _, _, _, _, _)" "seen(sn2, _, _)" "ack(sn2, _)" "decision(d3, _)"; do has_fact "$K/kb.pl" "$x" "kept"; done
          okb --dir "$K" lint; rc_is 0 "lint is clean after the archive"; out_hasnt '^E[0-9A-Z]' "no error"; }

# ================================================================ T38
# PF8 (T38 c6): a pinning spec KB outside the root with no line in spec_kbs.txt (one made before
# T34). archive does not remove the pinned decision silently: when it removes facts without
# --root, it warns on stderr and names --root; with --root over the spec KB, d1 stays.
t_PF8() { t23_pk "decision(d1, 'Old export')" "decision(d2, 'New export')" "decided_by(d2, ann, '$T2')" "supersedes(d2, d1)"
          local o d; o=$(mktemp -d "$base/PF8out.XXXXXX"); o=$(cd "$o" && pwd -P)
          okb init "$o/spec" --request 'Build far away' --uses build,project >/dev/null 2>&1 || note "setup: init far spec failed"
          K=$o/spec; d=$(tdigest 'Old export')
          padd "project_kb('$T/pk')" "claim(c1, preserve, 'The far work holds')" "cites(c1, 'Build far away')" \
               "check(k1, c1)" "pins(c1, project, d1, '$d')" >/dev/null; rc_is 0 "setup: the far spec KB pins d1"
          rm -f "$T/pk/spec_kbs.txt"                       # the spec KB recorded its pin before T34: no line
          K=$T/pk; cp "$K/kb.pl" "$T/kb.before"
          okb --dir "$K" project archive --superseded-before "$T3"
          if kbq "$K/kb.pl" "kb(decision(d1, _))" >/dev/null; then :
          else printf '%s\n' "$err" | grep -Fq -- '--root' || note "d1 was removed and stderr does not name --root (stderr: $(snip "$err"))"
               printf '%s\n' "$err" | grep -Fq 'spec_kbs.txt' || note "the warning does not name spec_kbs.txt (stderr: $(snip "$err"))"
          fi
          cp "$T/kb.before" "$K/kb.pl"
          okb --dir "$K" project archive --superseded-before "$T3" --root "$o"; rc_is 0 "archive --root over the far spec KB"
          has_fact "$K/kb.pl" "decision(d1, _)" "with --root, the open far spec KB keeps d1"
          okb help project; out_has '[-][-]root' "help project names --root for archive"; }

# PF9 (T38 c7): the refusal path of archive (T34 c1): a result with a new lint error is refused
# with exit 1, the error is named, and kb.pl does not change.
t_PF9() { t23_pk "decision(d1, 'Old export')" "decision(d2, 'New export')" "decided_by(d2, ann, '$T2')" "supersedes(d2, d1)"
          okb --dir "$K" add "legacy('d1')" --doc 'A name of the old export.' >/dev/null; rc_is 0 "setup: a local fact"
          printf "lint_issue('E77', d1, 'the legacy name needs decision d1') :- legacy(_), not decision(d1, _).\n" > "$K/rules.pl"
          okb --dir "$K" lint; rc_is 0 "setup: lint is clean before the archive"
          cp "$K/kb.pl" "$T/kb.before"
          okb --dir "$K" project archive --superseded-before "$T3"; rc_is 1 "archive is refused"
          any_has 'E77' "the refusal names the new lint error"
          same_file "$K/kb.pl" "$T/kb.before" "a refused archive leaves kb.pl byte for byte"
          has_fact "$K/kb.pl" "decision(d1, _)" "d1 stays"; }

# PF10 (T38 c8): archive prunes spec_kbs.txt under the lock of the project KB: lines of gone KBs
# and repeated lines go.
t_PF10() { t23_pk "decision(d1, 'Old export')"
           local o; o=$(mktemp -d "$base/PF10out.XXXXXX"); o=$(cd "$o" && pwd -P)
           local s; for s in s1 s2 s3; do
               okb init "$o/$s" --request "Build $s" --uses build,project >/dev/null 2>&1 || note "setup: init $s failed"
               K=$o/$s; padd "project_kb('$T/pk')" >/dev/null; rc_is 0 "setup: $s names the project KB"
           done
           K=$T/pk; local R=$K/spec_kbs.txt
           [ "$(grep -c . "$R" 2>/dev/null)" = 3 ] || note "setup: spec_kbs.txt has $(grep -c . "$R" 2>/dev/null) lines, want 3"
           printf '%s\n' "$o/s1" >> "$R"; rm -rf "$o/s2"
           ORBIT_KB_WRITER=ann okb --dir "$K" add "note(d1, 'ann holds the lease')" >/dev/null; rc_is 0 "setup: ann writes"
           cp "$R" "$T/reg.before"
           ORBIT_KB_WRITER=bob okb --dir "$K" project archive --superseded-before "$T3"; rc_is 2 "bob's archive is refused while ann holds the lease"
           same_file "$R" "$T/reg.before" "a refused archive does not prune"
           ORBIT_KB_WRITER=ann okb --dir "$K" project archive --superseded-before "$T3"; rc_is 0 "archive"
           # T40 c3 (amends T38 c8): a missing KB is not pruned on one look; the repeated line goes at once
           [ "$(sort "$R" | tr '\n' ' ')" = "$o/s1 $o/s2 $o/s3 " ] || note "spec_kbs.txt after the first archive: [$(tr '\n' ' ' < "$R")], want $o/s1, $o/s2 and $o/s3 once each"
           ORBIT_KB_WRITER=ann okb --dir "$K" project archive --superseded-before "$T3"; rc_is 0 "a second archive"
           [ "$(sort "$R" | tr '\n' ' ')" = "$o/s1 $o/s3 " ] || note "spec_kbs.txt after the second archive: [$(tr '\n' ' ' < "$R")], want $o/s1 and $o/s3 once each"; }

# PF12 (T40 c2): show pin of a tracker pin taken before T38 (a digest of the text read as UTF-8, not
# of the bytes): the kept text is not edited, so show pin says that the digest rule changed, not that
# someone edited it, and names the re-pin. An edited kept text still says that it was edited. help
# build and the CHANGELOG give the re-pin and the re-prove recipe.
t_PF12() { t23_pk; printf 'Title: Café orders for ∀ weeks\n' > "$T/item.txt"
           local old; old=$(swipl -g "use_module(library(crypto)), crypto_file_hash('$T/item.txt', H, [algorithm(sha256)]), write(H), halt" 2>/dev/null)
           { [ -n "$old" ] && [ "$old" != "$(sha "$T/item.txt")" ]; } || note "setup: the digest rule before T38 gives no other digest ($old)"
           mkdir -p "$K/pins"; cp "$T/item.txt" "$K/pins/$old.txt"
           printf "pin(p3, tracker, 'gh:acme/widgets#13', 'sha256:%s', '%s').\n" "$old" "$T1" >> "$K/kb.pl"
           okb --dir "$K" show pin p3; rc_is 1 "no text matches under the byte digest"
           any_hasi 'digest rule' "show pin says that the digest rule changed"
           anyout | grep -q 'Someone edited' && note "show pin of an unedited old pin says Someone edited it: $(snip "$out")"
           any_has 'pin-item' "show pin names the re-pin (pin-item)"
           printf 'Title: Sort orders\n' > "$T/i2.txt"; local h2; h2=$(sha "$T/i2.txt")
           okb --dir "$K" pin-item p4 'gh:acme/widgets#14' --text-file "$T/i2.txt" --changed-at "$T1"; rc_is 0 "setup: a byte-digest pin"
           printf 'Title: Sort orders (edited)\n' > "$K/pins/$h2.txt"
           okb --dir "$K" show pin p4; rc_is 1 "an edited kept text"; any_hasi 'edited' "show pin still says an edit"
           okb help build; rc_is 0
           local bd; bd=$(printf '%s\n' "$out" | awk '/[Bb]yte digest/{f=1} f')
           printf '%s\n' "$bd" | grep -q 'pin-item' || note "help build has no re-pin recipe (pin-item) under byte digests"
           printf '%s\n' "$bd" | grep -q 'proof_changed' || note "help build has no re-prove recipe (proof_changed) under byte digests"
           local cl; cl=$(awk '/^- Byte digests/{f=1;print;next} f && /^(- |#)/{exit} f' "$here/../../CHANGELOG.md")
           printf '%s\n' "$cl" | grep -q 'pin-item' || note "the CHANGELOG Byte digests entry has no re-pin recipe (pin-item)"
           printf '%s\n' "$cl" | grep -q 'proof_changed' || note "the CHANGELOG Byte digests entry lost its re-prove recipe"; }

# PF13 (T40 c3): spec_kbs.txt loses no line. add registers a spec KB under the KB lock of the project
# KB (the lock of the archive prune): while another process holds it, add waits. A spec KB whose kb.pl
# is missing is pruned only when a second archive in a row finds it missing.
t_PF13() { t23_pk "decision(d1, 'Old export')"
           local o; o=$(mktemp -d "$base/PF13out.XXXXXX"); o=$(cd "$o" && pwd -P)
           local R=$T/pk/spec_kbs.txt s
           for s in s1 s2; do okb init "$o/$s" --request "Build $s" --uses build,project >/dev/null 2>&1 || note "setup: init $s failed"; done
           flock -x "$T/pk/kb.lock" -c 'sleep 3' & local lp=$!
           sleep 0.5
           local t0 t1; t0=$(date +%s)
           K=$o/s1; padd "project_kb('$T/pk')" >/dev/null; rc_is 0 "add project_kb while the project KB lock is held"
           t1=$(date +%s); wait "$lp"
           [ $((t1 - t0)) -ge 2 ] || note "add wrote spec_kbs.txt while another process held the project KB lock (it took $((t1 - t0)) s, the lock was held 2.5 s more)"
           grep -qxF "$o/s1" "$R" || note "the line of s1 is missing: [$(tr '\n' ' ' < "$R" 2>/dev/null)]"
           K=$o/s2; padd "project_kb('$T/pk')" >/dev/null; rc_is 0 "setup: s2 names the project KB"
           K=$T/pk
           mv "$o/s2" "$o/s2.away"
           okb --dir "$K" project archive --superseded-before "$T3"; rc_is 0 "archive, s2 missing (look 1)"
           grep -qxF "$o/s2" "$R" || note "one archive pruned the briefly missing s2"
           mv "$o/s2.away" "$o/s2"
           okb --dir "$K" project archive --superseded-before "$T3"; rc_is 0 "archive, s2 back"
           grep -qxF "$o/s2" "$R" || note "s2 came back and was pruned"
           mv "$o/s2" "$o/s2.away"
           okb --dir "$K" project archive --superseded-before "$T3"; rc_is 0 "archive, s2 missing again (look 1 after its return)"
           grep -qxF "$o/s2" "$R" || note "s2 was pruned on its first look after it came back"
           okb --dir "$K" project archive --superseded-before "$T3"; rc_is 0 "archive, s2 still missing (look 2)"
           grep -qxF "$o/s2" "$R" && note "s2 is still in spec_kbs.txt after two archives in a row found it missing"
           grep -qxF "$o/s1" "$R" || note "s1 was lost"; okb help project; out_has 'spec_kbs' "help project documents the registry"; }

# PF14 (T40 c5): archive with --root warns when a spec KB of spec_kbs.txt lies outside the root,
# as it warns without --root; with every registered spec KB under the root it does not warn.
t_PF14() { t23_pk "decision(d1, 'Old export')" "decision(d2, 'New export')" "decided_by(d2, ann, '$T2')" "supersedes(d2, d1)"
           local o; o=$(mktemp -d "$base/PF14out.XXXXXX"); o=$(cd "$o" && pwd -P)
           okb init "$o/spec" --request 'Build far away' --uses build,project >/dev/null 2>&1 || note "setup: init far spec failed"
           K=$o/spec; padd "project_kb('$T/pk')" >/dev/null; rc_is 0 "setup: the far spec KB is registered"
           K=$T/pk; mkdir -p "$T/near"; cp "$K/kb.pl" "$T/kb.before"
           okb --dir "$K" project archive --superseded-before "$T3" --root "$T/near"; rc_is 0 "archive --root near"
           no_fact "$K/kb.pl" "decision(d1, _)" "setup: d1 is archived"
           printf '%s\n' "$err" | grep -Fq "$o/spec" || note "archive --root does not name the registered spec KB outside the root (stderr: $(snip "$err"))"
           printf '%s\n' "$err" | grep -Fq 'spec_kbs.txt' || note "the --root warning does not name spec_kbs.txt (stderr: $(snip "$err"))"
           cp "$T/kb.before" "$K/kb.pl"
           okb --dir "$K" project archive --superseded-before "$T3" --root "$o"; rc_is 0 "archive --root over every registered spec KB"
           printf '%s\n' "$err" | grep -qi 'warning' && note "archive --root warns with every registered spec KB under the root (stderr: $(snip "$err"))"; return 0; }

# PF11 (T38 c9): pin-item --kind file digests the pinned file (a path, or the file of a subject),
# and refuses a --text-file that names another file.
t_PF11() { t23_pk; mkdir -p "$T/weeks/w45"; printf 'raw report of week 45\n' > "$T/weeks/w45/report.md"
           printf 'something else\n' > "$T/other.txt"
           local h; h=$(sha "$T/weeks/w45/report.md")
           cp "$K/kb.pl" "$T/kb.before"
           okb --dir "$K" pin-item p1 weeks/w45/report.md --kind file --text-file "$T/other.txt" --changed-at "$T1"
           rc_is 2 "a --text-file that names another file is refused"; any_has 'other.txt' "the refusal names the other file"
           same_file "$K/kb.pl" "$T/kb.before" "nothing is written"
           okb --dir "$K" pin-item p1 weeks/w45/report.md --kind file --changed-at "$T1"; rc_is 0 "a file pin needs no --text-file"
           has_fact "$K/kb.pl" "pin(p1, file, _, 'sha256:$h', _)" "the digest is of the pinned path"
           okb --dir "$K" pin-item p2 weeks/w45/report.md --kind file --text-file "$T/weeks/w45/../w45/report.md" --changed-at "$T1"
           rc_is 0 "a --text-file that names the same file"; has_fact "$K/kb.pl" "pin(p2, file, _, 'sha256:$h', _)"
           okb --dir "$K" subject s1 "$T/weeks/w45/report.md"; rc_is 0 "setup: a subject"
           okb --dir "$K" pin-item p3 s1 --kind file --changed-at "$T1"; rc_is 0 "a file pin of a subject id"
           has_fact "$K/kb.pl" "pin(p3, file, s1, 'sha256:$h', _)" "the digest is of the file of the subject"
           okb --dir "$K" pin-item p4 weeks/nope.md --kind file --changed-at "$T1"; rc_is 2 "a missing pinned file"
           okb help project; out_has 'text-file' "help project names --text-file"; }

# ================================================================ run
run_test t_PK1 PK1 "T06 c1: init --uses project; every fact of the module is accepted"
run_test t_PK2 PK2 "T06 c1: dangling refs and duplicate ids are refused (E4, E5)"
run_test t_PK3 PK3 "T06 c1: pin kind, digest and time are typed (E3)"
run_test t_PK4 PK4 "T06 c1: decision_digest is the sha256 of the decision text"
run_test t_PK5 PK5 "T06 c1: help project documents each predicate, the lock and release"
run_test t_PK6 PK6 "T18 c2: help codes lists WP1 to WP4"
run_test t_PK7 PK7 "T18 c3: README lint table, command reference and Locking cover the project module"
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
run_test t_PB1 PB1 "T06 review 1: project_kb at a missing directory is WP2, no crash"
run_test t_PB2 PB2 "T06 review 1: project_kb at a directory with no kb.pl is WP2, no crash"
run_test t_PB3 PB3 "T06 review 1: project_kb at a KB without the project module is WP2, no crash"
run_test t_PB4 PB4 "T06 review 1: project_kb at the KB itself is WP2, no crash"
run_test t_PB5 PB5 "T06 review 2: a project KB with errors gives WP3 and a blocking item, never silence"
run_test t_PB6 PB6 "T06 review 3: --take on a rejected add moves no lock and writes no takeover"
run_test t_PB7 PB7 "T06 review 5: writer names with a space are kept whole"
run_test t_PB8 PB8 "T06 review 5: an empty or malformed lock is an exit 2 with a fix line"
run_test t_PB9 PB9 "T06 review 4: WP1 clears after a re-pin; old pins stay"
run_test t_PB10 PB10 "T06 review 6: ==, \\==, @<, @>, @=<, @>= do not bind: E14 applies"
run_test t_PB11 PB11 "T06 review 8: show blocking prints KIND ID: SENTENCE: TEXT"
run_test t_PB12 PB12 "T06 follow-up: two project_kb facts give WP4 (only the first is read)"
run_test t_PW8 PW8 "T27 c1: CLAUDE_CODE_SESSION_ID names the writer; ORBIT_KB_WRITER, CLAUDE_CODE_SESSION_ID, CLAUDE_SESSION_ID, HUB_SESSION in order"
run_test t_PW9 PW9 "T27 c2: every KB has one writer; the lock is a lease that lapses after ORBIT_KB_LEASE minutes"
run_test t_PH1 PH1 "T27 c3: the handoff texts say release, the first write takes the lock, review has its own lease"
run_test t_PR1 PR1 "T27 c10: init --source pins the request; a changed text is stale until a human accepts it"
run_test t_PW10 PW10 "T37 c2: a takeover during a long run stops the old holder's append (exit 2, nothing written)"
run_test t_PR2 PR2 "T37 c3: the request pin reads nested ADO, Jira and Plane JSON; a state move is no change"

run_test t_PT1 PT1 "T23 c1: definition/2 and concerns of a definition; help project opens with the two sides"
run_test t_PT2 PT2 "T23 c2: rule/2 is pinned by a spec claim; WP1 and WP2 cover rule pins"
run_test t_PT3A PT3A "T23 c3: supersedes between decisions or definitions; current_fact; a cycle is E15"
run_test t_PT3B PT3B "T23 c3: depends_on between any two kinds; rests_on is its transitive closure"
run_test t_PT3C PT3C "T23 c3: a contradiction blocks only a spec KB that pins a side; rests_on gives WP5"
run_test t_PT3D PT3D "T23 c3: impact(X, SpecKB) and project impact X"
run_test t_PT4 PT4 "T23 c4: an agent's decision is proposed until a human ratifies it; only ratified decisions block"
run_test t_PT5 PT5 "T23 c5: analyses live in the project KB (WP6); a week's report is a file pin"
run_test t_PT6 PT6 "T23 c6: every new relation refuses a dangling reference (E4); help codes lists them"
run_test t_PT7 PT7 "T23 c7: CONTRACT D27 notes the Lean limit again"
run_test t_PE1 PE1 "T39 c2: a CI or tracker run is pinned with pin-item; a check reads the pin; the claim is fulfilled"
run_test t_PT8 PT8 "T23 c8: pin-item keeps the pinned text at pins/HEX.txt; show pin ID prints it"
run_test t_PT9 PT9 "T23 c9: project archive removes superseded facts that nothing keeps"
run_test t_PF1 PF1 "T34 c1: archive removes the facts that name an archived id; lint is clean after it"
run_test t_PF2 PF2 "T34 c2: impact and archive find a pinning spec KB outside the parent directory"
run_test t_PF3 PF3 "T34 c3: --superseded-before takes only a real date"
run_test t_PF4 PF4 "T34 c4: pin-item --kind file keeps no copy; show pin reports a mismatch"
run_test t_PF5 PF5 "T34 c5: excludes(X, X) and depends_on(X, X) are EP2; a depends_on cycle is WP7"
run_test t_PF7 PF7 "T34 c1 (a21): the removal closes over references; lint is clean after the archive"
run_test t_PF6 PF6 "T34 c6: ratified_by by an agent is refused at add in any case; Who is self-declared"
run_test t_PF8 PF8 "T38 c6: archive does not silently remove a decision that an unseen spec KB pins"
run_test t_PF9 PF9 "T38 c7: a refused archive exits 1, names the error, and leaves kb.pl as it was"
run_test t_PF10 PF10 "T38 c8: archive prunes spec_kbs.txt under the lock"
run_test t_PF11 PF11 "T38 c9: pin-item --kind file digests the pinned file"
run_test t_PF12 PF12 "T40 c2: show pin of a pin taken before byte digests says the digest rule changed"
run_test t_PF13 PF13 "T40 c3: spec_kbs.txt loses no line: register under the lock, prune after two looks"
run_test t_PF14 PF14 "T40 c5: archive --root warns about a registered spec KB outside the root"
NT=${#REG_ID[@]}
for ((i = 0; i < NT; i++)); do exec_test "$i"; done
echo "----"
echo "orbit-kb=$OKB lib=$LIB pass=$pass fail=$fail skip=$skip ${failed[*]:-}"
[ $fail = 0 ]
