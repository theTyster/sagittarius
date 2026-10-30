#!/usr/bin/env bash
# Black-box tests for kb/bin/orbit-kb.
#
# The ONLY source of expected behavior is kb/CONTRACT.md (v2.1). No test
# reads the CLI source or the library source, so the implementation is never the source
# of what a test expects. Where the contract is ambiguous, the test follows the reading
# that makes a failure loud, and the comment above the test says so.
#
# Usage: kb/tests/test_orbit_kb.sh [path-to-orbit-kb]
#   (or ORBIT_KB_BIN=/path/to/orbit-kb kb/tests/test_orbit_kb.sh)
#   ONLY='<regex>' runs only the tests whose id matches, for example ONLY='^(K|I)[0-9]'.
#   ORBIT_KB_TEST_JOBS=N runs the tests in N parallel workers (default 4, see below).
#   ORBIT_KB_TEST_JOBS=1 runs them one at a time in this shell, as the suite always did.
#   The default CLI is the repo copy. ORBIT_KB_LIB is set to the repo library, so the
#   suite works before installation (override: ORBIT_KB_TEST_LIB).
#   Exit status: 0 when every test passes, 1 when a test fails, 2 when the suite cannot
#   run (the CLI, the library, or a tool is missing, or ORBIT_KB_TEST_JOBS is not a number).
#   The suite is one CPU-heavy job. If your machine has a job queue, run it through the queue.
#
# Each test runs in a fresh mktemp -d and removes it at the end. Fixtures in fixtures/ are
# copied first and never modified. KBs that a test needs are built inline, next to the
# expected result. Facts in kb.pl are read back with swipl (kbq.pl, embedded below), so
# no test depends on the spacing or the quoting that the CLI chooses when it writes.
#
# Parallel runs (ORBIT_KB_TEST_JOBS > 1):
#  - The default is 4 workers (fewer when fewer CPUs are available, for example under
#    HEAVY_CPUS). The suite is one heavy job. On the author's shared,
#    heat-limited laptop (4 P-cores of 14 cores), a job queue lets 2 jobs run at once. 4 workers
#    use about 4 cores, so the other job and the interactive sessions keep the rest. Measured on an idle machine
#    (2026-10-16): N=2 27 s, N=4 15 s, N=8 9.5 s of wall time, but 55 s, 61 s, 74 s of CPU
#    time, because more workers run on E-cores and on hot, slower cores.
#  - Each worker takes the next test that no other worker took (an O_EXCL claim file), so a
#    test runs once. Each test runs in its own subshell, with stdin from /dev/null.
#  - The output does not change: the lines of each test come in run_test order, even when the
#    tests finish in a different order, then the same summary line and the same exit status.
#  - Tests whose id matches SERIAL (below) run alone, before the workers start. Use it for a
#    test whose result can change under CPU load.
#  - Isolation: no state is shared between tests. Each test has its own temp directory and
#    its own empty XDG_CACHE_HOME ($T/.cache), so a CLI result cache cannot carry results
#    from one test to another, or from ~/.cache. No ORBIT_KB_* variable of the caller
#    reaches the CLI; the suite sets ORBIT_KB_LIB.
#  - Prototypes: a setup that many tests repeat (mkclaim, h3_kb) runs once, with the same
#    CLI calls, in its own directory. Then each test copies the result into its own temp
#    directory. Nothing changes a prototype after it is built (see use_proto).
#
# Requirement map (contract v2.1 + H3/H4; section names, not line numbers, because the contract is edited):
#   K   KB resolution: --dir, $ORBIT_KB, parent walk, exit 2   (CLI: KB resolution, exit codes) : K1-K8
#   I   init                                                   (CLI: init)                      : I1-I8
#   U   uses: add a module to an existing KB                   (CLI: uses)                      : U1-U9
#   A   add: validation, all or nothing, rejections            (CLI: add; Declarations; Types)  : A1-A19
#   D   declare, declare-attest                                (CLI: declare, declare-attest)   : D1-D6
#   AT  attest: id, time, writers, digest(current)             (CLI: attest)                    : AT1-AT9
#   S   subject: sha256, relative paths, refresh               (CLI: subject; D3)               : S1-S8
#   R   run: numbering, log header, tail, unknown check, D1    (CLI: run; Files; D1)            : R1-R9
#   B   core and build rules through query, H1 guard           (Core rules; Build module)       : B1-B20
#   H3  passed/1 with arithmetic under negation                (H3; Engines: cross-check; D8)   : H3a-H3d
#   Q   query: output, -n, exit codes, --json, --html, --why   (CLI: query; exit codes)         : Q1-Q13
#   X   engines: H1, H2, cross-check, #= skip, flags           (H1; H2; Engines)                : X1-X10 X2g
#   G   grounded cross-check: 20x2 done, raw fallback NOTE     (D8)                             : GD GU (also H3d X2g DR4)
#   WN  whynot: holds, contradicts, absent                     (CLI: whynot)                    : WN1-WN4
#   Y   why: justification text, #pred templates               (CLI: why; Environment facts)    : Y1-Y3
#   L   lint E1-E13, W1-W6, --strict, hook, summary            (Lint; D2; H4)                   : L0 L0b E1-E13 W1 W3-W6 LS LS2 LH1 LH2
#   D7  review fixes: broken sources exit 2, unsafe negation, kb.lock (D7)                   : D7a-D7d RC E14 E13s
#   SH  show   RP report   DR doctor (H1-H4 self-tests)   HP help (CLI: show, report, doctor, help) : SH1-SH7 RP1-RP6 DR1-DR3 HP1-HP3
#   RL  report text layout: headings, bullets, nesting (D16 c4)   : RL1-RL7
#   RH  report --html: golden text, page, escaping, open first, evidence, review (D16)   : RH1-RH9
#   BP  burns: open, proved, changed, waived, lapsed       (Build module; D10)              : BP1-BP14
#   SC  D10 follow-up: inherited burns, supersede cycles, rules.pl, times, proof logs (D10 follow-up) : SC1-SC11
#   RF  refuted(Counterexample) in disproof and lean_result (2026-10-21) : RF1-RF7
#   WV  waivers of a check or a question (D13, 2026-10-21)     (Build module; D13)              : WV1-WV10
#   RW  reword a hypothesis with supersedes; W5 names a new check (D15, 2026-10-27) : RW1-RW5 W5b W5c
#   NC  no current claim: done, whynot, report, show open (D17, issue #1)   : NC1-NC5
#   PV  prove with real Lean (skipped without lake)        (CLI: prove; D10, D10 follow-up) : PV1-PV12
#
# Fixtures (fixtures/<name>/): valid, valid_local, e1_syntax, e2_undeclared, e3_oneof,
# e4_dangling, e5_duplicate, e6_nonground, e7_wrong_place, e8_writer, e9_no_log,
# e10_no_uses, e11_compile, e12_not_var, e13_atom_digits (one per error code), the variants e2_arity,
# e2_rule_body, e3_time, e4_wrong_kind, e5_cross, e8_script_type, e9_bad_header,
# e10_not_first, e10_unknown_module, e12_named_var, e14_unsafe_neg (D7), and the warning fixtures w3_no_cites,
# w4_no_reader, w5_superseded_check, w6_extension. A line that must get a diagnostic ends
# with the marker "% <-- E<n>". The tests read the expected line from the marker.
#
# Contract readings that tests rely on (also listed in the final report of the builder):
#  - lint prints diagnostics and the summary line on stdout; other checks accept either stream.
#  - add: a syntax error in a fact is a rejection (exit 1); an unknown check in run is exit 2,
#    because for run the exit code 1 means "the check failed" and a typo must not look like it.
#  - A stub-free engine disagreement test needs ORBIT_KB_SCASP_FLAGS=--forall=all (L122).
#  - D8: such negative controls (H2, H3) also set ORBIT_KB_SCASP_GROUND=raw. The H1 bad forms
#    (X4, X7) run in both modes; in ground mode they must print the raw-fallback NOTE.
#    The doctor lines for the new D8 controls are found by /H4.*ground/ and /corrupt/.
set -u

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
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
    printf 'test_orbit_kb.sh: ORBIT_KB_TEST_JOBS must be a positive integer, got "%s"\n' "${ORBIT_KB_TEST_JOBS:-}" >&2
    exit 2
fi
# Tests that run alone in a parallel run (an ERE on the test id; empty: none). No test needs
# it now. The time limits are the CLI's 20 s for s(CASP) (ORBIT_KB_SCASP_TIMEOUT, which the
# suite does not set), 10 s for the SWI engine, and $TMO per call here. Under 1.5x to 2x CPU
# overload (14 workers next to 7 or 14 busy loops), all tests passed in 4 of 4 runs, the
# slowest s(CASP) process took 6 s, and doctor (DR1, DR2) took 1.7 s at most. GD (D8, 20 claims
# x 2 runs, the default 20 s s(CASP) limit) passed with 8 workers next to 14 busy loops. In raw
# mode the same query times out, so a slow grounder shows up in GD as CROSS-CHECK SKIPPED.
SERIAL=''
# D8: the grounder's fallback line. NOTE_RAW for "must not appear" checks; NOTE_RAW_RE, at the
# start of a stderr line and with a reason after the colon, for "must appear" checks.
NOTE_RAW='NOTE: s\(CASP\) ran the raw program'
NOTE_RAW_RE='^NOTE: s\(CASP\) ran the raw program: .*[^ ]'

# ---------------------------------------------------------------- preconditions
if [ ! -f "$OKB" ] || [ ! -x "$OKB" ]; then
    printf 'test_orbit_kb.sh: the orbit-kb CLI is missing or is not executable: %s\n' "$OKB" >&2
    printf '  Check the repo copy (kb/bin/orbit-kb), or pass its path as the first argument.\n' >&2
    exit 2
fi
OKB=$(cd "$(dirname "$OKB")" && pwd -P)/$(basename "$OKB")
if [ -d "$LIB" ]; then LIB=$(cd "$LIB" && pwd -P); fi
if [ ! -f "$LIB/core.pl" ]; then
    printf 'test_orbit_kb.sh: the library is missing (no core.pl in %s)\n' "$LIB" >&2
    printf '  Build it first, or set ORBIT_KB_TEST_LIB to a library directory.\n' >&2
    exit 2
fi
for tool in swipl scasp sha256sum timeout mktemp awk grep sed diff cmp sort head wc cp mv; do
    command -v "$tool" >/dev/null 2>&1 || { printf 'test_orbit_kb.sh: required tool not found: %s\n' "$tool" >&2; exit 2; }
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
# caller (ORBIT_KB, ORBIT_KB_SCASP_FLAGS, a cache switch, ...) reaches it, the suite sets
# ORBIT_KB_LIB, and each test sets its own XDG_CACHE_HOME (exec_test).
for v in $(compgen -e); do case $v in ORBIT_KB*) unset "$v";; esac; done
export ORBIT_KB_LIB="$LIB"

# ---------------------------------------------------------------- kbq: read kb.pl semantically
# kbq FILE GOAL: read every term of FILE (s(CASP) operators on), then run GOAL.
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
            p.*) proto_ensure "${t#p.}" ;;
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
    [ -n "${ONLY:-}" ] || TASKS+=(p.mkclaim.build p.h3)
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

