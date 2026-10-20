#!/usr/bin/env bash
# Black-box tests for shared/link/.local/bin/orbit-kb.
#
# The ONLY source of expected behavior is thoughts/orbit-kb-contract.md (v2.1). No test
# reads the CLI source or the library source, so the implementation is never the source
# of what a test expects. Where the contract is ambiguous, the test follows the reading
# that makes a failure loud, and the comment above the test says so.
#
# Usage: scripts/orbit-kb/test_orbit_kb.sh [path-to-orbit-kb]
#   (or ORBIT_KB_BIN=/path/to/orbit-kb scripts/orbit-kb/test_orbit_kb.sh)
#   ONLY='<regex>' runs only the tests whose id matches, for example ONLY='^(K|I)[0-9]'.
#   ORBIT_KB_TEST_JOBS=N runs the tests in N parallel workers (default 4, see below).
#   ORBIT_KB_TEST_JOBS=1 runs them one at a time in this shell, as the suite always did.
#   The default CLI is the repo copy. ORBIT_KB_LIB is set to the repo library, so the
#   suite works before installation (override: ORBIT_KB_TEST_LIB).
#   Exit status: 0 when every test passes, 1 when a test fails, 2 when the suite cannot
#   run (the CLI, the library, or a tool is missing, or ORBIT_KB_TEST_JOBS is not a number).
#   The suite is one CPU-heavy job: run it as `heavy bash scripts/orbit-kb/test_orbit_kb.sh`.
#
# Each test runs in a fresh mktemp -d and removes it at the end. Fixtures in fixtures/ are
# copied first and never modified. KBs that a test needs are built inline, next to the
# expected result. Facts in kb.pl are read back with swipl (kbq.pl, embedded below), so
# no test depends on the spacing or the quoting that the CLI chooses when it writes.
#
# Parallel runs (ORBIT_KB_TEST_JOBS > 1):
#  - The default is 4 workers (fewer when fewer CPUs are available, for example under
#    HEAVY_CPUS). The suite is one heavy job, and heavy lets 2 jobs run at once on this
#    shared, heat-limited laptop (4 P-cores of 14 cores). 4 workers use about 4 cores, so the
#    other heavy job and the interactive sessions keep the rest. Measured on an idle machine
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
#   U   uses: add a module to an existing KB                   (CLI: uses)                      : U1-U4
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
#   BP  burns: open, proved, changed, waived, lapsed       (Build module; D10)              : BP1-BP14
#   PV  prove with real Lean (skipped without lake)        (CLI: prove; D10)                : PV1-PV9
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
OKB=${1:-${ORBIT_KB_BIN:-$here/../../shared/link/.local/bin/orbit-kb}}
LIB=${ORBIT_KB_TEST_LIB:-$here/../../shared/link/.local/share/orbit-kb}
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
    printf '  Build it first (shared/link/.local/bin/orbit-kb), or pass its path as the first argument.\n' >&2
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
# file is DIR/lean/P.lean; the digest covers it alone.
add_proof() {  # add_proof DIR ID CLAIM [TIME]
    local d=$1 id=$2 c=$3 tm=${4:-2026-10-15T11:00:00Z} sha dg
    mkdir -p "$d/runs" "$d/lean"; [ -f "$d/lean/P.lean" ] || printf 'theorem t : True := trivial\n' > "$d/lean/P.lean"
    sha="sha256:$(sha "$d/lean/P.lean")"
    dg="sha256:$(printf '%s %s\n' "$sha" P.lean | sha256sum | cut -d' ' -f1)"
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
t_K4() { mkdir -p "$T/empty/sub"; okb_in "$T/empty/sub" query 'true'; rc_is 2; any_has -- '--dir'; any_has 'ORBIT_KB'; any_hasi 'parent|walk|kb\.pl'; }
t_K5() { mkdir -p "$T/x"; printf 'request(r1, a).\nuses([]).\n' > "$T/x/kb.pl"; okb_in "$T/x" query 'true'; rc_is 2 "kb.pl whose first term is not uses/1 is no KB"; }
t_K6() { valid_copy; mkdir -p "$T/other"; okb_in "$T/other" --dir "$K" query 'current(c1)'; rc_is 0 "--dir wins over the cwd";
         mkdir -p "$T/kb2"; printf 'uses([]).\n' > "$T/kb2/kb.pl"
         ORBIT_KB="$T/kb2" okb_env --dir "$K" query 'current(c1)'; rc_is 0 "--dir wins over \$ORBIT_KB"; }
t_K7() { okb --dir "$T/does-not-exist" query 'true'; rc_is 2 "--dir without a KB"; }
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
t_A17() { mkclaim; rejects badwriter 'writer|allow|agent|human' add "attest(a1, disproof, c1, verdict(c1, refuted), human, '2026-10-15T10:00:00Z')"; }

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
t_B7() { kb_intro "$T/k"; K=$T/k; add_result $K k2 1 pass; echo "attest(d1, disproof, c2, verdict(c2, refuted), agent, '2026-10-15T10:00:30Z')." >> $K/kb.pl
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
          okb --dir "$K" report; out_has 'c1.*NOT PROVED.*waived.*2999-01-01'; }
t_BP9() { kb_burndone "$T/k"; K=$T/k; rejects agentwaiver 'writer|human' attest waiver c1 "waive(c1, '2999-01-01T00:00:00Z', 'x')"
          printf "attest(w1, waiver, c1, waive(c1, '2999-01-01T00:00:00Z', x), agent, '2026-10-15T11:00:00Z').\n" >> $K/kb.pl
          okb --dir "$K" lint; rc_is 1; out_has '^E8'; is_false 'burn_waived(c1)' "an agent cannot waive a proof"; is_false 'done'; }
t_BP10() { kb_burndone "$T/k"; K=$T/k; printf "attest(w1, waiver, c1, waive(c1, '2020-01-01T00:00:00Z', 'Old deadline'), human, '2019-12-01T00:00:00Z').\n" >> $K/kb.pl
           is_set 'waiver_lapsed(X)' 'X = w1'; is_false 'burn_waived(c1)'; is_false 'done' "the waiver is past its due time"
           okb --dir "$K" report; out_has 'Waiver w1 of the proof of claim c1 was due at 2020-01-01'; }
t_BP11() { kb_burndone "$T/k"; K=$T/k; printf "supersedes(c3, c1).\nclaim(c3, preserve, 'One stays true, new words').\ncites(c3, 'Do two things').\ncheck(k3, c3).\nserves(x1, c3).\n" >> $K/kb.pl
           add_result $K k3 4 pass; is_true 'burn(c1)'; is_false 'burn_open(c1)' "a superseded claim has no open burn"; is_true 'done'; }
t_BP12() { kb_burndone "$T/k"; K=$T/k; add_proof "$K" p1 c1
           printf "check(k9, c1).\nconformance(k9).\n" >> $K/kb.pl; is_false 'conforms(c1)'; is_true 'done' "conformance is optional"
           add_result $K k9 4 pass; is_true 'conforms(c1)'; is_true 'done'; }
t_BP13() { kb_burn "$T/k"; K=$T/k; is_set 'burn_open(X)' 'X = c1|X = c3|X = c4' "contested twice, universal, and requested all need a proof"; }
t_BP14() { mkclaim; rejects reserved 'reserved' declare 'proved(ref(claim))' --doc 'x' --kind rule; }

# ---- D10: orbit-kb prove with real Lean. The Lake project is built once (prototype lake).
# Each test copies it, so lake build has little to do. Skip when lake is missing.
LEAN_TC=$(command -v elan >/dev/null 2>&1 && elan toolchain list 2>/dev/null | sed -n 's/^\(leanprover\/lean4:v[0-9.]*\).*/\1/p' | sort -V | tail -1)
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
          local order; order=$(printf '%s\n' "$out" | grep -oE '^(Delivered|Claims|Guesses|Disclosures|Not checked|Open|To land):' | paste -sd' ')
          [ "$order" = "Delivered: Claims: Guesses: Disclosures: Not checked: Open: To land:" ] || note "sections: [$order]"; }
