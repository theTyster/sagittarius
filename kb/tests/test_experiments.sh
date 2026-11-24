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
    # a crash is not a kill: SIGSEGV and SIGABRT are a fail, with the 0.7.2 line; exit 124 is a fail too
    run_k k1 -- sh -c 'kill -SEGV $$'; rc_is 1
    out_has '^run 3 k1 fail \(exit 139\) log=' "SIGSEGV: the fail line"; out_has '^Last [0-9]+ line\(s\) of output:'
    is_set 'verdict(a3, V)' 'V = conflicts'; no_fact "$K/kb.pl" "unresolved_because(a3, _)"
    run_k k1 -- sh -c 'kill -ABRT $$'; out_has '^run 4 k1 fail \(exit 134\)' "SIGABRT"
    run_k k1 -- sh -c 'kill -TERM $$'; out_has '^run 5 k1 unresolved \(exit 143\)' "SIGTERM stays unresolved"
    run_k k1 -- sh -c 'exit 124'; out_has '^run 6 k1 fail \(exit 124\)' "exit 124 (coreutils timeout) is a fail"
    okb --dir "$K" help build; out_has 'orbit(-kb)? run --timeout|run K --timeout' "help build: a time limit belongs in run --timeout"
    sed -i '/result(k1, [3-6],/d' "$K/kb.pl"
    is_false 'control(A)'
}
t_UV4() {  # a run that times out
    mk
    local t0=$SECONDS
    run_k k1 --timeout 1 -- sleep 30; rc_is 1
    [ $((SECONDS - t0)) -lt 15 ] || note "the timeout did not stop the command"
    out_has '^run 1 k1 unresolved \(exit 137\) log=' "timeout: the line"
    has_goal "$K/kb.pl" "kb(unresolved_because(a1, W)), sub_atom(W, _, _, _, 'timed out after 1 s')" "the reason"
    printf '#!/bin/sh\nsleep 31 &\necho $! > "%s/child.pid"\nwait\n' "$T" > "$T/tree.sh"; chmod +x "$T/tree.sh"
    run_k k1 --timeout 1 -- "$T/tree.sh"; rc_is 1
    kill -0 "$(cat "$T/child.pid")" 2>/dev/null && { note "the timeout left a process of the command alive"; kill "$(cat "$T/child.pid")"; }
    run_k k1 --timeout 20 -- true; rc_is 0 "inside the limit"
    out_has '^run 3 k1 pass \(exit 0\)'
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

# ---------------------------------------------------------------- ST: stale verdicts (c39)
green() { run_k k1 -- false >/dev/null; run_k k1 -- true >/dev/null; }   # the control, then a pass
t_ST1() {  # the scenario of checks/stale_pass.sh (k8, k39)
    mk; echo 1 > "$T/val"
    run_k k1 -- sh -c "test \$(cat '$T/val') = 2"; rc_is 1 "red first"
    is_true 'control(a1)' "the red run before any change is the control"
    is_false 'conflict_open(A)' "a control needs no location"
    echo 2 > "$T/val"
    okb --dir "$K" add "change(x1, 'set val to 2')" 'serves(x1, c1)'
    run_k k1 -- sh -c "test \$(cat '$T/val') = 2"; rc_is 0
    judge_ok; is_true 'fulfilled(c1)'; is_true done
    okb --dir "$K" add "change(x2, 'val is 1 again')" 'serves(x2, c1)'
    is_false 'fulfilled(c1)' "a later change that serves the claim"; is_false done
    is_true 'verdict_stale(a2, c1)'
    is_set 'blocking(X)' 'X = under(c1)|X = verdict_stale(k1)'
    okb --dir "$K" show open; out_has '^- verdict_stale k1: .*x2' "show open names the stale verdict and the change"
    okb --dir "$K" show stale; out_has '^- stale: run a2 of claim c1'
    run_k k1 -- true; is_true 'fulfilled(c1)' "a new run"; is_true done
}
t_ST2() {  # a change with no change time makes no run stale; a change that serves another claim does not either
    mk; green; judge_ok
    printf "change(x7, 'old data').\nserves(x7, c1).\n" >> "$K/kb.pl"
    is_true 'fulfilled(c1)' "an undated change"; is_true done
    okb --dir "$K" add "claim(c2, preserve, 'other')" "cites(c2, 'rings')" "change(x8, 'other')" 'serves(x8, c2)' 'check(k2, c2)' "checks_that(k2, 'other')"
    run_k k2 -- true
    is_true 'fulfilled(c1)' "a change of another claim"
}
t_ST3() {  # a measurement premise that is found false: the verdict becomes unresolved (the clock 2 s off)
    mk
    okb --dir "$K" add "measurement_premise(mp1, k1, 'The clock is right within 0.2 s.')"; rc_is 0
    run_k k1 -- "$T/timer.sh" 615; run_k k1 -- "$T/timer.sh" 600
    judge_ok; is_true done; is_set 'verdict(a2, V)' 'V = meets'
    okb --dir "$K" attest measurement mp1 "false('The clock is 2 s off.')"; rc_is 0 "the finding"
    is_set 'verdict(a2, V)' 'V = unresolved'
    is_false 'fulfilled(c1)'; is_false done
    is_set 'blocking(X)' 'X = check_unresolved(k1)|X = under(c1)'
    okb --dir "$K" show open; out_has 'check_unresolved k1: .*measurement' "show open says why"
    run_k k1 -- "$T/timer.sh" 600
    is_set 'verdict(a5, V)' 'V = meets' "a run after the finding counts"
    is_true 'fulfilled(c1)'
}
# ---------------------------------------------------------------- GF: the grandfather rule (c20, c39, q27)
old_done_kb() {  # a KB as orbit-kb 0.7.2 left it: done, with a pass that is older than a later change
    K=$T/old; mkdir -p "$K/runs"
    cat > "$K/kb.pl" <<'EOF'
uses([build]).
request(r1, 'val is 2').
% Made by orbit-kb 0.7.2.
hypothesis(h1, feature, 'val is 2').
no_premises(h1).
claim(c1, introduce, 'val is 2').
cites(c1, 'val is 2').
check(k1, c1).
checks_that(k1, 'val holds 2').
EOF
    add_result "$K" k1 1 fail; add_result "$K" k1 2 pass
    printf "change(x1, 'set val').\nserves(x1, c1).\nchange_at(x1, '2026-10-15T10:00:01Z').\nchange(x2, 'later').\nserves(x2, c1).\nchange_at(x2, '2026-10-16T10:00:00Z').\n" >> "$K/kb.pl"
}
t_GF1() {  # done before the upgrade stays done, with no write; the stale verdict is listed
    old_done_kb; cp "$K/kb.pl" "$T/before.pl"
    is_true done "a KB that 0.7.2 called done"; is_false 'blocking(X)'
    is_true 'verdict_stale(t2, c1)' "the rule calls the pass stale"
    is_true done_before_upgrade; is_true 'fulfilled(c1)'
    okb --dir "$K" show open; out_has '^- stale \(done before the upgrade\): .*t2.*c1' "show open lists it"; out_has 'Nothing is open'
    okb --dir "$K" show stale; out_has '^- stale \(done before the upgrade\): run t2 of claim c1'
    same_file "$K/kb.pl" "$T/before.pl" "reading writes nothing"
}
t_GF2() {  # the first write records the upgrade; done still holds; a change after the upgrade counts
    old_done_kb
    okb --dir "$K" add "note(c1, 'a note')"; rc_is 0
    has_fact "$K/kb.pl" "upgraded(_, _)"; has_fact "$K/kb.pl" "done_before_upgrade(_, _)"
    has_goal "$K/kb.pl" "findall(L, kb_line(L, upgraded(_, _)), [LU]), kb_line(LN, note(c1, _)), LU < LN" "upgraded/2 stands before the write"
    is_true done "done after the first write"; is_false 'blocking(X)'
    is_true 'before_upgrade_record(t1)'; is_false 'after_upgrade_change(x2)' "the order of kb.pl decides, not the second"
    okb --dir "$K" add "note(c1, 'a second note')"
    fact_count "$K/kb.pl" "upgraded(_, _)" 1 "one upgraded fact"
    okb --dir "$K" add "change(x3, 'new work')" 'serves(x3, c1)'
    is_false done "a change after the upgrade makes the old pass stale"
    is_set 'blocking(X)' 'X = under(c1)|X = verdict_stale(k1)'
    run_k k1 -- true; is_true done "a new run; the goal of a ticket that was done needs no judgment"
}
t_GF3() {  # an open old KB gets the new rules at once, and keeps its old open items
    old_done_kb
    printf "claim(c2, preserve, 'open').\ncites(c2, 'val is 2').\ncheck(k2, c2).\nchecks_that(k2, 'x').\n" >> "$K/kb.pl"
    is_false done; is_false done_before_upgrade
    is_set 'blocking(X)' 'X = check_unrun(k2)|X = goal_unjudged(h1)|X = under(c1)|X = under(c2)|X = verdict_stale(k1)'
    okb --dir "$K" add "note(c1, 'a note')"
    has_fact "$K/kb.pl" "upgraded(_, _)"; no_fact "$K/kb.pl" "done_before_upgrade(_, _)"
}
t_GF4() {  # a rejected write records no upgrade
    old_done_kb; cp "$K/kb.pl" "$T/before.pl"
    okb --dir "$K" add "nonsense("; rc_is 1
    same_file "$K/kb.pl" "$T/before.pl" "a rejected add writes nothing"
}
# ---------------------------------------------------------------- JD: the judgment of the human (c10, c41)
t_JD1() {  # k41: no judgment, done is no; judgment and one unresolved claim, done is no; a waiver with a due time, done is yes
    mk; green
    is_false done "every blocker clear and no judgment of the goal"
    is_set 'blocking(X)' 'X = goal_unjudged(h1)'
    okb --dir "$K" show open; out_has '^- goal_unjudged h1: .*judge h1 satisfied --by human'
    okb --dir "$K" judge h1 satisfied; rc_is 1 "an agent cannot judge"; any_hasi 'only the human'
    okb --dir "$K" judge h1 satisfied --by human --note 'Ty: it is what I wanted'; rc_is 0
    is_true 'goal_satisfied(h1)'; is_true done
    has_fact "$K/kb.pl" "attest(_, judgment, h1, satisfied, human, _)"
    okb --dir "$K" add "claim(c2, preserve, 'It is as loud as before.')" "cites(c2, 'rings')" 'check(k2, c2)' "checks_that(k2, 'loudness')"
    run_k k2 -- sh -c 'exit 77'
    is_false done "the judgment turns no unresolved verdict into meets"
    is_set 'blocking(X)' 'X = check_unresolved(k2)|X = under(c2)'
    is_false 'blocking(check_failing(k2))' "c7 (k7): an unresolved check is not listed as failing"
    okb --dir "$K" show open; [ "$(printf '%s\n' "$out" | grep -c ' k2: ')" = 1 ] || note "show open prints one line for the unresolved check: $(snip "$out")"
    cp -r "$K" "$T/kb2"
    okb --dir "$K" attest waiver c2 "waive(c2, '2999-12-15T00:00:00Z', 'the tool that measures it does not exist')" --by human; rc_is 0
    is_true done "a human waiver of the claim with a due time (the example of c41)"
    is_false 'fulfilled(c2)'
    okb --dir "$K" report; out_has 'Status: not fulfilled' "the delivery"; out_has 'Not shown' "the delivery says not shown"
    run_k k2 -- false
    is_false done "a waiver of the claim does not cover a conflict"
    K=$T/kb2
    okb --dir "$K" attest waiver k2 "waive(k2, '2999-12-15T00:00:00Z', 'the tool that measures it does not exist')" --by human; rc_is 0
    is_true done "a human waiver of the check, as at 0.7.2"
    okb --dir "$K" attest waiver c2 "waive(c2, '2020-01-01T00:00:00Z', 'past')" --by human; is_true done
}
t_JD2() {  # a later not-satisfied judgment or a not-wanted case reopens; a judgment is a record
    mk; green; judge_ok; is_true done
    okb --dir "$K" judge h1 case 'the ring at 60.9 s is too late for the kitchen' not-wanted --by human; rc_is 0
    has_fact "$K/kb.pl" "attest(_, judgment, h1, case('the ring at 60.9 s is too late for the kitchen', not_wanted), human, _)"
    is_false done "a not-wanted case"; is_true 'passed(k1)' "no check fails"; is_true 'fulfilled(c1)'
    is_set 'blocking(X)' 'X = goal_unjudged(h1)'
    okb --dir "$K" show open; out_has 'For discovery: a[0-9]+' "with no hypothesis named, the case goes to discovery"
    okb --dir "$K" judge h1 case 'the ring at 60.0 s' wanted --by human
    is_false done
    okb --dir "$K" judge h1 satisfied --by human; is_true done
    okb --dir "$K" judge h1 not-satisfied --by human; is_false done
    q 'experiment(A, judgment, h1)' -n 0; [ "$(printf '%s\n' "$out" | grep -c 'A = ')" = 5 ] || note "five judgments are experiments: $(snip "$out")"
}
t_JD3() {  # a not-wanted case against a hypothesis defeats it; with no hypothesis named it blocks (case_unplaced)
    K=$T/kb; kb_new "$K" <<'EOF'
uses([build]).
% Made by orbit-kb 0.8.0.
request(r1, 'replay').
goal(g1, feature, human, 'A replayed import leaves the member records as one clean run would.').
hypothesis(hya, g1, agent, 'Skipping each seen record ID makes a replay safe.').
claim(c1, preserve, 'The member count is the one of a clean run.').
cites(c1, 'replay').
check(k1, c1).
EOF
    add_result "$K" k1 1 pass
    okb --dir "$K" judge g1 case 'the corrected address of member 12 was dropped' not-wanted --by human; rc_is 0
    local j; j=$(kbq "$K/kb.pl" "kb(attest(J, judgment, _, _, _, _)), write(J)")
    is_set 'blocking(X)' "X = case_unplaced($j)|X = goal_unjudged(g1)"
    okb --dir "$K" show open; out_has "^- case_unplaced $j: .*member 12"
    is_false 'hypothesis_defeated(H)'
    okb --dir "$K" add "case_against($j, hya)"; rc_is 0
    is_set 'hypothesis_defeated(H)' 'H = hya'
    is_false 'case_unplaced(J)'; is_true 'passed(k1)' "no check fails"
}
t_JD4() {  # a formal statement that the human has not accepted is listed in the delivery draft; W18
    K=$T/kb; kb_new "$K" <<'EOF'
uses([build]).
% Made by orbit-kb 0.8.0.
request(r1, 'replay').
goal(g1, feature, human, 'A replay is safe.').
claim(c1, preserve, 'The member count is the one of a clean run.').
cites(c1, 'replay').
EOF
    printf '(check-sat)\n' > "$T/m.smt2"
    okb --dir "$K" subject m1 "$T/m.smt2" >/dev/null
    okb --dir "$K" add 'formal_statement(m1, c1)'; rc_is 0
    okb --dir "$K" lint; out_has '^W18 m1' "W18: no could_change"
    okb --dir "$K" add "could_change(m1, 'whether a notification counts')"
    okb --dir "$K" lint; out_hasnt '^W18'
    okb --dir "$K" report; out_has 'Formal: not yet accepted by the human' "the heading"; out_has 'm1.*c1' "the statement"
    okb --dir "$K" judge m1 accepts c1 --by human; rc_is 0
    okb --dir "$K" report; out_hasnt 'not yet accepted by the human'
    sed -i 's/Made by orbit-kb 0.8.0/Made by orbit-kb 0.7.2/' "$K/kb.pl"; sed -i '/could_change/d' "$K/kb.pl"
    okb --dir "$K" lint; out_hasnt '^W18' "a KB from before 0.8.0 gets no W18"
}
# ---------------------------------------------------------------- LC: the location of a conflict (c9, c40)
conflict_kb() {  # mk, the control, a change by build, and a run that conflicts: a3
    mk
    run_k k1 --as build -- "$T/timer.sh" 615
    ORBIT_KB_WRITER=sb okb --dir "$K" add "change(x1, 'the timer rings')" 'serves(x1, c1)' --as build
    ORBIT_KB_WRITER=sb okb --dir "$K" run k1 --as build -- "$T/timer.sh" 615
    A=$(last_run_id)
}
loc_id() { kbq "$K/kb.pl" "findall(L, kb(attest(L, location, _, _, _, _)), Ls), last(Ls, X), write(X)"; }
t_LC1() {  # a conflict with no location blocks done; the control needs none; located in the build stays with build
    conflict_kb; judge_ok
    is_true 'control(a1)'; is_false "control($A)"
    is_set 'conflict_open(X)' "X = $A"
    is_set 'blocking(X)' "X = check_failing(k1)|X = conflict_unlocated($A)|X = under(c1)"
    okb --dir "$K" show open; out_has "^- conflict_unlocated $A: .*locate $A"
    okb --dir "$K" locate $A build --evidence 'a bug in the comparison'; rc_is 0
    is_false 'conflict_open(X)'; is_false 'blocking(location_unconfirmed(L))'; is_false 'to_discovery(X)'
    is_set 'blocking(X)' "X = check_failing(k1)|X = under(c1)"
    ORBIT_KB_WRITER=sb okb --dir "$K" run k1 --as build -- "$T/timer.sh" 600
    is_true done "build fixed it: no discovery lap"
    okb --dir "$K" locate a99 build --evidence x; rc_is 1 "an unknown run"
}
t_LC2() {  # the measurement: open until a pane that did not build confirms; then unresolved, and a new run is owed
    conflict_kb; judge_ok
    ORBIT_KB_WRITER=sb okb --dir "$K" locate $A measurement --evidence 'a second clock reads 60.4 s' --as build; rc_is 0
    local l; l=$(loc_id)
    is_set 'blocking(X)' "X = check_failing(k1)|X = location_unconfirmed($l)|X = under(c1)"
    is_set "verdict($A, V)" 'V = conflicts'
    ORBIT_KB_WRITER=sb okb --dir "$K" confirm $l --note 'I agree with myself' --as build; rc_is 0
    is_false "location_confirmed($l)" "build cannot move the conflict out of the build by its own word"
    ORBIT_KB_WRITER=sb okb --dir "$K" confirm $l --note 'same session, other role' --as review
    ORBIT_KB_WRITER=sr okb --dir "$K" confirm $l --take --note 'same role, other session' --as build
    is_false "location_confirmed($l)" "the role and the session must both differ"
    ORBIT_KB_WRITER=sr okb --dir "$K" confirm $l --take --note 'the second clock is the right one' --as review; rc_is 0
    is_true "location_confirmed($l)"
    is_set "verdict($A, V)" 'V = unresolved'
    is_set 'blocking(X)' "X = check_unresolved(k1)|X = under(c1)"
    ORBIT_KB_WRITER=sb okb --dir "$K" run k1 --take --as build -- "$T/timer.sh" 600
    is_true done "the repaired experiment ran again"
}
t_LC3() {  # the human confirms
    conflict_kb
    okb --dir "$K" locate $A measurement --evidence 'clock'; local l; l=$(loc_id)
    okb --dir "$K" confirm $l --note 'yes' --by human; rc_is 0
    is_true "location_confirmed($l)"
}
t_LC4() {  # a ticket with no hypothesis: a conflict in a claim of the goal goes to discovery; the goal is not defeated
    conflict_kb
    okb --dir "$K" locate $A claim:c1 --evidence 'the build does what the claim says'; local l; l=$(loc_id)
    is_false 'to_discovery(X)' "not before the confirmation"
    okb --dir "$K" confirm $l --note 'yes' --by human
    is_set 'to_discovery(X)' 'X = c1'
    is_false 'hypothesis_defeated(H)'; is_true 'under(c1)' "the claim stays open"
    okb --dir "$K" show open; out_has '^- For discovery: c1'
}
t_LC5() {  # located in the hypothesis: confirmed, the hypothesis is defeated and goes to discovery
    K=$T/kb; kb_new "$K" <<'EOF'
uses([build]).
% Made by orbit-kb 0.8.0.
request(r1, 'replay').
goal(g1, feature, human, 'A replay is safe.').
hypothesis(hya, g1, agent, 'Skipping each seen record ID makes a replay safe.').
premise(p1, hya, 'An ID never comes back with new data.').
claim(c1, preserve, 'No correction is lost.').
cites(c1, 'replay').
predicts(hya, c1).
check(k1, c1).
EOF
    add_result "$K" k1 1 fail
    okb --dir "$K" locate t1 hypothesis:hya --evidence 'a correction under a seen ID is discarded, as the hypothesis says'; rc_is 0
    local l; l=$(loc_id)
    is_true "blocking(location_unconfirmed($l))"; is_false 'hypothesis_defeated(H)'
    okb --dir "$K" confirm $l --note 'review saw the case' --by human
    is_set 'hypothesis_defeated(H)' 'H = hya'; is_set 'to_discovery(X)' 'X = hya'
    okb --dir "$K" locate t1 premise:p1 --evidence 'the premise is false'; rc_is 0
}
# ---------------------------------------------------------------- EX: one view of every kind (c6)
t_EX1() {  # show experiments: the claim, the procedure, the measurement premises, known-when, the observation, the verdict
    mk
    okb --dir "$K" lint; out_has '^W17 k1' "W17: no procedure and no run"
    okb --dir "$K" add "procedure(k1, 'An independent clock times the start and the ring.')" \
        "measurement_premise(mp1, k1, 'The clock is right within 0.2 s.')" \
        "known_when(k1, 'The tolerance and the error bound were fixed before the reading.')"; rc_is 0
    okb --dir "$K" lint; out_hasnt '^W17'
    old_done_kb; printf "claim(c9, preserve, 'x').\ncites(c9, 'val is 2').\ncheck(k9, c9).\nchecks_that(k9, 'x').\n" >> "$K/kb.pl"
    okb --dir "$K" lint; out_hasnt '^W17' "a KB from before 0.8.0 gets no W17"
    K=$T/kb
    run_k k1 -- "$T/timer.sh" 615
    okb --dir "$K" judge h1 case 'it rang at 61.5 s' not-wanted --by human
    okb --dir "$K" show experiments; rc_is 0
    out_has '^- a1 \(test\): verdict conflicts'; out_has 'Claim c1: It rings'
    out_has 'Procedure: An independent clock'; out_has 'Measurement premise mp1: The clock is right'
    out_has 'Known when: The tolerance'; out_has 'Observation: run 1 of check k1, result fail, log .*1-k1.log'
    out_has 'Verdict: conflicts'; out_has '^- a2 \(judgment\): verdict conflicts'; out_has 'Goal h1'
    okb --dir "$K" show experiments a2; out_hasnt '^- a1 '
    okb --dir "$K" add 'check(k2, c1)' "checks_that(k2, 'again')"; run_k k2 -- true
    okb --dir "$K" show experiments k2; out_has 'Procedure \(the command of the run\): true'
}
t_EX2() {  # a model result, a proof and a demo are experiments with one verdict each
    K=$T/kb; printf 'm\n' > "$T/m.smt2"; printf 'l\n' > "$T/run.log"; printf 'png\n' > "$T/d.png"
    local dm dl dd; dm=$(sha "$T/m.smt2"); dl=$(sha "$T/run.log"); dd=$(sha "$T/d.png")
    kb_new "$K" <<EOF
uses([build]).
request(r1, 'x').
claim(c1, preserve, 'A claim.').
cites(c1, 'x').
subject(m1, '$T/m.smt2', 'sha256:$dm').
subject(l1, '$T/run.log', 'sha256:$dl').
subject(s1, '$T/d.png', 'sha256:$dd').
model(m1, smt).
model_run(l1, m1, 'sha256:$dm').
encodes(m1, c1).
attest(a1, model_result, l1, verdict(m1, preserve(c1), unsat), agent, '2026-10-15T10:00:01Z').
attest(a2, model_result, l1, verdict(m1, preserve(c1), unknown), agent, '2026-10-15T10:00:02Z').
attest(a3, model_result, l1, verdict(m1, preserve(c1), sat), agent, '2026-10-15T10:00:03Z').
demo(s1, c1).
attest(a4, approval, s1, digest('sha256:$dd'), human, '2026-10-15T10:00:04Z').
EOF
    is_set 'experiment(A, Kind, c1)' 'A = a1, Kind = model|A = a2, Kind = model|A = a3, Kind = model|A = a4, Kind = demo'
    is_set 'verdict(A, V)' 'A = a1, V = meets|A = a2, V = unresolved|A = a3, V = conflicts|A = a4, V = meets'
    okb --dir "$K" show experiments; rc_is 0; out_has '^- a2 \(model\): verdict unresolved'; out_has '^- a4 \(demo\): verdict meets'
    printf 'changed\n' > "$T/d.png"
    is_set 'verdict(a4, V)' 'V = unresolved' "a demo whose file changed"
}
# ---------------------------------------------------------------- SB: Sound Basis (c16)
t_SB1() {  # a change that serves no claim is a conflict that opens its behavior for review
    mk; green; judge_ok
    okb --dir "$K" add "change(x9, 'the notification count')"
    is_set 'blocking(X)' 'X = over(x9)'
    okb --dir "$K" show open; okb --dir "$K" show blocking
    out_has '^- over x9: Conflict \(Sound Basis\): change x9 serves no claim\. Its behavior is open for review'
}
t_SB2() {  # behavior_conflict: open until a current claim names it, or a human waives it
    mk; green; judge_ok
    okb --dir "$K" add "behavior_conflict(b1, 'the old test of the notification count fails')"; rc_is 0
    is_set 'blocking(X)' 'X = behavior_open(b1)'; is_false done
    okb --dir "$K" show open; out_has '^- behavior_open b1: Conflict \(Sound Basis\).*open for review'
    okb --dir "$K" attest waiver b1 "waive(b1, '2999-01-01T00:00:00Z', 'known')" --by human; rc_is 0
    is_true done "a human waiver"
    sed -i '/waiver/d' "$K/kb.pl"; is_false done
    okb --dir "$K" add "claim(c3, preserve, 'One notification for each import.')" "cites(c3, 'rings')" 'names(c3, b1)' 'check(k3, c3)' "checks_that(k3, 'n')"
    run_k k3 -- true
    is_false 'behavior_open(B)' "a current claim names it"; is_true done
}
# ---------------------------------------------------------------- GC: a change of the goal (c42)
t_GC1() {  # a verdict that no record carried over fulfils nothing
    K=$T/kb; kb_new "$K" <<'EOF'
uses([build]).
% Made by orbit-kb 0.8.0.
request(r1, 'replay').
goal(g1, feature, human, 'The same member records.').
claim(c1, preserve, 'One notification.').
cites(c1, 'replay').
check(k1, c1).
EOF
    add_result "$K" k1 1 pass
    okb --dir "$K" attest judgment g1 satisfied --by human >/dev/null
    is_true done "setup"
    okb --dir "$K" add "goal(g2, feature, human, 'The same member records and no second notification.')" 'supersedes(g2, g1)' --by human; rc_is 0
    is_set 'before_goal(X, G)' 'X = c1, G = g2|X = t1, G = g2'
    is_set 'not_carried(X)' 'X = c1|X = t1'
    is_false 'fulfilled(c1)' "the meets verdict of the old goal is not carried"
    is_false 'current(c1)' "a claim of the old goal is not current until a record carries it over"
    okb --dir "$K" add 'carried(c1, g2)'
    is_set 'not_carried(X)' 'X = t1'; is_true 'current(c1)'
    is_true 'blocking(not_carried(t1))'; is_true 'blocking(goal_unjudged(g2))'
    okb --dir "$K" show open; out_has '^- not_carried t1: Not carried over'
    okb --dir "$K" add 'carried(t1, g2)'; is_true 'fulfilled(c1)'
}
t_GC2() {  # a restated hypothesis of the 0.7.2 form changes nothing (c43)
    mk; green
    okb --dir "$K" add "hypothesis(h2, feature, 'The timer rings 59 to 61 s after the start, each time.')" 'no_premises(h2)' 'supersedes(h2, h1)'
    is_false 'before_goal(X, G)'; is_true 'fulfilled(c1)'
    is_set 'blocking(X)' 'X = goal_unjudged(h2)'
}
# ---------------------------------------------------------------- RPX: report
rp_claims() { printf '%s\n' "$out" | sed -n '/^# Claims/,/^# Review/p'; }
t_RPX1() {  # the Claims field: fulfilled, conflicts, unresolved (with the reason), stale; never failed for unresolved
    mk; run_k k1 -- false; run_k k1 -- sh -c 'exit 77'
    okb --dir "$K" report; rc_is 0
    out_has 'Status: unresolved' "unresolved"; out_has 'could not decide: .*exit 77' "with the reason"; out_has 'Checks: k1 \(unresolved\)'; rp_claims | grep -Eq 'failed|not passed' && note "unresolved is printed as failed: $(rp_claims | tr '\n' '~')"
    run_k k1 -- false; okb --dir "$K" add "change(x1, 'a')" 'serves(x1, c1)'; run_k k1 -- false
    okb --dir "$K" report; out_has 'Status: conflicts'
    run_k k1 -- true; okb --dir "$K" report; out_has 'Status: fulfilled'
    okb --dir "$K" add "change(x2, 'b')" 'serves(x2, c1)'
    okb --dir "$K" report; out_has 'Status: stale'
}
run_test t_ST1 ST1 "c39 (k39): after a later change that serves the claim, with no new run, fulfilled and done are no; the control needs no location"
run_test t_ST2 ST2 "c39: an undated change and a change of another claim make no run stale"
run_test t_ST3 ST3 "c39: a measurement premise that is found false makes each earlier verdict of its check unresolved"
run_test t_GF1 GF1 "c20, c39, q27: a KB that was done before the upgrade is done with no write; its stale verdict is listed"
run_test t_GF2 GF2 "c20, c39: the first write records upgraded/2 and done_before_upgrade/2; done holds; a later change counts"
run_test t_GF3 GF3 "c20: an open KB from before the upgrade gets the new rules at once and keeps its open items"
run_test t_GF4 GF4 "c20: a rejected write records no upgrade"
run_test t_JD1 JD1 "c41 (k41): done needs the judgment of the goal; an unresolved claim holds it up; a human waiver covers it"
run_test t_JD2 JD2 "c10, c41: a not-wanted case reopens the goal and fails no check; the latest judgment counts"
run_test t_JD3 JD3 "c10, c41: a not-wanted case is recorded against the hypothesis that allowed it (case_unplaced, case_against)"
run_test t_JD4 JD4 "c10, c13: a formal statement that the human has not accepted is listed in the report; lint W18"
run_test t_LC1 LC1 "c9, c40: a conflict with no location blocks done; the control needs none; a conflict in the build stays with build"
run_test t_LC2 LC2 "c40: a conflict in the measurement counts only when a pane that did not build confirms it; then the run is unresolved"
run_test t_LC3 LC3 "c40: the human confirms a location"
run_test t_LC4 LC4 "c40: with no hypothesis, a confirmed conflict in a claim of the goal goes to discovery; the goal is not defeated"
run_test t_LC5 LC5 "c9: a confirmed conflict in the hypothesis defeats it, and it goes to discovery"
run_test t_EX1 EX1 "c6: show experiments prints the claim, the procedure, the measurement premises, known-when, the observation, the verdict; W17"
run_test t_EX2 EX2 "c6, c7: a model result and a demo are experiments with exactly one verdict"
run_test t_SB1 SB1 "c16: a change that serves no claim is a conflict that opens its behavior for review"
run_test t_SB2 SB2 "c16: behavior_conflict blocks until a current claim names it or a human waives it"
run_test t_GC1 GC1 "c42: after a change of the goal, a verdict that no record carried over fulfils nothing"
run_test t_GC2 GC2 "c43: a restated hypothesis of the 0.7.2 form carries everything, as at 0.7.2"
run_test t_RPX1 RPX1 "c7: report Claims says fulfilled, conflicts, unresolved (with the reason) or stale"

run_tests
echo "----"
echo "orbit-kb=$OKB lib=$LIB pass=$pass fail=$fail skip=$skip ${failed[*]:-}"
[ $fail = 0 ]