# ---------------------------------------------------------------- prototypes (see the header)
# A prototype is the state that a setup function leaves in a fresh $T: the KB, $T/.out and
# $T/.err of the last CLI call, rc, K, and any notes. It is built once, in $base/proto/NAME/t,
# by the same function and the same CLI calls as before, with its own XDG_CACHE_HOME. Then
# every test copies it into its own $T. Run logs and attest times keep the time of the build.
setup_run() {  # setup_run NAME: run the setup that prototype NAME stands for, in $T
    case $1 in
        mkclaim.*) mkclaim_fresh "${1#mkclaim.}" ;;
        h3)        h3_kb_fresh ;;
        lake)      lake_fresh ;;
        *)         note "setup: there is no prototype $1"; return 1 ;;
    esac
}
proto_build() {  # proto_build NAME (in a subshell): run setup NAME in $base/proto/NAME/t, as a test does
    local p=$base/proto/$1
    mkdir -p "$p/t" "$p/cache" || return 1
    T=$p/t; K=""; FAILS=(); out=""; err=""; rc=0
    XDG_CACHE_HOME=$p/cache; export XDG_CACHE_HOME
    cd "$T" || return 1
    setup_run "$1"
    printf '%s\n' "${K#"$T"}" > "$p/k"
    printf '%s\n' "$rc" > "$p/rc"
    : > "$p/notes"; if [ ${#FAILS[@]} -gt 0 ]; then printf '%s\n' "${FAILS[@]}" > "$p/notes"; fi
    : > "$p/ok"
}
proto_ensure() {  # proto_ensure NAME: build prototype NAME once. Other callers wait for the build.
    local p=$base/proto/$1 limit=$((SECONDS + 12 * TMO))   # a build makes at most 10 CLI calls
    [ -e "$p.done" ] && return 0
    if grab "$p.claim"; then
        ( proto_build "$1" ) >"$p.log" 2>&1 </dev/null &
        CUR=$!; wait "$CUR"; CUR=""
        : > "$p.done"
    else
        while [ ! -e "$p.done" ] && [ "$SECONDS" -lt "$limit" ]; do sleep 0.05; done
    fi
}
use_proto() {  # use_proto NAME: leave in $T what setup NAME leaves there, copied from its prototype
    local p=$base/proto/$1 k m
    proto_ensure "$1"
    if [ ! -e "$p/ok" ]; then setup_run "$1"; return; fi   # no complete prototype: do the setup here
    cp -R "$p/t/." "$T/" || { note "setup: cannot copy the prototype $1"; return 1; }
    read -r k < "$p/k"; K=$T$k; read -r rc < "$p/rc"
    out=$(<"$T/.out"); err=$(<"$T/.err")
    out=${out//"$p/t"/$T}; err=${err//"$p/t"/$T}   # for example "run ... log=PATH" names the KB
    while IFS= read -r m; do note "$m"; done < "$p/notes"
}

# ================================================================ KB builders (answers validated against the contract rules)
kb_intro() { kb_new "$1" <<'EOF'
uses([build]).
request(r1, 'Add saving and keep loading fast').
claim(c1, introduce, 'The widget can be saved').
claim(c2, preserve, 'Loading stays fast').
cites(c1, 'Add saving').
cites(c2, 'keep loading fast').
check(k1, c1).
check(k2, c2).
EOF
}
kb_overunder() { kb_new "$1" <<'EOF'
uses([build]).
request(r1, 'Change things').
claim(c1, introduce, 'Claim one').
claim(c2, preserve, 'Claim two').
cites(c1, 'Change things').
cites(c2, 'Change things').
check(k2, c2).
change(x1, 'A change that serves claim two').
change(x2, 'A change that serves nothing').
change(x3, 'A change that serves claim one').
serves(x1, c2).
serves(x3, c1).
EOF
    add_result "$1" k2 1 pass
}
kb_done() { kb_new "$1" <<'EOF'
uses([build]).
request(r1, 'Do two things').
claim(c1, preserve, 'One stays true').
claim(c2, introduce, 'Two becomes true').
cites(c1, 'Do two things').
cites(c2, 'Do two things').
check(k1, c1).
check(k2, c2).
change(x1, 'Edit one').
change(x2, 'Edit two').
serves(x1, c1).
serves(x2, c2).
question(q1, c1, 'Is it one').
assumed(q1, yes).
EOF
    add_result "$1" k1 1 pass; add_result "$1" k2 2 fail; add_result "$1" k2 3 pass
}
kb_burn() { kb_new "$1" <<'EOF'
uses([build]).
request(r1, 'Burn tests').
claim(c1, preserve, 'Contested twice').
claim(c2, preserve, 'Contested once').
claim(c3, preserve, 'Universal').
claim(c4, preserve, 'Burn requested').
claim(c5, preserve, 'Plain').
cites(c1, 'Burn tests').
cites(c2, 'Burn tests').
cites(c3, 'Burn tests').
cites(c4, 'Burn tests').
cites(c5, 'Burn tests').
universal(c3).
burn_requested(c4).
attest(d1, divergence, c1, claim(c1), agent, '2026-10-15T10:00:01Z').
attest(d2, divergence, c1, claim(c1), human, '2026-10-15T10:00:02Z').
attest(d3, divergence, c2, claim(c2), agent, '2026-10-15T10:00:03Z').
EOF
}
kb_burndone() {  # kb_burndone DIR: kb_done plus universal(c1), so c1 needs a Lean proof (D10)
    kb_done "$1"; printf "universal(c1).\n" >> "$1/kb.pl"
}
# D10: a lean_proof attestation and its log, as orbit-kb prove writes them. The proof
# file is DIR/lean/P.lean. The digest covers the claim, theorem, module, and statement
# lines and the one file (contract D10 follow-up: "claim C", "theorem T", "module M",
# "statement S", then "SHA PATH" per file, then "absent PATH" per absent config file).
add_proof() {  # add_proof DIR ID CLAIM [TIME]
    local d=$1 id=$2 c=$3 tm=${4:-2026-10-15T11:00:00Z} sha dg
    mkdir -p "$d/runs" "$d/lean"; [ -f "$d/lean/P.lean" ] || printf 'theorem t : True := trivial\n' > "$d/lean/P.lean"
    sha="sha256:$(sha "$d/lean/P.lean")"
    dg="sha256:$(printf 'claim %s\ntheorem t\nmodule P\nstatement True\n%s %s\n' "$c" "$sha" P.lean | sha256sum | cut -d' ' -f1)"
    printf '%% orbit-kb prove claim=%s digest=%s\ntheorem t\nmodule P\nsource P.lean\nstatement True\nlean 4.35.0\ntime %s\nroot lean\nfile %s P.lean\n--- lake build output\n' "$c" "$dg" "$tm" "$sha" > "$d/runs/proof-$id.log"
    printf "attest(%s, lean_proof, %s, proof(%s, '%s'), script, '%s').\n" "$id" "$c" "$c" "$dg" "$tm" >> "$d/kb.pl"
}
kb_toask() { kb_new "$1" <<'EOF'
uses([build]).
request(r1, 'Ask things').
claim(c1, preserve, 'Claim one').
cites(c1, 'Ask things').
question(q1, c1, 'Is it a').
question(q2, c1, 'Is it b').
assumed(q1, yes).
assumed(q2, no).
depends(q2, q1).
EOF
}
kb_super() { kb_new "$1" <<'EOF'
uses([build]).
request(r1, 'Replace a claim').
claim(c1, preserve, 'The old claim').
claim(c2, preserve, 'The new claim').
cites(c1, 'Replace a claim').
cites(c2, 'Replace a claim').
supersedes(c2, c1).
EOF
}
kb_q() { kb_new "$1" <<'EOF'
uses([build]).
request(r1, 'Query things').
claim(c1, preserve, 'One').
claim(c2, preserve, 'Two').
claim(c3, retire, 'Three').
cites(c1, 'Query things').
cites(c2, 'Query things').
cites(c3, 'Query things').
check(k1, c1).
change(x1, 'Edit').
serves(x1, c1).
serves(x1, c2).
EOF
}
kb_h2() { kb_new "$1" <<'EOF'
uses([]).
decl(fact, finding(id, atom, atom), 'A finding.', '').
decl(fact, about_system(atom), 'A system.', '').
decl(rule, finding_lead(atom), 'A finding that is a lead.', '').
decl(rule, finding_confirmed(atom), 'A finding that a script confirmed.', '').
finding(f1, sys, model).
about_system(sys).
attest(a1, other, foo, x, agent, t1).
attest(a2, reproduction, other, confirms(f9), script, t2).
attest(a4, reproduction, sys, confirms(f1), script, t4).
EOF
    cat > "$1/rules.pl" <<'EOF'
finding_lead(F) :- finding(F, K, model), about_system(K), not finding_confirmed(F).
finding_confirmed(F) :- attest(_, reproduction, _, confirms(F), _, _).
EOF
}
kb_wn() { kb_new "$1" <<'EOF'
uses([build]).
request(r1, 'Explain things').
claim(c1, preserve, 'Claim one').
cites(c1, 'Explain things').
world(door_closed).
-world(door_open).
EOF
}
kb_init() {  # kb_init DIR [uses]: a KB made by the CLI itself
    okb init "$1" --request 'Test request' --uses "${2:-build}" >/dev/null 2>&1 || note "setup: init failed: $(snip "$err")"
}
oadd() { okb --dir "$K" add "$@"; }
mkclaim() { use_proto "mkclaim.${1:-build}"; }   # standard small KB in $K made through the CLI
mkclaim_fresh() {  # the setup behind mkclaim. It runs once per suite, in a prototype (use_proto).
    K=$T/kb; kb_init "$K" "${1:-build}"
    oadd "claim(c1, introduce, 'The widget can be saved')" "cites(c1, 'Add saving')" "check(k1, c1)" >/dev/null 2>&1 || note "setup: add failed: $(snip "$err")"
}
orun() { okb --dir "$K" run "$@"; }
valid_copy() { copy_fixture valid "$T/kb"; K=$T/kb; }
lint_codes() { printf '%s\n' "$out" | grep -oE '^[EW][0-9]+' | sort -u | paste -sd' '; }

# ================================================================ K: KB resolution
t_K1() { valid_copy; okb --dir "$K" query 'current(c1)'; rc_is 0; out_has '^true'; }
t_K2() { valid_copy; ORBIT_KB="$K" okb_env query 'current(c1)'; rc_is 0; out_has '^true'; }
okb_env() { ( cd "$T" && ORBIT_KB="$ORBIT_KB" exec timeout "$TMO" "$OKB" "$@" ) >"$T/.out" 2>"$T/.err" </dev/null; rc=$?; out=$(<"$T/.out"); err=$(<"$T/.err"); }
t_K3() { valid_copy; mkdir -p "$K/runs/deep"; okb_in "$K/runs/deep" query 'current(c1)'; rc_is 0 "walk from a subdirectory"; out_has '^true'
         okb_in "$K" query 'current(c1)'; rc_is 0 "walk from the KB directory itself"; }
t_K4() { mkdir -p "$T/empty/sub"; okb_in "$T/empty/sub" query 'true'; rc_is 2; any_has '[-]-dir'; any_has 'ORBIT_KB'; any_hasi 'parent|walk|kb\.pl'; }
t_K5() { mkdir -p "$T/x"; printf 'request(r1, a).\nuses([]).\n' > "$T/x/kb.pl"; okb_in "$T/x" query 'true'; rc_is 2 "kb.pl whose first term is not uses/1 is no KB"; }
t_K6() { valid_copy; mkdir -p "$T/other"; okb_in "$T/other" --dir "$K" query 'current(c1)'; rc_is 0 "--dir wins over the cwd";
         mkdir -p "$T/kb2"; printf 'uses([]).\n' > "$T/kb2/kb.pl"
         ORBIT_KB="$T/kb2" okb_env --dir "$K" query 'current(c1)'; rc_is 0 "--dir wins over \$ORBIT_KB"; }
t_K7() { okb --dir "$T/does-not-exist" query 'true'; rc_is 2 "--dir without a KB"; }
t_K9() { valid_copy; mkdir -p "$T/proj" && cp -r "$K" "$T/proj/kb"; okb_in "$T/proj" query 'current(c1)'
         rc_is 2 "a KB below is not used on its own"; any_has '[-]-dir kb' "the message names the KB below"
         mkdir -p "$T/proj2/a/b/c" && cp -r "$K" "$T/proj2/a/b/c/kb"; okb_in "$T/proj2" query 'true'
         rc_is 2; any_hasnt 'a/b/c' "three levels down is not searched"; }
t_K8() { okb; rc_is 2 "no arguments"; okb frobnicate; rc_is 2 "unknown command"; }

# ================================================================ I: init
t_I1() { K=$T/new; okb init "$K" --request 'Make it fast'; rc_is 0; any_hasf "$K"; [ -f "$K/kb.pl" ] || note "kb.pl was not created"
         has_goal "$K/kb.pl" "findall(T, kb(T), [uses(U)|_]), is_list(U)" "first term is uses/1"
         has_fact "$K/kb.pl" "request(r1, 'Make it fast')" "request fact"; }
t_I2() { K=$T/new; okb init "$K" --request 'a'; rc_is 0 first; cp "$K/kb.pl" "$T/.b"; okb init "$K" --request 'b'; rc_is 1 second; same_file "$K/kb.pl" "$T/.b" "kb.pl after the rejected init"; }
t_I3() { K=$T/new; okb init "$K" --request a --uses build; rc_is 0; has_fact "$K/kb.pl" "uses([build])"; okb --dir "$K" query 'any_under'; rc_not 2 "build predicates are usable"; }
t_I4() { K=$T/new; okb init "$K" --request a --id req9; rc_is 0; has_fact "$K/kb.pl" "request(req9, a)"; }
t_I5() { K=$T/new; printf 'Words from a file\n' > "$T/req.txt"; okb init "$K" --request-file "$T/req.txt"; rc_is 0; has_goal "$K/kb.pl" "kb(request(r1, T)), sub_atom(T, _, _, _, 'Words from a file')"; }
t_I6() { K=$T/new; okb init "$K" --request "it's \"quoted\" ok"; rc_is 0; has_fact "$K/kb.pl" "request(r1, 'it\\'s \"quoted\" ok')" "quotes survive"; okb --dir "$K" lint; rc_is 0 "lint of a fresh KB"; }
t_I7() { K=$T/new; okb init "$K"; rc_is 2 "init without a request is a usage error"; [ -e "$K/kb.pl" ] && note "kb.pl exists after a usage error"; }
t_I8() { K=$T/new; okb init "$K" --request a; okb --dir "$K" lint; rc_is 0 "a fresh KB has no lint error"; okb --dir "$K" query 'current(X)'; rc_is 1 "no claims yet"; }

# ================================================================ U: uses
t_U1() { K=$T/k; kb_init "$K" discovery; oadd "claim(c1, introduce, 'Floor')" "cites(c1, 'floor')" >/dev/null
         rejects nobuild 'change/2' add "change(x1, 'Edit')"
         sed 1d "$K/kb.pl" > "$T/.tail.before"
         okb --dir "$K" uses build; rc_is 0; out_has '^uses\(\[discovery, ?build\]\)\.$'
         head -1 "$K/kb.pl" | grep -Eq '^uses\(\[discovery, ?build\]\)\.$' || note "line 1: $(head -1 "$K/kb.pl")"
         sed 1d "$K/kb.pl" > "$T/.tail.after"; same_file "$T/.tail.before" "$T/.tail.after" "the rest of kb.pl"
         oadd "change(x1, 'Edit')"; rc_is 0 "a build fact after uses build"; okb --dir "$K" lint; rc_is 0; }
t_U2() { K=$T/k; kb_init "$K" build; cp "$K/kb.pl" "$T/.kb.before"
         okb --dir "$K" uses build; rc_is 0; out_has 'already uses'; same_file "$K/kb.pl" "$T/.kb.before" "nothing written" ; }
t_U3() { K=$T/k; kb_init "$K" build; rejects unknown 'biuld' uses biuld
         okb --dir "$K" uses; rc_is 2 "no module named"; }
t_U4() { K=$T/k; kb_init "$K" build; rejects usesfact 'orbit-kb uses' add "uses([build, discovery])"
         okb --dir "$K" uses discovery; rc_is 0; head -1 "$K/kb.pl" | grep -Eq '^uses\(\[build, ?discovery\]\)\.$' || note "the order is kept: $(head -1 "$K/kb.pl")"; }

t_U5() { # a comment before the term and text between the term and its full stop are kept; the result parses
         K=$T/k; mkdir -p "$K"; printf '%% Discovery KB\nuses([discovery]) /* modules */ .\nrequest(r1, a).\n' > "$K/kb.pl"
         okb --dir "$K" uses build; rc_is 0
         printf '%% Discovery KB\nuses([discovery, build]) /* modules */ .\nrequest(r1, a).\n' > "$T/.want"; same_file "$K/kb.pl" "$T/.want" "kb.pl"
         okb --dir "$K" lint; rc_is 0 "the rewritten kb.pl parses"; }
t_U6() { # a first term that is not uses([atoms]) is exit 1, and kb.pl does not change
         K=$T/k; mkdir -p "$K"; local u
         for u in "request(r1, a)." "uses([discovery, f(x)])." "uses([discovery, \"build\"])."; do
             printf '%s\nclaim(c1, preserve, x).\n' "$u" > "$K/kb.pl"; cp "$K/kb.pl" "$T/.kb.before"
             okb --dir "$K" uses build; rc_is 1 "first term $u"; same_file "$K/kb.pl" "$T/.kb.before" "kb.pl after $u"
         done; }
t_U7() { # duplicate names and the comma form give each module once; an option is a usage error
         K=$T/k; kb_init "$K" discovery; okb --dir "$K" uses build build build,discovery; rc_is 0
         head -1 "$K/kb.pl" | grep -Eq '^uses\(\[discovery, ?build\]\)\.$' || note "line 1: $(head -1 "$K/kb.pl")"
         okb --dir "$K" uses -- build; rc_is 2 "-- is not a module"
         okb --dir "$K" uses build -h; rc_is 0 "help anywhere"; out_has 'orbit-kb uses MODULE'; }
t_U8() { # uses holds the KB lock: while another process holds kb.lock, uses waits and writes nothing
         command -v flock >/dev/null 2>&1 || { skip_test "flock is missing"; return 0; }
         K=$T/k; kb_init "$K" discovery; touch "$K/kb.lock"
         flock -x "$K/kb.lock" -c 'sleep 2' & local hold=$!; sleep 0.3
         ( cd "$T" && exec timeout "$TMO" "$OKB" --dir "$K" uses build ) >"$T/.u" 2>&1 </dev/null & local u=$!
         sleep 1; head -1 "$K/kb.pl" | grep -q build && note "uses wrote kb.pl while another process held the lock"
         wait "$hold"; wait "$u" || note "uses exited $?: $(snip "$(<"$T/.u")")"
         head -1 "$K/kb.pl" | grep -Eq '^uses\(\[discovery, ?build\]\)\.$' || note "line 1 after the lock: $(head -1 "$K/kb.pl")"; }
t_U9() { # the new module can add lint findings, so uses tells the agent to lint
         K=$T/k; kb_init "$K" build
         oadd "claim(c1, preserve, 'Old')" "cites(c1, 'x')" "claim(c2, preserve, 'New')" "cites(c2, 'x')" "supersedes(c2, c1)" >/dev/null
         echo x > "$K/s.txt"; okb --dir "$K" subject s1 "$K/s.txt" >/dev/null; okb --dir "$K" attest divergence s1 'claim(c1)' >/dev/null
         okb --dir "$K" lint; rc_is 0 "clean before"
         okb --dir "$K" uses discovery; rc_is 0; any_has 'orbit-kb lint' "uses says to lint"
         okb --dir "$K" lint; rc_is 1 "ED7 after uses discovery"; out_has '^ED7'; }

# ================================================================ A: add
t_A1() { mkclaim; oadd "claim(c2, preserve, 'Loading stays fast')" "cites(c2, 'fast')"; rc_is 0; any_has 'claim\(c2'; any_has 'cites\(c2'
         fact_count "$K/kb.pl" "claim(_,_,_)" 2; has_goal "$K/kb.pl" "kb_line(A, claim(c2,_,_)), kb_line(B, cites(c2,_)), A < B" "order"; }
t_A2() { mkclaim; rejects undeclared 'declare' add "gadget(g1, a)"; any_hasf 'orbit-kb declare'; }
t_A3() { mkclaim; rejects undeclared 'declare' add "gadget(g1, a)"
         okb --dir "$K" declare 'gadget(id, text)' --doc 'A gadget.'; rc_is 0 declare
         oadd "gadget(g1, a)"; rc_is 0 "after declare"; has_fact "$K/kb.pl" "gadget(g1, a)"; }
t_A4() { mkclaim; rejects oneof 'oneof|bogus|label|one of' add "claim(c2, bogus, x)"; any_has '^E3|E3'; }
t_A5() { mkclaim; rejects dangling 'ref|c9|exist|dangl' add "cites(c9, 'no such claim')"; }
t_A6() { mkclaim; rejects duplicate 'duplicate|unique|already|c1' add "claim(c1, preserve, 'again')"; }
t_A7() { mkclaim; rejects nonground 'ground|variable' add "world(foo(X))"; }
t_A8() { mkclaim; rejects rulepred 'rule|computed|fact for' add "fulfilled(c1)"; }
t_A9() { mkclaim; rejects scripttype 'run' add "attest(a1, test_result, k1, result(k1, 1, pass), script, '2026-10-15T10:00:00Z')"; any_hasf 'orbit-kb run'; }
t_A10() { mkclaim; rejects batch 'cites|c9|ref|exist' add "claim(c2, preserve, 'ok')" "cites(c9, 'dangling')" "risk(rk1, 'ok')"
          no_fact "$K/kb.pl" "claim(c2,_,_)" "the good fact before the bad one"; no_fact "$K/kb.pl" "risk(rk1,_)" "the good fact after the bad one"; }
t_A11() { mkclaim; oadd "cites(c2, 'x')" "claim(c2, preserve, 'later in the batch')"; rc_is 0 "facts in a batch may refer to each other"; has_fact "$K/kb.pl" "cites(c2, x)"; }
t_A12() { mkclaim; oadd "risk(rk1, 'a')." "risk(rk2, 'b')"; rc_is 0; has_fact "$K/kb.pl" "risk(rk1, a)"; has_fact "$K/kb.pl" "risk(rk2, b)"; }
t_A13() { mkclaim; oadd "-world(door_open)"; rc_is 0 "a ground negative fact"; has_fact "$K/kb.pl" "-world(door_open)"; }
t_A14() { mkclaim; rejects arity '' add "claim(c2, preserve)"; any_has 'E2|arity|claim/3|declared'; }
t_A15() { mkclaim; rejects syntax '' add "claim(c2 preserve, x)"; }
t_A16() { mkclaim; rejects badtime '' add "attest(a1, disclosure, c1, unverified(x), agent, 'yesterday')"; }
t_A17() { mkclaim; rejects badwriter 'writer|allow|agent|human' add "attest(a1, disproof, c1, verdict(c1, refuted('x fails')), human, '2026-10-15T10:00:00Z')"; }

# ================================================================ D: declare
t_D1() { mkclaim; okb --dir "$K" declare 'gizmo(id, text)' --doc 'A gizmo.' --template '@(1) is a gizmo called @(2)'; rc_is 0
         has_goal "$K/kb.pl" "kb(decl(fact, gizmo(id, text), _, T)), sub_atom(T, _, _, _, '@(1)')" "decl/4 line with the template"; }
t_D2() { mkclaim; okb --dir "$K" declare 'gizmo(id, text)' --doc 'A gizmo.'; rc_is 0 first; cp "$K/kb.pl" "$T/.b"
         okb --dir "$K" declare 'gizmo(id, text)' --doc 'Again.'; rc_is 1 second; same_file "$K/kb.pl" "$T/.b"; }
t_D3() { mkclaim; rejects badtype 'type|unknown|banana' declare 'gizmo(banana)' --doc 'x'; }
t_D4() { mkclaim; okb --dir "$K" declare 'claim(id)' --doc 'x'; rc_is 0 "claim/1 is a new predicate: only an exact name and arity match is rejected"
         has_fact "$K/kb.pl" "decl(fact, claim(id), _, _)" "decl line for claim/1"
         cp "$K/kb.pl" "$T/.b"; okb --dir "$K" declare 'claim(id, text, text)' --doc 'x'; rc_is 1 "same name and arity as the core claim/3"; same_file "$K/kb.pl" "$T/.b"; }
t_D5() { mkclaim; okb --dir "$K" declare-attest reading 'level(text, int)' --doc 'A reading.' --writers human,agent; rc_is 0
         okb --dir "$K" attest reading c1 'level(speed, 5)'; rc_is 0 "attest of the new type"; has_fact "$K/kb.pl" "attest(_, reading, c1, level(speed, 5), agent, _)"
         okb --dir "$K" declare-attest reading 'level(text, int)' --doc 'again' --writers human; rc_is 1 "duplicate type"; }
t_D6() { mkclaim; okb --dir "$K" declare 'okay(ref(claim))' --doc 'A computed thing.' --kind rule; rc_is 0; has_fact "$K/kb.pl" "decl(rule, okay(ref(claim)), _, _)"
         rejects rulefact 'rule' add "okay(c1)"; }

# ================================================================ AT: attest
t_AT1() { mkclaim; okb --dir "$K" attest disclosure c1 "unverified('Not measured')"; rc_is 0; any_has 'a1'
          has_fact "$K/kb.pl" "attest(a1, disclosure, c1, unverified('Not measured'), agent, _)"
          local t; t=$(kbq "$K/kb.pl" "kb(attest(a1,_,_,_,_,T)), write(T)")
          [[ $t =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]] || note "time is not YYYY-MM-DDTHH:MM:SSZ: '$t'"
          local e n; e=$(date -u -d "$t" +%s 2>/dev/null || echo 0); n=$(date -u +%s)
          [ $((n - e)) -ge -5 ] && [ $((n - e)) -le 180 ] || note "time '$t' is not now (UTC)"; }
t_AT2() { mkclaim; okb --dir "$K" attest disclosure c1 "unverified(a)"; okb --dir "$K" attest disclosure c1 "unverified(b)"; rc_is 0
          has_fact "$K/kb.pl" "attest(a1, disclosure, _, unverified(a), _, _)"; has_fact "$K/kb.pl" "attest(a2, disclosure, _, unverified(b), _, _)" "next free number"; }
t_AT3() { mkclaim; mkdir -p "$K"; echo hi > "$K/plan.txt"; okb --dir "$K" subject s1 plan.txt >/dev/null
          cp "$K/kb.pl" "$T/.b"; okb --dir "$K" attest approval s1 'digest(current)' --by agent; rc_is 1 "approval by agent"; any_hasi 'writer|allow|human'; same_file "$K/kb.pl" "$T/.b"; }
t_AT4() { mkclaim; echo hi > "$K/plan.txt"; local d; okb --dir "$K" subject s1 plan.txt >/dev/null; d=$(sha "$K/plan.txt")
          okb --dir "$K" attest approval s1 'digest(current)' --by human; rc_is 0; has_fact "$K/kb.pl" "attest(_, approval, s1, digest('sha256:$d'), human, _)" "digest(current) replaced"
          no_fact "$K/kb.pl" "attest(_,_,_,digest(current),_,_)" "the literal current"; }
t_AT5() { mkclaim; rejects dangling 'ref|s9|exist|subject' attest disclosure s9 "unverified(a)"; }
t_AT6() { mkclaim; okb --dir "$K" attest disclosure c1 "unverified(a)" --id myid; rc_is 0; has_fact "$K/kb.pl" "attest(myid, disclosure, c1, unverified(a), agent, _)"
          rejects dupid 'duplicate|already|myid' attest disclosure c1 "unverified(b)" --id myid; }
t_AT7() { mkclaim; rejects shape 'shape|type|expected|E3' attest disclosure c1 "nonsense(1)"; }
t_AT8() { mkclaim; rejects scripttype 'run|script|writer' attest test_result k1 'result(k1, 1, pass)'; }
t_AT9() { mkclaim; okb --dir "$K" attest disclosure c1 "guess(q9)"; rc_is 1 "dangling ref inside the predicate"; }

# ================================================================ S: subject
t_S1() { mkclaim; printf 'one\n' > "$K/plan.txt"; okb --dir "$K" subject s1 plan.txt; rc_is 0; local d; d=$(sha "$K/plan.txt")
         any_hasf "$d" "printed digest"; has_fact "$K/kb.pl" "subject(s1, _, 'sha256:$d')"; }
t_S2() { mkclaim; mkdir -p "$K/docs"; printf 'one\n' > "$K/docs/plan.txt"; okb --dir "$K" subject s1 "$K/docs/plan.txt"; rc_is 0
         has_fact "$K/kb.pl" "subject(s1, 'docs/plan.txt', _)" "inside the KB directory: relative path (D3)"; }
t_S3() { mkclaim; local f=$T/outside.txt; printf 'x\n' > "$f"; okb --dir "$K" subject s1 "$f"; rc_is 0; has_fact "$K/kb.pl" "subject(s1, '$f', _)" "outside the KB: absolute path"; }
t_S4() { mkclaim; cp "$K/kb.pl" "$T/.b"; okb --dir "$K" subject s1 nope.txt; rc_is 1; same_file "$K/kb.pl" "$T/.b"; }
t_S5() { mkclaim; printf 'one\n' > "$K/a.txt"; printf 'two\n' > "$K/b.txt"; okb --dir "$K" subject s1 a.txt >/dev/null; okb --dir "$K" subject s2 b.txt >/dev/null
         oadd "risk(rk1, 'after the subjects')" >/dev/null; cp "$K/kb.pl" "$T/.before"
         printf 'changed\n' > "$K/a.txt"; okb --dir "$K" subject s1 a.txt; rc_is 0 refresh
         fact_count "$K/kb.pl" "subject(s1,_,_)" 1 "no duplicate subject line"; local d; d=$(sha "$K/a.txt"); has_fact "$K/kb.pl" "subject(s1, _, 'sha256:$d')" "new digest"
         # every other term unchanged, and the order is unchanged
         local a b; a=$(kbq "$T/.before" "findall(T, (kb(T), T \\= subject(s1,_,_)), L), print(L)"); b=$(kbq "$K/kb.pl" "findall(T, (kb(T), T \\= subject(s1,_,_)), L), print(L)")
         [ -n "$a" ] && [ "$a" = "$b" ] || note "other terms changed by the refresh"
         has_goal "$K/kb.pl" "kb_line(L1, subject(s1,_,_)), kb_line(L2, subject(s2,_,_)), L1 < L2" "refreshed in place (still before s2)"; }
t_S6() { # D3: a KB directory moved to a new place keeps W1 and digest(current) working with no refresh
         mkclaim; printf 'one\n' > "$K/plan.txt"; okb --dir "$K" subject s1 plan.txt >/dev/null; mv "$K" "$T/moved"; K=$T/moved
         okb --dir "$K" lint; rc_is 0 "lint after the move"; any_hasnt '^W1' "no W1 after the move"
         okb --dir "$K" attest approval s1 'digest(current)' --by human; rc_is 0 "digest(current) after the move"; }
t_S7() { # D3 on the fixture: copying the valid fixture elsewhere keeps it clean
         valid_copy; mv "$K" "$T/elsewhere"; okb --dir "$T/elsewhere" lint --strict; rc_is 0 "valid fixture, copied, strict"; any_hasnt '^W1'; }
t_S8() { mkclaim; printf 'one\n' > "$K/plan.txt"; okb --dir "$K" subject s1 plan.txt >/dev/null; okb --dir "$K" subject s1 plan.txt >/dev/null; rc_is 0 "refresh without a change"
         fact_count "$K/kb.pl" "subject(s1,_,_)" 1; }

# ================================================================ R: run
t_R1() { mkclaim; orun k1 -- false; rc_is 1; any_has 'run 1 k1 fail'; has_fact "$K/kb.pl" "attest(_, test_result, k1, result(k1, 1, fail), script, _)"
         orun k1 -- true; rc_is 0; any_has 'run 2 k1 pass'; has_fact "$K/kb.pl" "attest(_, test_result, k1, result(k1, 2, pass), script, _)"; }
t_R2() { mkclaim; orun k1 -- sh -c 'echo hello-output; exit 3'; rc_is 1 "a nonzero command exit is a fail"; any_has 'exit 3|exit=3'; any_hasf hello-output "tail of the output on a fail"
         local f; f=$(ls "$K"/runs/1-k1.log 2>/dev/null); [ -n "$f" ] || { note "runs/1-k1.log is missing"; return; }
         head -n1 "$f" | grep -Eq '^% orbit-kb run 1 check=k1 result=fail exit=3 time=[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]+Z cmd=' || note "header is wrong: $(head -n1 "$f")"
         grep -q hello-output "$f" || note "the log lacks the command output"; }
t_R3() { mkclaim; orun k1 -- true; rc_is 0; head -n1 "$K/runs/1-k1.log" | grep -Eq '^% orbit-kb run 1 check=k1 result=pass exit=0 time=[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]+Z cmd=true' || note "header is wrong: $(head -n1 "$K/runs/1-k1.log")"
         okb --dir "$K" lint; rc_is 0 "a run made by the CLI passes lint (E9)"; any_hasnt '^E9'; }
t_R4() { mkclaim; cp "$K/kb.pl" "$T/.b"; orun nosuch -- true; rc_not 0; [ "$rc" = 2 ] || [ "$rc" = 1 ] || note "exit $rc"; any_hasi 'nosuch|check|exist'; same_file "$K/kb.pl" "$T/.b"; [ -e "$K/runs" ] && [ -n "$(ls -A "$K/runs")" ] && note "a log was written for an unknown check"; }
t_R5() { mkclaim; oadd "claim(c2, preserve, x)" "check(k2, c2)" >/dev/null; orun k1 -- true >/dev/null; orun k2 -- true; any_has 'run 2 k2 pass'; ls "$K/runs" | grep -q '^2-k2.log$' || note "run numbers are global per KB: want runs/2-k2.log, got $(ls "$K/runs" | paste -sd' ')"; }
t_R6() { mkclaim; orun k1 -- sh -c 'seq 1 100; exit 1'; rc_is 1; any_hasf 100 "last line"; any_hasf 61 "line 61 is in the last 40"; any_hasnt '^(1|20)$' "early lines are not in the tail"; }
t_R7() { # D1: core check/2 and test_result work with uses([])
         K=$T/kb; kb_init "$K" ""; oadd "claim(c1, introduce, 'x')" "cites(c1, 'y')" "check(k1, c1)" >/dev/null; orun k1 -- false >/dev/null; orun k1 -- true >/dev/null
         okb --dir "$K" query 'was_red(k1)'; rc_is 0 "was_red without the build module"; out_has '^true'; okb --dir "$K" query 'passed(k1)'; rc_is 0; }
t_R8() { mkclaim; orun k1 --; rc_is 2 "run without a command is a usage error"; }
t_R9() { mkclaim; orun k1 -- sh -c 'echo out; echo err >&2'; rc_is 0; grep -q out "$K/runs/1-k1.log" && grep -q err "$K/runs/1-k1.log" || note "the log must hold stdout and stderr"; }

# ================================================================ B: rules through query
t_B1() { kb_intro "$T/k"; K=$T/k; add_result $K k1 1 pass; is_false 'fulfilled(c1)'; is_true 'under(c1)'; is_false 'was_red(k1)'; is_true 'passed(k1)'; }
t_B2() { kb_intro "$T/k"; K=$T/k; add_result $K k1 1 fail; add_result $K k1 2 pass; is_true 'was_red(k1)'; is_true 'fulfilled(c1)'; is_false 'under(c1)'; }
t_B3() { kb_intro "$T/k"; K=$T/k; add_result $K k2 1 pass; is_true 'fulfilled(c2)'; is_false 'under(c2)'; is_false 'was_red(k2)'; }
t_B4() { kb_intro "$T/k"; K=$T/k; add_result $K k2 1 pass; add_result $K k2 2 fail; is_false 'passed(k2)'; is_false 'fulfilled(c2)'; is_true 'under(c2)'; }
t_B5() { kb_intro "$T/k"; K=$T/k; add_result $K k2 1 pass; add_result $K k2 2 fail; add_result $K k2 3 pass; is_true 'passed(k2)'; is_true 'fulfilled(c2)'; }
t_B6() { kb_intro "$T/k"; K=$T/k; add_result $K k1 1 fail; add_result $K k1 2 pass; add_result $K k1 3 fail; is_false 'fulfilled(c1)'; is_true 'under(c1)'; }
t_B7() { kb_intro "$T/k"; K=$T/k; add_result $K k2 1 pass; echo "attest(d1, disproof, c2, verdict(c2, refuted('save loses data')), agent, '2026-10-15T10:00:30Z')." >> $K/kb.pl
         is_true 'refuted(c2)'; is_false 'fulfilled(c2)'; is_true 'under(c2)'; }
t_B8() { kb_overunder "$T/k"; K=$T/k; is_set 'under(X)' 'X = c1'; is_set 'over(X)' 'X = x2'; is_set 'served(X)' 'X = x1|X = x3'; is_set 'fulfilled(X)' 'X = c2'; }
t_B9() { kb_done "$T/k"; K=$T/k; is_true "done"; is_false any_under; is_false any_over; is_false any_to_ask; }
t_B10() { kb_done "$T/k"; K=$T/k; printf "claim(c3, preserve, 'Unchecked').\ncites(c3, 'Do two things').\nserves(x2, c3).\n" >> $K/kb.pl; is_false "done"; is_true any_under; is_set 'under(X)' 'X = c3'; }
t_B11() { kb_done "$T/k"; K=$T/k; printf "change(x3, 'Unrelated').\n" >> $K/kb.pl; is_false "done"; is_true any_over; is_set 'over(X)' 'X = x3'; is_false any_under; }
t_B12() { kb_done "$T/k"; K=$T/k; printf "question(q2, c2, 'Is it two').\nassumed(q2, no).\ndepends(q2, q1).\nanswer(q1, no, human).\n" >> $K/kb.pl
          is_false "done"; is_true any_to_ask; is_set 'to_ask(X)' 'X = q2'; is_set 'defeated(X)' 'X = q1'; }
t_B13() { kb_burn "$T/k"; K=$T/k; is_set 'burn(X)' 'X = c1|X = c3|X = c4'; is_true 'burn(c1)'; is_false 'burn(c2)'; is_false 'burn(c5)'; is_set 'contested(X)' 'X = c1|X = c2'; is_set 'contested_twice(X)' 'X = c1'; }
t_B14() { kb_toask "$T/k"; K=$T/k; echo "answer(q1, no, human)." >> $K/kb.pl; is_set 'to_ask(X)' 'X = q2'; is_set 'defeated(X)' 'X = q1'; }
t_B15() { kb_toask "$T/k"; K=$T/k; echo "answer(q1, yes, human)." >> $K/kb.pl; is_false 'to_ask(X)'; is_false 'defeated(X)'; }
t_B16() { kb_toask "$T/k"; K=$T/k; echo "answer(q1, no, agent)." >> $K/kb.pl; is_false 'to_ask(X)'; is_false 'defeated(X)'; is_false 'answered(X)'; }
t_B17() { kb_toask "$T/k"; K=$T/k; echo "attest(d1, divergence, c1, claim(c1), agent, '2026-10-15T10:00:01Z')." >> $K/kb.pl; is_set 'to_ask(X)' 'X = q1|X = q2'
          echo "answer(q1, yes, human)." >> $K/kb.pl; is_set 'to_ask(X)' 'X = q2'; }
t_B18() { mkclaim; printf 'v1\n' > "$K/plan.txt"; okb --dir "$K" subject s1 plan.txt >/dev/null; okb --dir "$K" attest approval s1 'digest(current)' --by human >/dev/null
          is_false 'stale(X)'; printf 'v2\n' > "$K/plan.txt"; is_false 'stale(X)'
          okb --dir "$K" subject s1 plan.txt >/dev/null; is_set 'stale(X)' 'X = a1'; }
t_B19() { kb_super "$T/k"; K=$T/k; is_set 'superseded(X)' 'X = c1'; is_set 'current(X)' 'X = c2'; is_false 'current(c1)'; is_false 'under(c1)'; is_set 'under(X)' 'X = c2'; }
t_B20() { kb_done "$T/k"; K=$T/k; printf "claim(c3, retire, 'Three').\ncites(c3, 'Do two things').\nserves(x2, c3).\n" >> $K/kb.pl
          is_false "done" "done must be false while one claim is open among several facts (H1)"; add_result $K k3 4 pass; printf "check(k3, c3).\n" >> $K/kb.pl; is_false "done"; }

t_B21() { # D5: to_ask only asks questions whose claim is current
          kb_new "$T/k" <<'EOF2'
uses([build]).
request(r1, 'Replace a claim').
claim(c2, preserve, 'The old claim').
cites(c2, 'Replace a claim').
check(k1, c2).
question(q1, c2, 'Is it so').
attest(d1, divergence, c2, claim(c2), agent, '2026-10-15T10:00:01Z').
EOF2
          K=$T/k; add_result $K k1 1 pass
          is_true 'to_ask(q1)'; is_false "done"
          printf "claim(c2b, preserve, 'The new claim').\ncites(c2b, 'Replace a claim').\nsupersedes(c2b, c2).\ncheck(k2, c2b).\n" >> $K/kb.pl; add_result $K k2 2 pass
          is_false 'to_ask(q1)'; is_false 'any_to_ask'; is_true "done"; }
# H3: arithmetic under negation (passed/1)
h3_kb() { use_proto h3; }
h3_kb_fresh() {  # the setup behind h3_kb. It runs once per suite, in a prototype (use_proto).
    K=$T/kb; kb_init "$K" ""; oadd "claim(c1, preserve, 'The runs behave')" "cites(c1, 'x')" "check(k1, c1)" "check(k2, c1)" "check(k3, c1)" "check(k4, c1)" >/dev/null || note "setup failed: $(snip "$err")"
    local s
    for s in k1:true k1:false k2:false k2:true k3:true k4:true k4:false k4:true; do orun "${s%%:*}" -- "${s##*:}" >/dev/null 2>&1; done
}
t_H3a() { h3_kb; okb --dir "$K" query 'passed(K)' -n 0; rc_is 0; local got; got=$(printf '%s\n' "$out" | LC_ALL=C sort | paste -sd'|'); [ "$got" = "K = k2|K = k3|K = k4" ] || note "passed(K) answers [$got], want k2, k3, k4 (no k1, with k4)"
         ls "$K/runs" | grep -q '^8-k4.log$' || note "run numbers 1..8 expected, runs: $(ls "$K/runs" | paste -sd' ')"; }
t_H3b() { # the negative control runs on the raw program (D8): in ground mode H3 cannot occur
         h3_kb; ORBIT_KB_SCASP_GROUND=raw ORBIT_KB_SCASP_FLAGS=--forall=all okb --dir "$K" query 'passed(K)' -n 0; rc_is 2 "forall=all answers k1,k2,k3: wrong, and only the full-set comparison sees it"; any_hasf 'ENGINE DISAGREEMENT'; }
t_H3d() { # D8: ground mode (the default) under --forall=all gives the correct answer, with no disagreement
         h3_kb; ORBIT_KB_SCASP_FLAGS=--forall=all okb --dir "$K" query 'passed(K)' -n 0; rc_is 0
         local got; got=$(printf '%s\n' "$out" | LC_ALL=C sort | paste -sd'|'); [ "$got" = "K = k2|K = k3|K = k4" ] || note "passed(K) answers [$got], want exactly k2, k3, k4"
         any_hasnt 'ENGINE DISAGREEMENT' "no disagreement in ground mode"; any_hasnt "$NOTE_RAW" "the H3 program is a supported form: no raw fallback"
         ORBIT_KB_SCASP_FLAGS=--forall=all okb --dir "$K" query 'passed(k1)'; rc_is 1 "ground passed(k1) under --forall=all: pass, then fail is not passed"; any_hasnt 'ENGINE DISAGREEMENT'
         ORBIT_KB_SCASP_FLAGS=--forall=all okb --dir "$K" query 'passed(k4)'; rc_is 0 "ground passed(k4) under --forall=all"; any_hasnt 'ENGINE DISAGREEMENT'; }
t_H3c() { h3_kb; okb --dir "$K" query 'passed(k1)'; rc_is 1 "pass, then fail: not passed"; okb --dir "$K" query 'passed(k4)'; rc_is 0; }

# ================================================================ Q: query
t_Q1() { kb_q "$T/k"; K=$T/k; q 'fulfilled(c1)'; rc_is 1; any_hasnti 'error|disagree'; }
t_Q2() { kb_q "$T/k"; K=$T/k; q 'burn_requested(X)'; rc_is 1 "declared, empty"; any_hasnti 'error|undeclared|unknown'; }
t_Q3() { kb_q "$T/k"; K=$T/k; q 'nonesuch(X)'; rc_is 2; any_hasi 'nonesuch|declare'; q 'current(X), nonesuch(X)'; rc_is 2 "undeclared inside a conjunction"; }
t_Q4() { kb_q "$T/k"; K=$T/k; q 'current(X'; rc_is 2; q ''; rc_is 2 "empty goal"; }
t_Q5() { kb_q "$T/k"; K=$T/k; q 'current(c1)'; rc_is 0; [ "$(first_line)" = true ] || note "first line '$(first_line)', want true"
         q 'current(X)' -n 0; rc_is 0; out_has '^X = c1$'; out_has '^X = c3$'; q 'current(X)' ; rc_is 0; [ "$(printf '%s\n' "$out" | grep -c '^X = ')" = 1 ] || note "-n defaults to 1 answer: $(snip "$out")"; }
t_Q6() { kb_q "$T/k"; K=$T/k; q 'serves(X, Y)' -n 0; rc_is 0; out_has '^(X = x1, Y = c1|Y = c1, X = x1)$'; out_has '^(X = x1, Y = c2|Y = c2, X = x1)$'; }
t_Q7() { kb_q "$T/k"; K=$T/k; q '1 < 2'; rc_is 0 builtin; q 'a \= a'; rc_is 1; q 'X = abc'; rc_is 0; out_has '^X = abc$'; q 'current(X), check(K, X)' ; rc_is 0; }
t_Q8() { kb_q "$T/k"; K=$T/k; q 'current(c1)' --json; rc_is 0
         if [ $have_python = 1 ]; then printf '%s' "$out" | python3 -I -c 'import json,sys; d=json.load(sys.stdin); assert len(d["answers"])>=1' 2>/dev/null || note "--json output is not s(CASP) JSON with answers: $(snip "$out")"
         else out_has '"answers"'; fi; }
t_Q9() { kb_q "$T/k"; K=$T/k; q 'current(c1)' --html "$T/out.html"; rc_is 0; [ -s "$T/out.html" ] && grep -qi '<html' "$T/out.html" || note "--html file missing or not HTML"; }
t_Q10() { kb_q "$T/k"; K=$T/k; q 'current(c1)' --why; rc_is 0; out_has '^true'; out_has 'c1'; [ "$(printf '%s\n' "$out" | wc -l)" -ge 3 ] || note "--why adds a tree: $(snip "$out")"; }
t_Q11() { kb_q "$T/k"; K=$T/k; q 'claim(c1)'; rc_is 2 "wrong arity is undeclared"; }
t_Q12() { kb_q "$T/k"; K=$T/k; q 'current(X)' -n 2; rc_is 0; [ "$(printf '%s\n' "$out" | grep -c '^X = ')" = 2 ] || note "-n 2 gives two answers: $(snip "$out")"; }
t_Q13() { kb_q "$T/k"; K=$T/k; q 'current(c1)' -n x; rc_is 2 "bad -n"; }

# ================================================================ X: engines
t_X1() { kb_h2 "$T/k"; K=$T/k; q 'finding_lead(F)'; rc_is 1 "H2 under the default flags: no answer"; any_hasnt 'ENGINE DISAGREEMENT'; }
t_X2() { kb_h2 "$T/k"; K=$T/k; ORBIT_KB_SCASP_GROUND=raw ORBIT_KB_SCASP_FLAGS=--forall=all q 'finding_lead(F)'; rc_is 2; any_hasf 'ENGINE DISAGREEMENT'; any_has 'H1|H2'; }
t_X3() { kb_h2 "$T/k"; K=$T/k; ORBIT_KB_SCASP_GROUND=raw ORBIT_KB_SCASP_FLAGS=--forall=all okb --dir "$K" query 'finding_lead(F)' -n 0; rc_is 2; any_hasf 'ENGINE DISAGREEMENT'; }
t_X2g() { # D8: the H2 program under --forall=all in ground mode (the default): correct, no disagreement
          kb_h2 "$T/k"; K=$T/k
          ORBIT_KB_SCASP_FLAGS=--forall=all q 'finding_lead(F)'; rc_is 1 "H2 in ground mode: no answer"; any_hasnt 'ENGINE DISAGREEMENT'; any_hasnt "$NOTE_RAW" "the H2 program is a supported form: no raw fallback"
          ORBIT_KB_SCASP_FLAGS=--forall=all q 'finding_lead(F)' -n 0; rc_is 1 "-n 0: no answer"; any_hasnt 'ENGINE DISAGREEMENT'
          printf 'finding(f2, sys, model).\n' >> "$K/kb.pl"
          ORBIT_KB_SCASP_FLAGS=--forall=all q 'finding_lead(F)' -n 0; rc_is 0 "with f2 unconfirmed: one answer"; any_hasnt 'ENGINE DISAGREEMENT' "the answer sets agree in ground mode"
          local got; got=$(printf '%s\n' "$out" | LC_ALL=C sort | paste -sd'|'); [ "$got" = "F = f2" ] || note "finding_lead(F) -n 0 answers [$got], want exactly F = f2"; }
x_h1kb() { kb_new "$T/k" <<'EOF'
uses([build]).
request(r1, 'H1 tests').
claim(c1, introduce, 'Widget saves').
cites(c1, 'H1 tests').
change(x1, 'Edit').
serves(x1, c1).
decl(rule, bad_done, 'The H1 bad form of done.', '').
decl(rule, helper_any_under, 'The helper.', '').
decl(rule, good_done, 'The helper form of done.', '').
decl(rule, bad_over(ref(change)), 'The H1 bad form of over.', '').
EOF
    cat > "$T/k/rules.pl" <<'EOF'
bad_done :- not under(_).
helper_any_under :- under(_).
good_done :- not helper_any_under.
bad_over(X) :- change(X, _), not serves(X, Y).
EOF
    K=$T/k
}
# D8: the H1 bad form is a not over a free variable, so the grounder falls back to the raw
# program with a NOTE. It must disagree in both modes.
t_X4() { x_h1kb; q 'bad_done'; rc_is 2 "H1 bad form, ground mode (falls back to raw): engines disagree"; any_hasf 'ENGINE DISAGREEMENT'; err_has "$NOTE_RAW_RE" "ground mode: the raw fallback NOTE on stderr"
         ORBIT_KB_SCASP_GROUND=raw q 'bad_done'; rc_is 2 "H1 bad form, raw mode: engines disagree"; any_hasf 'ENGINE DISAGREEMENT'; }
t_X5() { x_h1kb; okb --dir "$K" lint; rc_is 1; out_has '^E12 '; }
t_X6() { x_h1kb; q 'good_done'; rc_is 1 "H1 helper form is false"; any_hasnt 'ENGINE DISAGREEMENT'; q 'helper_any_under'; rc_is 0 "c1 has no check, so under(c1) holds: helper true"; }
t_X7() { x_h1kb; q 'bad_over(X)'; rc_is 2 "named variable under not, ground mode (falls back to raw): disagreement, never exit 1"; any_hasf 'ENGINE DISAGREEMENT'; err_has "$NOTE_RAW_RE" "ground mode: the raw fallback NOTE on stderr"
         ORBIT_KB_SCASP_GROUND=raw q 'bad_over(X)'; rc_is 2 "named variable under not, raw mode: disagreement, never exit 1"; any_hasf 'ENGINE DISAGREEMENT'; }
t_X8() { kb_new "$T/k" <<'EOF'
uses([]).
request(r1, 'Add one').
decl(rule, plus_one(int, int), 'The second number is the first plus one.', '').
EOF
    echo 'plus_one(X, Y) :- Y #= X + 1.' > "$T/k/rules.pl"; K=$T/k; q 'plus_one(1, Y)'; rc_is 0; any_hasf 'CROSS-CHECK SKIPPED'; any_hasf '(unchecked)'; any_has 'Y = 2'; }
t_X9() { kb_h2 "$T/k"; K=$T/k; printf 'finding(f2, sys, model).\n' >> $K/kb.pl; q 'finding_lead(F)' -n 0; rc_is 0; out_has '^F = f2$'; out_hasnt 'f1'
         ORBIT_KB_SCASP_GROUND=raw ORBIT_KB_SCASP_FLAGS=--forall=all q 'finding_lead(F)' -n 0; rc_is 2 "raw mode: existence agrees, the answer sets differ"; any_hasf 'ENGINE DISAGREEMENT'; }
gd_kb() {  # gd_kb DIR: a build KB with 20 claims, each with a check, a serving change, and 2 runs (fail, then pass)
    local d=$1 i kind
    mkdir -p "$d"
    {   echo 'uses([build]).'
        echo "request(r1, 'Ship twenty things')."
        for ((i = 1; i <= 20; i++)); do
            kind=preserve; [ $((i % 2)) = 0 ] && kind=introduce
            echo "claim(c$i, $kind, 'Thing $i works')."
            echo "cites(c$i, 'Ship twenty things')."
            echo "check(k$i, c$i)."
            echo "change(x$i, 'Edit $i')."
            echo "serves(x$i, c$i)."
        done
    } > "$d/kb.pl"
    for ((i = 1; i <= 20; i++)); do add_result "$d" "k$i" $((2 * i - 1)) fail; add_result "$d" "k$i" $((2 * i)) pass; done
}
# ---- RF: the refuted verdict carries its counterexample (2026-10-21)
# R1: refuted(Counterexample) with text, in disproof and lean_result. R2: refuted(C) holds for it.
# R3: a bare refuted is E3 and the message shows the new form. R4: the other verdicts are unchanged.
# R5: why prints the counterexample.
t_RF1() { mkclaim; oadd "attest(d1, disproof, c1, verdict(c1, refuted('delete then save loses data')), agent, '2026-10-15T10:00:00Z')"; rc_is 0 "disproof with a counterexample"
          oadd "attest(l1, lean_result, c1, verdict(c1, refuted('n = 0')), agent, '2026-10-15T10:00:01Z')"; rc_is 0 "lean_result with a counterexample"
          has_goal "$K/kb.pl" "kb(attest(d1, disproof, c1, verdict(c1, refuted('delete then save loses data')), agent, _))" "the fact is stored with its text"
          okb --dir "$K" lint; rc_is 0 "lint is clean"; }
t_RF2() { mkclaim; oadd "attest(d1, disproof, c1, verdict(c1, refuted('boom')), agent, '2026-10-15T10:00:00Z')"
          q 'refuted(X)' -n 0; rc_is 0; out_has 'X = c1'; }
t_RF3() { mkclaim; add_result "$K" k1 1 fail; add_result "$K" k1 2 pass; is_true 'fulfilled(c1)' "before the refutation"
          oadd "attest(l1, lean_result, c1, verdict(c1, refuted('n = 0')), agent, '2026-10-15T10:00:01Z')"; rc_is 0
          is_true 'refuted(c1)'; is_false 'fulfilled(c1)'; is_true 'under(c1)'; }
t_RF4() { mkclaim; rejects "bare refuted in disproof" 'E3|must match' add "attest(d1, disproof, c1, verdict(c1, refuted), agent, '2026-10-15T10:00:00Z')"
          any_hasf "verdict(c1, refuted('the counterexample'))" "the message shows the whole new form"
          rejects "bare refuted in lean_result" 'E3|must match' add "attest(l1, lean_result, c1, verdict(c1, refuted), agent, '2026-10-15T10:00:00Z')"
          any_hasf "refuted('the counterexample')" "the message shows the new form"
          rejects "bare refuted from attest" 'E3|must match' attest disproof c1 'verdict(c1, refuted)'; }
t_RF5() { mkclaim
          rejects "refuted with an integer" 'text|E3' add "attest(d1, disproof, c1, verdict(c1, refuted(5)), agent, '2026-10-15T10:00:00Z')"
          rejects "refuted with two arguments" 'must match|E3' add "attest(d1, disproof, c1, verdict(c1, refuted(a, b)), agent, '2026-10-15T10:00:00Z')"; }
t_RF6() { mkclaim; local n=0 v
          for v in inconclusive abstained; do n=$((n+1)); oadd "attest(d$n, disproof, c1, verdict(c1, $v), agent, '2026-10-15T10:00:0${n}Z')"; rc_is 0 "disproof $v"; done
          for v in stated 'tested(7)'; do n=$((n+1)); oadd "attest(l$n, lean_result, c1, verdict(c1, $v), agent, '2026-10-15T10:00:0${n}Z')"; rc_is 0 "lean_result $v"; done
          is_false 'refuted(c1)' "none of these refutes"; okb --dir "$K" lint; rc_is 0; }
t_RF7() { mkclaim; oadd "attest(d1, disproof, c1, verdict(c1, refuted('delete then save loses data')), agent, '2026-10-15T10:00:00Z')"; rc_is 0
          okb --dir "$K" why 'refuted(c1)'; rc_is 0; any_hasf 'delete then save loses data' "why shows the counterexample"; }

# ---- D14 (2026-10-21): GO / NO-GO / HOLD is a weighted vote (discovery module)
# V1: attest type vote, vote(Round, Choice), writers agent and human; one vote per writer per
# round (a second is ED10); the largest round counts. V2: artifact_vote/1 by rule.
# V3: gate/1 needs the human plus one other role, else hold; gate_split/0; no answer before the
# human votes. V4: report seals the agent's vote and the artifacts' vote until the human votes;
# WD9 flags a human vote with no agent vote in its round; attest refuses a late agent vote.
# V6: WD6 and discovery_has_outcome no longer recommend NO-GO.
da_copy() { copy_fixture discovery-a "$T/k"; K=$T/k; }   # discovery-a: discovery_ready, current claims
vt_add() {  # vt_add ID BY ROUND CHOICE: append a vote to kb.pl
    printf "attest(%s, vote, r1, vote(%s, %s), %s, '2026-10-15T12:00:00Z').\n" "$1" "$3" "$4" "$2" >> "$K/kb.pl"
}
kb_noshow() {  # kb_noshow DIR: a discovery KB that is ready because h1 did not reproduce; no claim
    kb_new "$1" <<'EOF'
uses([discovery]).
request(r1, 'Orders are charged twice.').
hypothesis(h1, defect, 'A retry charges an order twice.').
budget(laps, 3).
subject(log1, 'logs/pay.log', 'sha256:0000000000000000000000000000000000000000000000000000000000000000').
discovery_evidence(log1, system).
attest(a1, reproduction, log1, result(h1, not_reproduced), agent, '2026-10-15T09:10:00Z').
EOF
    mkdir -p "$1/logs"; echo 'no double charge' > "$1/logs/pay.log"
    sed -i "s/sha256:0*/sha256:$(sha "$1/logs/pay.log")/" "$1/kb.pl"
}
t_VT1() { da_copy
          okb --dir "$K" attest vote r1 'vote(1, go)'; rc_is 0 "an agent vote"
          okb --dir "$K" attest vote r1 'vote(1, hold)' --by human; rc_is 0 "a human vote"
          has_goal "$K/kb.pl" "kb(attest(_, vote, r1, vote(1, hold), human, _))" "the human vote is stored"
          okb --dir "$K" lint; rc_is 0 "two votes lint clean"; out_hasnt '^E'
          rejects "a choice that is not go, no_go, or hold" 'E3|must match|oneof|go' attest vote r1 'vote(1, maybe)'
          rejects "a vote with no round" 'E3|must match' attest vote r1 'vote(go)'
          rejects "a script vote" 'script|human|agent' attest vote r1 'vote(1, go)' --by script
          vt_add v9 script 1 go; okb --dir "$K" lint; rc_is 1 "a script vote in kb.pl"; out_has '^E8 '; }
t_VT2() { da_copy; vt_add v1 agent 1 go; vt_add v2 agent 1 hold; vt_add v3 human 1 go
          okb --dir "$K" lint; rc_is 1 "two agent votes in one round"
          [ "$(printf '%s\n' "$out" | grep -c '^ED10 ')" = 2 ] || note "want ED10 on both agent votes: $(snip "$out")"
          out_has '^ED10 v1' ; out_has '^ED10 v2'
          da_copy; vt_add v1 agent 1 go; vt_add v2 human 1 hold; vt_add v3 agent 2 no_go; vt_add v4 human 2 no_go
          okb --dir "$K" lint; rc_is 0 "one vote per writer per round"; out_hasnt '^ED10'
          is_set 'vote_round(R)' 'R = 2' "the largest round counts"
          is_set 'human_vote(V)' 'V = no_go' "round 2 replaces the human vote of round 1"
          is_set 'agent_vote(V)' 'V = no_go' "round 2 replaces the agent vote of round 1"
          da_copy; vt_add v1 agent 1 go; vt_add v2 human 1 hold; vt_add v3 agent 2 no_go
          is_false 'human_vote(V)' "the human has not voted in round 2"; is_false 'gate(V)' "no gate before the human votes in round 2"; }
t_VT3() { da_copy; is_set 'artifact_vote(V)' 'V = go' "ready with a current claim"
          grep -v "^answer(q1, floor_wins, human)\.$" "$K/kb.pl" > "$K/kb.new" && mv "$K/kb.new" "$K/kb.pl"
          is_false 'discovery_ready' "setup: q1 waits"; is_set 'artifact_vote(V)' 'V = hold' "not ready"
          kb_noshow "$T/n"; K=$T/n; okb --dir "$K" lint; rc_is 0 "setup lints"
          is_true 'discovery_ready' "setup: ready, nothing reproduced"; is_set 'artifact_vote(V)' 'V = no_go' "ready because no hypothesis reproduced"
          printf "claim(c0, introduce, 'In a cycle.').\ncites(c0, 'charged twice').\nsupersedes(c0, c0).\n" >> "$K/kb.pl"
          is_false 'current(c0)' "setup: a claim that is not current"; is_set 'artifact_vote(V)' 'V = no_go' "a claim that is not current does not make it go"
          printf "claim(c1, introduce, 'No double charge.').\ncites(c1, 'charged twice').\ncheck(t1, c1).\n" >> "$K/kb.pl"
          is_set 'artifact_vote(V)' 'V = go' "a current claim with a falsifier makes it go"
          printf "lap_done(3).\nhypothesis(h2, risk, 'Untouched.').\n" >> "$K/kb.pl"
          is_true 'discovery_decide' "setup: budget spent"; is_false 'discovery_ready'; is_set 'artifact_vote(V)' 'V = hold' "budget spent is not ready"
          kb_noshow "$T/n2"; K=$T/n2; printf "hypothesis(h2, risk, 'Untouched.').\n" >> "$K/kb.pl"
          is_false 'discovery_ready' "setup: h2 untouched"; is_set 'artifact_vote(V)' 'V = hold' "not ready with no current claim is hold, not no_go"; }
vt_gate() {  # vt_gate HUMAN AGENT GATE SPLIT: on discovery-a (artifacts vote go). - is no vote.
    da_copy; [ "$2" = - ] || vt_add v1 agent 1 "$2"; [ "$1" = - ] || vt_add v2 human 1 "$1"
    local lbl="human $1, agent $2, artifacts go"
    if [ "$3" = - ]; then is_false 'gate(V)' "$lbl: no gate"; else is_set 'gate(V)' "V = $3" "$lbl: gate"; fi
    if [ "$4" = y ]; then is_true 'gate_split' "$lbl: split"; else is_false 'gate_split' "$lbl: no split"; fi
}
t_VT4() { vt_gate - - - n; vt_gate - go - n; vt_gate go go go n; vt_gate go - go n
          vt_gate go hold go n; vt_gate go no_go go n; vt_gate hold hold hold n; vt_gate no_go no_go no_go n
          vt_gate hold go hold y; vt_gate no_go go hold y; vt_gate no_go hold hold y; vt_gate hold no_go hold y; vt_gate no_go - hold y; }
t_VT5() { kb_noshow "$T/n"; K=$T/n; vt_add v1 agent 1 go; vt_add v2 human 1 no_go
          is_set 'gate(V)' 'V = no_go' "human and artifacts agree on no_go"; is_false 'gate_split'
          vt_add v3 agent 2 hold; vt_add v4 human 2 go
          is_set 'gate(V)' 'V = hold' "round 2: human go against agent hold and artifacts no_go"; is_true 'gate_split'; }
vt_section() { printf '%s\n' "$out" | awk '/^# Vote:/{f=1;next} /^# /{f=0} f'; }
t_VT6() { da_copy; okb --dir "$K" report; rc_is 0; local g; g=$(vt_section)
          [ -n "$g" ] || note "report has a Vote: section in a discovery KB: $(snip "$out")"
          vt_add v1 agent 1 no_go; okb --dir "$K" report; rc_is 0; g=$(vt_section)
          printf '%s\n' "$g" | grep -qi 'sealed' || note "the agent vote is sealed: [$g]"
          printf '%s\n' "$g" | grep -Eqi 'no_go|no-go|\bgo\b' && note "before the human votes, no choice is shown: [$g]"
          vt_add v2 human 1 go; okb --dir "$K" report; rc_is 0; g=$(vt_section)
          printf '%s\n' "$g" | grep -Eq 'gent.*no_go' || note "after the human votes, the agent vote shows: [$g]"
          printf '%s\n' "$g" | grep -Eq 'uman.*go' || note "the human vote shows: [$g]"
          printf '%s\n' "$g" | grep -Eqi 'artifacts.*go' || note "the artifacts vote shows: [$g]"
          printf '%s\n' "$g" | grep -Eqi 'outcome.*go' || note "the outcome shows: [$g]"
          da_copy; vt_add v1 agent 1 go; vt_add v2 human 1 hold; okb --dir "$K" report; rc_is 0; g=$(vt_section)
          printf '%s\n' "$g" | grep -Eqi 'divergence' || note "a split names a divergence: [$g]"
          kb_new "$T/b" <<'EOF'
uses([build]).
request(r1, 'Plain').
EOF
          K=$T/b; okb --dir "$K" report; rc_is 0; out_hasnt '^# Vote:' "no Vote: section without discovery"; }
t_VT7() { da_copy; vt_add v2 human 1 go; okb --dir "$K" lint; rc_is 0 "a warning only"
          out_has '^WD9 v2' "a human vote with no agent vote in its round"
          da_copy; vt_add v1 agent 1 go; vt_add v2 human 1 go; okb --dir "$K" lint; out_hasnt '^WD9'
          da_copy; vt_add v1 agent 1 go; vt_add v2 human 1 go; vt_add v3 human 2 go; okb --dir "$K" lint; out_has '^WD9 v3' "round 2 has no agent vote"
          da_copy; okb --dir "$K" attest vote r1 'vote(1, go)' --by human; rc_is 0
          rejects "a late agent vote" 'seal|human' attest vote r1 'vote(1, go)'
          okb --dir "$K" attest vote r1 'vote(2, go)'; rc_is 0 "an agent vote in a new round"; }
t_VT8() { da_copy; printf 'gate(go).\nartifact_vote(go) :- some_hypothesis.\ngate_split :- some_hypothesis.\nhuman_vote(go).\n' > "$K/rules.pl"
          okb --dir "$K" lint; rc_is 1 "rules.pl cannot change the vote rules"
          [ "$(printf '%s\n' "$out" | grep -c '^E16 rules.pl')" = 4 ] || note "want E16 on each of the 4 clauses: $(snip "$out")"
          is_false 'gate(V)' "the engines ignore the clauses"; is_false 'gate_split'; is_false 'human_vote(V)'; is_set 'artifact_vote(V)' 'V = go'; }
t_VT9() { da_copy; sed -i 's/result(h1, reproduced)/result(h1, not_reproduced)/' "$K/kb.pl"
          okb --dir "$K" lint; out_has '^WD6 a1: .*Tell the human what you tried\.' "the new WD6 text"
          any_hasnt 'NO-GO candidate' "WD6 recommends nothing"
          okb --dir "$K" why discovery_has_outcome; rc_is 0; any_hasnt 'NO-GO' "the template is neutral"; }
t_VT10() { da_copy; okb help attest; rc_is 0; local line
           line=$(printf '%s\n%s\n' "$out" "$err" | grep -E '^ *orbit-kb attest vote ' | head -n1)
           [ -n "$line" ] || { note "help attest has no example line that starts with orbit-kb attest vote"; return; }
           line=${line#*orbit-kb attest vote }
           eval "set -- $line" 2>/dev/null || { note "the example does not parse in a shell: $line"; return; }
           okb --dir "$K" attest vote "$@"; rc_is 0 "the help example runs as typed: $line"
           okb help query; any_has 'gate' "help query names gate"; }

# ---- D10: a burn needs a Lean proof (or a human waiver); done waits for it
t_BP1() { kb_burndone "$T/k"; K=$T/k; is_true 'burn(c1)'; is_set 'burn_open(X)' 'X = c1'; is_false 'done' "c1 burns and has no proof"
          is_true any_burn_open; is_false any_under; is_false any_over; is_false any_to_ask; }
t_BP2() { kb_burndone "$T/k"; K=$T/k
          printf "attest(l1, lean_result, c1, verdict(c1, stated), agent, '2026-10-15T11:00:00Z').\nattest(l2, lean_result, c1, verdict(c1, tested(1000)), agent, '2026-10-15T11:00:01Z').\n" >> $K/kb.pl
          okb --dir "$K" lint; rc_is 0 "stated and tested are allowed lean_result verdicts"
          is_false 'done' "stated and tested are progress, not a proof"; is_true 'burn_open(c1)'; }
t_BP3() { kb_burndone "$T/k"; K=$T/k; printf "attest(l1, lean_result, c1, verdict(c1, proved), agent, '2026-10-15T11:00:00Z').\n" >> $K/kb.pl
          okb --dir "$K" lint; rc_is 1 "lean_result has no proved verdict"; out_has '^E3'; }
t_BP4() { kb_burndone "$T/k"; K=$T/k; add_proof "$K" p1 c1
          okb --dir "$K" lint; rc_is 0 "a proof with its log lints clean"; is_true 'burn_proved(c1)'; is_false 'burn_open(c1)'; is_true 'done' "c1 is proved"; }
t_BP5() { kb_burndone "$T/k"; K=$T/k; add_proof "$K" p1 c1; echo '-- edit' >> "$K/lean/P.lean"
          is_set 'proof_changed(X)' 'X = p1'; is_false 'burn_proved(c1)'; is_false 'done' "a file of the proof changed"
          okb --dir "$K" report; out_has 'Proof p1 of claim c1 no longer counts'; }
t_BP6() { kb_burndone "$T/k"; K=$T/k; add_proof "$K" p1 c1; rm "$K/runs/proof-p1.log"
          okb --dir "$K" lint; rc_is 1 "a proof without its log"; out_has '^E9'; is_false 'burn_proved(c1)'; is_false 'done'; }
t_BP7() { kb_burndone "$T/k"; K=$T/k; add_proof "$K" p1 c1; sed -i '$ s/), script, /), agent, /' "$K/kb.pl"   # a valid log; only the writer is wrong
          okb --dir "$K" lint; rc_is 1; out_has '^E8.*orbit-kb prove'; any_hasnt '^E9' "the log matches"; is_false 'burn_proved(c1)' "an agent cannot write a proof"
          mkclaim; rejects scripttype 'prove' attest lean_proof c1 "proof(c1, 'sha256:$(printf '%064d' 0)')"
          rejects scripttype 'prove' add "attest(p2, lean_proof, c1, proof(c1, 'sha256:$(printf '%064d' 0)'), script, '2026-10-15T10:00:00Z')"; }
t_BP8() { kb_burndone "$T/k"; K=$T/k; okb --dir "$K" attest waiver c1 "waive(c1, '2999-01-01T00:00:00Z', 'Ship before the demo')" --by human; rc_is 0
          is_true 'burn_waived(c1)'; is_false 'burn_open(c1)'; is_true 'done' "a human waived the proof"; is_false 'burn_proved(c1)'
          okb --dir "$K" report; rp_item c1 | grep -Eq 'NOT PROVED' || note "c1 block says NOT PROVED"; rp_item c1 | grep -Eq 'waived the proof until 2999-01-01' || note "c1 block says the waiver and its due time: $(snip "$(rp_item c1)")"; }
t_BP9() { kb_burndone "$T/k"; K=$T/k; rejects agentwaiver 'writer|human' attest waiver c1 "waive(c1, '2999-01-01T00:00:00Z', 'x')"
          printf "attest(w1, waiver, c1, waive(c1, '2999-01-01T00:00:00Z', x), agent, '2026-10-15T11:00:00Z').\n" >> $K/kb.pl
          okb --dir "$K" lint; rc_is 1; out_has '^E8'; is_false 'burn_waived(c1)' "an agent cannot waive a proof"; is_false 'done'; }
t_BP10() { kb_burndone "$T/k"; K=$T/k; printf "attest(w1, waiver, c1, waive(c1, '2020-01-01T00:00:00Z', 'Old deadline'), human, '2019-12-01T00:00:00Z').\n" >> $K/kb.pl
           is_set 'waiver_lapsed(X)' 'X = w1'; is_false 'burn_waived(c1)'; is_false 'done' "the waiver is past its due time"
           okb --dir "$K" report; out_has 'Waiver w1 of the proof of claim c1 was due at 2020-01-01'; }
t_BP11() { kb_burndone "$T/k"; K=$T/k; printf "supersedes(c3, c1).\nclaim(c3, preserve, 'One stays true, new words').\ncites(c3, 'Do two things').\ncheck(k3, c3).\nserves(x1, c3).\n" >> $K/kb.pl
           add_result $K k3 4 pass; is_true 'burn(c1)'; is_false 'burn_open(c1)' "a superseded claim has no open burn"
           is_true 'burn_open(c3)' "c3 inherits the burn of c1 (D10 follow-up, S1)"; is_false 'done'; }
t_BP12() { kb_burndone "$T/k"; K=$T/k; add_proof "$K" p1 c1
           printf "check(k9, c1).\nconformance(k9).\n" >> $K/kb.pl; is_false 'conforms(c1)'; is_true 'done' "conformance is optional"
           add_result $K k9 4 pass; is_true 'conforms(c1)'; is_true 'done'; }
t_BP13() { kb_burn "$T/k"; K=$T/k; is_set 'burn_open(X)' 'X = c1|X = c3|X = c4' "contested twice, universal, and requested all need a proof"; }
t_BP14() { mkclaim; rejects reserved 'reserved' declare 'proved(ref(claim))' --doc 'x' --kind rule; }

# ---- D10 follow-up (2026-10-20): restated claims, supersede cycles, rules.pl, times, logs
sc_restate() {  # sc_restate: kb_burndone, then c3 restates the universal claim c1 (c3 has no trigger of its own)
    kb_burndone "$T/k"; K=$T/k
    printf "supersedes(c3, c1).\nclaim(c3, preserve, 'One stays true, new words').\ncites(c3, 'Do two things').\ncheck(k3, c3).\nserves(x1, c3).\n" >> $K/kb.pl
    add_result $K k3 4 pass
}
t_SC1() { sc_restate; is_true 'burn(c3)' "c3 supersedes the burning claim c1, so c3 inherits the burn (S1)"
          is_set 'burn_open(X)' 'X = c3'; is_false 'done' "the inherited burn of c3 is open"
          okb --dir "$K" lint; rc_is 0 "a restated claim is not a lint error"; out_hasnt '^E[0-9]'
          add_proof "$K" p1 c3; is_false 'burn_open(c3)'; is_true 'done' "a proof of c3 closes the inherited burn"; }
t_SC2() { sc_restate
          printf "supersedes(c4, c3).\nclaim(c4, preserve, 'One stays true, newer words').\ncites(c4, 'Do two things').\ncheck(k4, c4).\nserves(x1, c4).\n" >> $K/kb.pl
          add_result $K k4 5 pass
          is_set 'supersedes_closure(N, c1)' 'N = c3|N = c4' "the closure has every claim that reaches c1"
          is_true 'burn(c4)' "c4 reaches c1 in two steps (S1)"; is_set 'burn_open(X)' 'X = c4'; is_false 'done'
          is_false 'supersede_cycle(X)' "a chain is not a cycle"; }
t_SC3() { kb_burndone "$T/k"; K=$T/k; printf "supersedes(c1, c1).\n" >> $K/kb.pl
          okb --dir "$K" lint; rc_is 1 "supersedes(c1, c1) is a lint error (S2)"; out_has '^E15 .*kb.pl'
          is_true 'supersede_cycle(c1)'; is_false 'done' "a supersede cycle makes done false (S2)"; any_hasnt 'ENGINE DISAGREEMENT'
          is_false 'burn_open(C)' "both engines answer; c1 is not current"; any_hasnt 'ENGINE DISAGREEMENT'
          okb --dir "$K" report; rc_is 0; out_has 'cycle'; }
t_SC4() { kb_burndone "$T/k"; K=$T/k; printf "supersedes(c1, c2).\nsupersedes(c2, c1).\n" >> $K/kb.pl
          okb --dir "$K" lint; rc_is 1 "a two-claim cycle is a lint error (S2)"
          [ "$(printf '%s\n' "$out" | grep -c '^E15 ')" = 2 ] || note "want E15 on both supersedes facts: $(snip "$out")"
          is_set 'supersede_cycle(X)' 'X = c1|X = c2'; is_true 'burn(c2)' "c2 reaches the universal claim c1"
          q 'done'; rc_is 1 "done is false, and both engines finish (S3)"; any_hasnt 'ENGINE DISAGREEMENT'
          q 'burn_open(C)' -n 0; rc_is 1 "no claim of the cycle is current"; any_hasnt 'ENGINE DISAGREEMENT'
          q 'burn(C)' -n 0; rc_is 0; any_hasnt 'ENGINE DISAGREEMENT'; }
t_SC5() { kb_burndone "$T/k"; K=$T/k; rejects selfsup 'cycle' add 'supersedes(c1, c1)'
          oadd 'supersedes(c2, c1)'; rc_is 0 "a plain supersedes fact"
          rejects cycle2 'cycle' add 'supersedes(c1, c2)'; }
t_SC6() { kb_burndone "$T/k"; K=$T/k; printf 'burn_proved(c1).\ndone.\nburn_waived(C) :- claim(C, _, _).\n' > $K/rules.pl
          okb --dir "$K" lint; rc_is 1 "rules.pl cannot close a burn (F8)"
          [ "$(printf '%s\n' "$out" | grep -c '^E16 rules.pl')" = 3 ] || note "want E16 on each of the 3 clauses: $(snip "$out")"
          out_hasnt '^W6' "E16, not W6"; is_false 'done' "the engines ignore the protected clauses of rules.pl"; is_true 'burn_open(c1)'; }
t_SC7() { kb_burndone "$T/k"; K=$T/k
          printf "attest(w9, waiver, c1, waive(c1, '2999-01-01T00:00:00Z', 'x'), human, '2026-10-15T11:00:00Z').\n" > $K/rules.pl
          okb --dir "$K" lint; rc_is 1; out_has '^E7 rules.pl'; is_false 'burn_waived(c1)' "a waiver in rules.pl does not count"; is_false 'done'
          rm $K/rules.pl; printf 'burn_proved(c1).\n' >> $K/kb.pl
          okb --dir "$K" lint; rc_is 1; out_has '^E7 .*kb.pl'; is_false 'done' "a burn_proved fact in kb.pl does not count"; }
t_SC8() { kb_burndone "$T/k"; K=$T/k; local t
          for t in 2026-99-99T99:99:99Z 2026-13-01T00:00:00Z 2026-00-10T00:00:00Z 2026-04-31T00:00:00Z 2027-02-29T00:00:00Z \
                   2100-02-29T00:00:00Z 2026-10-20T24:00:00Z 2026-10-20T23:60:00Z 2026-10-20T23:59:60Z; do
              rejects "time $t" 'time' attest waiver c1 "waive(c1, '$t', 'x')" --by human
          done
          okb --dir "$K" attest waiver c1 "waive(c1, '2028-02-29T23:59:59Z', 'leap day')" --by human; rc_is 0 "2028 is a leap year"
          okb --dir "$K" attest waiver c1 "waive(c1, '2400-02-29T00:00:00Z', 'leap day')" --by human; rc_is 0 "2400 is a leap year"
          printf "attest(w9, waiver, c1, waive(c1, '2999-02-30T00:00:00Z', x), human, '2026-10-15T11:00:00Z').\n" >> $K/kb.pl
          okb --dir "$K" lint; rc_is 1; out_has '^E3 .*kb.pl'; }
t_SC9() { kb_burndone "$T/k"; K=$T/k
          printf "attest(w1, waiver, c1, waive(c1, never, x), human, '2026-10-15T11:00:00Z').\nattest(w2, waiver, c1, waive(c1, 2020, x), human, '2026-10-15T11:00:00Z').\nattest(w3, waiver, c1, waive(c1, '2999-02-30T00:00:00Z', x), human, '2026-10-15T11:00:00Z').\n" >> $K/kb.pl
          is_set 'waiver_lapsed(X)' 'X = w1|X = w2|X = w3' "an invalid due time counts as lapsed (F9)"
          is_false 'burn_waived(c1)'; is_false 'done'; }
t_SC10() { kb_burndone "$T/k"; K=$T/k; local soon past
           soon=$(date -u -d '+1 day' +%Y-%m-%dT%H:%M:%SZ); past=$(date -u -d '-2 minutes' +%Y-%m-%dT%H:%M:%SZ)
           printf "attest(w1, waiver, c1, waive(c1, '%s', x), human, '2026-10-15T11:00:00Z').\n" "$soon" >> $K/kb.pl
           is_true 'done' "a waiver due tomorrow counts"
           printf "attest(w2, waiver, c1, waive(c1, '%s', x), human, '2026-10-15T11:00:00Z').\n" "$past" >> $K/kb.pl
           is_set 'waiver_lapsed(X)' 'X = w2' "only the waiver due 2 minutes ago lapsed (the clock is now)"; }
t_SC11() { kb_burndone "$T/k"; K=$T/k; printf "universal(c2).\n" >> $K/kb.pl; add_proof "$K" p1 c1; local dg sha2
           dg=$(sed -n '1s/.*digest=//p' "$K/runs/proof-p1.log")
           # a copy of the log for c2, with the claim edited in its header (F6)
           sed '1s/claim=c1/claim=c2/' "$K/runs/proof-p1.log" > "$K/runs/proof-p2.log"
           printf "attest(p2, lean_proof, c2, proof(c2, '%s'), script, '2026-10-15T11:00:00Z').\n" "$dg" >> $K/kb.pl
           # an unedited copy for c2 (MX)
           cp "$K/runs/proof-p1.log" "$K/runs/proof-p3.log"
           printf "attest(p3, lean_proof, c2, proof(c2, '%s'), script, '2026-10-15T11:00:00Z').\n" "$dg" >> $K/kb.pl
           is_set 'proof_changed(X)' 'X = p2|X = p3' "a log copied for another claim does not count"; is_true 'burn_open(c2)'; is_false 'done'
           okb --dir "$K" lint; rc_is 1; [ "$(printf '%s\n' "$out" | grep -c '^E9 ')" = 2 ] || note "want E9 on p2 and p3: $(snip "$out")"
           # an edited statement line (MD)
           sed -i 's/^statement True$/statement False/' "$K/runs/proof-p1.log"
           is_true 'proof_changed(p1)' "an edited statement line does not count"; is_true 'burn_open(c1)'
           okb --dir "$K" lint; rc_is 1; [ "$(printf '%s\n' "$out" | grep -c '^E9 ')" = 3 ] || note "want E9 on p1 too: $(snip "$out")"
           sed -i 's/^statement False$/statement True/' "$K/runs/proof-p1.log"; is_false 'proof_changed(p1)' "the log is restored"
           # an edited file, and its sha256 edited in the log to match (MD)
           echo '-- edit' >> "$K/lean/P.lean"; sha2="sha256:$(sha "$K/lean/P.lean")"
           sed -i "s/^file sha256:[0-9a-f]* P.lean$/file $sha2 P.lean/" "$K/runs/proof-p1.log"
           is_true 'proof_changed(p1)' "the digest no longer matches the file lines"; }

# ---- D13 (2026-10-21): a human waiver can target a claim, a check, or a question
kb_waive() {  # kb_waive DIR: c1 is under (k1 never ran), q1 must be asked (c2 is contested), c2 is fulfilled
    kb_new "$1" <<'EOF'
uses([build]).
request(r1, 'Waive things').
claim(c1, introduce, 'Claim one').
claim(c2, preserve, 'Claim two').
cites(c1, 'Waive things').
cites(c2, 'Waive things').
check(k1, c1).
check(k2, c2).
change(x1, 'Edit one').
serves(x1, c1).
serves(x1, c2).
question(q1, c2, 'Is it two').
attest(d1, divergence, c2, claim(c2), agent, '2026-10-15T10:00:00Z').
EOF
    add_result "$1" k2 1 pass
}
wv_add() {  # wv_add ID TARGET DUE [BY]: append a waiver to kb.pl
    printf "attest(%s, waiver, %s, waive(%s, '%s', 'Come back later'), %s, '2026-10-15T11:00:00Z').\n" "$1" "$2" "$2" "$3" "${4:-human}" >> "$K/kb.pl"
}
t_WV1() { kb_waive "$T/k"; K=$T/k
          is_true 'under(c1)' "setup"; is_true 'to_ask(q1)' "setup"; is_false 'done' "setup"
          okb --dir "$K" attest waiver k1 "waive(k1, '2999-01-01T00:00:00Z', 'Check later')" --by human; rc_is 0 "a waiver on a check"
          okb --dir "$K" attest waiver q1 "waive(q1, '2999-01-01T00:00:00Z', 'Ask later')" --by human; rc_is 0 "a waiver on a question"
          okb --dir "$K" attest waiver c1 "waive(c1, '2999-01-01T00:00:00Z', 'Prove later')" --by human; rc_is 0 "a waiver on a claim"
          okb --dir "$K" lint; rc_is 0 "the three waivers lint clean"
          rejects "waiver on a change" 'E4' attest waiver x1 "waive(x1, '2999-01-01T00:00:00Z', 'x')" --by human
          any_hasi 'claim.*check.*question' "the message names the three allowed kinds"
          rejects "waiver on the request" 'E4' attest waiver r1 "waive(r1, '2999-01-01T00:00:00Z', 'x')" --by human
          rejects "waiver on an unknown id" 'E4' attest waiver c1 "waive(nope, '2999-01-01T00:00:00Z', 'x')" --by human
          rejects "waiver on a non-atom" 'E3' attest waiver c1 "waive(5, '2999-01-01T00:00:00Z', 'x')" --by human
          wv_add w9 x1 2999-01-01T00:00:00Z; okb --dir "$K" lint; rc_is 1 "a waiver on a change in kb.pl"; out_has '^E4 .*kb.pl'; }
t_WV2() { kb_waive "$T/k"; K=$T/k; wv_add w1 k1 2999-01-01T00:00:00Z
          is_false 'under(c1)' "a waived check covers its claim (W3)"; is_false 'fulfilled(c1)' "a waived check does not fulfil (W3)"
          is_false any_under; is_false 'done' "q1 must still be asked"
          wv_add w2 q1 2999-01-01T00:00:00Z; is_true 'done' "the check and the question are waived"
          printf "claim(c3, preserve, 'Claim three').\ncites(c3, 'Waive things').\ncheck(k3, c3).\nserves(x1, c3).\n" >> $K/kb.pl
          is_set 'under(X)' 'X = c3' "the waiver of k1 covers c1 only, not c3"; is_false 'done'; }
t_WV3() { kb_waive "$T/k"; K=$T/k; printf "universal(c1).\n" >> $K/kb.pl; wv_add w1 k1 2999-01-01T00:00:00Z; wv_add w2 q1 2999-01-01T00:00:00Z
          is_false 'under(c1)'; is_true 'burn_open(c1)' "a check waiver does not close a burn (W3)"; is_false 'burn_waived(c1)'; is_false 'done'
          wv_add w3 c1 2999-01-01T00:00:00Z; is_false 'burn_open(c1)' "a claim waiver closes the burn (W2)"; is_true 'done'; }
t_WV4() { kb_waive "$T/k"; K=$T/k; wv_add w1 q1 2999-01-01T00:00:00Z
          is_false 'to_ask(q1)' "a waived question is not to_ask (W4)"; is_false any_to_ask; is_true 'under(c1)' "a question waiver does not cover a claim"
          is_false 'answered(q1)' "a waiver is not an answer"; }
t_WV5() { kb_waive "$T/k"; K=$T/k; wv_add w1 k1 2020-01-01T00:00:00Z; wv_add w2 q1 2020-01-01T00:00:00Z
          printf "attest(w3, waiver, k1, waive(k1, never, x), human, '2026-10-15T11:00:00Z').\nattest(w4, waiver, q1, waive(q1, '2999-02-30T00:00:00Z', x), human, '2026-10-15T11:00:00Z').\n" >> $K/kb.pl
          is_set 'waiver_lapsed(X)' 'X = w1|X = w2|X = w3|X = w4' "past and invalid due times lapse (W5)"
          is_true 'under(c1)' "a lapsed check waiver does not cover"; is_true 'to_ask(q1)' "a lapsed question waiver does not count"; is_false 'done'; }
t_WV6() { kb_waive "$T/k"; K=$T/k
          rejects "agent waiver on a check" 'writer|human' attest waiver k1 "waive(k1, '2999-01-01T00:00:00Z', 'x')"
          rejects "agent waiver on a question" 'writer|human' attest waiver q1 "waive(q1, '2999-01-01T00:00:00Z', 'x')"
          wv_add w1 k1 2999-01-01T00:00:00Z agent; wv_add w2 q1 2999-01-01T00:00:00Z agent
          okb --dir "$K" lint; rc_is 1; [ "$(printf '%s\n' "$out" | grep -c '^E8 ')" = 2 ] || note "want E8 on both agent waivers: $(snip "$out")"
          is_true 'under(c1)' "an agent waiver does not count (W5)"; is_true 'to_ask(q1)'; is_false 'done'; }
t_WV7() { kb_waive "$T/k"; K=$T/k; wv_add w1 c1 2999-01-01T00:00:00Z; wv_add w2 c2 2999-01-01T00:00:00Z
          is_true 'under(c1)' "a claim waiver does not cover the checks of the claim (W2)"; is_true 'to_ask(q1)' "a claim waiver does not cover its questions"
          is_true 'burn_waived(c1)' "a claim waiver closes a burn as before"; is_false 'burn_waived(k1)'; }
t_WV8() { kb_waive "$T/k"; K=$T/k; wv_add w1 k1 2999-01-01T00:00:00Z; wv_add w2 q1 2020-01-01T00:00:00Z; wv_add w3 c2 2999-06-01T00:00:00Z
          okb --dir "$K" report; rc_is 0; local g; g=$(printf '%s\n' "$out" | awk '/^# Waivers:/{f=1;next} /^# /{f=0} f')
          printf '%s\n' "$g" | grep -Eq 'w1 \*\*in force\*\*: check k1, due 2999-01-01T00:00:00Z' || note "w1 (check, in force) in Waivers: [$g]"
          printf '%s\n' "$g" | grep -Eq 'w2 \*\*lapsed\*\*: question q1, due 2020-01-01T00:00:00Z' || note "w2 (question, lapsed) in Waivers: [$g]"
          printf '%s\n' "$g" | grep -Eq 'w3 \*\*in force\*\*: claim c2, due 2999-06-01T00:00:00Z' || note "w3 (claim, in force) in Waivers: [$g]"
          rp_item c1 | grep -Eq 'waived' || note "the c1 block says that a check of c1 is waived: $(snip "$(rp_item c1)")"
          out_has 'Waiver w2 of question q1 was due at 2020-01-01' "Open lists the lapsed question waiver"
          kb_waive "$T/k2"; K=$T/k2; okb --dir "$K" report; rc_is 0; g=$(printf '%s\n' "$out" | awk '/^# Waivers:/{f=1;next} /^# /{f=0} f')
          printf '%s\n' "$g" | grep -q 'None' || note "no waivers: the section says None: [$g]"; }
t_WV9() { kb_waive "$T/k"; K=$T/k; printf 'check_waived(C) :- claim(C, _, _).\nquestion_waived(Q) :- question(Q, _, _).\n' > $K/rules.pl
          okb --dir "$K" lint; rc_is 1 "rules.pl cannot waive a check or a question (W7)"
          [ "$(printf '%s\n' "$out" | grep -c '^E16 rules.pl')" = 2 ] || note "want E16 on each of the 2 clauses: $(snip "$out")"
          is_true 'under(c1)' "the engines ignore the clauses"; is_true 'to_ask(q1)'; is_false 'done'; }
t_WV10() { kb_waive "$T/k"; K=$T/k; okb help attest; rc_is 0; local line
           line=$(printf '%s\n%s\n' "$out" "$err" | grep -E '^ *orbit-kb attest waiver ' | head -n1)
           [ -n "$line" ] || { note "help attest has no example line that starts with orbit-kb attest waiver"; return; }
           any_hasi 'check' "help names checks"; any_hasi 'question' "help names questions"
           line=${line#*orbit-kb attest waiver }
           eval "set -- $line" 2>/dev/null || { note "the example does not parse in a shell: $line"; return; }
           okb --dir "$K" attest waiver "$@"; rc_is 0 "the help example runs as typed: $line"; }

# ---- D15 (2026-10-27): reword a hypothesis with supersedes(HNew, HOld). Both sides are claims,
# or both are hypotheses; a mix is E4. A superseded hypothesis raises no WD7 or WD6 and does not
# count for discovery_ready. current/1, under/1, and burn/1 stay claims only.
t_RW1() { kb_noshow "$T/k"; K=$T/k; printf "claim(c1, introduce, 'No double charge.').\ncites(c1, 'charged twice').\n" >> "$K/kb.pl"
          oadd "hypothesis(h2, defect, 'A retry after a timeout charges an order twice.')" "supersedes(h2, h1)"
          rc_is 0 "a hypothesis replaces a hypothesis"
          has_fact "$K/kb.pl" "supersedes(h2, h1)" "the supersedes fact is stored"
          rejects "a claim cannot replace a hypothesis" 'claim.*hypothes|hypothes.*claim' add "supersedes(c1, h1)"
          rejects "a hypothesis cannot replace a claim" 'claim.*hypothes|hypothes.*claim' add "supersedes(h2, c1)"
          rejects "a mix in one add" 'claim.*hypothes|hypothes.*claim' add "hypothesis(h3, risk, 'Other words.')" "supersedes(h3, c1)"
          rejects "a request is no claim or hypothesis" 'E4' add "supersedes(c1, r1)"
          printf "supersedes(c1, h1).\n" >> "$K/kb.pl"; okb --dir "$K" lint; rc_is 1 "a mix in kb.pl is a lint error"
          out_has '^E4 .*kb\.pl:.*hypothes' "E4 names the kinds"
          kb_new "$T/c" <<'EOF'
uses([]).
request(r1, 'Fix the thing').
claim(c1, preserve, 'It works').
cites(c1, 'Fix the thing').
claim(c2, preserve, 'It works better').
cites(c2, 'Fix the thing').
EOF
          K=$T/c; rejects "core only: a request is not a claim" 'E4' add "supersedes(c2, r1)"
          oadd "supersedes(c2, c1)"; rc_is 0 "core only: a claim replaces a claim"
          okb --dir "$K" lint; rc_is 0 "core only: lint is clean"; out_hasnt '^E'; }
t_RW2() { da_copy; is_true 'discovery_ready' "setup: discovery-a is ready"
          oadd "hypothesis(h2, defect, 'Old words.')"; rc_is 0
          okb --dir "$K" lint; out_has '^WD7 h2' "setup: h2 has no system result"; is_false 'discovery_ready' "setup: h2 blocks"
          oadd "hypothesis(h3, defect, 'New words.')" "supersedes(h3, h2)"; rc_is 0 "the human rewords h2 as h3"
          okb --dir "$K" lint; out_hasnt '^WD7 h2' "a superseded hypothesis has no WD7"; out_has '^WD7 h3' "the new hypothesis needs a result"
          is_false 'discovery_ready' "h3 has no system result yet"
          okb --dir "$K" attest reproduction log4417 'result(h3, reproduced)'; rc_is 0
          okb --dir "$K" lint; rc_is 0; out_hasnt '^WD7' "no WD7 left"
          is_false 'some_untouched_hypothesis' "the superseded h2 is not untouched"
          is_true 'discovery_ready' "a superseded hypothesis does not block discovery_ready"
          is_set 'artifact_vote(V)' 'V = go' "the artifacts vote go"
          oadd "hypothesis(h4, defect, 'Reworded h1.')" "supersedes(h4, h1)"; rc_is 0
          okb --dir "$K" lint; out_hasnt '^WD7 h1'; out_has '^WD7 h4' "the result of h1 does not carry over to h4"
          is_false 'discovery_ready' "h4 needs its own system result"; }
t_RW3() { kb_noshow "$T/n"; K=$T/n; is_true 'discovery_ready' "setup: ready because h1 did not reproduce"
          oadd "hypothesis(h2, defect, 'A retry after a timeout charges an order twice.')" "supersedes(h2, h1)"; rc_is 0
          okb --dir "$K" lint; out_hasnt '^WD6' "no WD6 on the result of a superseded hypothesis"
          out_hasnt '^WD7 h1'; out_has '^WD7 h2'
          is_false 'discovery_has_outcome' "the not_reproduced result of a superseded hypothesis is no outcome"
          is_false 'discovery_ready'; is_set 'artifact_vote(V)' 'V = hold'
          okb --dir "$K" attest reproduction log1 'result(h2, not_reproduced)'; rc_is 0
          okb --dir "$K" lint; out_has '^WD6 ' "WD6 on the result of the new hypothesis"; out_hasnt '^WD7'
          is_true 'discovery_ready' "ready: h2 did not reproduce"; is_set 'artifact_vote(V)' 'V = no_go'; }
t_RW4() { kb_new "$T/k" <<'EOF'
uses([build, discovery]).
request(r1, 'Orders are charged twice.').
hypothesis(h1, defect, 'Old words.').
hypothesis(h2, defect, 'New words.').
supersedes(h2, h1).
claim(c1, introduce, 'No double charge.').
cites(c1, 'charged twice').
universal(c1).
EOF
          K=$T/k; okb --dir "$K" lint; out_hasnt '^E' "setup: no lint error"
          is_set 'supersedes_closure(N, O)' 'N = h2, O = h1'; is_true 'superseded(h1)'
          is_set 'current(X)' 'X = c1' "current is claims only"; is_set 'under(X)' 'X = c1' "under is claims only"
          is_set 'burn(X)' 'X = c1' "burn is claims only"
          oadd "hypothesis(h3, defect, 'Newer words.')" "supersedes(h3, h2)"; rc_is 0
          is_set 'supersedes_closure(N, h1)' 'N = h2|N = h3' "the closure follows a hypothesis chain"
          rejects "a hypothesis cycle" 'cycle' add "supersedes(h1, h3)"
          printf "supersedes(h1, h3).\n" >> "$K/kb.pl"; okb --dir "$K" lint; rc_is 1
          out_has '^E15 .*hypothes' "E15 on a hypothesis cycle names hypotheses"
          is_set 'supersede_cycle(X)' 'X = h1|X = h2|X = h3'; is_false 'done' "a hypothesis cycle makes done false"
          okb --dir "$K" show open; rc_is 0; out_has 'supersede_cycle h1: hypothesis h1' "show open names the kind"; }
t_RW5() { okb help discovery; rc_is 0; any_has 'supersedes\(h[A-Za-z0-9]*, ?h' "help discovery shows supersedes on hypotheses"
          any_hasi 'reword' "help discovery says how to reword"
          okb help core; rc_is 0; any_hasi 'supersedes.*hypothes|hypothes.*supersedes|two hypotheses' "help core: supersedes takes hypotheses too"
          okb help codes; rc_is 0; any_has 'W5 .*new check' "help codes: W5 says to add a new check"; }

# ---- D17 (issue #1): done needs a current claim; report says nothing about questions that do not exist
t_NC1() { K=$T/k; kb_init "$K" build
          is_false 'done' "a build KB with no claim is not done"; is_false 'any_current_claim'
          okb --dir "$K" whynot 'done'; rc_is 0; [ "$(first_line)" = absent ] || note "whynot done: first line '$(first_line)'"
          out_has 'no claim is current' "whynot done names the missing claim"; out_has 'some claim is current'
          oadd "claim(c1, preserve, 'One stays true')" "cites(c1, 'Test request')" "check(k1, c1)" >/dev/null
          add_result "$K" k1 1 pass
          is_true 'any_current_claim'; is_true 'done' "one fulfilled claim: done holds"
          okb --dir "$K" whynot 'done'; rc_is 0; [ "$(first_line)" = holds ] || note "whynot done after a claim: '$(first_line)'"; }
t_NC2() { K=$T/k; kb_init "$K" build; okb --dir "$K" report; rc_is 0
          out_hasnt 'answered every question' "no question exists, so no human answered one"
          rl_is "Guesses with no question" "  - None. No question has a default." "$(rp_sec Guesses)"
          rl_is "Not checked with no claim" "  - None. No claim is current." "$(rp_sec 'Not checked')"
          rl_is "Open with no claim" "  - **no claim**: No claim is current
    - Add a claim. The work is not done without one." "$(rp_sec Open)"
          okb --dir "$K" show open; rc_is 0; out_has '^- no_claim: no claim is current' "show open names the missing claim"
          out_hasnt 'Nothing is open' "show open: something is open"
          okb --dir "$K" report --html "$T/r.html"; rc_is 0
          grep -q 'data-open="no_claim"' "$T/r.html" || note "the page lists the missing claim as an open item"; }
t_NC3() { K=$T/k; kb_init "$K" build; oadd "claim(c1, preserve, 'One stays true')" "cites(c1, 'Test request')" >/dev/null
          okb --dir "$K" report; rc_is 0
          rl_is "Guesses with a claim and no question" "  - None. No question has a default." "$(rp_sec Guesses)"
          out_hasnt 'no claim' "a current claim exists"
          oadd "question(q1, c1, 'Is it one')" "assumed(q1, yes)" "answer(q1, yes, human)" >/dev/null
          okb --dir "$K" report; rc_is 0
          rl_is "Guesses when a human answered" "  - None. A human answered every question with a default." "$(rp_sec Guesses)"
          okb --dir "$K" show open; out_hasnt 'no_claim' "show open: a current claim exists"; }
t_NC4() { K=$T/k; kb_init "$K" build; printf 'any_current_claim.\n' > "$K/rules.pl"
          okb --dir "$K" lint; rc_is 1 "rules.pl cannot make a claim appear for done"; out_has '^E16 rules.pl'
          is_false 'any_current_claim' "the engines ignore the protected clause"; is_false 'done'; }
t_NC5() { K=$T/k; kb_init "$K" discovery
          is_false 'discovery_ready' "no hypothesis and no claim: not ready"; is_false 'discovery_decide'
          is_set 'artifact_vote(V)' 'V = hold' "an empty discovery KB votes hold"; }

# ---- D10: orbit-kb prove with real Lean. The Lake project is built once (prototype lake).
# Each test copies it, so lake build has little to do. Skip when lake is missing.
# LEAN_TC is the newest installed toolchain, named exactly as elan lists it (an -rc name must not be cut to a release that is not installed).
LEAN_TC=$(command -v elan >/dev/null 2>&1 && elan toolchain list 2>/dev/null | awk '$1 ~ /^leanprover\/lean4:v/ {print $1}' | sort -V | tail -1)
lake_fresh() {  # the setup behind lean_proj: a Lake project in $T/lp with one module per case, built
    local d=$T/lp; mkdir -p "$d/Fx"
    printf '%s\n' "$LEAN_TC" > "$d/lean-toolchain"
    printf 'name = "fx"\ndefaultTargets = ["Fx"]\n\n[[lean_lib]]\nname = "Fx"\n' > "$d/lakefile.toml"
    printf 'def loadSteps (n : Nat) : Nat := n\n' > "$d/Fx/Model.lean"
    printf 'import Fx.Model\n\ntheorem load_linear (n : Nat) : loadSteps n ≤ n := Nat.le_refl n\n\ndef helper : Nat := 1\n' > "$d/Fx/Good.lean"
    printf 'theorem with_sorry (n : Nat) : n + 0 = n := by sorry\n' > "$d/Fx/Sorry.lean"
    printf 'theorem by_native : 2 + 2 = 4 := by native_decide\n' > "$d/Fx/Native.lean"
    printf 'axiom cheat : 1 = 2\ntheorem by_axiom : 1 = 2 := cheat\n' > "$d/Fx/Ax.lean"
    printf 'import Fx.Good\n\ntheorem own (n : Nat) : n = n := rfl\n' > "$d/Fx/Other.lean"
    printf 'import Lean\nopen Lean Elab Command in\nset_option debug.skipKernelTC true in\nrun_cmd liftCoreM <| addDecl (.thmDecl { name := `bogus, levelParams := [], type := mkConst ``False, value := mkConst ``True.intro })\n' > "$d/Fx/Hack.lean"
    printf 'theorem bad : 1 = 2 := rfl\n' > "$d/Fx/Broken.lean"
    ( cd "$d" && lake build Fx.Good Fx.Sorry Fx.Native Fx.Ax Fx.Other Fx.Hack >/dev/null 2>&1 ) || note "setup: lake build failed"
    K=$T/kb; kb_init "$K" build
    oadd "claim(c1, preserve, 'Load is linear')" "cites(c1, 'Load is linear')" "universal(c1)" >/dev/null 2>&1 || note "setup: add failed: $(snip "$err")"
}
lean_proj() {  # lean_proj: $K is a KB with universal claim c1, $LP is the Lake project
    if [ -z "$LEAN_TC" ] || ! command -v lake >/dev/null 2>&1; then skip_test "lake or a Lean toolchain is missing"; return 1; fi
    use_proto lake; LP=$T/lp
}
prove_rejects() {  # prove_rejects LABEL MSG_RE FILE THEOREM: prove exits 1, says why, and records nothing
    local label=$1 re=$2; shift 2
    cp "$K/kb.pl" "$T/.kb.before"
    okb --dir "$K" prove c1 "$@"; rc_is 1 "$label"
    any_hasi "$re" "$label: the reason"; any_has 'Nothing was recorded' "$label"
    same_file "$K/kb.pl" "$T/.kb.before" "$label: kb.pl"
    ls "$K"/runs/proof-* >/dev/null 2>&1 && note "$label: a proof log exists"
    return 0
}
t_PV1() { lean_proj || return 0; is_true 'burn_open(c1)'
          okb --dir "$K" prove c1 "$LP/Fx/Good.lean" load_linear; rc_is 0 "a real proof"; out_has '^Statement: .*loadSteps n ≤ n'
          has_fact "$K/kb.pl" "attest(a1, lean_proof, c1, proof(c1, _), script, _)"
          okb --dir "$K" lint; rc_is 0 "lint after prove"; is_true 'burn_proved(c1)'; is_false 'burn_open(c1)'
          grep -q '^file .* Fx/Model.lean$' "$K/runs/proof-a1.log" || note "the log covers the imported model file"
          printf '\n-- edit\n' >> "$LP/Fx/Model.lean"; is_false 'burn_proved(c1)' "the model changed"; is_set 'proof_changed(X)' 'X = a1'
          okb --dir "$K" prove c1 "$LP/Fx/Good.lean" load_linear; rc_is 0 "prove again after the edit"; is_true 'burn_proved(c1)'; }
t_PV2() { lean_proj || return 0; prove_rejects sorry 'sorry' "$LP/Fx/Sorry.lean" with_sorry; }
t_PV3() { lean_proj || return 0; prove_rejects native 'axiom.*native|native_decide' "$LP/Fx/Native.lean" by_native; }
t_PV4() { lean_proj || return 0; prove_rejects axiom 'cheat' "$LP/Fx/Ax.lean" by_axiom; }
t_PV5() { lean_proj || return 0; prove_rejects def 'not a theorem' "$LP/Fx/Good.lean" helper
          prove_rejects missing 'no declaration' "$LP/Fx/Good.lean" no_such_theorem; }
t_PV6() { lean_proj || return 0; prove_rejects othermodule 'declared in module Fx.Good' "$LP/Fx/Other.lean" load_linear
          prove_rejects library 'declared in module Init' "$LP/Fx/Good.lean" Nat.add_comm; }
t_PV7() { lean_proj || return 0; prove_rejects kernel 'leanchecker' "$LP/Fx/Hack.lean" bogus; }
t_PV8() { lean_proj || return 0; prove_rejects build 'lake build' "$LP/Fx/Broken.lean" bad; }
t_PV9() { lean_proj || return 0; okb --dir "$K" prove c9 "$LP/Fx/Good.lean" load_linear; rc_is 2 "no such claim"
          okb --dir "$K" prove c1 "$T/nope.lean" load_linear; rc_is 2 "no such file"
          printf 'theorem t : True := trivial\n' > "$T/loose.lean"; okb --dir "$K" prove c1 "$T/loose.lean" t; rc_is 2 "no Lake project"; any_has 'lakefile'
          okb --dir "$K" prove c1; rc_is 2 "usage"; }
# D10 follow-up: the log records the statement (MS) and the absent config files (F7); a
# config file that changes, or appears, reopens the burn (MC, F7).
t_PV10() { lean_proj || return 0
           okb --dir "$K" prove c1 "$LP/Fx/Good.lean" load_linear; rc_is 0 "a real proof"
           grep -qx 'statement ∀ (n : Nat), loadSteps n ≤ n' "$K/runs/proof-a1.log" || note "the log records the statement of the theorem"
           grep -qx 'theorem load_linear' "$K/runs/proof-a1.log" || note "the log records the theorem"
           grep -qx 'absent lakefile.lean' "$K/runs/proof-a1.log" || note "the log records the absent lakefile.lean"
           is_true 'burn_proved(c1)'
           printf 'import Lake\nopen Lake DSL\npackage fx\n@[default_target] lean_lib Fx\n' > "$LP/lakefile.lean"
           is_set 'proof_changed(X)' 'X = a1' "a lakefile.lean that appears after the proof"
           rm "$LP/lakefile.lean"; is_true 'burn_proved(c1)' "the project is as it was"
           printf '# a comment\n' >> "$LP/lakefile.toml"; is_set 'proof_changed(X)' 'X = a1' "an edit of lakefile.toml"; }
# MF: the module of --module must be the module of FILE.
t_PV11() { lean_proj || return 0; prove_rejects modfile 'not the file' "$LP/Fx/Other.lean" load_linear --module Fx.Good; }
# MN: a file that changes while prove checks it (here during leanchecker) is not a proof.
t_PV12() { lean_proj || return 0; local real; real=$(command -v lake); mkdir -p "$T/bin"
           printf '#!/bin/sh\nif [ "$1 $2" = "env leanchecker" ]; then printf "\\n-- touched\\n" >> "%s/Fx/Model.lean"; fi\nexec "%s" "$@"\n' "$LP" "$real" > "$T/bin/lake"
           chmod +x "$T/bin/lake"
           PATH="$T/bin:$PATH" prove_rejects changed 'changed while' "$LP/Fx/Good.lean" load_linear; }

t_GD() { # D8: query done on 20 claims x 2 runs is answered and cross-checked in ground mode (default timeout)
         gd_kb "$T/k"; K=$T/k
         okb --dir "$K" lint; rc_is 0 "the generated KB is valid"
         q 'done'; rc_is 0 "every claim is fulfilled: done holds"; out_has '^true'
         any_hasnt 'CROSS-CHECK SKIPPED' "done is cross-checked"; any_hasnt 'ENGINE DISAGREEMENT'; any_hasnt "$NOTE_RAW" "the build rules are a supported form: no raw fallback"
         add_result "$K" k20 41 fail
         q 'done'; rc_is 1 "k20 failed last: done is false"; any_hasnt 'CROSS-CHECK SKIPPED' "done is cross-checked"; any_hasnt 'ENGINE DISAGREEMENT'
         is_set 'under(X)' 'X = c20'; any_hasnt 'CROSS-CHECK SKIPPED' "under(X) -n 0 is cross-checked"; }
t_GU() { # D8: an unsupported form (a constraint) falls back to the raw program with a NOTE, and the answer is still right
         kb_new "$T/k" <<'EOF'
uses([]).
request(r1, 'Add one').
decl(rule, plus_one(int, int), 'The second number is the first plus one.', '').
EOF
         echo 'plus_one(X, Y) :- Y #= X + 1.' > "$T/k/rules.pl"; K=$T/k
         q 'plus_one(1, Y)'; rc_is 0; any_has 'Y = 2'; err_has "$NOTE_RAW_RE" "the raw fallback NOTE on stderr"; any_hasnt 'ENGINE DISAGREEMENT'; }
t_X10() { kb_h2 "$T/k"; K=$T/k; ORBIT_KB_SCASP_FLAGS=--forall=sasp q 'finding_lead(F)'; rc_is 1 "ORBIT_KB_SCASP_FLAGS replaces the default"; }

# ================================================================ WN: whynot, Y: why
t_WN1() { kb_wn "$T/k"; K=$T/k; okb --dir "$K" whynot 'current(c1)'; rc_is 0; [ "$(first_line)" = holds ] || note "first line '$(first_line)'"; }
t_WN2() { kb_wn "$T/k"; K=$T/k; okb --dir "$K" whynot 'world(door_open)'; rc_is 0; [ "$(first_line)" = contradicts ] || note "first line '$(first_line)'"; }
t_WN3() { kb_wn "$T/k"; K=$T/k; okb --dir "$K" whynot 'current(c9)'; rc_is 0; [ "$(first_line)" = absent ] || note "first line '$(first_line)'"; [ "$(printf '%s\n' "$out" | wc -l)" -ge 2 ] || note "a justification follows the verdict"; }
t_WN4() { kb_wn "$T/k"; K=$T/k; okb --dir "$K" whynot 'world(door_closed)'; [ "$(first_line)" = holds ] || note "a fact with a -clause elsewhere still holds: '$(first_line)'"; okb --dir "$K" whynot 'world(window)'; [ "$(first_line)" = absent ] || note "no clause for it: absent, got '$(first_line)'"; }
t_Y1() { mkclaim; okb --dir "$K" declare 'gizmo(id, text)' --doc 'A gizmo.' --template '@(1) is a gizmo called @(2)' >/dev/null; oadd "gizmo(g1, sprocket)" >/dev/null
         okb --dir "$K" why 'gizmo(g1, N)'; rc_is 0; any_hasf 'g1 is a gizmo called sprocket' "the local template text"; }
t_Y2() { kb_q "$T/k"; K=$T/k; okb --dir "$K" why 'current(c1)'; rc_is 0; out_has 'c1'; out_has 'because|holds|evidence'; }
t_Y3() { kb_q "$T/k"; K=$T/k; okb --dir "$K" why 'current(c9)'; rc_is 1 "why on a false goal has no answer"; }

# ================================================================ L: lint
t_L0() { copy_fixture valid; okb --dir "$T/valid" lint; rc_is 0; out_hasnt '^E[0-9]'; out_hasnt '^W[0-9]'; okb --dir "$T/valid" lint --strict; rc_is 0 "no warnings either"; }
t_L0b() { copy_fixture valid_local; okb --dir "$T/valid_local" lint; rc_is 0 "local decls and rules, D2 allowed non-ground unit clause"; out_hasnt '^E[0-9]'; out_hasnt '^E6'; out_hasnt '^E7'; out_has '^W2'; }
# fx_lint FIXTURE CODE EXTRA-ALLOWED-CODES: the fixture's error codes must be exactly CODE (plus the allowed extras),
# and each "% <-- CODE" marker line must carry a diagnostic with that code.
fx_lint() {
    local name=$1 code=$2 extra=${3:-} want got c m
    copy_fixture "$name" "$T/f"; okb --dir "$T/f" lint
    case $code in E*) rc_is 1;; *) rc_is 0 "warnings alone do not fail";; esac
    got=$(lint_codes)
    case $code in
      E*) for c in $got; do case $c in E*) [ "$c" = "$code" ] || [[ " $extra " == *" $c "* ]] || note "unexpected $c (want only $code${extra:+ plus $extra}); output: $(snip "$out")";; esac; done ;;
      W*) for c in $got; do case $c in E*) note "unexpected error $c";; W*) [ "$c" = "$code" ] || [[ " $extra " == *" $c "* ]] || note "unexpected $c (want only $code${extra:+ plus $extra})";; esac; done ;;
    esac
    [[ " $got " == *" $code "* ]] || note "missing $code; got [$got]"
    # marker lines
    while IFS=: read -r file ln _; do
        [ -n "$file" ] || continue
        for m in $(sed -n "${ln}p" "$T/f/$file" | grep -oE '<-- [EW][0-9]+' | cut -d' ' -f2); do
            printf '%s\n' "$out" | grep -Eq "^$m .*${file//./\\.}:$ln:" || note "no $m diagnostic for $file:$ln"
        done
    done < <(cd "$T/f" && grep -n -- '<-- [EW][0-9]' kb.pl rules.pl 2>/dev/null | awk -F: '{print $1":"$2":"}')
}
t_E1() { fx_lint e1_syntax E1 E11; }
t_E2() { fx_lint e2_undeclared E2; fx_lint e2_arity E2; any_hasf 'claim'; fx_lint e2_rule_body E2 E11; }
t_E3() { fx_lint e3_oneof E3; fx_lint e3_time E3; }
t_E4() { fx_lint e4_dangling E4; fx_lint e4_wrong_kind E4; }
t_E5() { fx_lint e5_duplicate E5; fx_lint e5_cross E5; }
t_E6() { fx_lint e6_nonground E6 E3; }
t_E7() { fx_lint e7_wrong_place E7; local n; n=$(printf '%s\n' "$out" | grep -c '^E7 '); [ "$n" -ge 2 ] || note "E7 twice expected (kb.pl and rules.pl), got $n"
         printf '%s\n' "$out" | grep -Eq '^E7 .*rules\.pl' || note "no E7 for rules.pl"; printf '%s\n' "$out" | grep -Eq '^E7 .*kb\.pl' || note "no E7 for kb.pl"; }