t_RP2() { kb_overunder "$T/k"; K=$T/k; okb --dir "$K" report; rc_is 0; out_has 'c1.*under|under.*c1'; out_has 'c2.*fulfilled|fulfilled.*c2'; out_has 'x2' "over change in Open"; }
t_RP3() { valid_copy; okb --dir "$K" report; local g; g=$(printf '%s\n' "$out" | awk '/^Guesses:/{f=1;next} /^[A-Z][A-Za-z ]*:/{f=0} f'); printf '%s\n' "$g" | grep -q q2 || note "q2 (default never answered by a human) is a guess: [$g]"; printf '%s\n' "$g" | grep -q 'q1' && note "q1 was answered by a human, not a guess"; true; }
t_RP4() { kb_overunder "$T/k"; K=$T/k; printf "claim(c3, preserve, 'No check').\ncites(c3, 'Change things').\n" >> $K/kb.pl; okb --dir "$K" report; local g; g=$(printf '%s\n' "$out" | awk '/^Not checked:/{f=1;next} /^[A-Z][A-Za-z ]*:/{f=0} f'); printf '%s\n' "$g" | grep -q c3 || note "c3 has no check: [$g]"; printf '%s\n' "$g" | grep -q 'c2' && note "c2 has a check"; true; }
t_RP5() { valid_copy; okb --dir "$K" report; local g; g=$(printf '%s\n' "$out" | awk '/^Disclosures:/{f=1;next} /^[A-Z][A-Za-z ]*:/{f=0} f'); printf '%s\n' "$g" | grep -Eq 'a5|a6|Not measured|slow disk' || note "disclosures missing: [$g]"; }
t_RP6() { kb_new "$T/k" <<'EOF'
uses([]).
request(r1, 'Plain').
claim(c1, preserve, 'x').
cites(c1, 'x').
EOF
    K=$T/k; okb --dir "$K" report; rc_is 0 "report without build"; out_has '^Claims:'; out_has 'c1'; }
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
run_test t_PV1 PV1 "D10: prove records a real proof; an edit of an imported file reopens it"
run_test t_PV2 PV2 "D10: prove rejects sorry"
run_test t_PV3 PV3 "D10: prove rejects native_decide"
run_test t_PV4 PV4 "D10: prove rejects a local axiom"
run_test t_PV5 PV5 "D10: prove rejects a def and a missing name"
run_test t_PV6 PV6 "D10: prove rejects a theorem from another module"
run_test t_PV7 PV7 "D10: prove rejects a declaration that skipped the kernel (leanchecker)"
run_test t_PV8 PV8 "D10: prove rejects a file that does not build"
run_test t_PV9 PV9 "D10: prove usage errors exit 2"
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
run_test t_DR1 DR1 "doctor exits 0 on this machine"
run_test t_DR2 DR2 "doctor reports H1, H2, H3 self-tests as passing"
run_test t_DR3 DR3 "doctor with a broken library exits 2"
run_test t_DR4 DR4 "D8: doctor reports the ground-mode H4 and grounder-corruption controls as passing"
run_test t_HP1 HP1 "help explains H1 and H2"
run_test t_HP2 HP2 "help query"
run_test t_HP3 HP3 "--help"

run_tests
echo "----"
echo "orbit-kb=$OKB lib=$LIB pass=$pass fail=$fail skip=$skip ${failed[*]:-}"
[ $fail = 0 ]
