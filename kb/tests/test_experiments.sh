#!/usr/bin/env bash
# Black-box tests for stage 2 of the scientific-method overhaul: experiments and verdicts
# (kb/CONTRACT.md D55 to D62; ticket scientific-method-overhaul, claims c6, c7, c9, c10, c16,
# c39, c40, c41, c42 and the grandfather rule of c20).
#
# Usage: kb/tests/test_experiments.sh [path-to-orbit-kb]
#   ONLY='<regex>' runs only the tests whose id matches. ORBIT_KB_TEST_JOBS=N as in test_orbit_kb.sh.
# The harness (helpers, driver) is the one of test_orbit_kb.sh. No test depends on the value of
# the VERSION file: a KB "from before the upgrade" has a hand-written "% Made by orbit-kb 0.7.2."
# line and no upgraded/2 fact, and a "new" KB is one that the tool under test wrote to (the first
# write records upgraded/2) or that has a "% Made by orbit-kb 0.8.0." line.
#
#   UV  c7   a verdict is meets, conflicts or unresolved; run decides it          : UV1-UV8
#   ST  c39  a verdict counts only for the state that its experiment observed      : ST1-ST5
#   GF  c20, c39  a ticket that was done before the upgrade stays done             : GF1-GF6
#   JD  c10, c41  the judgment of the human; done                                  : JD1-JD8
#   LC  c9, c40  the location of a conflict                                        : LC1-LC9
#   EX  c6   one view of every kind of experiment; W17, W18                        : EX1-EX6
#   SB  c16  Sound Basis: over, behavior_conflict                                  : SB1-SB3
#   GC  c42  a change of the ticket goal: carried, not_carried                     : GC1-GC3
#   RP  the Claims field of report                                                 : RPX1
set -u

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
# A test function that is defined twice silently runs the later body under both ids, so
# one test hides another. Refuse to run the suite.
dups=$(grep -oE '^t_[A-Za-z0-9_]+\(\)' "${BASH_SOURCE[0]}" | sort | uniq -d)
if [ -n "$dups" ]; then echo "ERROR: test functions defined twice: $(echo $dups)" >&2; exit 2; fi
FIX=$here/fixtures
OKB=${1:-${ORBIT_KB_BIN:-$here/../bin/orbit-kb}}
LIB=${ORBIT_KB_TEST_LIB:-$here/../share/orbit-kb}
TMO=${ORBIT_KB_TEST_TIMEOUT:-120}
if [ -z "${ORBIT_KB_TEST_JOBS:-}" ]; then
    # CPUs available to this process (nproc follows the CPU affinity, for example HEAVY_CPUS)
    ncpu=$(unset OMP_NUM_THREADS OMP_THREAD_LIMIT; nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null)
    case $ncpu in ''|*[!0-9]*) ncpu=1;; esac
    JOBS=$(( ncpu < 4 ? ncpu : 4 ))
else
    JOBS=$ORBIT_KB_TEST_JOBS