t_E8() { fx_lint e8_writer E8; fx_lint e8_script_type E8; }
t_E9() { fx_lint e9_no_log E9; fx_lint e9_bad_header E9; }
t_E10() { fx_lint e10_no_uses E10; fx_lint e10_not_first E10; fx_lint e10_unknown_module E10; }
t_E11() { fx_lint e11_compile E11; }
t_E13() { fx_lint e13_atom_digits E13; any_hasi 'rename'; }
t_A18() { mkclaim; rejects atomdigits 'rename' add "world(order_4417)"; }
t_A19() { mkclaim; rejects atomdigits_id 'rename' add "risk(rk_12, 'x')"; okb init "$T/new" --request a --id req_9; rc_is 1 "init --id with a trailing _digits"; [ -e "$T/new/kb.pl" ] && note "kb.pl written despite the rejection"; true; }
t_E12() { fx_lint e12_not_var E12; fx_lint e12_named_var E12; any_hasi 'helper|any_|predicate'; }
t_W1() { copy_fixture valid "$T/f"; echo 'changed' >> "$T/f/plan.txt"; okb --dir "$T/f" lint; rc_is 0 "a warning alone is exit 0"; out_has '^W1 '
         okb --dir "$T/f" lint --strict; rc_is 1 "--strict turns the warning into exit 1"; rm "$T/f/plan.txt"; okb --dir "$T/f" lint; out_has '^W1 ' "missing file"; rc_is 0; }
t_W3() { fx_lint w3_no_cites W3; }
t_W4() { fx_lint w4_no_reader W4 W2; out_has '^W2 '; }
t_W5() { fx_lint w5_superseded_check W5; }
# 2026-10-27: check ids are unique (E5) and facts are append-only, so a check cannot be pointed
# at the new claim. W5 says to add a new check of the new claim, and it stops once that claim
# has a check of its own.
t_W5b() { copy_fixture w5_superseded_check "$T/f"; K=$T/f; okb --dir "$K" lint; rc_is 0
          out_has '^W5 .*[Aa]dd a new check of c2' "W5 says to add a new check of the new claim"
          out_has '^W5 .*orbit-kb run' "W5 says to run the new check"
          out_hasnt '^W5 .*Point the check' "W5 must not say to point the old check at the new claim"
          printf "check(k2, c2).\n" >> "$K/kb.pl"; okb --dir "$K" lint; rc_is 0
          out_hasnt '^W5' "no W5 once the new claim has a check of its own"; }
t_W5c() { kb_new "$T/k" <<'EOF'
uses([]).
request(r1, 'Fix the thing').
claim(c1, preserve, 'It works').
cites(c1, 'Fix the thing').
claim(c2, preserve, 'It works better').
cites(c2, 'Fix the thing').
claim(c3, preserve, 'It works best').
cites(c3, 'Fix the thing').
supersedes(c2, c1).
supersedes(c3, c2).
check(k1, c1).
check(k2, c2).
EOF
          K=$T/k; okb --dir "$K" lint; rc_is 0
          [ "$(printf '%s\n' "$out" | grep -c '^W5 ')" = 2 ] || note "want W5 on k1 and k2: $(snip "$out")"
          out_has '^W5 .*k1.*claim c3 replaces' "W5 on k1 names the current claim c3"
          out_has '^W5 .*k2.*claim c3 replaces' "W5 on k2 names the current claim c3"
          out_hasnt '^W5 .*claim c2 replaces' "c2 is superseded too, so W5 does not name it"
          printf "check(k3, c3).\n" >> "$K/kb.pl"; okb --dir "$K" lint; rc_is 0
          out_hasnt '^W5' "no W5 once the current claim c3 has a check"; }