fi
case $JOBS in ''|*[!0-9]*) JOBS=0;; *) JOBS=$((10#$JOBS));; esac
if [ "$JOBS" -lt 1 ]; then
    printf 'test_experiments.sh: ORBIT_KB_TEST_JOBS must be a positive integer, got "%s"\n' "${ORBIT_KB_TEST_JOBS:-}" >&2
    exit 2
fi
# Tests that run alone in a parallel run (an ERE on the test id; empty: none). No test needs
# it now. The time limits are the CLI's 10 s for the SWI engine and $TMO per call here. Under
# 1.5x to 2x CPU overload (14 workers next to 7 or 14 busy loops), all tests passed in 4 of 4
# runs. (This note was measured before D20, when s(CASP) was the second engine.)
SERIAL=''

# ---------------------------------------------------------------- preconditions
if [ ! -f "$OKB" ] || [ ! -x "$OKB" ]; then
    printf 'test_experiments.sh: the orbit-kb CLI is missing or is not executable: %s\n' "$OKB" >&2
    printf '  Check the repo copy (kb/bin/orbit-kb), or pass its path as the first argument.\n' >&2
    exit 2
fi
OKB=$(cd "$(dirname "$OKB")" && pwd -P)/$(basename "$OKB")
if [ -d "$LIB" ]; then LIB=$(cd "$LIB" && pwd -P); fi
if [ ! -f "$LIB/core.pl" ]; then
    printf 'test_experiments.sh: the library is missing (no core.pl in %s)\n' "$LIB" >&2
    printf '  Build it first, or set ORBIT_KB_TEST_LIB to a library directory.\n' >&2
    exit 2
fi
for tool in swipl sha256sum timeout mktemp awk grep sed diff cmp sort head wc cp mv; do
    command -v "$tool" >/dev/null 2>&1 || { printf 'test_experiments.sh: required tool not found: %s\n' "$tool" >&2; exit 2; }
done
have_python=0
command -v python3 >/dev/null 2>&1 && have_python=1

pass=0 fail=0 skip=0
failed=()
FAILS=()
SKIPMSG=""
LAST_STATUS=""
out="" err="" rc=0
T="" K=""
WORKERS=()
CUR=""

base=$(mktemp -d "${TMPDIR:-/tmp}/orbit-kb-test.XXXXXX") || exit 2
base=$(cd "$base" && pwd -P)
mkdir "$base/proto" || exit 2
cleanup() {  # stop the workers and the test subshell of this shell, then remove the temp tree
    local p
    for p in ${WORKERS[@]+"${WORKERS[@]}"} ${CUR:+"$CUR"}; do kill "$p" 2>/dev/null; done
    wait 2>/dev/null
    rm -rf "$base" 2>/dev/null || { sleep 1; rm -rf "$base"; }
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# The tests control the environment of the CLI completely: no ORBIT_KB_* variable of the
# caller (ORBIT_KB, a cache switch, ...) reaches it, the suite sets
# ORBIT_KB_LIB, and each test sets its own XDG_CACHE_HOME (exec_test).
for v in $(compgen -e); do case $v in ORBIT_KB*|CLAUDE_SESSION_ID|CLAUDE_CODE_SESSION_ID|HUB_SESSION) unset "$v";; esac; done
export ORBIT_KB_LIB="$LIB"

# ---------------------------------------------------------------- kbq: read kb.pl semantically
# kbq FILE GOAL: read every term of FILE (the not operator on), then run GOAL.
#   kb(T) lists the terms in file order. kb_line(L, T) adds the line of each term.
#   Exit 0 when GOAL succeeds, 1 when it fails, 3 on an error in GOAL.
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
    (   catch(call(Goal), E2, (print_message(error, E2), halt(3)))
    ->  halt(0)
    ;   halt(1)
    ).

kb(T) :- kb_t(_, T).
kb_line(L, T) :- kb_t(L, T).

load_kb(File) :-
    open(File, read, S),
    repeat,
      catch(read_term(S, T, [term_position(P)]), _, T = '$syntax_error'),
      (   T == end_of_file -> !, close(S)
      ;   T == '$syntax_error' -> fail
      ;   stream_position_data(line_count, P, L), assertz(kb_t(L, T)), fail
      ).
PROLOG
kbq() { swipl -q "$base/kbq.pl" -- "$@" 2>/dev/null; }

# ---------------------------------------------------------------- reporting
ok()    { pass=$((pass+1)); LAST_STATUS=pass; echo "PASS $1 $2"; }
bad()   { fail=$((fail+1)); failed+=("$1"); LAST_STATUS=fail; echo "FAIL $1 $2"; local m; for m in "${@:3}"; do echo "     - $m"; done; }
skipt() { skip=$((skip+1)); LAST_STATUS=skip; echo "SKIP $1 $2: $3"; }

snip() { printf '%s' "$1" | head -c 300 | tr '\n' '~'; }
note() { FAILS+=("$*"); }

# ---------------------------------------------------------------- running the CLI
# okb_in DIR ARGS...: run the CLI in DIR. Sets out (stdout), err (stderr), rc.
okb_in() {
    local d=$1; shift
    ( cd "$d" && exec timeout "$TMO" "$OKB" "$@" ) >"$T/.out" 2>"$T/.err" </dev/null
    rc=$?
    out=$(<"$T/.out"); err=$(<"$T/.err")
}
okb() { okb_in "$T" "$@"; }
anyout() { printf '%s\n%s\n' "$out" "$err"; }

# ---------------------------------------------------------------- assertions (they add to FAILS)
rc_is() {   # rc_is WANT [LABEL]
    [ "$rc" = "$1" ] && return 0
    note "${2:+$2: }exit $rc, want $1 (stdout: $(snip "$out") | stderr: $(snip "$err"))"; return 1
}
rc_not() {  # rc_not UNWANTED [LABEL]
    [ "$rc" != "$1" ] && return 0
    note "${2:+$2: }exit $rc, it must not be $1 (stdout: $(snip "$out") | stderr: $(snip "$err"))"; return 1
}
out_has() {   # out_has ERE [LABEL]: stdout has a line that matches
    printf '%s\n' "$out" | grep -Eq -- "$1" && return 0
    note "${2:+$2: }stdout lacks /$1/ (stdout: $(snip "$out"))"; return 1
}
out_hasnt() {
    if printf '%s\n' "$out" | grep -Eq -- "$1"; then note "${2:+$2: }stdout has /$1/, it must not (stdout: $(snip "$out"))"; return 1; fi
    return 0
}
err_has() {
    printf '%s\n' "$err" | grep -Eq -- "$1" && return 0
    note "${2:+$2: }stderr lacks /$1/ (stderr: $(snip "$err"))"; return 1
}
any_has() {   # any_has ERE [LABEL]: stdout or stderr has a line that matches
    anyout | grep -Eq -- "$1" && return 0
    note "${2:+$2: }output lacks /$1/ (stdout: $(snip "$out") | stderr: $(snip "$err"))"; return 1
}
any_hasi() {  # like any_has, ignoring case
    anyout | grep -Eiq -- "$1" && return 0
    note "${2:+$2: }output lacks /$1/ (stdout: $(snip "$out") | stderr: $(snip "$err"))"; return 1
}
any_hasf() {  # any_hasf STRING [LABEL]: a fixed string
    anyout | grep -Fq -- "$1" && return 0
    note "${2:+$2: }output lacks \"$1\" (stdout: $(snip "$out") | stderr: $(snip "$err"))"; return 1
}
any_hasnt() {
    if anyout | grep -Eq -- "$1"; then note "${2:+$2: }output has /$1/, it must not (stdout: $(snip "$out") | stderr: $(snip "$err"))"; return 1; fi
    return 0
}
any_hasnti() {
    if anyout | grep -Eiq -- "$1"; then note "${2:+$2: }output has /$1/, it must not (stdout: $(snip "$out") | stderr: $(snip "$err"))"; return 1; fi
    return 0
}
same_file() {  # same_file A B [LABEL]
    cmp -s "$1" "$2" && return 0
    note "${3:+$3: }the file changed ($1)"; return 1
}

# facts in a kb.pl, read with swipl
has_goal()  { kbq "$1" "$2" >/dev/null && return 0; note "${3:+$3: }${1##*/}: no match for: $2"; return 1; }
has_fact()  { has_goal "$1" "kb($2)" "${3:-}"; }
no_fact()   { kbq "$1" "kb($2)" >/dev/null || return 0; note "${3:+$3: }${1##*/} has a fact that matches $2, it must not"; return 1; }
fact_count() {  # fact_count FILE PATTERN WANT [LABEL]
    local n; n=$(kbq "$1" "findall(x, kb($2), L), length(L, N), write(N)")
    [ "$n" = "$3" ] && return 0
    note "${4:+$4: }${1##*/} has ${n:-?} facts that match $2, want $3"; return 1
}

# KB construction
kb_new() { mkdir -p "$1" && cat > "$1/kb.pl"; }   # kb_new DIR < kb.pl text
sha() { sha256sum "$1" | cut -d' ' -f1; }
add_result() {  # add_result DIR CHECK N pass|fail: append a test_result and its run log, as orbit-kb run would
    local d=$1 k=$2 n=$3 r=$4 ec=0 cmd=true
    [ "$r" = fail ] && { ec=1; cmd=false; }
    mkdir -p "$d/runs"
    printf '%% orbit-kb run %s check=%s result=%s exit=%s time=2026-10-15T10:00:%02dZ cmd=%s\n' "$n" "$k" "$r" "$ec" "$n" "$cmd" > "$d/runs/$n-$k.log"
    printf "attest(t%s, test_result, %s, result(%s, %s, %s), script, '2026-10-15T10:00:%02dZ').\n" "$n" "$k" "$k" "$n" "$r" "$n" >> "$d/kb.pl"
}
copy_fixture() {  # copy_fixture NAME [DEST]: a private copy of a fixture
    local dest=${2:-$T/$1}
    rm -rf "$dest"; cp -a "$FIX/$1" "$dest"
}
skip_test() { SKIPMSG=$1; }

# rejects LABEL MSG_RE ARGS...: the CLI (run in $K) must exit 1, print a reason that
# matches MSG_RE (when MSG_RE is not empty), and leave kb.pl unchanged.
rejects() {
    local label=$1 re=$2; shift 2
    cp "$K/kb.pl" "$T/.kb.before"
    okb --dir "$K" "$@"
    rc_is 1 "$label"
    [ -n "$out$err" ] || note "$label: the rejection printed nothing"
    if [ -n "$re" ]; then any_hasi "$re" "$label: the reason"; fi
    same_file "$K/kb.pl" "$T/.kb.before" "$label: kb.pl after the rejection"
}

# query helpers (run in $K)
q() { okb --dir "$K" query "$@"; }
is_true()  { q "$1"; rc_is 0 "query '$1' must hold"; }
is_false() { q "$1"; rc_is 1 "query '$1' must have no answer"; }
is_set() {  # is_set GOAL "ANSWER|ANSWER": all answers of GOAL (-n 0), no more and no less. "" means no answer.
    q "$1" -n 0
    if [ -z "$2" ]; then rc_is 1 "query '$1' -n 0 must have no answer"; return; fi
    rc_is 0 "query '$1' -n 0" || return 1
    local got; got=$(printf '%s\n' "$out" | LC_ALL=C sort | paste -sd'|')
    [ "$got" = "$2" ] || note "query '$1' -n 0: answers [$got], want [$2]"
}
first_line() { printf '%s\n' "$out" | head -n1; }
norm_time() { sed -E 's/\([0-9.]+ ?sec(onds)?\)//g'; }

# test driver. run_test only registers a test. run_tests, at the end of the file, runs them.
REG_FN=()
REG_ID=()
REG_DESC=()
REG_ARGS=()
run_test() {  # run_test FUNC ID DESCRIPTION [ARGS...]
    local fn=$1 id=$2 desc=$3; shift 3
    if [ -n "${ONLY:-}" ] && ! [[ $id =~ $ONLY ]]; then return 0; fi
    REG_FN+=("$fn"); REG_ID+=("$id"); REG_DESC+=("$desc")
    if [ $# -gt 0 ]; then REG_ARGS+=("$(printf '%q ' "$@")"); else REG_ARGS+=(""); fi
}
exec_test() {  # exec_test I: run registered test I in this shell, and print its result
    local fn=${REG_FN[$1]} id=${REG_ID[$1]} desc=${REG_DESC[$1]}
    if [ -n "${REG_ARGS[$1]}" ]; then eval "set -- ${REG_ARGS[$1]}"; else set --; fi
    LAST_STATUS=""
    T=$(mktemp -d "$base/$id.XXXXXX") || return 1
    T=$(cd "$T" && pwd -P)
    FAILS=(); SKIPMSG=""; out=""; err=""; rc=0; K=""
    XDG_CACHE_HOME=$T/.cache; export XDG_CACHE_HOME; mkdir "$XDG_CACHE_HOME"
    cd "$T" || return 1
    "$fn" "$@"
    cd "$here" || true
    if [ -n "$SKIPMSG" ]; then skipt "$id" "$desc" "$SKIPMSG"
    elif [ ${#FAILS[@]} -eq 0 ]; then ok "$id" "$desc"
    else bad "$id" "$desc" "${FAILS[@]}"; fi
    rm -rf "$T"
}

# ---------------------------------------------------------------- parallel runs (see the header)
grab() {  # grab FILE: create FILE only when it does not exist (O_EXCL). Exactly one caller wins.
    local r
    set -C; { : > "$1"; } 2>/dev/null; r=$?; set +C
    return $r
}
run_task() {  # run_task I: run test I in a subshell. Its stdout, stderr and status go to $res/I.*
    local i=$1 st
    ( exec_test "$i"; printf '%s\n' "${LAST_STATUS:-none}" > "$res/$i.st0" ) >"$res/$i.out" 2>"$res/$i.err" </dev/null &
    CUR=$!; wait "$CUR"; st=$?; CUR=""
    [ -s "$res/$i.st0" ] || printf 'exit:%s\n' "$st" > "$res/$i.st0"
    mv -f "$res/$i.st0" "$res/$i.st"   # the rename makes the result visible all at once
}
worker() {  # worker: run each task that no other worker took first, in list order
    local t
    trap 'kill ${CUR:+"$CUR"} 2>/dev/null; exit 143' TERM
    for t in "${TASKS[@]}"; do
        kill -0 $$ 2>/dev/null || exit 143   # the suite is gone
        grab "$res/claim.$t" || continue
        case $t in
            *)   run_task "$t" ;;
        esac
    done
}
workers_alive() { local p; for p in ${WORKERS[@]+"${WORKERS[@]}"}; do kill -0 "$p" 2>/dev/null && return 0; done; return 1; }
emit() {  # emit I: wait for the result of test I, then print it and count it
    local i=$1 st
    while [ ! -e "$res/$i.st" ]; do
        if ! workers_alive; then [ -e "$res/$i.st" ] || echo lost > "$res/$i.st"; break; fi
        sleep 0.05
    done
    if [ -s "$res/$i.err" ]; then cat "$res/$i.err" >&2; fi
    if [ -s "$res/$i.out" ]; then cat "$res/$i.out"; fi
    read -r st < "$res/$i.st"
    case $st in
        pass) pass=$((pass+1)) ;;
        fail) fail=$((fail+1)); failed+=("${REG_ID[$i]}") ;;
        skip) skip=$((skip+1)) ;;
        none) ;;   # mktemp failed, so the test did not start; a serial run does not count it either
        exit:*) bad "${REG_ID[$i]}" "${REG_DESC[$i]}" "the test stopped before its result (exit status ${st#exit:})" ;;
        *) bad "${REG_ID[$i]}" "${REG_DESC[$i]}" "no result: the worker that ran the test stopped" ;;
    esac
}
run_parallel() {  # run the registered tests in $JOBS workers; print the results in run_test order
    local i w
    res=$base/results; mkdir "$res" || exit 2
    TASKS=()
    # The full suite uses these prototypes, so the first workers build them while the other
    # workers start the first tests. With ONLY, the first test that needs a prototype builds it.
    for ((i = 0; i < NT; i++)); do
        if [ -n "$SERIAL" ] && [[ ${REG_ID[$i]} =~ $SERIAL ]]; then run_task "$i"; else TASKS+=("$i"); fi
    done
    for ((w = 0; w < JOBS; w++)); do worker & WORKERS+=("$!"); done
    for ((i = 0; i < NT; i++)); do emit "$i"; done
    wait "${WORKERS[@]}"
    WORKERS=()
}
run_tests() {  # run the registered tests: serially in this shell when JOBS is 1, else in workers
    local i
    NT=${#REG_ID[@]}
    if [ "$JOBS" -gt "$NT" ]; then JOBS=$NT; fi
    if [ "$JOBS" -le 1 ]; then
        for ((i = 0; i < NT; i++)); do exec_test "$i"; done
    else
        run_parallel
    fi
}


# ---------------------------------------------------------------- fixtures of this file
# timer_script: the timer of the handoff (ScientificMethod.lean, namespace Timer), in tenths of
# a second. The claim: it rings 59.0 to 61.0 s after the start. The clock is right within 0.2 s.
# Exit 0: every elapsed time that the reading allows is inside (meets). Exit 1: none is inside
# (conflicts). Exit 77: some are inside and some are not (the check cannot decide: unresolved).
timer_script() {
    cat > "$T/timer.sh" <<'SH'
#!/bin/sh
r=$1
lo=$((r - 2)); hi=$((r + 2))
echo "reading $r tenths; elapsed between $lo and $hi"
if [ "$lo" -ge 590 ] && [ "$hi" -le 610 ]; then exit 0; fi
if [ "$hi" -lt 590 ] || [ "$lo" -gt 610 ]; then exit 1; fi
exit 77
SH
    chmod +x "$T/timer.sh"
}
# mk: a build KB in $K with the goal h1 (the 0.7.2 form), one introduce claim c1 and its check k1.
mk() {
    K=$T/kb
    okb init "$K" --request 'the timer rings 59 to 61 s after the start' --uses build
    okb --dir "$K" add "hypothesis(h1, feature, 'The timer rings 59 to 61 s after the start.')" 'no_premises(h1)' \
        "claim(c1, introduce, 'It rings 59 to 61 s after the start.')" "cites(c1, 'rings')" \
        "example(c1, 'start at 0, ring at 60.0')" 'check(k1, c1)' "checks_that(k1, 'the ring time is inside 59 to 61 s')"
    rc_is 0 "mk: add"
    timer_script
}
run_k() { okb --dir "$K" run "$@"; }
judge_ok() { okb --dir "$K" attest judgment "${1:-h1}" satisfied --by human; rc_is 0 "the judgment of the goal"; }
last_run_id() { kbq "$K/kb.pl" "findall(A, kb(attest(A, test_result, _, _, _, _)), L), last(L, X), write(X)"; }

# ---------------------------------------------------------------- UV: verdicts (c7)
t_UV1() {  # the timer: 60.0 meets, 61.1 unresolved, 61.5 conflicts
    mk
    run_k k1 -- "$T/timer.sh" 615; rc_is 1 "61.5"
    out_has '^run 1 k1 fail \(exit 1\) log=' "61.5: the 0.7.2 line of a fail"
    out_has '^Last [0-9]+ line\(s\) of output:' "61.5: the tail"
    is_set 'verdict(a1, V)' 'V = conflicts'
    run_k k1 -- "$T/timer.sh" 600; rc_is 0 "60.0"
    out_has '^run 2 k1 pass \(exit 0\) log=' "60.0: the 0.7.2 line of a pass"
    [ "$(printf '%s\n' "$out" | wc -l)" = 1 ] || note "60.0: a pass prints one line: [$(snip "$out")]"
    is_set 'verdict(a2, V)' 'V = meets'
    is_true 'fulfilled(c1)'
    run_k k1 -- "$T/timer.sh" 611; rc_is 1 "61.1: not passed"
    out_has '^run 3 k1 unresolved \(exit 77\) log=' "61.1: the line"
    is_set 'verdict(a3, V)' 'V = unresolved'
    has_fact "$K/kb.pl" "attest(a3, test_result, k1, result(k1, 3, unresolved), script, _)"
    has_goal "$K/kb.pl" "kb(unresolved_because(a3, W)), sub_atom(W, _, _, _, 'exit 77')" "the reason"
    grep -q 'result=unresolved exit=77' "$K/runs/3-k1.log" || note "the log header says unresolved"
}
t_UV2() {  # an unresolved verdict fulfils nothing, defeats nothing, and keeps its claim open
    mk
    run_k k1 -- "$T/timer.sh" 615
    run_k k1 -- "$T/timer.sh" 600
    judge_ok
    is_true done
    run_k k1 -- "$T/timer.sh" 611
    is_false 'fulfilled(c1)'
    is_false done
    is_set 'blocking(X)' 'X = check_unresolved(k1)|X = under(c1)'
    is_false 'conflict_open(A)'
    is_false 'passed(k1)'
    okb --dir "$K" show open
    out_has 'check_unresolved k1: .*unresolved.*exit 77' "show open names the unresolved check with the reason"
    out_hasnt 'check_failing' "an unresolved check is not a failing check"
    okb --dir "$K" show blocking
    out_has 'check_unresolved k1' "show blocking"
    run_k k1 -- "$T/timer.sh" 600
    is_true 'fulfilled(c1)'; is_true done
}
t_UV3() {  # a check that is killed
    mk
    run_k k1 -- sh -c 'kill -9 $$'; rc_is 1
    out_has '^run 1 k1 unresolved \(exit 137\) log=' "killed: the line"
    has_goal "$K/kb.pl" "kb(unresolved_because(a1, W)), sub_atom(W, _, _, _, 'killed by signal 9')" "the reason"
    run_k k1 -- sh -c 'exit 143'; rc_is 1
    out_has '^run 2 k1 unresolved \(exit 143\)' "exit 143 is a kill"
    has_goal "$K/kb.pl" "kb(unresolved_because(a2, W)), sub_atom(W, _, _, _, 'killed by signal 15')" "the reason of 143"
    is_set 'verdict(a1, V)' 'V = unresolved'
    is_false 'was_red(k1)'
    is_false 'control(A)'
}
t_UV4() {  # a run that times out
    mk
    local t0=$SECONDS
    run_k k1 --timeout 1 -- sleep 30; rc_is 1
    [ $((SECONDS - t0)) -lt 15 ] || note "the timeout did not stop the command"
    out_has '^run 1 k1 unresolved \(exit 137\) log=' "timeout: the line"
    has_goal "$K/kb.pl" "kb(unresolved_because(a1, W)), sub_atom(W, _, _, _, 'timed out after 1 s')" "the reason"
    run_k k1 --timeout 20 -- true; rc_is 0 "inside the limit"
    out_has '^run 2 k1 pass \(exit 0\)'
    run_k k1 --timeout x -- true; rc_is 2 "a bad --timeout is a usage error"
}
t_UV5() {  # a solver: --expect; unknown and a time limit are unresolved, typed by nobody
    command -v z3 >/dev/null 2>&1 || { skip_test "z3 is not on the PATH"; return; }
    mk
    printf '(declare-const x Int)\n(assert (> x 2))\n(assert (< x 2))\n(check-sat)\n' > "$T/unsat.smt2"
    printf '(declare-const x Int)\n(assert (> x 2))\n(check-sat)\n' > "$T/sat.smt2"
    # nonlinear integer arithmetic with a 1 ms limit: z3 answers unknown or timeout
    printf '(declare-const a Int)\n(declare-const b Int)\n(declare-const c Int)\n(assert (> a 1000))\n(assert (> b 1000))\n(assert (> c 1000))\n(assert (= (+ (* a a a) (* b b b)) (* c c c)))\n(check-sat)\n' > "$T/hard.smt2"
    run_k k1 --expect unsat -- z3 "$T/sat.smt2"; rc_is 1 "sat when unsat is expected"
    out_has '^run 1 k1 fail \(exit 0\)' "the other decided answer is a fail"
    run_k k1 --expect unsat -- z3 "$T/unsat.smt2"; rc_is 0 "unsat as expected"
    out_has '^run 2 k1 pass \(exit 0\)'
    run_k k1 --expect unsat -- z3 -T:1 "$T/hard.smt2"; rc_is 1 "z3 with a time limit"
    out_has '^run 3 k1 unresolved ' "a solver timeout or unknown is unresolved"
    has_goal "$K/kb.pl" "kb(unresolved_because(a3, W)), (sub_atom(W, _, _, _, 'unknown') ; sub_atom(W, _, _, _, 'timed out'))" "the reason"
    is_set 'verdict(a3, V)' 'V = unresolved'
    printf '#!/bin/sh\necho unknown\n' > "$T/unk.sh"; chmod +x "$T/unk.sh"
    run_k k1 --expect unsat -- "$T/unk.sh"; rc_is 1
    has_goal "$K/kb.pl" "kb(unresolved_because(a4, W)), sub_atom(W, _, _, _, 'the solver answered unknown')" "unknown"
    run_k k1 --expect maybe -- true; rc_is 2 "a bad --expect is a usage error"
}
t_UV6() {  # exactly one verdict for each run; the 0.7.2 results still read
    mk
    run_k k1 -- false; run_k k1 -- true; run_k k1 -- sh -c 'exit 77'; run_k k1 -- sh -c 'exit 3'
    local a n
    for a in a1 a2 a3 a4; do
        q "verdict($a, V)" -n 0; n=$(printf '%s\n' "$out" | grep -c 'V = ')
        [ "$n" = 1 ] || note "$a has $n verdicts, want 1: $(snip "$out")"
    done
    is_set 'attest(A, test_result, k1, result(k1, N, R), script, _)' 'A = a1, N = 1, R = fail|A = a2, N = 2, R = pass|A = a3, N = 3, R = unresolved|A = a4, N = 4, R = fail'
    is_set 'experiment(a3, Kind, C)' 'Kind = test, C = c1'
    is_set 'latest_run(k1, A)' 'A = a4'
}
run_test t_UV1 UV1 "c7, c25: the timer: 60.0 meets, 61.1 unresolved (exit 77), 61.5 conflicts; the pass and fail lines keep their form"
run_test t_UV2 UV2 "c7: an unresolved verdict fulfils nothing, records no conflict, and keeps the claim open (check_unresolved, not check_failing)"
run_test t_UV3 UV3 "c7: a check that a signal killed (also exit 137, 143) is unresolved, with the reason"
run_test t_UV4 UV4 "c7: run --timeout: a run that times out is unresolved"
run_test t_UV5 UV5 "c7, c26: run --expect: a solver that answers unknown or runs into its time limit is unresolved"
run_test t_UV6 UV6 "c7: each run has exactly one verdict"

run_tests
echo "----"
echo "orbit-kb=$OKB lib=$LIB pass=$pass fail=$fail skip=$skip ${failed[*]:-}"
[ $fail = 0 ]