t_W6() { fx_lint w6_extension W6; okb --dir "$T/f" lint --strict; rc_is 1 "--strict with W6"; }
t_LS() { copy_fixture valid_local "$T/f"; okb --dir "$T/f" lint --strict; rc_is 1 "W2 under --strict"; okb --dir "$T/f" lint; rc_is 0; }
t_LH1() { kb_new "$T/k" <<'EOF'
uses([]).
request(r1, 'Hook').
claim(c1, preserve, 'x').
cites(c1, 'x').
EOF
    printf "lint_issue('W9', c1, 'custom hook warning') :- claim(c1, _, _).\n" > "$T/k/rules.pl"; K=$T/k; okb --dir "$K" lint; rc_is 0; out_has '^W9 c1: custom hook warning' "module hook output format"; }
t_LH2() { kb_new "$T/k" <<'EOF'
uses([]).
request(r1, 'Hook').
claim(c1, preserve, 'x').
cites(c1, 'x').
EOF
    printf "lint_issue('E99', c1, 'custom hook error') :- claim(c1, _, _).\n" > "$T/k/rules.pl"; K=$T/k; okb --dir "$K" lint; rc_is 1; out_has '^E99 c1: custom hook error'; }
# ================================================================ D7: review fixes (contract D7, E14, E13 on strings)
kb_d7() {  # kb_d7 DIR: a KB with fact predicates q, r, w and the rule predicate p, all atom-typed
    kb_new "$1" <<'EOF'
uses([]).
request(r1, 'Find the p things').
decl(fact, q(atom), 'A q thing.', '').
decl(fact, r(atom), 'An r thing.', '').
decl(fact, w(atom), 'A w thing.', '').
decl(rule, p(atom), 'A p thing.', '').
r(z).
q(a).
w(b).
EOF
}
t_D7a() { # D7: a syntax error in rules.pl (a rule that ends in a comma) is exit 2, never a quiet "false" (exit 1)
    kb_d7 "$T/k"; K=$T/k; printf 'p(X) :- r(X),\n' > "$K/rules.pl"
    q 'p(X)'; rc_is 2 "query on a predicate of the broken rules.pl"
    q 'r(X)'; rc_is 2 "query on another predicate, same broken rules.pl"
    okb --dir "$K" why 'p(X)'; rc_is 2 "why"
    okb --dir "$K" whynot 'p(z)'; rc_is 2 "whynot"
    okb --dir "$K" show; rc_is 2 "show"
    okb --dir "$K" report; rc_is 2 "report"; }
t_D7b() { # D7: a broken line in kb.pl (after uses/1) is exit 2, never exit 1
    kb_d7 "$T/k"; K=$T/k; printf 'p(X) :- r(X).\n' > "$K/rules.pl"; printf 'q(c\n' >> "$K/kb.pl"
    q 'p(X)'; rc_is 2 "query with a syntax error in kb.pl"
    q 'q(nothere)'; rc_is 2 "a goal that would be false must not exit 1"; }
t_D7c() { # D7: a misspelled head in rules.pl (undeclared pp/1 for the declared rule p/1) is exit 2
    kb_d7 "$T/k"; K=$T/k; printf 'pp(X) :- r(X).\n' > "$K/rules.pl"
    q 'p(X)'; rc_is 2 "p/1 has no clauses because of the typo; the answer must not be a quiet false"; }
t_D7d() { # D7: not before the positive literal that binds its variable; SWI moves it after, answers z and b
    kb_d7 "$T/k"; K=$T/k; printf 'p(X) :- not q(X), w(X).\np(X) :- r(X).\n' > "$K/rules.pl"
    is_set 'p(X)' 'X = b|X = z'
    okb --dir "$K" lint; rc_is 0 "X occurs in the positive literal w(X): safe, no lint error"; out_hasnt '^E14' "no E14"; }
t_E14() { fx_lint e14_unsafe_neg E14; }
t_E13s() { # D7: E13 also checks strings (a string "x_1" in rules.pl)
    kb_new "$T/k" <<'EOF'
uses([]).
request(r1, 'Strings').
decl(rule, s(text), 'A string thing.', '').
EOF
    K=$T/k; printf 's("x_1").\n' > "$K/rules.pl"
    okb --dir "$K" lint; rc_is 1; out_has '^E13 .*rules\.pl' "E13 for the string in rules.pl"; }
t_RC() { # D7: 8 concurrent runs on one KB (kb.lock): run numbers 1..8, unique ids, one matching log per run
    mkclaim; local i pids=() rcs=() cmd n r line
    for i in 1 2 3 4 5 6 7 8; do
        cmd=true; [ $((i % 2)) = 0 ] && cmd=false
        ( cd "$T" && exec timeout "$TMO" "$OKB" --dir "$K" run k1 -- "$cmd" ) >"$T/.c$i" 2>&1 </dev/null &
        pids+=("$!")
    done
    for i in 0 1 2 3 4 5 6 7; do wait "${pids[$i]}"; rcs+=("$?"); done
    for i in 1 2 3 4 5 6 7 8; do   # each process: exit 0 for true, 1 for false, and its "run N k1 R" line
        cmd=pass; [ $((i % 2)) = 0 ] && cmd=fail
        [ "${rcs[$((i-1))]}" = "$([ $cmd = pass ] && echo 0 || echo 1)" ] || note "process $i ($cmd) exited ${rcs[$((i-1))]}: $(snip "$(<"$T/.c$i")")"
        grep -Eq "run [1-8] k1 $cmd" "$T/.c$i" || note "process $i printed no 'run N k1 $cmd' line: $(snip "$(<"$T/.c$i")")"
    done
    local nums; nums=$(kbq "$K/kb.pl" "findall(N, kb(attest(_, test_result, k1, result(k1, N, _), _, _)), L), msort(L, S), print(S)")
    [ "$nums" = "[1,2,3,4,5,6,7,8]" ] || note "run numbers [$nums], want [1,2,3,4,5,6,7,8]"
    has_goal "$K/kb.pl" "findall(A, kb(attest(A,_,_,_,_,_)), L), length(L, N), sort(L, S), length(S, N)" "attestation ids are unique"
    fact_count "$K/kb.pl" "attest(_, test_result, _, _, _, _)" 8 "one test_result per run"
    local logs; logs=$(cd "$K/runs" 2>/dev/null && printf '%s\n' * | LC_ALL=C sort -n | paste -sd' ')
    [ "$logs" = "1-k1.log 2-k1.log 3-k1.log 4-k1.log 5-k1.log 6-k1.log 7-k1.log 8-k1.log" ] || note "run logs [$logs], want 1-k1.log .. 8-k1.log"
    for n in 1 2 3 4 5 6 7 8; do
        r=$(kbq "$K/kb.pl" "kb(attest(_, test_result, k1, result(k1, $n, R), _, _)), write(R)")
        [ -f "$K/runs/$n-k1.log" ] || { note "runs/$n-k1.log is missing"; continue; }
        line=$(head -n1 "$K/runs/$n-k1.log")
        [[ $line =~ ^%\ orbit-kb\ run\ $n\ check=k1\ result=${r:-none}\ exit=[01]\  ]] || note "runs/$n-k1.log header does not match result ${r:-?}: '$line'"
        [ "$(grep -c '^% orbit-kb run ' "$K/runs/$n-k1.log")" = 1 ] || note "runs/$n-k1.log has more than one header"
    done
    okb --dir "$K" lint; rc_is 0 "lint after the concurrent runs"; out_hasnt '^E5' "no E5"; out_hasnt '^E9' "no E9"; out_hasnt '^E1 ' "no E1 (no torn line)"; }
t_LS2() { copy_fixture valid "$T/f";okb --dir "$T/f" lint; printf '%s\n' "$out" | tail -n1 | grep -Eiq '[0-9]|clean|ok|error|warning' || note "no summary line: $(snip "$out")"; }

# ================================================================ SH / RP / DR / HP
t_SH1() { valid_copy; okb --dir "$K" show claims; rc_is 0; out_has 'c1'; out_has 'widget can be saved'; }
t_SH2() { valid_copy; okb --dir "$K" show questions; rc_is 0; out_has 'q1'; out_has 'q2'; }
t_SH3() { kb_done "$T/k"; K=$T/k; printf "question(q2, c2, 'Is it two').\nassumed(q2, no).\ndepends(q2, q1).\nanswer(q1, no, human).\nchange(x3, 'Unrelated').\n" >> $K/kb.pl
          okb --dir "$K" show open; rc_is 0; out_has 'q2'; out_has 'x3'; out_hasnt 'c1' "nothing else is open"; }
t_SH4() { valid_copy; okb --dir "$K" show disclosures; rc_is 0; out_has 'a6|a5'; }
t_SH5() { copy_fixture w6_extension "$T/k"; K=$T/k; okb --dir "$K" show extensions; rc_is 0; out_has 'to_ask'; }
t_SH6() { valid_copy; okb --dir "$K" show; rc_is 0; out_has 'c1'; okb --dir "$K" show all; rc_is 0; out_has 'q1'; }
t_SH7() { valid_copy; okb --dir "$K" show bogus; rc_is 2; }
t_RP1() { valid_copy; okb --dir "$K" report; rc_is 0
          local order; order=$(printf '%s\n' "$out" | grep -oE '^# (Delivered|Claims|Guesses|Disclosures|Not checked|Open|To land):' | sed 's/^# //' | paste -sd' ')
          [ "$order" = "Delivered: Claims: Guesses: Disclosures: Not checked: Open: To land:" ] || note "sections: [$order]"; }
t_RP2() { kb_overunder "$T/k"; K=$T/k; okb --dir "$K" report; rc_is 0; rp_item c1 | grep -q 'Status: under' || note "c1 is under: $(snip "$out")"; rp_item c2 | grep -q 'fulfilled' || note "c2 is fulfilled: $(snip "$out")"; out_has 'x2' "over change in Open"; }
t_RP3() { valid_copy; okb --dir "$K" report; local g; g=$(printf '%s\n' "$out" | awk '/^# Guesses:/{f=1;next} /^# /{f=0} f'); printf '%s\n' "$g" | grep -q q2 || note "q2 (default never answered by a human) is a guess: [$g]"; printf '%s\n' "$g" | grep -q 'q1' && note "q1 was answered by a human, not a guess"; true; }
t_RP4() { kb_overunder "$T/k"; K=$T/k; printf "claim(c3, preserve, 'No check').\ncites(c3, 'Change things').\n" >> $K/kb.pl; okb --dir "$K" report; local g; g=$(printf '%s\n' "$out" | awk '/^# Not checked:/{f=1;next} /^# /{f=0} f'); printf '%s\n' "$g" | grep -q c3 || note "c3 has no check: [$g]"; printf '%s\n' "$g" | grep -q 'c2' && note "c2 has a check"; true; }
t_RP5() { valid_copy; okb --dir "$K" report; local g; g=$(printf '%s\n' "$out" | awk '/^# Disclosures:/{f=1;next} /^# /{f=0} f'); printf '%s\n' "$g" | grep -Eq 'a5|a6|Not measured|slow disk' || note "disclosures missing: [$g]"; }
t_RP6() { kb_new "$T/k" <<'EOF'
uses([]).
request(r1, 'Plain').
claim(c1, preserve, 'x').
cites(c1, 'x').
EOF
    K=$T/k; okb --dir "$K" report; rc_is 0 "report without build"; out_has '^# Claims:'; out_has 'c1'; }

# ---- RL: the layout of the report text (D16 c4, 2026-10-28). Markdown that also reads as raw text:
# "# Section:" headings, a blank line between sections, two-space-indented bullets, the label in
# **bold**, and nested bullets for the detail of a claim that needs attention.
rp_sec() {  # rp_sec NAME: the lines of one section of $out, without its heading
    printf '%s\n' "$out" | awk -v h="# $1:" '$0==h {f=1; next} /^# / {f=0} f'; }
rp_item() {  # rp_item ID: the first bullet of $out that starts with ID, and the lines nested under it
    printf '%s\n' "$out" | awk -v id="$1" 'BEGIN {p = "  - " id}
        !f && substr($0, 1, length(p)) == p && substr($0, length(p) + 1, 1) ~ /[ :]/ {f=1; print; next}
        f && /^    / {print; next} f {exit}'; }
rl_is() {  # rl_is LABEL WANT GOT: exact text
    [ "$2" = "$3" ] || note "$1: want [$(printf '%s' "$2" | tr '\n' '~')] got [$(printf '%s' "$3" | tr '\n' '~')]"; }
t_RL1() { # headings: "# Name:" in contract order, one blank line before each but the first, no trailing blank line
    rh_kb report_review; okb --dir "$K" report; rc_is 0
    local heads; heads=$(printf '%s\n' "$out" | grep -E '^# ' | paste -sd'|')
    rl_is "headings" "# Delivered:|# Claims:|# Guesses:|# Disclosures:|# Waivers:|# Not checked:|# Open:|# To land:" "$heads"
    printf '%s\n' "$out" | grep -qE '^[A-Z][A-Za-z ]*:$' && note "a heading without the # mark"
    local n; n=$(printf '%s\n' "$out" | awk '/^# / && NR > 1 && prev != "" {bad++} {prev = $0} END {print bad + 0}')
    rl_is "a blank line before every heading but the first" 0 "$n"
    [ "$(printf '%s\n' "$out" | sed -n 1p)" = "# Delivered:" ] || note "the first line is the Delivered heading"
    [ -n "$(printf '%s\n' "$out" | tail -n 1)" ] || note "the last line is blank"
    [ "$(printf '%s\n' "$out" | grep -c '^$')" = 7 ] || note "want exactly 7 blank lines (one between sections), got $(printf '%s\n' "$out" | grep -c '^$')"
    rh_kb discovery; okb --dir "$K" report; rc_is 0; out_has '^# Vote:' "the Vote heading"; }
t_RL2() { # every other line is a bullet at two spaces plus two per level; no tabs, no colour codes, no box drawing
    local k bl
    for k in report_review valid overunder nobuild discovery; do
        rh_kb "$k"; okb --dir "$K" report; rc_is 0 "report $k"
        bl=$(printf '%s\n' "$out" | grep -vE '^(# .*:|)$' | grep -vE '^( {2}| {4}| {6}| {8})- [^ ]' | head -n 3)
        [ -z "$bl" ] || note "$k: lines that are not bullets at 2, 4, 6, or 8 spaces: $(snip "$bl")"
        printf '%s\n' "$out" | grep -q "$(printf '\t')" && note "$k: a tab"
        printf '%s\n' "$out" | grep -q "$(printf '\033')" && note "$k: a colour code"
        printf '%s\n' "$out" | LC_ALL=C grep -q $'\xe2[\x94-\x95]' && note "$k: a box-drawing character"
        printf '%s\n' "$out" | grep -qE ' +$' && note "$k: trailing spaces"
    done; true; }
t_RL3() { # a fulfilled claim with nothing to add stays on one line; a claim that needs attention nests its status and checks
    rh_kb report_review; okb --dir "$K" report; rc_is 0
    rl_is "c1 (fulfilled)" "  - c1 **introduce**: The widget can be saved. Status: fulfilled. Checks: k1 (passed)." "$(rp_item c1)"
    rl_is "c2 (under)" "  - c2 **preserve**: Loading stays fast
    - Status: under.
      - It is not fulfilled yet.
    - Checks: k2 (not passed)." "$(rp_item c2)"
    rl_is "c3 (burn waived)" "  - c3 **preserve**: Every saved widget loads back the same
    - Status: fulfilled.
    - Burn: NOT PROVED.
      - A human waived the proof until 2999-01-01T00:00:00Z.
    - Checks: k3 (passed)." "$(rp_item c3)"
    rl_is "c4 (check waived)" "  - c4 **preserve**: Old files still load
    - Status: not fulfilled.
      - A human waived check k4 until 2999-01-01T00:00:00Z, so the claim does not block done until then.
    - Checks: k4 (never run)." "$(rp_item c4)"
    rl_is "c5 (burn open)" "  - c5 **preserve**: Saving never loses data
    - Status: fulfilled.
    - Burn: NOT PROVED.
      - A Lean proof is required.
    - Checks: k5 (passed)." "$(rp_item c5)"
    rl_is "c6 (under, no check)" "  - c6 **introduce**: The save button has a tooltip
    - Status: under.
      - It is not fulfilled yet.
    - Checks: none." "$(rp_item c6)"
    rh_kb valid; okb --dir "$K" report; rc_is 0
    rl_is "c4 (fulfilled, fits in 100 columns)" "  - c4 **preserve**: The new save button is shown. Status: fulfilled. Checks: k3 (passed)." "$(rp_item c4)"
    rl_is "c2 (burn proved) is long, so it nests" "  - c2 **preserve**: Loading stays fast
    - Status: fulfilled.
    - Burn: proved in Lean.
    - Checks: k2 (passed)." "$(rp_item c2)"
    rl_is "no line of a one-line claim is over 100 columns" 0 "$(printf '%s\n' "$out" | awk '/^  - c[0-9]+ \*\*[a-z]+\*\*: .*Status: fulfilled\. / && length($0) > 100 {n++} END {print n + 0}')"; }
t_RL4() { # more than one check: they nest under Checks
    rh_kb report_review; printf "check(k8, c1).\n" >> "$K/kb.pl"; okb --dir "$K" report; rc_is 0
    rl_is "c1 with two checks" "  - c1 **introduce**: The widget can be saved
    - Status: fulfilled.
    - Checks:
      - k1 (passed)
      - k8 (never run)" "$(rp_item c1)"; }
t_RL5() { # the other sections: bullets, the label in bold, detail nested
    rh_kb report_review; okb --dir "$K" report; rc_is 0
    rl_is "q1 (guess)" "  - q1: Is a cold start in scope
    - The default is no. No human answered it." "$(rp_item q1)"
    rl_is "a1 (disclosure)" "  - a1 **unverified**: Not measured on a slow disk
    - About c2, by agent." "$(rp_item a1)"
    rl_is "a2 (disclosure)" "  - a2 **guess**: q2
    - About q2, by agent." "$(rp_item a2)"
    rl_is "w1 (waiver in force)" "  - w1 **in force**: claim c3, due 2999-01-01T00:00:00Z" "$(rp_item w1)"
    rl_is "w3 (waiver lapsed)" "  - w3 **lapsed**: claim c5, due 2001-01-01T00:00:00Z
    - The item blocks done again." "$(rp_item w3)"
    rl_is "c6 (not checked)" "  - c6: The save button has a tooltip
    - It has no check." "$(rp_sec 'Not checked')"
    rl_is "Open: the kind in bold, the first sentence, then the rest nested" "  - **ask**: Ask question q1 now
  - **over**: Change x2 serves no claim
  - **burn open**: Claim c5 needs a Lean proof
    - Prove it with orbit-kb prove, or ask a human for a waiver.
  - **waiver lapsed**: Waiver w3 of the proof of claim c5 was due at 2001-01-01T00:00:00Z
    - The proof is due now." "$(rp_sec Open)"
    rl_is "the Delivered placeholder" "  - (Write what you delivered here.)" "$(rp_sec Delivered)"
    rl_is "the To land placeholder" "  - (Write the steps to land the work here.)" "$(rp_sec 'To land')"
    rh_kb valid; okb --dir "$K" report; rc_is 0
    rl_is "empty Waivers" "  - None." "$(rp_sec Waivers)"
    rl_is "empty Open" "  - Nothing is open." "$(rp_sec Open)"
    rh_kb discovery; okb --dir "$K" report; rc_is 0
    rl_is "Vote: the first sentence, the rest nested" "  - No vote yet
    - The agent votes first, and seals the vote: orbit-kb attest vote r1 'vote(1, CHOICE)'. CHOICE is go, no_go, or hold." "$(rp_sec Vote)"; }
t_RL6() { # without the build module: no status and no burn, only the checks; the report still runs
    rh_kb nobuild; okb --dir "$K" report; rc_is 0
    rl_is "c1 without build, no check" "  - c1 **preserve**: x
    - Checks: none." "$(rp_item c1)"
    printf '%s\n' "$out" | grep -q 'Status:' && note "Status: without the build module"; true; }
t_RL7() { # a long claim text stays on its line (no hard wrap), and the page keeps the status words
    rh_kb report_review
    local long="A saved widget keeps every field, its history, and its attachments when it is loaded back on a second machine after a crash"
    printf "claim(c8, preserve, '%s').\ncites(c8, 'Make saving safe').\n" "$long" >> "$K/kb.pl"
    okb --dir "$K" report; rc_is 0
    rl_is "c8" "  - c8 **preserve**: $long
    - Status: under.
      - It is not fulfilled yet.
    - Checks: none." "$(rp_item c8)"
    okb --dir "$K" report --html "$T/r.html"; rc_is 0
    local sk; for sk in "c1 fulfilled" "c2 under" "c4 waived" "c6 under"; do
        rh_has "$(rh_claim "$T/r.html" "${sk% *}")" "data-status=\"${sk#* }\"" "the page status of ${sk% *}"; done; }

# ---- RH: report --html (D16, 2026-10-28). The page is read as text, through the hooks that the
# contract names: data-section, data-claim with data-status, data-open with data-ref, data-check,
# data-mark, data-kb, data-digest, review-copy, review-text. No test runs the page script.
GOLD=$FIX/report_golden
rh_kb() {  # rh_kb NAME: a KB for the golden report NAME in $T/NAME; K is set
    K=$T/$1
    case $1 in
        valid|report_review) copy_fixture "$1" "$K" ;;
        overunder) kb_overunder "$K" ;;
        nobuild) printf "uses([]).\nrequest(r1, 'Plain').\nclaim(c1, preserve, 'x').\ncites(c1, 'x').\n" | kb_new "$K" ;;
        discovery) printf "uses([discovery]).\nrequest(r1, 'Is it slow').\n" | kb_new "$K" ;;
    esac
}
rh_section() {  # rh_section FILE NAME: the page text from data-section="NAME" to the next data-section
    awk -v n="data-section=\"$2\"" 'index($0, n) {f=1; print; next} f && /data-section="/ {exit} f' "$1"
}
rh_claim() {  # rh_claim FILE ID: the page text of one claim, from data-claim="ID" to its </article>
    awk -v n="data-claim=\"$2\"" 'index($0, n) {f=1} f {print} f && /<\/article>/ {exit}' "$1"
}
rh_has() {  # rh_has TEXT ERE LABEL
    printf '%s\n' "$1" | grep -Eq -- "$2" && return 0
    note "$3: lacks /$2/ ($(snip "$1"))"; return 1
}
rh_hasnt() {
    printf '%s\n' "$1" | grep -Eq -- "$2" || return 0
    note "$3: has /$2/, it must not ($(snip "$1"))"; return 1
}
t_RH1() { # c2 (D16 C4): plain report text is byte-identical to the golden files (made again from the CLI after C4, read by eye); --html prints the same text
    local k
    for k in valid report_review overunder nobuild discovery; do
        rh_kb "$k"; okb --dir "$K" report; rc_is 0 "report $k"
        cmp -s "$T/.out" "$GOLD/$k.txt" || note "report $k: the text differs from $GOLD/$k.txt: $(diff "$GOLD/$k.txt" "$T/.out" | head -n 6 | tr '\n' '~')"
        okb --dir "$K" report --html "$T/$k.html"; rc_is 0 "report --html $k"
        cmp -s "$T/.out" "$GOLD/$k.txt" || note "report --html $k: stdout differs from $GOLD/$k.txt"
        [ -s "$T/$k.html" ] || note "report --html $k wrote no file"
    done; }
t_RH2() { # c1: one self-contained page with each claim, its status as a label, and its checks
    rh_kb report_review; okb --dir "$K" report --html "$T/r.html"; rc_is 0; err_has 'HTML written to .*r\.html' "stderr names the file"
    local h; h=$(<"$T/r.html")
    head -c 15 "$T/r.html" | grep -qi '^<!doctype html>' || note "the page does not start with <!doctype html>"
    rh_hasnt "$h" '<script[^>]*src=|<link[^>]*href=|@import|url\(|(src|href|action)="?(https?:)?//' "no external resource"
    local c s
    for c in c1:fulfilled c2:under c3:fulfilled c4:waived c5:fulfilled c6:under c7:fulfilled; do
        s=${c#*:}; c=${c%%:*}
        rh_has "$h" "data-claim=\"$c\"[^>]*data-status=\"$s\"" "claim $c has status $s"
        rh_claim "$T/r.html" "$c" | grep -q ">$s<" || note "claim $c: the status $s is not shown as a text label"
    done
    for c in c1:k1 c2:k2 c3:k3 c4:k4 c5:k5 c7:k7; do rh_has "$(rh_claim "$T/r.html" "${c%%:*}")" "data-check=\"${c#*:}\"" "claim ${c%%:*} lists check ${c#*:}"; done
    rh_has "$(rh_claim "$T/r.html" c2)" 'Status: under\. It is not fulfilled yet\.' "the status sentence of the text report"
    rh_has "$(rh_claim "$T/r.html" c5)" 'Burn: NOT PROVED\. A Lean proof is required\.' "the burn sentence of the text report"
    rh_kb nobuild; okb --dir "$K" report --html "$T/n.html"; rc_is 0 "a KB without build"
    rh_has "$(<"$T/n.html")" 'data-claim="c1"[^>]*data-status="none"' "without build a claim has no status"
    rh_kb discovery; okb --dir "$K" report --html "$T/d.html"; rc_is 0 "a discovery KB"
    rh_has "$(rh_section "$T/d.html" vote)" 'No vote yet' "the Vote section"; }
t_RH3() { # c1: every KB string is escaped
    kb_new "$T/k" <<'EOF'
uses([build]).
request(r1, 'Try <i>markup</i>').
claim(c1, introduce, '<script>alert(1)</script> & "q" \'s\'').
cites(c1, '</textarea><img src=x onerror=alert(2)>').
example(c1, '<!-- open comment').
check(k1, c1).
EOF
    K=$T/k; okb --dir "$K" report --html "$T/r.html"; rc_is 0
    local h; h=$(<"$T/r.html")
    rh_hasnt "$h" '<script>alert|<img src=x|<i>markup|<!-- open' "a KB string is not markup"
    rh_has "$h" '&lt;script&gt;alert\(1\)&lt;/script&gt; &amp; (&quot;|&#34;)q(&quot;|&#34;)' "claim text escaped"
    rh_has "$h" '&lt;/textarea&gt;&lt;img src=x onerror=alert\(2\)&gt;' "citation escaped"
    rh_has "$h" '&lt;i&gt;markup&lt;/i&gt;' "request escaped"
    rh_hasnt "$(<"$GOLD/report_review.txt")" '&lt;' "setup: the text report is not escaped"
    rh_kb report_review; okb --dir "$K" report --html "$T/v.html"; rc_is 0
    rh_hasnt "$(<"$T/v.html")" '<b>bold</b>|<b>x</b>' "fixture claim c7 and its example"; }
t_RH4() { # c3: open items come first: under claims, open burns, lapsed waivers, questions to ask
    rh_kb report_review; okb --dir "$K" report --html "$T/r.html"; rc_is 0
    local o po pc
    po=$(grep -n 'data-section="open"' "$T/r.html" | head -n1 | cut -d: -f1)
    pc=$(grep -n 'data-section="claims"' "$T/r.html" | head -n1 | cut -d: -f1)
    [ -n "$po" ] && [ -n "$pc" ] && [ "$po" -lt "$pc" ] || note "the open section ($po) must come before the claims ($pc)"
    o=$(rh_section "$T/r.html" open)
    rh_has "$o" 'data-open="under"[^>]*data-ref="c2"' "under c2"
    rh_has "$o" 'data-open="under"[^>]*data-ref="c6"' "under c6"
    rh_has "$o" 'data-open="burn_open"[^>]*data-ref="c5"' "open burn c5"
    rh_has "$o" 'data-open="waiver_lapsed"[^>]*data-ref="w3"' "lapsed waiver w3"
    rh_has "$o" 'data-open="to_ask"[^>]*data-ref="q1"' "question q1"
    rh_has "$o" 'data-open="over"[^>]*data-ref="x2"' "over x2"
    rh_hasnt "$o" 'data-ref="(c1|c3|c4|c7|w1|w2)"' "nothing else is open"
    rh_kb valid; okb --dir "$K" report --html "$T/v.html"; rc_is 0
    o=$(rh_section "$T/v.html" open); rh_hasnt "$o" 'data-open=' "valid fixture: nothing open"; rh_has "$o" 'Nothing is open' "valid fixture: says so"; }
t_RH5() { # c3: each claim carries its evidence
    rh_kb report_review; okb --dir "$K" report --html "$T/r.html"; rc_is 0
    local c
    c=$(rh_claim "$T/r.html" c1)
    rh_has "$c" 'Make saving safe' "c1 citation"; rh_has "$c" 'close the app, open it again' "c1 example"
    rh_has "$c" 'runs/2-k1\.log' "c1: the log of the latest run of k1"; rh_hasnt "$c" 'runs/1-k1\.log' "c1: not an older run"
    rh_has "$c" 'data-check="k1"[^>]*data-run="2"[^>]*data-result="pass"' "c1: k1 latest run 2 passed"
    c=$(rh_claim "$T/r.html" c2)
    rh_has "$c" 'data-check="k2"[^>]*data-run="3"[^>]*data-result="fail"' "c2: k2 run 3 failed"; rh_has "$c" 'runs/3-k2\.log' "c2 log"
    rh_has "$c" 'd1' "c2 divergence id"; rh_has "$c" 'slow on a cold start' "c2 divergence note"
    rh_has "$c" 'Not measured on a slow disk' "c2 disclosure"; rh_has "$c" 'Is a cold start in scope' "c2 question"
    c=$(rh_claim "$T/r.html" c3); rh_has "$c" 'w1' "c3 waiver id"; rh_has "$c" '2999-01-01T00:00:00Z' "c3 waiver due"; rh_has "$c" 'Prove it after the demo' "c3 waiver reason"
    c=$(rh_claim "$T/r.html" c4); rh_has "$c" 'w2' "c4: the waiver of its check"; rh_has "$c" 'data-check="k4"[^>]*data-run="none"' "c4: k4 never ran"
    c=$(rh_claim "$T/r.html" c5); rh_has "$c" 'w3' "c5 waiver"; rh_has "$c" 'lapsed' "c5 waiver lapsed"; }
t_RH6() { # c3: review marks, one button, a textarea fallback, keyed by the KB path and the report digest
    rh_kb report_review; okb --dir "$K" report; local d; d=sha256:$(sha "$T/.out")
    okb --dir "$K" report --html "$T/r.html"; rc_is 0
    local h; h=$(<"$T/r.html")
    rh_has "$h" "data-digest=\"$d\"" "the digest of the plain report"
    rh_has "$h" "data-kb=\"$K\"" "the KB path"
    local m; for m in ok doubt wrong; do rh_has "$(rh_claim "$T/r.html" c2)" "data-mark=\"$m\"" "claim mark $m"; done
    rh_has "$h" 'id="review-copy"' "the copy button"; rh_has "$h" '<textarea[^>]*id="review-text"' "the textarea fallback"
    printf '%s\n' "$h" | grep -n 'localStorage' | grep -vq 'try' && note "every localStorage access is inside try (one per line)"
    true; }
t_RH7() { # --open runs xdg-open (or open) only when given
    mkdir -p "$T/bin"; local x
    for x in xdg-open open; do printf '#!/bin/sh\nprintf "%%s\\n" "$@" >> "%s/opened"\n' "$T" > "$T/bin/$x"; chmod +x "$T/bin/$x"; done
    rh_kb report_review
    PATH="$T/bin:$PATH" okb --dir "$K" report --html "$T/r.html"; rc_is 0
    [ -e "$T/opened" ] && note "a browser opened without --open"
    PATH="$T/bin:$PATH" okb --dir "$K" report --html "$T/r.html" --open; rc_is 0 "--open"
    local i; for i in 1 2 3 4 5 6 7 8 9 10; do [ -s "$T/opened" ] && break; sleep 0.2; done
    grep -q 'r\.html' "$T/opened" 2>/dev/null || note "--open did not open the page"; }
t_RH8() { # usage
    rh_kb report_review
    okb --dir "$K" report --html; rc_is 2 "--html needs a value"
    okb --dir "$K" report --open; rc_is 2 "--open needs --html"
    okb --dir "$K" report extra; rc_is 2 "report still takes no argument"
    okb --dir "$K" report --html "$T/no/such/dir/r.html"; rc_is 2 "a path that cannot be written"; any_hasnt 'internal error' "a plain message"; }
t_RH9() { # c3: an engine disagreement is an open item, and the exit is 2 (H3 on the raw program)
    kb_new "$T/k" <<'EOF'
uses([build]).
request(r1, 'Runs').
claim(c1, preserve, 'The runs behave').
cites(c1, 'Runs').
check(k1, c1).
EOF
    K=$T/k; add_result "$K" k1 1 pass; add_result "$K" k1 2 fail
    okb --dir "$K" report --html "$T/a.html"; rc_is 0 "the default flags agree"
    rh_has "$(<"$T/a.html")" 'data-crosscheck="agree"' "the page says the engines agree"
    ORBIT_KB_SCASP_GROUND=raw ORBIT_KB_SCASP_FLAGS=--forall=all okb --dir "$K" report --html "$T/r.html"; rc_is 2 "a disagreement exits 2"
    any_hasf 'ENGINE DISAGREEMENT'
    rh_has "$(rh_section "$T/r.html" open)" 'data-open="disagreement"' "the disagreement is an open item"; }
t_DR1() { okb doctor; rc_is 0 "doctor on this machine"; any_hasi 'swipl'; any_hasi 'scasp'; }
t_DR2() { okb doctor; any_has 'H1'; any_has 'H2'; any_has 'H3'; any_has 'H4'; local l; for l in H1 H2 H3 H4; do anyout | grep -E "$l" | grep -Eiq 'pass|ok' || note "no passing line for $l"; anyout | grep -E "$l" | grep -Eiq "$FAIL_WORD" && note "the $l line reports a failure"; done; true; }
# A doctor line that reports a failure: the word fail, fails, failed, or failure. Whole words only,
# so a line that names the rule failed_after (D8: the grounder-corruption control) is no failure.
FAIL_WORD='\bfail(s|ed|ure)?\b'
dr_passes() {  # dr_passes ERE LABEL: doctor (in $out/$err) has a line matching ERE (case-insensitive), and each such line passes
    local lines; lines=$(anyout | grep -Ei -- "$1")
    [ -n "$lines" ] || { note "doctor has no line for $2 (/$1/): $(snip "$out")"; return 1; }
    printf '%s\n' "$lines" | grep -Eiv -- '\b(ok|pass(ed|es)?)\b' | grep -q . && note "a $2 line does not say ok or pass: $(snip "$lines")"
    printf '%s\n' "$lines" | grep -Eiq -- "$FAIL_WORD" && note "a $2 line reports a failure: $(snip "$lines")"
    return 0
}
t_DR4() { # D8: doctor adds the ground-mode H4 control and the grounder-corruption control; both pass
          okb doctor; rc_is 0 "doctor on this machine"
          dr_passes 'H4.*ground|ground.*H4' "ground-mode H4 control"
          dr_passes 'corrupt' "grounder-corruption control"; }
t_DR3() { local e; e=$(mktemp -d "$base/emptylib.XXXXXX"); ( cd "$T" && ORBIT_KB_LIB="$e" exec timeout "$TMO" "$OKB" doctor ) >"$T/.out" 2>"$T/.err" </dev/null; rc=$?; out=$(<"$T/.out"); err=$(<"$T/.err")
         rc_is 2 "doctor with a broken library"; any_hasi 'librar'; }
t_HP1() { okb help; rc_is 0; any_has 'H1'; any_has 'H2'; any_hasi 'query'; any_hasi 'lint'; }
t_HP2() { okb help query; rc_is 0; any_hasi 'query'; any_hasi -- '--why|--json'; }
t_HP3() { okb --help; rc_is 0 "--help"; any_hasi 'usage'; }
t_HP4() { okb help; rc_is 0; any_has 'How to use'; local t
          for t in core build discovery codes answers; do any_has "orbit-kb help $t" "general help names $t"; done; }
t_HP5() { local t; for t in core build discovery codes answers; do
            okb help "$t"; rc_is 0 "help $t"; any_hasi "$t" "help $t is not empty"; done; }
t_HP6() { okb help nosuchtopic; rc_is 2 "unknown topic"; }
t_HP7() { okb init "$T/hp7" --request 'x'; rc_is 0; any_has 'Next:.*help core'; }

# ================================================================ run
for id in K1 K2 K3 K4 K5 K6 K7 K8; do :; done
run_test t_K1 K1 "--dir finds the KB"
run_test t_K2 K2 "\$ORBIT_KB finds the KB"
run_test t_K3 K3 "parent-directory walk finds the KB"
run_test t_K4 K4 "no KB: exit 2, message names all three options"
run_test t_K5 K5 "kb.pl without uses/1 first is not a KB"
run_test t_K6 K6 "resolution order: --dir, then \$ORBIT_KB"
run_test t_K7 K7 "--dir with no KB exits 2"
run_test t_K8 K8 "no command and unknown command exit 2"
run_test t_K9 K9 "no KB here, but one below: the message names it"
run_test t_I1 I1 "init creates kb.pl with uses and request, prints the path"
run_test t_I2 I2 "second init exits 1 and keeps kb.pl"
run_test t_I3 I3 "init --uses build"
run_test t_I4 I4 "init --id"
run_test t_I5 I5 "init --request-file"
run_test t_I6 I6 "init keeps quotes in the request and lints clean"
run_test t_I7 I7 "init without a request is a usage error"
run_test t_I8 I8 "fresh KB: lint clean, no claims"
run_test t_U1 U1 "uses build: a discovery KB gets the build module; only line 1 changes"
run_test t_U2 U2 "uses: a module already in use writes nothing"
run_test t_U3 U3 "uses: unknown module exits 1, no module exits 2"
run_test t_U4 U4 "uses: add refuses uses/1 and names orbit-kb uses; the order is kept"
run_test t_U5 U5 "uses: a comment and text before the full stop are kept; kb.pl parses"
run_test t_U6 U6 "uses: a bad first term is exit 1 and kb.pl does not change"
run_test t_U7 U7 "uses: duplicates and the comma form; -- is a usage error; -h anywhere"
run_test t_U8 U8 "uses: waits for the KB lock"
run_test t_U9 U9 "uses: says to lint; a new module can add lint findings (ED7)"
run_test t_A1 A1 "add appends valid facts in order and prints them"
run_test t_A2 A2 "add rejects an undeclared predicate and names declare"
run_test t_A3 A3 "after declare the same fact is accepted"
run_test t_A4 A4 "add rejects a label outside oneof"
run_test t_A5 A5 "add rejects a dangling ref"
run_test t_A6 A6 "add rejects a duplicate id"
run_test t_A7 A7 "add rejects a non-ground fact"
run_test t_A8 A8 "add rejects a fact for a rule predicate"
run_test t_A9 A9 "add rejects test_result and points to run"
run_test t_A10 A10 "add batch is all or nothing"
run_test t_A11 A11 "facts in one batch may refer to each other"
run_test t_A12 A12 "trailing dot is optional"
run_test t_A13 A13 "add accepts a ground -fact"
run_test t_A14 A14 "add rejects a wrong arity"
run_test t_A15 A15 "add rejects a syntax error"
run_test t_A16 A16 "add rejects a bad time"
run_test t_A17 A17 "add rejects a writer that is not allowed"
run_test t_D1 D1 "declare appends decl/4 with the template"
run_test t_D2 D2 "declare twice exits 1"
run_test t_D3 D3 "declare with an unknown type exits 1"
run_test t_D4 D4 "declare: a new arity of a core name is accepted, the same name and arity exits 1"
run_test t_D5 D5 "declare-attest then attest"
run_test t_D6 D6 "declare --kind rule rejects facts for it"
run_test t_AT1 AT1 "attest generates id a1 and the UTC time"
run_test t_AT2 AT2 "attest takes the next free id"
run_test t_AT3 AT3 "approval by agent is rejected"
run_test t_AT4 AT4 "approval by human; digest(current) is replaced"
run_test t_AT5 AT5 "attest on a missing subject is rejected"
run_test t_AT6 AT6 "attest --id, and a duplicate id is rejected"
run_test t_AT7 AT7 "attest with a wrong shape is rejected"
run_test t_AT8 AT8 "attest of a script type is rejected"
run_test t_AT9 AT9 "attest with a dangling ref inside the predicate"
run_test t_S1 S1 "subject records the sha256 and prints it"
run_test t_S2 S2 "subject inside the KB stores a relative path (D3)"
run_test t_S3 S3 "subject outside the KB stores an absolute path (D3)"
run_test t_S4 S4 "subject of a missing file exits 1"
run_test t_S5 S5 "subject refresh rewrites its line in place"
run_test t_S6 S6 "moved KB: W1 and digest(current) need no refresh (D3)"
run_test t_S7 S7 "moved valid fixture still lints clean (D3)"
run_test t_S8 S8 "subject refresh without change keeps one line"
run_test t_R1 R1 "run: fail is run 1 exit 1, then pass is run 2 exit 0"
run_test t_R2 R2 "run log header format, output tail on fail"
run_test t_R3 R3 "run passes lint E9"
run_test t_R4 R4 "run on an unknown check fails and writes nothing"
run_test t_R5 R5 "run numbers are global per KB"
run_test t_R6 R6 "run prints the last 40 lines on a fail"
run_test t_R7 R7 "D1: uses([]) run, then was_red without build"
run_test t_R8 R8 "run without a command is a usage error"
run_test t_R9 R9 "run log holds stdout and stderr"
run_test t_B1 B1 "introduce needs a fail before the pass (pass only: under)"
run_test t_B2 B2 "introduce: fail then pass is fulfilled"
run_test t_B3 B3 "preserve needs only a pass"
run_test t_B4 B4 "pass then later fail is not fulfilled"
run_test t_B5 B5 "pass, fail, pass is passed"
run_test t_B6 B6 "fail, pass, fail is not fulfilled"
run_test t_B7 B7 "a refuted claim is not fulfilled"
run_test t_RF1 RF1 "R1: disproof and lean_result accept refuted(text)"
run_test t_RF2 RF2 "R2: refuted(C) holds for refuted(text)"
run_test t_RF3 RF3 "R2: a lean_result refuted(text) refutes the claim"
run_test t_RF4 RF4 "R3: a bare refuted is E3 and the message shows refuted('...')"
run_test t_RF5 RF5 "R1: refuted takes one text argument"
run_test t_RF6 RF6 "R4: inconclusive, abstained, stated, tested(N) are unchanged"
run_test t_RF7 RF7 "R5: why prints the counterexample"
run_test t_VT1 VT1 "D14 V1: vote attestations by agent and human; bad shapes and writers fail"
run_test t_VT2 VT2 "D14 V1: one vote per writer per round (ED10); the largest round counts"
run_test t_VT3 VT3 "D14 V2: artifact_vote is go, no_go, or hold by rule"
run_test t_VT4 VT4 "D14 V3: gate needs the human plus one other role; gate_split"
run_test t_VT5 VT5 "D14 V3: no_go wins with the artifacts; a later round replaces the earlier"
run_test t_VT6 VT6 "D14 V4: report seals the votes until the human votes"
run_test t_VT7 VT7 "D14 V4: WD9 and a late agent vote is refused"
run_test t_VT8 VT8 "D14 V2/V3: rules.pl cannot change the vote rules (E16)"
run_test t_VT9 VT9 "D14 V6: WD6 and the discovery_has_outcome template do not recommend NO-GO"
run_test t_VT10 VT10 "D14: help attest has a vote example that runs; help query names gate"
run_test t_B8 B8 "under and over (a change that serves nothing is over)"
run_test t_B9 B9 "done is true when everything is clear"
run_test t_B10 B10 "done is false with an open claim among several facts (H1)"
run_test t_B11 B11 "done is false with an over change"
run_test t_B12 B12 "done is false with a question to ask; to_ask after a human defeats a default"
run_test t_B13 B13 "burn: contested twice, universal, burn_requested"
run_test t_B14 B14 "to_ask: dependent question after a human answer defeats the default"
run_test t_B15 B15 "to_ask: human agrees with the default, nothing to ask"
run_test t_B16 B16 "to_ask: an agent answer does not count"
run_test t_B17 B17 "to_ask: contested claim asks its questions"
run_test t_B18 B18 "stale: approval on the old digest after a subject refresh"
run_test t_B19 B19 "a superseded claim is not current and not under"
run_test t_B20 B20 "done stays false with several facts present (H1 guard)"
run_test t_B21 B21 "D5: to_ask drops a question once its claim is superseded; done holds"
run_test t_BP1 BP1 "D10: a burn without a proof is open, and done is false"
run_test t_BP2 BP2 "D10: lean_result stated and tested do not close a burn"
run_test t_BP3 BP3 "D10: lean_result has no proved verdict (E3)"
run_test t_BP4 BP4 "D10: a lean_proof with its log closes the burn; done holds"
run_test t_BP5 BP5 "D10: a changed proof file reopens the burn (proof_changed)"
run_test t_BP6 BP6 "D10: a lean_proof without its log is E9 and does not count"
run_test t_BP7 BP7 "D10: only orbit-kb prove writes lean_proof (E8, attest, add)"
run_test t_BP8 BP8 "D10: a human waiver closes the burn; report says NOT PROVED with the due time"
run_test t_BP9 BP9 "D10: an agent cannot waive a proof"
run_test t_BP10 BP10 "D10: a waiver past its due time lapses; done is false"
run_test t_BP11 BP11 "D10: a superseded claim has no open burn"
run_test t_BP12 BP12 "D10: conformance is optional; conforms holds after its check passes"
run_test t_BP13 BP13 "D10: each burn trigger needs a proof"
run_test t_BP14 BP14 "D10: proved/1 is a reserved name (s(CASP) model wrapper)"
run_test t_SC1 SC1 "D10 follow-up: a claim that supersedes a burning claim inherits the burn (F11, S1)"
run_test t_SC2 SC2 "D10 follow-up: the burn passes along a supersede chain (S1)"
run_test t_SC3 SC3 "D10 follow-up: supersedes(c1, c1) is E15, and done is false (L-F2, S2)"
run_test t_SC4 SC4 "D10 follow-up: a two-claim supersede cycle: E15, done false, both engines finish (S2, S3)"
run_test t_SC5 SC5 "D10 follow-up: add refuses a supersede cycle"
run_test t_SC6 SC6 "D10 follow-up: rules.pl clauses for the burn rules are E16 and do not count (F8)"
run_test t_SC7 SC7 "D10 follow-up: an E7 waiver in rules.pl or burn_proved fact in kb.pl does not count (F8)"
run_test t_SC8 SC8 "D10 follow-up: the time type checks month, day, leap years, hour, minute, second (F10)"
run_test t_SC9 SC9 "D10 follow-up: a waiver with an invalid due time counts as lapsed (F9)"
run_test t_SC10 SC10 "D10 follow-up: waivers compare with the clock (MT)"
run_test t_SC11 SC11 "D10 follow-up: a log copied for another claim or edited does not count (F6, MX, MD)"
run_test t_WV1 WV1 "D13: a waiver targets a claim, a check, or a question; any other id is E4 (W1)"
run_test t_WV2 WV2 "D13: a check waiver covers its claim for done, but does not fulfil it (W3)"
run_test t_WV3 WV3 "D13: a check waiver does not close a burn; a claim waiver does (W2, W3)"
run_test t_WV4 WV4 "D13: a question waiver makes the question not to_ask (W4)"
run_test t_WV5 WV5 "D13: a lapsed or invalid check or question waiver blocks done again (W5)"
run_test t_WV6 WV6 "D13: an agent waiver of a check or a question is E8 and does not count (W5)"
run_test t_WV7 WV7 "D13: a claim waiver does not cover its checks or questions (W2)"
run_test t_WV8 WV8 "D13: report lists every waiver with target, kind, due time, and lapse (W6)"
run_test t_WV9 WV9 "D13: rules.pl clauses for check_waived and question_waived are E16 (W7)"
run_test t_WV10 WV10 "D13: the waiver example in help attest is typable in a shell"
run_test t_RW1 RW1 "D15: supersedes takes two hypotheses; a claim-hypothesis mix is E4"
run_test t_RW2 RW2 "D15: a superseded hypothesis has no WD7 and does not block discovery_ready"
run_test t_RW3 RW3 "D15: a superseded hypothesis's not_reproduced is no outcome and has no WD6"
run_test t_RW4 RW4 "D15: closure and E15 work on hypotheses; current, under, burn stay claims"
run_test t_RW5 RW5 "D15: help discovery, core, and codes describe rewording and the new W5"
run_test t_NC1 NC1 "D17: done needs a current claim; whynot done names it"
run_test t_NC2 NC2 "D17: report and show open on a KB with no claim"
run_test t_NC3 NC3 "D17: Guesses says no question has a default, unless a human answered one"
run_test t_NC4 NC4 "D17: a rules.pl clause for any_current_claim is E16"
run_test t_NC5 NC5 "D17: an empty discovery KB is not ready and votes hold"
run_test t_PV1 PV1 "D10: prove records a real proof; an edit of an imported file reopens it"
run_test t_PV2 PV2 "D10: prove rejects sorry"
run_test t_PV3 PV3 "D10: prove rejects native_decide"
run_test t_PV4 PV4 "D10: prove rejects a local axiom"
run_test t_PV5 PV5 "D10: prove rejects a def and a missing name"
run_test t_PV6 PV6 "D10: prove rejects a theorem from another module"
run_test t_PV7 PV7 "D10: prove rejects a declaration that skipped the kernel (leanchecker)"
run_test t_PV8 PV8 "D10: prove rejects a file that does not build"
run_test t_PV9 PV9 "D10: prove usage errors exit 2"
run_test t_PV10 PV10 "D10 follow-up: the log has the statement and absent config files; a config change reopens (F7, MS, MC)"
run_test t_PV11 PV11 "D10 follow-up: prove rejects a --module that is not the module of FILE (MF)"
run_test t_PV12 PV12 "D10 follow-up: prove rejects a file that changes during the checks (MN)"
run_test t_H3a H3a "H3: passed(K) -n 0 lists k2, k3, k4 (default flags)"
run_test t_H3b H3b "H3: --forall=all gives ENGINE DISAGREEMENT, exit 2"
run_test t_H3c H3c "H3: ground passed(k1) is false, passed(k4) is true"
run_test t_H3d H3d "D8: H3 under --forall=all in ground mode: exactly k2, k3, k4, no disagreement"
run_test t_Q1 Q1 "query with no answer exits 1"
run_test t_Q2 Q2 "declared empty predicate exits 1 without an error"
run_test t_Q3 Q3 "undeclared predicate in a query exits 2"
run_test t_Q4 Q4 "query syntax error exits 2"
run_test t_Q5 Q5 "output: true, X = v, and the -n default of 1"
run_test t_Q6 Q6 "output with two variables"
run_test t_Q7 Q7 "built-ins in a query"
run_test t_Q8 Q8 "--json prints s(CASP) JSON"
run_test t_Q9 Q9 "--html writes a file"
run_test t_Q10 Q10 "--why adds a justification"
run_test t_Q11 Q11 "wrong arity in a query exits 2"
run_test t_Q12 Q12 "-n 2"
run_test t_Q13 Q13 "bad -n value is a usage error"
run_test t_X1 X1 "H2 under default flags: no answer, exit 1"
run_test t_X2 X2 "H2 under --forall=all: ENGINE DISAGREEMENT, exit 2"
run_test t_X3 X3 "H2 under --forall=all with -n 0"
run_test t_X2g X2g "D8: H2 under --forall=all in ground mode: correct, no disagreement"
run_test t_X4 X4 "H1 bad form in rules.pl: disagreement, exit 2"
run_test t_X5 X5 "H1 bad form: lint reports E12"
run_test t_X6 X6 "H1 helper form agrees with both engines"
run_test t_X7 X7 "H1 named variable under not: disagreement, exit 2"
run_test t_X8 X8 "#= constraint: CROSS-CHECK SKIPPED and (unchecked)"
run_test t_X9 X9 "answer sets differ under --forall=all with -n 0"
run_test t_X10 X10 "ORBIT_KB_SCASP_FLAGS replaces the default flag"
run_test t_GD GD "D8: query done on 20 claims x 2 runs: cross-checked, correct"
run_test t_GU GU "D8: a constraint falls back to the raw program with a NOTE, answer correct"
run_test t_WN1 WN1 "whynot: holds"
run_test t_WN2 WN2 "whynot: contradicts (a -world fact)"
run_test t_WN3 WN3 "whynot: absent, with a justification"
run_test t_WN4 WN4 "whynot: holds and absent for a predicate with a -clause"
run_test t_Y1 Y1 "why shows the local declare --template text"
run_test t_Y2 Y2 "why prints a justification"
run_test t_Y3 Y3 "why on a false goal exits 1"
run_test t_L0 L0 "valid fixture lints clean, also with --strict"
run_test t_L0b L0b "valid_local lints without errors (D2 allowed case)"
run_test t_E1 E1 "lint E1 syntax error with file and line"
run_test t_E2 E2 "lint E2 undeclared and wrong arity"
run_test t_E3 E3 "lint E3 type error"
run_test t_E4 E4 "lint E4 dangling ref"
run_test t_E5 E5 "lint E5 duplicate id"
run_test t_E6 E6 "lint E6 non-ground fact in kb.pl"
run_test t_E7 E7 "lint E7 clause in the wrong place, both cases (D2)"
run_test t_E8 E8 "lint E8 writer not allowed"
run_test t_E9 E9 "lint E9 test_result without a matching log"
run_test t_E10 E10 "lint E10 uses/1 missing, not first, unknown module"
run_test t_E11 E11 "lint E11 assembled program does not compile"
run_test t_E13 E13 "lint E13 atom ends in _digits (H4)"
run_test t_A18 A18 "add rejects an atom ending in _digits and suggests a rename (H4)"
run_test t_A19 A19 "add and init --id reject _digits atoms (H4)"
run_test t_E12 E12 "lint E12 not over a body-only variable"
run_test t_W1 W1 "lint W1 changed subject; --strict exits 1"
run_test t_W3 W3 "lint W3 claim without cites"
run_test t_W4 W4 "lint W4 fact predicate with no reader"
run_test t_W5 W5 "lint W5 check on a superseded claim"
run_test t_W5b W5b "lint W5 says to add a new check of the new claim, and stops when it has one"
run_test t_W5c W5c "lint W5 follows a supersede chain to the current claim"
run_test t_W6 W6 "lint W6 local rule extends a core predicate"
run_test t_LS LS "lint --strict turns W2 into exit 1"
run_test t_E14 E14 "lint E14 unsafe negation: head variable in no positive literal (D7)"
run_test t_E13s E13s "lint E13 also checks strings (D7)"
run_test t_D7a D7a "D7: syntax error in rules.pl: query, why, whynot, show, report exit 2"
run_test t_D7b D7b "D7: syntax error in kb.pl: query exits 2, never 1"
run_test t_D7c D7c "D7: misspelled head in rules.pl: query exits 2"
run_test t_D7d D7d "D7: not before its binding literal: p(X) -n 0 is exactly z and b"
run_test t_RC RC "D7: 8 concurrent runs: numbers 1..8, unique ids, matching logs, lint clean"
run_test t_LS2 LS2 "lint prints a summary line"
run_test t_LH1 LH1 "lint_issue hook: warning output"
run_test t_LH2 LH2 "lint_issue hook: E code exits 1"
run_test t_SH1 SH1 "show claims"
run_test t_SH2 SH2 "show questions"
run_test t_SH3 SH3 "show open"
run_test t_SH4 SH4 "show disclosures"
run_test t_SH5 SH5 "show extensions"
run_test t_SH6 SH6 "show and show all"
run_test t_SH7 SH7 "show with a bad topic exits 2"
run_test t_RP1 RP1 "report sections in contract order"
run_test t_RP2 RP2 "report: fulfilled, under, over"
run_test t_RP3 RP3 "report: guesses"
run_test t_RP4 RP4 "report: not checked"
run_test t_RP5 RP5 "report: disclosures"
run_test t_RP6 RP6 "report without build"
run_test t_RL1 RL1 "report text: # headings, one blank line between sections"
run_test t_RL2 RL2 "report text: bullets at two spaces per level; plain text only"
run_test t_RL3 RL3 "report text: a claim that needs attention nests its status, burn, and checks"
run_test t_RL4 RL4 "report text: several checks nest under Checks"
run_test t_RL5 RL5 "report text: the other sections use bullets, bold labels, and nesting"
run_test t_RL6 RL6 "report text without the build module"
run_test t_RL7 RL7 "report text: long claim text is not wrapped; the page keeps the status words"
run_test t_RH1 RH1 "report text is byte-identical to the golden files; --html prints the same text"
run_test t_RH2 RH2 "report --html: one self-contained page, each claim with a status label and its checks"
run_test t_RH3 RH3 "report --html escapes every KB string (<script> in a claim)"
run_test t_RH4 RH4 "report --html: open items come first"
run_test t_RH5 RH5 "report --html: each claim carries its evidence"
run_test t_RH6 RH6 "report --html: review marks, copy button, textarea, KB path and report digest"
run_test t_RH7 RH7 "report --html: --open runs the opener only when given"
run_test t_RH8 RH8 "report --html: usage errors exit 2"
run_test t_RH9 RH9 "report --html: an engine disagreement is an open item and exits 2"
run_test t_DR1 DR1 "doctor exits 0 on this machine"
run_test t_DR2 DR2 "doctor reports H1, H2, H3 self-tests as passing"
run_test t_DR3 DR3 "doctor with a broken library exits 2"
run_test t_DR4 DR4 "D8: doctor reports the ground-mode H4 and grounder-corruption controls as passing"
run_test t_HP1 HP1 "help explains H1 and H2"
run_test t_HP2 HP2 "help query"
run_test t_HP3 HP3 "--help"
run_test t_HP4 HP4 "general help starts with how to use and names each topic"
run_test t_HP5 HP5 "each help topic prints"
run_test t_HP6 HP6 "unknown help topic exits 2"
run_test t_HP7 HP7 "init prints a Next line"

run_tests
echo "----"
echo "orbit-kb=$OKB lib=$LIB pass=$pass fail=$fail skip=$skip ${failed[*]:-}"
[ $fail = 0 ]
