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
# Requirement map (contract v2.1 + D20 + D21 + D22; section names, not line numbers, because the contract is edited):
#   K   KB resolution: --dir, $ORBIT_KB, parent walk, exit 2   (CLI: KB resolution, exit codes) : K1-K10
#   I   init                                                   (CLI: init)                      : I1-I8
#   U   uses: add a module to an existing KB                   (CLI: uses)                      : U1-U9
#   A   add: validation, all or nothing, rejections            (CLI: add; Declarations; Types)  : A1 A4-A22
#   D   rule declarations by add (decl(rule, ...))            (CLI: add; T26 removed declare)  : D1-D4 D6
#   AT  attest: id, time, writers, digest(current)             (CLI: attest)                    : AT1-AT9
#   S   subject: sha256, relative paths, refresh               (CLI: subject; D3)               : S1-S8
#   R   run: numbering, log header, tail, unknown check, D1    (CLI: run; Files; D1)            : R1-R9
#   B   core and build rules through query, H1 guard           (Core rules; Build module)       : B1-B21
#   H3  passed/1 with arithmetic under negation                (Engine)                         : H3a H3c
#   Q   query: output, -n, exit codes, --why                   (CLI: query; exit codes)         : Q1-Q13
#   X   engine: negation as failure, E17, E18, no scasp        (Engine; D20)                    : X1-X10
#   G   20x2 done                                              (Engine)                         : GD
#   WN  whynot: holds, absent, what blocks (D20)               (CLI: whynot)                    : WN1-WN5
#   FL  flares: visual claims, demos, approvals (D21)          (Build module; D21)              : FL1-FL11
#   Y   why: justification text, #pred templates               (CLI: why; Environment facts)    : Y1-Y3
#   L   lint E1-E18, W1-W6, WD8, --strict, hook, summary       (Lint; D2; D20)                  : L0 L0b E1-E10 E17 W1 W3-W6 LS LS2 LH1 LH2 WD8
#   D7  review fixes: broken sources exit 2, unsafe negation, kb.lock (D7)                   : D7a-D7d RC E14
#   SH  show   RP report   DR doctor (self-tests)   HP help (CLI: show, report, doctor, help) : SH1-SH7 RP1-RP7 DR1-DR3 HP1-HP7
#   RL  report text layout: headings, bullets, nesting (D16 c4)   : RL1-RL7
#   RH  report --html: golden text, page, escaping, open first, evidence, review (D16)   : RH1-RH9
#   BP  burns: open, proved, changed, waived, lapsed       (Build module; D10)              : BP1-BP14
#   SC  D10 follow-up: inherited burns, supersede cycles, rules.pl, times, proof logs (D10 follow-up) : SC1-SC11
#   RF  refuted(Counterexample) in disproof and lean_result (2026-10-21) : RF1-RF7
#   WV  waivers of a check or a question (D13, 2026-10-21)     (Build module; D13)              : WV1-WV10
#   RW  reword a hypothesis with supersedes; W5 names a new check (D15, 2026-10-27) : RW1-RW5 W5b W5c
#   NC  no current claim: done, whynot, report, show open (D17, issue #1)   : NC1-NC5
#   VT  weighted vote: vote attestations, gate, sealed agent vote (D14)    (Discovery module; D14) : VT1-VT10
#   LG  attest model_result reads the solver log (D18)    (CLI: attest; D18)               : LG1-LG3
#   PV  prove with real Lean (skipped without lake)        (CLI: prove; D10, D10 follow-up) : PV1-PV12
#   FU  schema declared on first use, W7, E19 typo guard    (CLI: add, declare; Lint; D22)   : FU1-FU6 FU8 (FU7 superseded, not run)
#   RT  retired: declare-attest and depends/2              (D22)                            : RT1-RT3
#   KD  declare removed, --doc, show kinds (T26); a later --doc, show kinds under E19/E2, repeated --doc (T40) : KD1-KD9
#   BL  blocking/1 and show blocking                       (Core and build rules; D22)      : BL1-BL11 BL6b BL8b
#   PN  pin stamp                                          (CLI: pin; D22)                  : PN1 PN2
#   PH  help names the phases                              (CLI: help; D22)                 : PH1
#   AC  acceptance criteria: ac/1, show and draft blocking (D29)                             : AC1-AC5
#   VR  verification records: actor, review_saw, verdicts, independently_verified, WR1 (D28) : VR1-VR12 (VR7-VR11: T38; VR12: T40)
#   HY  the hypothesis and its premises in every KB; the open discovery orbit (D30, 0.3.0 K-A) : HY1-HY8; review fixes HY9-HY18
#   KR  the report and show print what the KB holds: hypothesis, examples, KB, Signals, Formal, the discovery report (D31, 0.3.0 K-B) : KR1-KR7
#   OP  no quiet "Nothing is open": blocking, what blocks readiness, stale pins (D32, 0.3.0 K-C) : OP1-OP5
#   RD  readiness and the vote: examples, preserve checks, calibration, red system runs, the gate (D33, 0.3.0 K-D) : RD1-RD6
#   VN  the version of the tool: version, help, init, a link and a copy (D34, 0.3.0 V-A) : VN1-VN3
#   SG  signals have records: signal/4, lean_back/2, further requests, report Signals (D35, 0.3.0 K-G) : SG1-SG4
#
# Fixtures (fixtures/<name>/): valid, valid_local, e1_syntax, e2_undeclared, e3_oneof,
# e4_dangling, e5_duplicate, e6_nonground, e7_wrong_place, e8_writer, e9_no_log,
# e10_no_uses, e17_scasp_syntax (one per error code), the variants e2_arity,
# e2_rule_body, e3_time, e4_wrong_kind, e5_cross, e8_script_type, e9_bad_header,
# e10_not_first, e10_unknown_module, e14_unsafe_neg (D7), and the warning fixtures w3_no_cites,
# w4_no_reader, w5_superseded_check, w6_extension. A line that must get a diagnostic ends
# with the marker "% <-- E<n>". The tests read the expected line from the marker.
#
# Contract readings that tests rely on (also listed in the final report of the builder):
#  - lint prints diagnostics and the summary line on stdout; other checks accept either stream.
#  - add: a syntax error in a fact is a rejection (exit 1); an unknown check in run is exit 2,
#    because for run the exit code 1 means "the check failed" and a typo must not look like it.
#  - D20 (2026-11-02): s(CASP) is gone. The tests of the cross-check, the grounder, and
#    hazards H1-H4 went with it. X, WN, E17, and E18 test the one engine instead.
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
    printf 'test_orbit_kb.sh: ORBIT_KB_TEST_JOBS must be a positive integer, got "%s"\n' "${ORBIT_KB_TEST_JOBS:-}" >&2
    exit 2
fi
# Tests that run alone in a parallel run (an ERE on the test id; empty: none). No test needs
# it now. The time limits are the CLI's 10 s for the SWI engine and $TMO per call here. Under
# 1.5x to 2x CPU overload (14 workers next to 7 or 14 busy loops), all tests passed in 4 of 4
# runs. (This note was measured before D20, when s(CASP) was the second engine.)
SERIAL=''

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
for tool in swipl sha256sum timeout mktemp awk grep sed diff cmp sort head wc cp mv; do
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
t_K10() { okb to_ask; rc_is 2 "a query name used as a command"; any_has "orbit-kb query 'to_ask" "the message shows the query form"; }

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
# A2 and A3 (add rejects an undeclared predicate) went with D22: a new predicate is now
# declared by its first use (FU1). FU5 checks the declare-first path that A3 checked.
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
t_A13() { mkclaim; rejects classical 'classical negation' add "-world(door_open)"; any_has 'E17' "the code"; }
t_A14() { mkclaim; rejects arity '' add "claim(c2, preserve)"; any_has 'E2|arity|claim/3|declared'; }
t_A15() { mkclaim; rejects syntax '' add "claim(c2 preserve, x)"; }
t_A16() { mkclaim; rejects badtime '' add "attest(a1, disclosure, c1, unverified(x), agent, 'yesterday')"; }
t_A17() { mkclaim; rejects badwriter 'writer|allow|agent|human' add "attest(a1, disproof, c1, verdict(c1, refuted('x fails')), human, '2026-10-15T10:00:00Z')"; }
t_A20() { mkclaim; rejects conjunction 'own argument' add "risk(rk1, 'a'), risk(rk2, 'b')"; no_fact "$K/kb.pl" "risk(rk1,_)" "nothing written"; }
t_A21() { mkclaim; rejects noteid 'does not create' add "note(n1, 'a note')"; any_hasi 'note\(c1|r1|existing' "the message shows how to attach a note"; }
t_A22() { mkclaim; rejects barelabel 'verdict\(CLAIM, tested\(100\)\)' attest lean_result c1 'tested(100)'; }

# ================================================================ D: rule heads (T26: the declare command is gone; add takes no decl term)
# A head of rules.pl is declared by its first clause. Lint checks it as it checked a declared head.
old_decl() { printf '%s\n' "$1" >> "$K/kb.pl"; }   # a decl/4 line as an older KB has it (declare wrote it)
t_D1() { mkclaim; printf "okay(C) :- claim(C, _, _).\n" > "$K/rules.pl"
         okb --dir "$K" lint; rc_is 0 "the first clause declares okay/1: no E2"; out_hasnt '^E' "no error"; out_has '^W9 rules\.pl:1.*okay/1' "W9: no doc comment"
         is_true 'okay(c1)'; }
t_D2() { mkclaim; printf "%%%% doc: A thing.\nokay(C) :- claim(C, _, _).\nokay(C) :- claim(C, _, _), world(C).\n" > "$K/rules.pl"
         okb --dir "$K" lint; rc_is 0; out_hasnt '^W9' "the doc comment above the first clause is the doc"
         okb --dir "$K" show kinds; out_has '^- okay/1 \(rule\): A thing\.' "the doc shows once"; [ "$(printf '%s\n' "$out" | grep -c 'okay/1')" = 1 ] || note "okay/1 is listed once"; }
t_D3() { mkclaim; printf "not(C) :- claim(C, _, _).\n" > "$K/rules.pl"
         okb --dir "$K" lint; rc_is 1 "a reserved name is not a head"; out_has '^E2 rules\.pl:1' "E2 at the head"; }
t_D4() { mkclaim; printf "claim(C) :- current(C).\n" > "$K/rules.pl"
         okb --dir "$K" lint; out_hasnt '^E2' "claim/1 is a new predicate: only an exact name and arity match is an extension"
         printf "claim(C, T, X) :- current(C), T = a, X = b.\n" >> "$K/rules.pl"
         okb --dir "$K" lint; out_has '^(E7|W6) ' "claim/3 is the core fact: its clause is flagged"; }
# D5 (declare-attest then attest) went with D22: declare-attest is retired (RT1).
t_D6() { mkclaim; printf "okay(C) :- claim(C, _, _).\n" > "$K/rules.pl"
         rejects rulefact 'rule' add "okay(c1)"
         rejects ruledecl 'rules\.pl.*doc' add "decl(rule, okay2(id), 'x', '')"
         rejects factdecl '--doc' add "decl(fact, okay2(id), 'x', '')"; }
t_D8() { mkclaim; printf "pk(C) :- claim(C, _, _).\n" > "$K/rules.pl"; old_decl "decl(fact, pq(atom), 'A pq.', '')."
         printf "pp(C) :- claim(C, _, _).\n" >> "$K/rules.pl"; okb --dir "$K" lint; rc_is 1 "a head 2 edits from a declared name is a typo"
         out_has '^E19 rules\.pl:2.*pp/1' "E19 names the head"; }

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
t_B12() { kb_done "$T/k"; K=$T/k; printf "question(q2, c2, 'Is it two').\nassumed(q2, no).\nattest(d1, divergence, c2, claim(c2), agent, '2026-10-15T10:00:09Z').\nanswer(q1, no, human).\n" >> $K/kb.pl
          is_false "done"; is_true any_to_ask; is_set 'to_ask(X)' 'X = q2'; is_set 'defeated(X)' 'X = q1'; }
t_B13() { kb_burn "$T/k"; K=$T/k; is_set 'burn(X)' 'X = c1|X = c3|X = c4'; is_true 'burn(c1)'; is_false 'burn(c2)'; is_false 'burn(c5)'; is_set 'contested(X)' 'X = c1|X = c2'; is_set 'contested_twice(X)' 'X = c1'; }
t_B14() { kb_toask "$T/k"; K=$T/k; echo "answer(q1, no, human)." >> $K/kb.pl; is_false 'to_ask(X)' "D22: a defeated default alone asks nothing"; is_set 'defeated(X)' 'X = q1'; }
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
# H3: arithmetic under negation (passed/1); the name is from s(CASP) days (D20)
h3_kb() { use_proto h3; }
h3_kb_fresh() {  # the setup behind h3_kb. It runs once per suite, in a prototype (use_proto).
    K=$T/kb; kb_init "$K" ""; oadd "claim(c1, preserve, 'The runs behave')" "cites(c1, 'x')" "check(k1, c1)" "check(k2, c1)" "check(k3, c1)" "check(k4, c1)" >/dev/null || note "setup failed: $(snip "$err")"
    local s
    for s in k1:true k1:false k2:false k2:true k3:true k4:true k4:false k4:true; do orun "${s%%:*}" -- "${s##*:}" >/dev/null 2>&1; done
}
t_H3a() { h3_kb; okb --dir "$K" query 'passed(K)' -n 0; rc_is 0; local got; got=$(printf '%s\n' "$out" | LC_ALL=C sort | paste -sd'|'); [ "$got" = "K = k2|K = k3|K = k4" ] || note "passed(K) answers [$got], want k2, k3, k4 (no k1, with k4)"
         ls "$K/runs" | grep -q '^8-k4.log$' || note "run numbers 1..8 expected, runs: $(ls "$K/runs" | paste -sd' ')"; }
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
t_Q8() { kb_q "$T/k"; K=$T/k; q 'current(c1)' --json; rc_is 2 "D20: --json is gone"; any_hasi 'unknown option'; }
t_Q9() { kb_q "$T/k"; K=$T/k; q 'current(c1)' --html "$T/out.html"; rc_is 2 "D20: query --html is gone"; [ -e "$T/out.html" ] && note "a file was written"; true; }
t_Q10() { kb_q "$T/k"; K=$T/k; q 'current(c1)' --why; rc_is 0; out_has '^true'; out_has 'c1'; out_has 'because'; [ "$(printf '%s\n' "$out" | wc -l)" -ge 3 ] || note "--why adds a tree: $(snip "$out")"; }
t_Q11() { kb_q "$T/k"; K=$T/k; q 'claim(c1)'; rc_is 2 "wrong arity is undeclared"; }
t_Q12() { kb_q "$T/k"; K=$T/k; q 'current(X)' -n 2; rc_is 0; [ "$(printf '%s\n' "$out" | grep -c '^X = ')" = 2 ] || note "-n 2 gives two answers: $(snip "$out")"; }
t_Q13() { kb_q "$T/k"; K=$T/k; q 'current(c1)' -n x; rc_is 2 "bad -n"; }

# ================================================================ X: the engine (D20)
t_X1() { kb_h2 "$T/k"; K=$T/k; q 'finding_lead(F)'; rc_is 1 "H2 program: no answer"; }
t_X2() { x_h1kb; q 'bad_done'; rc_is 1 "not under(_) means no under at all; under(c1) holds, so bad_done is false"; }
t_X3() { kb_h2 "$T/k"; K=$T/k; printf 'finding(f2, sys, model).\n' >> $K/kb.pl; is_set 'finding_lead(F)' 'F = f2'; }
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
t_X4() { x_h1kb; q 'bad_over(X)'; rc_is 1 "x1 serves c1: not serves(x1, Y) is false"; okb --dir "$K" lint; rc_is 0 "a variable only under not is no error (D20: E12 is gone)"; }
t_X5() { # D20: E18, rules that are not stratified
    kb_new "$T/k" <<'EOF'
uses([]).
request(r1, 'Loop').
decl(rule, p, 'p.', '').
decl(rule, q, 'q.', '').
EOF
    K=$T/k; printf 'p :- not q.\nq :- not p.\n' > "$K/rules.pl"
    okb --dir "$K" lint; rc_is 1; out_has '^E18 rules\.pl:1' "E18 at the first clause"; out_has '^E18 rules\.pl:2' "E18 at the second clause"
    q 'p'; rc_is 2 "no answer from rules that are not stratified"; any_has 'E18'
    printf 'p :- not q.\nq.\n' > "$K/rules.pl"; okb --dir "$K" lint; rc_is 0 "stratified: no E18"; q 'p'; rc_is 1; }
t_X6() { x_h1kb; q 'good_done'; rc_is 1 "H1 helper form is false"; q 'helper_any_under'; rc_is 0 "c1 has no check, so under(c1) holds: helper true"; }
t_X7() { # D20: E17, s(CASP) forms in rules.pl; the engine skips them, so query gives no answer
    kb_new "$T/k" <<'EOF'
uses([]).
request(r1, 'Add one').
decl(rule, plus_one(int, int), 'The second number is the first plus one.', '').
decl(rule, door(atom), 'A door.', '').
EOF
    K=$T/k; printf 'plus_one(X, Y) :- Y #= X + 1.\n-door(a).\n:- door(b).\n#pred door(X) :: x.\n' > "$K/rules.pl"
    okb --dir "$K" lint; rc_is 1; local n; n=$(printf '%s\n' "$out" | grep -c '^E17 rules\.pl:[1-4]:'); [ "$n" = 4 ] || note "want 4 E17 lines, got $n: $(snip "$out")"
    any_hasi 'classical negation'; q 'plus_one(1, Y)'; rc_is 2 "no answer while an E17 form is in rules.pl"; any_has 'E17'
    printf 'plus_one(X, Y) :- Y is X + 1.\n' > "$K/rules.pl"; q 'plus_one(1, Y)'; rc_is 0; out_has '^Y = 2$'; }
t_X8() { # D20: a body literal -p is E17 too, also under not
    kb_new "$T/k" <<'EOF'
uses([]).
request(r1, 'Neg').
decl(rule, door(atom), 'A door.', '').
decl(rule, shut(atom), 'Shut.', '').
EOF
    K=$T/k; printf 'door(a).\nshut(X) :- door(X), not -door(X).\n' > "$K/rules.pl"
    okb --dir "$K" lint; rc_is 1; out_has '^E17 rules\.pl:2:'; }
t_X9() { # D20: no scasp is needed. A scasp on PATH that records each call is never called.
    mkclaim; mkdir -p "$T/fakebin"; printf '#!/bin/sh\ntouch "%s/called"\nexit 1\n' "$T" > "$T/fakebin/scasp"; chmod +x "$T/fakebin/scasp"
    local c; for c in "query done" "whynot done" "why current(c1)" "lint" "report" "doctor"; do
        PATH="$T/fakebin:$PATH" okb --dir "$K" $c; [ "$rc" -le 1 ] || note "$c: exit $rc"; done
    [ -e "$T/called" ] && note "scasp was called"; true; }
t_X10() { # D20 review: forms of s(CASP) in kb.pl and in a goal; no E2 for #<; E18 names the rules.pl clause
    mkclaim; printf ':- claim(c1, introduce, x).\n' >> "$K/kb.pl"
    okb --dir "$K" lint; rc_is 1; out_has '^E17 kb\.pl'; out_hasnt '^E7 ' "E17 only"
    q 'current(c1)'; rc_is 2 "no answer while kb.pl holds a constraint"
    mkclaim; q '-current(c1)'; rc_is 2; any_hasi 'classical negation' "a clear message for -p in a goal"; any_hasnt 'SWI ERROR'
    printf 'q :- current(X), X #< 3.\n' > "$K/rules.pl"; true
    okb --dir "$K" lint; rc_is 1; out_has '^E17 rules\.pl:1'; out_hasnt '^E2 ' "no E2 for #<"
    printf 'superseded(C) :- current(C).\n' > "$K/rules.pl"
    okb --dir "$K" lint; rc_is 1; out_has '^E18 rules\.pl:1' "E18 names the rules.pl clause that closes the cycle"; }
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
          is_set 'artifact_vote(V)' 'V = hold' "D33 R1: a current claim with no example blocks readiness"
          printf "example(c1, 'order 7 is charged once').\n" >> "$K/kb.pl"
          is_set 'artifact_vote(V)' 'V = go' "a current claim with an example and a falsifier makes it go"
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
# D18 LG: attest model_result reads the solver log and refuses a result it clearly contradicts.
lg_kb() {  # lg_kb: a KB with a TLC model m1 and a z3 model m2, and a log of each class
    K=$T/lg; mkdir -p "$K"; printf 'model\n' > "$K/m.tla"; printf 'model\n' > "$K/m.smt"
    printf 'Model checking completed. No error has been found.\n' > "$K/holds.log"
    printf 'Error: Invariant Inv is violated.\n' > "$K/viol.log"
    printf 'Error: Deadlock reached.\n' > "$K/dead.log"
    printf 'unsat\n' > "$K/unsat.log"; printf 'sat\n' > "$K/sat.log"; printf 'sat\nunsat\n' > "$K/mixed.log"
    kb_new "$K" <<EOF
uses([discovery]).
request(r1, 'q').
model(m1, tla).
model(m2, smt).
claim(c1, preserve, 'x').
cites(c1, 'r').
subject(m1, 'm.tla', 'sha256:$(sha "$K/m.tla")').
subject(m2, 'm.smt', 'sha256:$(sha "$K/m.smt")').
EOF
    local l
    for l in holds viol dead gone unsat sat mixed; do
        printf "subject(l_%s, '%s.log', 'sha256:%064d').\n" "$l" "$l" 0 >> "$K/kb.pl"
    done
    for l in holds viol dead gone; do printf "model_run(l_%s, m1, 'sha256:%s').\n" "$l" "$(sha "$K/m.tla")" >> "$K/kb.pl"; done
    for l in unsat sat mixed; do printf "model_run(l_%s, m2, 'sha256:%s').\n" "$l" "$(sha "$K/m.smt")" >> "$K/kb.pl"; done
}
lg_refused() {  # lg_refused LABEL LOG PRED: exit 1, nothing written, the message names the fix
    rejects "$1" 'run the solver again' attest model_result "$2" "$3"
}
t_WD8() { lg_kb   # an old result says whether a newer result of the same check replaces it
          okb --dir "$K" uses discovery >/dev/null
          okb --dir "$K" attest model_result l_viol 'verdict(m1, sanity, reached)'; rc_is 0 "first result"
          okb --dir "$K" attest model_result l_holds 'mutation(m1, g, survived)'; rc_is 0 "second result"
          printf 'model v2\n' > "$K/m.tla"; okb --dir "$K" subject m1 "$K/m.tla"; rc_is 0 "model edited"
          okb --dir "$K" lint; out_has 'WD8 a[0-9]+:.*Run the solver again' "a stale result asks for a new run"
          printf 'Error: Invariant X is violated.\n' > "$K/new.log"
          okb --dir "$K" subject l_new "$K/new.log"; rc_is 0 "new log"
          printf "model_run(l_new, m1, 'sha256:%s').\n" "$(sha "$K/m.tla")" >> "$K/kb.pl"
          okb --dir "$K" attest model_result l_new 'verdict(m1, sanity, reached)'; rc_is 0 "the renewed result"
          okb --dir "$K" lint
          out_has 'WD8 a[0-9]+:.*replaces it; nothing to do' "the renewed check says nothing to do"
          out_has 'WD8 a[0-9]+:.*Run the solver again' "the mutation, not renewed, still asks for a run"; }
t_LG1() { lg_kb   # TLC
          lg_refused "reached on a log with no error" l_holds 'verdict(m1, sanity, reached)'
          lg_refused "violated on a log with no error" l_holds 'verdict(m1, preserve(c1), violated)'
          lg_refused "holds on a violated log" l_viol 'verdict(m1, preserve(c1), holds)'
          lg_refused "killed on a log with no error" l_holds 'mutation(m1, g, killed)'
          lg_refused "survived on a violated log" l_viol 'mutation(m1, g, survived)'
          okb --dir "$K" attest model_result l_viol 'verdict(m1, sanity, reached)'; rc_is 0 "reached on a violated log"
          okb --dir "$K" attest model_result l_holds 'verdict(m1, preserve(c1), holds)'; rc_is 0 "holds on a log with no error"
          okb --dir "$K" attest model_result l_viol 'mutation(m1, g, killed)'; rc_is 0 "killed on a violated log"
          okb --dir "$K" attest model_result l_holds 'mutation(m1, g, survived)'; rc_is 0 "survived on a log with no error"
          okb --dir "$K" attest model_result l_holds 'verdict(m1, sanity, unknown)'; rc_is 0 "unknown is never refused"; }
t_LG2() { lg_kb   # z3
          lg_refused "sat on an unsat log" l_unsat 'verdict(m2, bad_case, sat)'
          lg_refused "unsat on a sat log" l_sat 'verdict(m2, together, unsat)'
          lg_refused "killed on an unsat log" l_unsat 'mutation(m2, g, killed)'
          lg_refused "survived on a sat log" l_sat 'mutation(m2, g, survived)'
          okb --dir "$K" attest model_result l_sat 'verdict(m2, bad_case, sat)'; rc_is 0 "sat on a sat log"
          okb --dir "$K" attest model_result l_unsat 'verdict(m2, together, unsat)'; rc_is 0 "unsat on an unsat log"
          okb --dir "$K" attest model_result l_sat 'verdict(m2, bad_case, unknown)'; rc_is 0 "unknown is never refused"; }
t_LG3() { lg_kb   # accepted; a NOTE when the log was not checked
          okb --dir "$K" attest model_result l_holds "calibration(m1, case('x'), matches)"; rc_is 0 "calibration is not checked"
          printf '%s\n' "$err" | grep -q 'not checked' && note "calibration prints no NOTE: $(snip "$err")"
          okb --dir "$K" attest model_result l_viol "calibration(m1, case('x'), differs)"; rc_is 0 "calibration on a violated log"
          okb --dir "$K" attest model_result l_dead 'verdict(m1, sanity, reached)'; rc_is 0 "a deadlock log is unclassified"
          err_has 'NOTE: the log was not checked' "unclassified TLC log"
          okb --dir "$K" attest model_result l_mixed 'verdict(m2, bad_case, unsat)'; rc_is 0 "a log with sat and unsat is unclassified"
          err_has 'NOTE: the log was not checked' "unclassified z3 log"
          okb --dir "$K" attest model_result l_gone 'verdict(m1, preserve(c1), holds)'; rc_is 0 "a missing log file"
          err_has 'NOTE: the log was not checked' "missing log"; }
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

# ---- 0.3.0 K-A: the hypothesis and its premises in every KB (CONTRACT D30). hypothesis/3 is a core fact
# with a fourth kind, change; premise/3, premise_checked/2, no_premises/1 and the query premise_unchecked/1;
# lint W10; Guesses lists unchecked premises and the defaults of the hypothesis; the discovery orbit is open
# until the human approves the ticket after a GO (discovery_end/1), and again after a back attestation.
DARK='With dark mode on, every screen shows a dark scheme.'
hy_build() {  # hy_build DIR: a build KB with one claim, its example and its check
    kb_init "$1" build; K=$1
    oadd "claim(c1, introduce, '$DARK')" "cites(c1, 'Test request')" "example(c1, 'the reports page is dark')" "check(k1, c1)" >/dev/null || note "setup: the claim: $(snip "$out$err")"
}
hy_disc() {  # hy_disc DIR: a discovery KB that is ready: a hypothesis, one claim with an example, a red system check, a reproduction
    kb_init "$1" discovery; K=$1
    oadd "hypothesis(h1, defect, 'The amount and the tier decide the points.')" "budget(laps, 3)" \
         "claim(c1, introduce, 'Every purchase gets the points that its amount and tier give.')" "cites(c1, 'Test request')" \
         "check(t1, c1)" "discovery_evidence(t1, system)" "example(c1, 'gold, 40, gives 80')" >/dev/null || note "setup: the discovery facts: $(snip "$out$err")"
    okb --dir "$K" run t1 -- false >/dev/null
    okb --dir "$K" attest reproduction t1 'result(h1, reproduced)' >/dev/null || note "setup: the reproduction: $(snip "$out$err")"
}
hy_go() {  # hy_go DIR: hy_disc, both vote go, and the human approves the ticket
    hy_disc "$1"
    okb --dir "$K" attest vote r1 'vote(1, go)'; rc_is 0 "setup: the agent votes go"
    okb --dir "$K" attest vote r1 'vote(1, go)' --by human; rc_is 0 "setup: the human votes go"
    printf '# ticket\n' > "$K/ticket.md"
    okb --dir "$K" subject tk "$K/ticket.md" >/dev/null; oadd "ticket(tk)" >/dev/null
    okb --dir "$K" attest approval tk 'digest(current)' --by human; rc_is 0 "setup: the human approves the ticket"
}
t_HY1() { hy_build "$T/b"
          oadd "hypothesis(h1, feature, '$DARK')"; rc_is 0 "a build KB takes the hypothesis of its ticket"
          okb --dir "$K" lint; out_hasnt '^WD7' "no discovery finding in a build KB"
          okb --dir "$K" report; rc_is 0; out_hasnt '^# Vote:' "no Vote section in a build KB"; out_hasnt 'not ready' "no readiness in a build KB"
          oadd "hypothesis(h2, change, 'The README names the two interfaces.')"; rc_is 0 "the kind change, for a direct build of a document or a configuration"
          rejects "a kind outside defect, feature, risk, change" 'E3' add "hypothesis(h3, wish, 'Other words.')"
          kb_new "$T/c" <<'EOF2'
uses([]).
request(r1, 'Fix the thing').
EOF2
          K=$T/c; oadd "hypothesis(h1, defect, 'The thing is broken.')"; rc_is 0 "a KB with no module takes a hypothesis"
          okb --dir "$K" lint; out_hasnt '^E' "core only: no lint error"; }
t_HY2() { hy_disc "$T/d"
          okb --dir "$K" lint; out_hasnt '^WD7' "setup: h1 has its system result"; is_true 'discovery_ready' "setup: ready"
          oadd "hypothesis(h2, risk, 'A refund takes the points back.')"; rc_is 0
          okb --dir "$K" lint; out_has '^WD7 h2' "the discovery rules hold in a KB that uses discovery: WD7"
          is_false 'discovery_ready' "a hypothesis with no system result blocks readiness"
          okb --dir "$K" attest reproduction t1 'result(h2, reproduced)'; rc_is 0
          okb --dir "$K" lint; out_hasnt '^WD7'; is_true 'discovery_ready'; }
t_HY3() { hy_build "$T/b"; oadd "hypothesis(h1, feature, '$DARK')" >/dev/null
          okb --dir "$K" lint; out_has '^W10 h1' "lint names a hypothesis with no premise and no no_premises"
          oadd "premise(p1, h1, 'The app has one color scheme today.')"; rc_is 0; any_hasnt 'new predicate|first use' "premise/3 is declared"
          okb --dir "$K" lint; out_hasnt '^W10' "a premise answers W10"
          is_true 'premise_unchecked(p1)' "a new premise is not checked"
          oadd "premise_checked(p1, 'src/theme.css:1')"; rc_is 0; any_hasnt 'new predicate|first use' "premise_checked/2 is declared"
          is_false 'premise_unchecked(p1)' "a checked premise"
          rejects "a premise of an id that is no hypothesis" 'E4' add "premise(p2, c1, 'Other words.')"
          hy_build "$T/b2"; oadd "hypothesis(h1, feature, '$DARK')" >/dev/null
          oadd "no_premises(h1)"; rc_is 0; any_hasnt 'new predicate|first use' "no_premises/1 is declared"
          okb --dir "$K" lint; out_hasnt '^W10' "the record Premises: none answers W10"
          okb help codes; any_has '^ *W10 ' "help codes lists W10"; }
t_HY4() { hy_build "$T/b"; oadd "hypothesis(h1, feature, '$DARK')" "premise(p1, h1, 'Only the settings page has a theme.')" >/dev/null
          is_true 'premise_unchecked(p1)' "setup"
          oadd "hypothesis(h2, feature, 'With dark mode on, the settings page shows a dark scheme.')" "supersedes(h2, h1)" "no_premises(h2)"; rc_is 0
          is_false 'premise_unchecked(p1)' "a premise of a superseded hypothesis is not asked for"
          okb --dir "$K" lint; out_hasnt '^W10' "W10 names no superseded hypothesis"
          okb --dir "$K" report; rc_is 0
          printf '%s\n' "$(rp_sec Guesses)" | grep -q 'settings page has a theme' && note "Guesses lists a premise of a superseded hypothesis"; true; }
t_HY5() { hy_build "$T/b"; oadd "hypothesis(h1, feature, '$DARK')" \
              "premise(p1, h1, 'The app has one color scheme today.')" "premise(p2, h1, 'The app has twelve screens.')" \
              "premise_checked(p2, 'src/routes.ts:4')" >/dev/null
          oadd "question(q1, h1, 'Every screen, or only the settings page?')" "assumed(q1, 'all twelve screens')"; rc_is 0 "a question on the hypothesis marks its default"
          okb --dir "$K" report; rc_is 0
          local g; g=$(rp_sec Guesses)
          printf '%s\n' "$g" | grep -q 'p1.*The app has one color scheme today' || note "Guesses lists the unchecked premise p1: [$g]"
          printf '%s\n' "$g" | grep -q 'all twelve screens' || note "Guesses lists the default of the hypothesis: [$g]"
          printf '%s\n' "$g" | grep -q 'The app has twelve screens' && note "Guesses lists a checked premise: [$g]"
          printf '%s\n' "$g" | grep -q 'None' && note "Guesses says None: [$g]"
          oadd "premise_checked(p1, 'src/theme.css:1')" "answer(q1, 'all twelve screens', human)" >/dev/null
          okb --dir "$K" report; rl_is "Guesses when each premise is checked and each default answered" "  - None. Each premise is checked, and a human answered every question with a default." "$(rp_sec Guesses)"; }
t_HY6() { hy_build "$T/b"; oadd "hypothesis(h1, feature, '$DARK')" >/dev/null
          oadd "hypothesis(h2, feature, 'With dark mode on, the settings page shows a dark scheme.')" "supersedes(h2, h1)"; rc_is 0 "a build KB restates its hypothesis"
          okb --dir "$K" lint; out_hasnt '^WD7' "no WD7 in a build KB"
          hy_go "$T/d"
          is_true 'discovery_end(A)' "the approval of the ticket after a GO ends the discovery orbit"
          is_true 'discovery_closed'; is_false 'discovery_open'
          okb --dir "$K" uses build >/dev/null
          oadd "hypothesis(h2, defect, 'The amount and the tier decide the points, for members only.')" "supersedes(h2, h1)"; rc_is 0
          okb --dir "$K" lint; out_hasnt '^WD7' "after the GO, a restated hypothesis needs no system result"
          is_true 'discovery_ready' "the restatement does not change readiness"; is_true 'gate(go)' "nor the outcome of the vote"
          okb --dir "$K" show open; out_hasnt 'not ready'
          okb --dir "$K" report; printf '%s\n' "$(rp_sec Open)" | grep -q 'not ready' && note "the report shows the closed orbit as not ready"; true; }
t_HY7() { hy_go "$T/d"; okb --dir "$K" uses build >/dev/null
          okb --dir "$K" attest back h1 "back('The human cannot say what the hypothesis changes to.')"; rc_is 0 "a return to discovery is a record"
          is_true 'discovery_open' "after the back attestation the discovery orbit is open again"
          is_false 'discovery_closed'
          oadd "hypothesis(h3, defect, 'Refunds take the points back.')" "supersedes(h3, h1)"; rc_is 0
          okb --dir "$K" lint; out_has '^WD7 h3' "after a return to discovery, a new hypothesis needs its system result"
          is_false 'discovery_ready' "and readiness is asked again"
          okb --dir "$K" attest reproduction t1 'result(h3, reproduced)'; rc_is 0
          is_true 'discovery_ready' "its system result makes discovery ready again"; }
t_HY8() { hy_disc "$T/d"
          okb --dir "$K" attest vote r1 'vote(1, hold)'; okb --dir "$K" attest vote r1 'vote(1, no_go)' --by human
          is_false 'gate(go)' "setup: the vote is split (the artifacts vote go)"
          printf '# ticket\n' > "$K/ticket.md"; okb --dir "$K" subject tk "$K/ticket.md" >/dev/null; oadd "ticket(tk)" >/dev/null
          okb --dir "$K" attest approval tk 'digest(current)' --by human; rc_is 0 "the human's approval is never refused"
          any_hasi 'discovery orbit.*open|open.*discovery orbit' "a NOTE says that the orbit stays open: gate(go) does not hold"
          is_false 'discovery_end(A)' "no GO, so the approval does not end the orbit"; is_true 'discovery_open'
          rejects "only orbit-kb attest writes discovery_end" 'discovery_end' add "discovery_end(a1)"; }

# ---- Review of K-A and K-B on e9f9a4b (claim c_k_a_3b refuted; CONTRACT D30 H5 to H10, D31 B7, B8).
hy_closed() {  # hy_closed DIR: hy_go, then the build: the discovery orbit is closed
    hy_go "$1"; okb --dir "$K" uses build >/dev/null; }
t_HY9() { hy_closed "$T/d"   # finding 1: after a return to discovery, a new round of votes and readiness
          okb --dir "$K" attest back h1 "back('The human cannot say what the hypothesis changes to.')"; rc_is 0
          is_false 'gate(V)' "after a return to discovery, the votes of the earlier orbit do not count"
          oadd "hypothesis(h3, defect, 'Refunds take the points back.')" "supersedes(h3, h1)" "no_premises(h3)" >/dev/null
          okb --dir "$K" attest approval tk 'digest(current)' --by human; rc_is 0 "the human's approval is never refused"
          fact_count "$K/kb.pl" 'discovery_end(_)' 1 "an approval with no new vote does not close the orbit again"
          is_true 'discovery_open'; okb --dir "$K" lint; out_has '^WD7 h3' "h3 still needs its system result"
          is_false 'discovery_ready'
          okb --dir "$K" attest reproduction t1 'result(h3, reproduced)' >/dev/null; is_true 'discovery_ready' "setup"
          okb --dir "$K" attest vote r1 'vote(2, go)'; rc_is 0 "the agent votes in a new round"
          okb --dir "$K" attest vote r1 'vote(2, go)' --by human; rc_is 0
          is_set 'gate(V)' 'V = go'
          okb --dir "$K" attest approval tk 'digest(current)' --by human; rc_is 0
          fact_count "$K/kb.pl" 'discovery_end(_)' 2 "a new round and readiness close the orbit again"
          is_true 'discovery_closed'; }
t_HY10() { kb_init "$T/d" discovery; K=$T/d   # finding 2: no closure while not ready, and the round keeps its record
          oadd "hypothesis(h1, defect, 'The amount and the tier decide the points.')" "no_premises(h1)" "budget(laps, 3)" \
               "claim(c1, introduce, 'Every purchase gets the points that its amount and tier give.')" "cites(c1, 'Test request')" \
               "example(c1, 'gold, 40, gives 80')" "check(t1, c1)" >/dev/null
          okb --dir "$K" run t1 -- false >/dev/null
          is_false 'discovery_ready' "setup: h1 was never reproduced"
          vt_add v1 agent 1 go
          okb --dir "$K" attest vote r1 'vote(1, go)' --by human; rc_is 0
          printf '# ticket\n' > "$K/ticket.md"; okb --dir "$K" subject tk "$K/ticket.md" >/dev/null; oadd "ticket(tk)" >/dev/null
          okb --dir "$K" attest approval tk 'digest(current)' --by human; rc_is 0
          is_false 'discovery_end(A)' "an approval while discovery is not ready does not close the orbit"
          okb --dir "$K" lint; out_has '^WD7 h1' "WD7 h1 stays"
          okb --dir "$K" show open; out_hasnt 'Nothing is open'
          okb --dir "$K" report; rp_sec Vote | grep -q 'Formal artifacts (0.24): hold' || note "the round keeps the artifacts' hold: [$(rp_sec Vote)]"
          # a closed orbit keeps the record of its round: the artifacts' go stays, whatever the build adds
          hy_closed "$T/c"; oadd "claim(c7, introduce, 'A refund takes the points back.')" "cites(c7, 'Test request')" >/dev/null
          is_set 'artifact_vote(V)' 'V = go' "after closure the round keeps the artifacts' vote"
          okb --dir "$K" report; rp_sec Vote | grep -q 'Formal artifacts (0.24): go' || note "the report keeps the round: [$(rp_sec Vote)]"; }
t_HY11() { hy_disc "$T/d"   # finding 3: a stale approval of the ticket does not close the orbit
          okb --dir "$K" attest vote r1 'vote(1, go)' >/dev/null; okb --dir "$K" attest vote r1 'vote(1, go)' --by human >/dev/null
          printf '# ticket\n' > "$K/ticket.md"; okb --dir "$K" subject tk "$K/ticket.md" >/dev/null; oadd "ticket(tk)" >/dev/null
          okb --dir "$K" attest approval tk "digest('sha256:$(printf '0%.0s' $(seq 1 64))')" --by human; rc_is 0 "the human's approval is never refused"
          any_hasi 'stale|digest' "a NOTE says why"
          is_false 'discovery_end(A)' "a stale approval (a digest that is not the ticket's) does not close the orbit"
          is_true 'discovery_open'; }
t_HY12() { hy_closed "$T/d"   # finding 6: a vote after the orbit closed
          rejects "an agent vote after the orbit closed" 'closed' attest vote r1 'vote(2, no_go)'
          okb --dir "$K" attest vote r1 'vote(2, no_go)' --by human; rc_is 0 "the human's vote is never refused"
          err_has 'closed' "a NOTE says that the orbit is closed and the vote does not change the outcome"
          is_set 'gate(V)' 'V = go' "a vote after closure does not change the outcome"
          okb --dir "$K" report; rp_sec Vote | grep -qi 'after the discovery orbit closed' || note "the report says that the vote came after the orbit closed: [$(rp_sec Vote)]"; }
t_HY13() { hy_disc "$T/d"   # finding 7: a hand-written discovery_end of something that is no human approval of the ticket
          printf 'discovery_end(a1).\n' >> "$K/kb.pl"
          okb --dir "$K" lint; rc_is 1 "lint finds an error"; out_has '^ED11 a1' "ED11 names it"
          okb help codes; any_has '^ *ED11 ' "help codes lists ED11"; }
t_HY14() { hy_build "$T/b"; oadd "hypothesis(h1, feature, '$DARK')" "premise(p1, h1, 'The app has one color scheme today.')" "no_premises(h1)" >/dev/null   # finding 9
          okb --dir "$K" lint; out_has '^W11 h1' "lint names a hypothesis with a premise and the record Premises: none"
          okb --dir "$K" report; rp_sec Hypothesis | grep -qi 'none.*conflict\|conflict.*none\|W11' || note "the report shows the conflict: [$(rp_sec Hypothesis)]"
          okb help codes; any_has '^ *W11 ' "help codes lists W11"; }
t_HY15() { kb_init "$T/d" discovery; kb_init "$T/n" ""   # finding 10: the CONTRACT reserves each fact kind of the discovery module
          okb --dir "$T/d" show kinds; local dk; dk=$(printf '%s\n' "$out" | sed -n 's/^- \([a-z_]*\/[0-9]*\): .*/\1/p' | LC_ALL=C sort)
          okb --dir "$T/n" show kinds; local nk; nk=$(printf '%s\n' "$out" | sed -n 's/^- \([a-z_]*\/[0-9]*\): .*/\1/p' | LC_ALL=C sort)
          local res k; res=$(awk '/^- Facts: `budget\/2`/,/^- Lint codes/' "$here/../CONTRACT.md")
          [ -n "$res" ] || { note "setup: the reserved facts of the discovery module in CONTRACT"; return; }
          for k in $(LC_ALL=C comm -23 <(printf '%s\n' "$dk") <(printf '%s\n' "$nk")); do
              printf '%s\n' "$res" | grep -qF "\`$k\`" || note "CONTRACT does not reserve the discovery fact $k"
          done; }
t_HY16() { hy_disc "$T/d"; okb --dir "$K" run t1 -- true >/dev/null   # finding 11
          okb --dir "$K" report; local s; s=$(rp_sec System)
          printf '%s\n' "$s" | grep -q 'failed on the current system (run 1)\.$' && note "System says t1 fails now, though run 2 passed: [$s]"
          printf '%s\n' "$s" | grep -q 'run 2' || note "System names the later run that passed: [$s]"; }
t_HY17() { hy_disc "$T/d"   # finding 12: back needs a closed orbit and a hypothesis
          rejects "back while the discovery orbit is open" 'open' attest back h1 "back('No approval yet.')"
          hy_closed "$T/c"
          rejects "back on a claim" 'hypothesis' attest back c1 "back('A claim.')"; }
t_HY18() { hy_build "$T/b"; oadd "hypothesis(h1, feature, 'Line one.\nLine two.')" "premise(p1, h1, 'First.\nSecond.')" >/dev/null   # finding 12
          okb --dir "$K" report; local h; h=$(rp_sec Hypothesis)
          printf '%s\n' "$h" | grep -qvE '^  +- ' && note "a newline in the text breaks the bullets: [$h]"
          printf '%s\n' "$h" | grep -q 'Line one. Line two.' || note "the text keeps its words on one line: [$h]"; true; }

# ---- 0.3.0 K-B: the tool shows what it holds (CONTRACT D31). report: KB, Signals, Hypothesis with its
# premises, an example under each claim, Formal (a theorem with its statement, or a model with its property),
# and in a discovery KB the parts of the discovery report (System, Findings, Scope, Risk, Not explored).
# show all starts with the hypothesis; show claims prints the examples.
t_KR1() { hy_build "$T/b"; oadd "hypothesis(h1, feature, '$DARK')" "premise(p1, h1, 'The app has one color scheme today.')" >/dev/null
          okb --dir "$K" report; rc_is 0
          local head; head=$(printf '%s\n' "$out" | sed '/^# Claims:/,$d')
          printf '%s\n' "$head" | grep -q '^# Hypothesis:' || note "report: a Hypothesis section before Claims: [$(snip "$head")]"
          printf '%s\n' "$head" | grep -qF "$DARK" || note "report: the hypothesis before the claims"
          printf '%s\n' "$head" | grep -q 'p1.*The app has one color scheme today' || note "report: the premise beside the hypothesis"
          okb --dir "$K" show all; rc_is 0
          local sh; sh=$(printf '%s\n' "$out" | sed '/^Claims:/,$d')
          printf '%s\n' "$sh" | grep -qF "$DARK" || note "show all: the hypothesis before the claims: [$(snip "$out")]"
          printf '%s\n' "$sh" | grep -q 'The app has one color scheme today' || note "show all: the premise beside the hypothesis"
          okb --dir "$K" show hypothesis; rc_is 0 "show hypothesis is a section"; any_hasf "$DARK" "show hypothesis prints it"
          hy_build "$T/b2"; oadd "hypothesis(h1, feature, '$DARK')" "no_premises(h1)" >/dev/null
          okb --dir "$K" report; rp_sec Hypothesis | grep -q 'Premises: none' || note "report: Premises: none [$(snip "$(rp_sec Hypothesis)")]"
          okb --dir "$K" show all; out_has 'Premises: none' "show all: Premises: none"
          oadd "hypothesis(h2, feature, 'With dark mode on, the settings page is dark.')" "supersedes(h2, h1)" "no_premises(h2)" >/dev/null
          okb --dir "$K" report; rp_sec Hypothesis | grep -qF "$DARK" && note "report: a superseded hypothesis is not the current one"
          rp_sec Hypothesis | grep -q 'settings page is dark' || note "report: the current hypothesis"
          hy_build "$T/b3"; okb --dir "$K" report; rl_is "no hypothesis" "  - None. No hypothesis is recorded. Every ticket has one: add hypothesis(H, KIND, TEXT)." "$(rp_sec Hypothesis)"; }
t_KR2() { hy_build "$T/b"; okb --dir "$K" report; rc_is 0
          rp_item c1 | grep -q 'Example: the reports page is dark' || note "report: the example under the claim: [$(snip "$(rp_item c1)")]"
          okb --dir "$K" show claims; rc_is 0; out_has '^  Example: the reports page is dark' "show claims: the example under the claim"; }
t_KR3() { hy_build "$T/b"; okb --dir "$K" report; rc_is 0
          local heads; heads=$(printf '%s\n' "$out" | grep -oE '^# (Delivered|KB|Signals|Claims|Formal|Guesses):' | sed 's/^# //' | paste -sd' ')
          rl_is "the fields of the delivery block, in its order" "Delivered: KB: Signals: Claims: Formal: Guesses:" "$heads"
          rp_sec KB | grep -qF "$K" || note "KB names the KB directory: [$(rp_sec KB)]"
          rp_sec Signals | paste -sd' ' | grep -q 'questions.*divergence.*effort' || note "Signals names the six signals (D35: one line each): [$(rp_sec Signals)]"
          rl_is "Formal with no formal statement" "  - None. No claim has a formal statement." "$(rp_sec Formal)"
          okb --dir "$K" report --html "$T/r.html"; rc_is 0
          local s; for s in kb signals hypothesis formal; do grep -q "data-section=\"$s\"" "$T/r.html" || note "the page has the section $s"; done; }
t_KR4() { kb_burndone "$T/k"; K=$T/k; add_proof "$K" p1 c1
          okb --dir "$K" report; rc_is 0
          local f; f=$(rp_sec Formal)
          printf '%s\n' "$f" | grep -q 'c1.*theorem t.*True' || note "Formal gives the theorem and its statement from the proof log: [$f]"
          printf '%s\n' "$f" | grep -q 'One stays true' || note "Formal puts the plain sentence of the claim beside it: [$f]"
          local b; b=$(rp_item c1)
          printf '%s\n' "$b" | grep -q 'Burn: proved in Lean: theorem t' || note "the Burn part names the theorem: [$(snip "$b")]"
          printf '%s\n' "$b" | grep -q 'about the Lean definitions' || note "the Burn part says that the proof is about the Lean definitions"
          printf '%s\n' "$b" | grep -q 'No conformance check carries the examples' || note "the Burn part says that no check carries the examples to the code"
          oadd "conformance(k1)" >/dev/null
          okb --dir "$K" report; rp_item c1 | grep -q 'Conformance check k1 carries the examples' || note "the Burn part names the conformance check: [$(snip "$(rp_item c1)")]"; }
t_KR5() { hy_disc "$T/d"; printf '(check-sat)\n' > "$T/m1.smt"
          okb --dir "$K" subject m1 "$T/m1.smt" >/dev/null; oadd "model(m1, smt)" "encodes(m1, c1)" >/dev/null
          okb --dir "$K" report; rp_sec Formal | grep -q 'c1.*model m1' || note "Formal names a model that states the claim: [$(rp_sec Formal)]"
          oadd "property(m1, c1, '(assert (not (= points 80)))')"; rc_is 0; any_hasnt 'new predicate|first use' "property/3 is declared"
          okb --dir "$K" report; rp_sec Formal | grep -qF '(assert (not (= points 80)))' || note "Formal gives the property: [$(rp_sec Formal)]"
          rejects "a property of a model that is no model" 'E4' add "property(c1, c1, 'x')"; }
t_KR6() { hy_disc "$T/d"
          oadd "scope(in, 'the points of one purchase')" "scope(out, 'the tiers themselves')" \
               "risk(rk1, 'a wrong build changes the balance of a member')" "not_explored('refunds')" \
               "finding(f1, surprise('a guest got 12 points in the model'), model)" "finding(f2, trace('the tier is read once a day'), system)" >/dev/null
          okb --dir "$K" report; rc_is 0
          local heads; heads=$(printf '%s\n' "$out" | grep -oE '^# [A-Za-z ]+:' | sed 's/^# //' | paste -sd'|')
          rl_is "the sections of a discovery report" "Delivered:|KB:|Signals:|Hypothesis:|System:|Findings:|Claims:|Formal:|Scope:|Risk:|Not explored:|Guesses:|Disclosures:|Not checked:|Open:|Vote:|To land:" "$heads"
          rp_sec Hypothesis | grep -q 'The amount and the tier decide the points' || note "the hypothesis"
          rp_sec System | grep -q 'h1.*reproduced' || note "what the system showed: [$(rp_sec System)]"
          rp_item f1 | grep -q 'From a model only' || note "the finding f1 is marked as from a model only: [$(rp_sec Findings)]"
          rp_item f2 | grep -q 'From the system' || note "the finding f2 is marked as from the system: [$(rp_sec Findings)]"
          rp_item c1 | grep -q 'Example: gold, 40, gives 80' || note "the example of the claim"
          rp_item c1 | grep -q 't1' || note "the falsifier of the claim (its check)"
          rp_sec Scope | grep -q 'In: the points of one purchase' || note "scope in: [$(rp_sec Scope)]"
          rp_sec Scope | grep -q 'Out: the tiers themselves' || note "scope out"
          rp_sec Risk | grep -q 'rk1.*a wrong build changes the balance' || note "the risk: [$(rp_sec Risk)]"
          rp_sec 'Not explored' | grep -q 'refunds' || note "not explored: [$(rp_sec 'Not explored')]"; }
t_KR7() { hy_disc "$T/d"; okb --dir "$K" attest vote r1 'vote(1, go)'; rc_is 0 "setup: the agent votes"
          okb --dir "$K" report; rc_is 0
          local v; v=$(rp_sec Vote)
          printf '%s\n' "$v" | grep -Eq '\bgo\b|Agent \(0.24\)|Formal artifacts' && note "the report shows the agent's vote before the human votes: [$v]"
          printf '%s\n' "$out" | grep -Eq 'Agent \(0.24\)|artifacts vote' && note "no section leaks the vote"
          okb --dir "$K" attest vote r1 'vote(1, go)' --by human; okb --dir "$K" report
          rp_sec Vote | grep -q 'Agent (0.24): go' || note "after the human votes, the vote shows: [$(rp_sec Vote)]"; }

# ---- 0.3.0 K-C: no quiet "Nothing is open" (CONTRACT D32). show open and the Open part of the report name
# each answer of blocking(X), each thing that blocks readiness while the discovery orbit is open
# (ready_blocker(X)), and each stale pin that the KB rests on. "Nothing is open" only when none holds.
# OP1 and OP2 take the kinds from the rules (the one place where this suite reads the library: the ticket asks
# for "a test for each kind of blocking(X), made from the rules, so that a new kind cannot be missed").
op_kinds() {  # op_kinds HEAD: the kinds of the clause heads HEAD(KIND...) of core.pl and the modules, one per line
    grep -ohE "^$1\([a-z_]+" "$LIB/core.pl" "$LIB"/modules/*.pl | sed -E "s/^$1\(//" | LC_ALL=C sort -u; }
op_answers() {  # op_answers GOAL: the answers X of GOAL(X) in $K, one term per line ("" when none)
    q "$1(X)" -n 0; [ "$rc" = 0 ] && printf '%s\n' "$out" | sed -n 's/^X = //p'; true; }
op_named() {  # op_named PREFIX: each answer of blocking(X) (PREFIX "") or ready_blocker(X) (PREFIX "not_ready ") is named
    local goal=$1 pre=$2 x kind id re o rep
    okb --dir "$K" show open; rc_is 0 "show open"; o=$out
    okb --dir "$K" report; rc_is 0 "report"; rep=$(rp_sec Open)
    while IFS= read -r x; do
        [ -n "$x" ] || continue
        kind=${x%%(*}; id=; [ "$kind" != "$x" ] && { id=${x#*(}; id=${id%)}; }
        printf '%s\n' "$x" >> "$T/.seen.$goal"
        if [ "$goal" = ready_blocker ] && [ "$kind" = to_ask ]; then re="^- to_ask $id:"   # blocking names it
        elif [ -n "$id" ]; then re="^- $pre$kind $id:"; else re="^- $pre$kind:"; fi
        printf '%s\n' "$o" | grep -Eq -- "$re" || note "show open does not name $goal($x) (want /$re/): [$(snip "$o")]"
        if [ -n "$id" ]; then printf '%s\n' "$rep" | grep -qF -- "$id" || note "report Open does not name $goal($x): [$(snip "$rep")]"
        else printf '%s\n' "$rep" | grep -qE -- "$kind|${kind//_/ }" || note "report Open does not name $goal($x): [$(snip "$rep")]"; fi
    done < <(op_answers "$goal")
    [ -s "$T/.seen.$goal" ] || note "setup: $goal(X) has no answer in this case"
    printf '%s\n' "$o" | grep -q 'Nothing is open' && note "show open says Nothing is open while $goal(X) has answers"
    printf '%s\n' "$rep" | grep -q 'Nothing is open' && note "report Open says Nothing is open while $goal(X) has answers"
    true; }
op_cover() {  # op_cover GOAL: every kind of GOAL in the rules had an answer in some case
    local k
    while IFS= read -r k; do
        sed -E 's/\(.*//' "$T/.seen.$1" | grep -qx -- "$k" || note "no case of the test shows $1($k(...)): a kind of the rules with no test"
    done < <(op_kinds "$1"); }
t_OP1() { : > "$T/.seen.blocking"
          kb_new "$T/k" <<'EOF'
uses([build]).
request(r1, 'Every kind').
claim(c1, preserve, 'Text of c1 contested').
claim(c2, preserve, 'Text of c2 universal').
claim(c3, preserve, 'Text of c3 visual').
claim(c4, introduce, 'Text of c4 checks').
claim(c5, preserve, 'Text of c5 cycle').
claim(c6, preserve, 'Text of c6 cycle').
cites(c1, 'Every kind').
cites(c2, 'Every kind').
cites(c3, 'Every kind').
cites(c4, 'Every kind').
cites(c5, 'Every kind').
cites(c6, 'Every kind').
question(q1, c1, 'Text of q1').
attest(d1, divergence, c1, claim(c1), agent, '2026-10-15T10:00:01Z').
universal(c2).
attest(w1, waiver, c2, waive(c2, '2020-01-01T00:00:00Z', 'Text of w1'), human, '2026-10-15T10:00:02Z').
visual(c3).
check(k1, c4).
check(k2, c4).
due(c4, '2020-01-01T00:00:00Z').
change(x1, 'Text of x1').
supersedes(c5, c6).
supersedes(c6, c5).
EOF
          K=$T/k; add_result "$K" k1 1 fail; op_named blocking ""
          kb_init "$T/n" build; K=$T/n; op_named blocking ""
          local J=$T/item.json
          printf '{"title": "Export daily", "body": "Send the export each day."}\n' > "$J"
          okb init "$T/r" --request-file "$J" --source 'gh:acme/widgets#3' --uses build >/dev/null; K=$T/r
          oadd "claim(c1, introduce, 'The export runs daily.')" "cites(c1, 'Export daily')" "example(c1, 'one file on Monday')" "check(k1, c1)" >/dev/null
          okb --dir "$K" run k1 -- false >/dev/null; okb --dir "$K" run k1 -- true >/dev/null
          printf '{"title": "Export daily", "body": "Send the export each hour."}\n' > "$J"
          okb --dir "$K" pin-request --request-file "$J" >/dev/null; op_named blocking ""
          op_project "$T/pc" human; K=$T/pc/sp; op_named blocking ""
          op_project "$T/pu" human; printf 'this is not (valid.\n' >> "$T/pu/p/kb.pl"; K=$T/pu/sp; op_named blocking ""
          op_cover blocking; }
op_project() {  # op_project DIR BY: a project KB with excludes(d1, d2), and a spec KB in DIR/sp whose fulfilled claim pins d1
    local P=$1/p S=$1/sp
    okb init "$P" --request project --uses project >/dev/null; K=$P
    oadd "decision(d1, 'Prices include tax.')" "decided_by(d1, ty, '2026-11-01T00:00:00Z')" \
         "decision(d2, 'Prices exclude tax.')" "decided_by(d2, ty, '2026-11-02T00:00:00Z')" "excludes(d1, d2)" --by human >/dev/null
    okb --dir "$P" release >/dev/null
    okb init "$S" --request 'show the price' --uses build,project >/dev/null; K=$S
    oadd "project_kb('../p')" >/dev/null
    q 'project_decision_digest(d1, D)'; local dg; dg=$(printf '%s\n' "$out" | grep -oE 'sha256:[0-9a-f]{64}' | head -n1)
    oadd "claim(c1, introduce, 'The page shows the price.')" "cites(c1, 'show the price')" "example(c1, 'the page shows 12.00')" \
         "check(k1, c1)" "pins(c1, project, d1, '$dg')" >/dev/null || note "setup: the spec KB: $(snip "$out$err")"
    okb --dir "$S" run k1 -- false >/dev/null; okb --dir "$S" run k1 -- true >/dev/null; }
t_OP2() { : > "$T/.seen.ready_blocker"
          kb_init "$T/e" discovery; K=$T/e; op_named ready_blocker "not_ready "
          kb_init "$T/h" discovery; K=$T/h; oadd "hypothesis(h1, defect, 'The amount and the tier decide the points.')" >/dev/null
          op_named ready_blocker "not_ready "
          hy_disc "$T/d"
          oadd "claim(c2, introduce, 'A refund takes the points back.')" "cites(c2, 'Test request')" \
               "claim(c3, preserve, 'A purchase by a guest gets no points.')" "cites(c3, 'Test request')" \
               "example(c3, 'a guest buys for 40 and gets 0')" "check(t3, c3)" "discovery_evidence(t3, system)" \
               "finding(f1, surprise('a guest got 12 points'), system)" "question(q9, h1, 'Do guests get points?')" "raised_by(q9, f1)" \
               "finding(f2, conflict([c1, c3]), model)" >/dev/null || note "setup: $(snip "$out$err")"
          okb --dir "$K" run t3 -- false >/dev/null
          okb --dir "$K" attest disproof c1 "verdict(c1, refuted('a gold member who buys for 40 gets 40'))" >/dev/null
          op_named ready_blocker "not_ready "
          da_copy
          cat >> "$K/kb.pl" <<'EOF'
attest(a90, model_result, run_target, mutation(m_target, cap, survived), agent, '2026-10-15T11:00:00Z').
attest(a91, model_result, run_now, calibration(m_now, passes('one code of $5.00 on a list of $40.00'), differs), agent, '2026-10-15T11:00:01Z').
attest(a92, model_result, run_target, verdict(m_target, applies(c2b), unsat), agent, '2026-10-15T11:00:02Z').
attest(a93, model_result, run_target, verdict(m_target, preserve(c2b), sat), agent, '2026-10-15T11:00:03Z').
attest(a94, model_result, run_target, verdict(m_target, preserve(c2b), unsat), agent, '2026-10-15T11:00:04Z').
attest(a95, divergence, t1, claim(c1), agent, '2026-10-15T11:00:05Z').
claim(c1x, introduce, 'No order is charged below its floor, and the floor is shown.').
supersedes(c1x, c1).
cites(c1x, 'paid less than our minimum price').
question(q8, c2b, 'Is the floor shown?').
attest(a96, divergence, t1, claim(c2b), agent, '2026-10-15T11:00:06Z').
EOF
          op_named ready_blocker "not_ready "
          op_cover ready_blocker; }
t_OP3() { local P=$T/p F=$T/report.txt
          printf 'week 1\n' > "$F"
          okb init "$P" --request project --uses project >/dev/null; K=$P
          oadd "decision(d1, 'Prices include tax.')" "decided_by(d1, ty, '2026-11-01T00:00:00Z')" \
               "decision(d0, 'Prices are shown.')" "decided_by(d0, ty, '2026-11-01T00:00:00Z')" --by human >/dev/null
          okb --dir "$K" subject s1 "$F" >/dev/null
          okb --dir "$K" pin-item pf1 s1 --kind file --changed-at 2026-11-01T00:00:00Z >/dev/null; rc_is 0 "setup: a file pin"
          oadd "concerns(d1, pf1)" >/dev/null
          is_false 'stale_pin_open(pf1)' "a pin that did not change is not open"
          okb --dir "$K" show open; out_hasnt 'pf1' "show open names no fresh pin"
          printf 'week 1, edited\n' > "$F"
          is_true 'stale_pin(pf1)' "setup"; is_true 'stale_pin_open(pf1)' "a stale pin that a current decision rests on is open"
          okb --dir "$K" show open; out_has '^- stale_pin pf1: .*d1' "show open names the stale pin and the decision on it"
          out_hasnt 'Nothing is open'
          okb --dir "$K" lint; out_has '^WP8 pf1.*stale' "lint WP8 names the stale pin"
          okb --dir "$K" report; rp_sec Open | grep -q 'pf1' || note "report Open names the stale pin: [$(rp_sec Open)]"
          is_false 'blocking(X)' "a stale pin does not block done"
          # pinned again: the decision rests on the new pin of the same source
          okb --dir "$K" subject s1 "$F" >/dev/null
          okb --dir "$K" pin-item pf2 s1 --kind file --changed-at 2026-11-02T00:00:00Z >/dev/null; oadd "concerns(d1, pf2)" >/dev/null
          is_true 'stale_pin(pf1)' "the old pin stays stale (it is never rewritten)"
          is_false 'stale_pin_open(pf1)' "a decision that rests on a newer pin of the source is pinned again"
          okb --dir "$K" show open; out_hasnt 'stale_pin' "show open after the new pin"
          okb --dir "$K" lint; out_hasnt '^WP8' "lint after the new pin"
          # a superseded decision does not keep a stale pin open
          okb --dir "$K" pin-item pf3 s1 --kind file --changed-at 2026-11-02T00:00:00Z >/dev/null; oadd "concerns(d0, pf3)" >/dev/null
          printf 'week 2\n' > "$F"
          is_true 'stale_pin_open(pf3)' "setup: d0 rests on the stale pf3"
          oadd "decision(d9, 'Prices are shown with tax.')" "decided_by(d9, ty, '2026-11-03T00:00:00Z')" "supersedes(d9, d0)" --by human >/dev/null
          is_false 'stale_pin_open(pf3)' "a pin that only a superseded decision rests on is not open"
          # a spec KB: a pin that nothing names is open until the source is pinned again
          local S=$T/sp G=$T/notes.txt; printf 'v1\n' > "$G"
          okb init "$S" --request 'show the price' --uses build,project >/dev/null; K=$S
          oadd "claim(c1, introduce, 'The page shows the price.')" "cites(c1, 'show the price')" "example(c1, 'the page shows 12.00')" "check(k1, c1)" >/dev/null
          okb --dir "$K" subject s2 "$G" >/dev/null; okb --dir "$K" pin-item pf2 s2 --kind file --changed-at 2026-11-01T00:00:00Z >/dev/null
          printf 'v2\n' > "$G"
          okb --dir "$K" show open; out_has '^- stale_pin pf2:' "show open names a stale pin of a spec KB"
          okb --dir "$K" lint; out_has '^WP8 pf2' "lint names it"
          okb --dir "$K" subject s2 "$G" >/dev/null; okb --dir "$K" pin-item pf4 s2 --kind file --changed-at 2026-11-02T00:00:00Z >/dev/null
          is_false 'stale_pin_open(X)' "the source is pinned again"
          # a project KB with a tracker item pinned twice and nothing on it: no noise
          K=$P; printf 'item text\n' > "$T/item.txt"
          okb --dir "$K" pin-item pt1 'gh:acme/w#1' --text-file "$T/item.txt" --changed-at 2026-11-01T00:00:00Z >/dev/null
          okb --dir "$K" pin-item pt2 'gh:acme/w#1' --text-file "$T/item.txt" --changed-at 2026-11-02T00:00:00Z >/dev/null
          is_true 'stale_pin(pt1)' "setup: a newer record makes pt1 stale"; is_false 'stale_pin_open(pt1)' "an old record that nothing rests on is not open"; }
t_OP4() { kb_done "$T/k"; K=$T/k; is_true 'done' "setup"
          okb --dir "$K" show open; out_has '^- Nothing is open\.' "show open says it when nothing blocks"
          okb --dir "$K" report; rl_is "report Open when nothing blocks" "  - Nothing is open." "$(rp_sec Open)"
          hy_disc "$T/d"; is_true 'discovery_ready' "setup"
          okb --dir "$K" show open; out_has '^- Nothing is open\.' "a ready discovery KB with nothing open"
          okb --dir "$K" report; rl_is "report Open of a ready discovery KB" "  - Nothing is open." "$(rp_sec Open)"
          # a build KB with an under claim: the report no longer says Nothing is open (the old quiet failure)
          hy_build "$T/b"; okb --dir "$K" report; rp_sec Open | grep -q 'Nothing is open' && note "report Open says Nothing is open while c1 is under"
          rp_sec Open | grep -q 'c1' || note "report Open names the under claim c1: [$(rp_sec Open)]"
          rp_sec Open | grep -q 'k1' || note "report Open names the check k1 that never ran: [$(rp_sec Open)]"
          okb --dir "$K" report --html "$T/b.html"; rc_is 0
          [ "$(grep -c 'data-open="under"' "$T/b.html")" = 1 ] || note "the page lists the under claim once in Open"; }

# ---- 0.3.0 K-C and K-D: the examples of the two Lean models, carried to the CLI (c_k_c_1b, c_k_d_1b).
# OP5_TABLE and RD6_TABLE are copies of what #eval prints in kb/proofs/open_items/OpenItems.lean and
# kb/proofs/gate_ready/GateReady.lean. With lake on PATH the tests read the #eval output of the model
# itself (lake env lean; the projects have no packages), so a copy that differs from the model is a
# failure, and so is a model that does not compile. Without lake, the copy is the table.
OP5_TABLE='OP5 hypothesis_only: not_ready no_system_result | not_ready no_outcome | not_ready untouched h1
OP5 contradiction: project_contradiction d1
OP5 done: Nothing is open
OP5 under_never_ran: under c1 | check_unrun k1
OP5 no_example: not_ready no_example c2
OP5 preserve_fails: not_ready preserve_failing t2
OP5 ready: Nothing is open
OP5 closed: Nothing is open
OP5 stale_pin: stale_pin pf2'
RD6_TABLE='RD6 not_ready_votes: refused=[1] gate=hold closed=false
RD6 ready_then_new_hypothesis: refused=[] gate=hold closed=false
RD6 approved_then_build: refused=[] gate=go closed=true
RD6 approved_then_back: refused=[] gate=none closed=false
RD6 stale_approval: refused=[] gate=go closed=false
RD6 vote_after_closure: refused=[4] gate=go closed=true'
lean_rows() {  # lean_rows PROJECT FILE TAG COPY: sets LEAN_ROWS, the lines "TAG ..." that #eval prints (or COPY without lake)
    local d=$here/../proofs/$1 out
    if ! command -v lake >/dev/null 2>&1; then LEAN_ROWS=$4; return; fi
    if ! out=$(cd "$d" && timeout 600 lake env lean "$2" 2>&1); then
        note "lake env lean failed on $1/$2: $(snip "$out")"; LEAN_ROWS=$4; return
    fi
    LEAN_ROWS=$(printf '%s\n' "$out" | grep "^$3 " | awk '!seen[$0]++')
    [ "$LEAN_ROWS" = "$4" ] || note "the copy of the table differs from the #eval output of $1/$2: $(diff <(printf '%s\n' "$4") <(printf '%s\n' "$LEAN_ROWS") | head -n 6 | tr '\n' '~')"
}
op5_case() {  # op5_case NAME: make the KB of the example NAME in $T/NAME; K is set
    local n=$1
    case $n in
        hypothesis_only) kb_init "$T/$n" discovery; K=$T/$n; oadd "hypothesis(h1, defect, 'The amount and the tier decide the points.')" >/dev/null ;;
        contradiction) op_project "$T/$n" human; K=$T/$n/sp ;;
        done) kb_done "$T/$n"; K=$T/$n ;;
        under_never_ran) hy_build "$T/$n" ;;
        no_example) hy_disc "$T/$n"; oadd "claim(c2, introduce, 'A refund takes the points back.')" "cites(c2, 'Test request')" "check(t2, c2)" >/dev/null ;;
        preserve_fails) hy_disc "$T/$n"
            oadd "claim(c2, preserve, 'A purchase by a guest gets no points.')" "cites(c2, 'Test request')" \
                 "example(c2, 'a guest who buys for 40 gets 0 points')" "check(t2, c2)" "discovery_evidence(t2, system)" >/dev/null
            okb --dir "$K" run t2 -- false >/dev/null ;;
        ready) hy_disc "$T/$n" ;;
        closed) hy_go "$T/$n"; oadd "claim(c7, introduce, 'A refund takes the points back.')" "cites(c7, 'Test request')" "check(t7, c7)" >/dev/null ;;
        stale_pin) okb init "$T/$n" --request 'show the price' --uses project >/dev/null; K=$T/$n
            printf 'v1\n' > "$T/$n.txt"; okb --dir "$K" subject s2 "$T/$n.txt" >/dev/null
            okb --dir "$K" pin-item pf2 s2 --kind file --changed-at 2026-11-01T00:00:00Z >/dev/null; printf 'v2\n' > "$T/$n.txt" ;;
        *) note "OP5: no CLI case for the example $n of the Lean model"; return 1 ;;
    esac
}
t_OP5() { lean_rows open_items OpenItems.lean OP5 "$OP5_TABLE"
          local line n want got
          while IFS= read -r line; do
              [ -n "$line" ] || continue
              n=${line#OP5 }; n=${n%%:*}; want=$(printf '%s\n' "${line#*: }" | tr '|' '\n' | sed 's/^ *//; s/ *$//' | LC_ALL=C sort | paste -sd'|')
              op5_case "$n" || continue
              okb --dir "$K" show open; rc_is 0 "show open ($n)"
              got=$(printf '%s\n' "$out" | sed -n 's/^- \([^:]*\).*/\1/p' | sed 's/^Nothing is open\.$/Nothing is open/' | LC_ALL=C sort | paste -sd'|')
              [ "$got" = "$want" ] || note "example $n: show open names [$got], the Lean model [$want]"
          done <<< "$LEAN_ROWS"
          [ "$(printf '%s\n' "$LEAN_ROWS" | grep -c .)" = 9 ] || note "the model has $(printf '%s\n' "$LEAN_ROWS" | grep -c .) examples, want 9"; }
rd6_ticket() {  # rd6_ticket: the ticket subject of $K
    printf '# ticket\n' > "$K/ticket.md"; okb --dir "$K" subject tk "$K/ticket.md" >/dev/null; oadd "ticket(tk)" >/dev/null; }
t_RD6() { lean_rows gate_ready GateReady.lean RD6 "$RD6_TABLE"
          local line n steps st i refused gate closed
          while IFS= read -r line; do
              [ -n "$line" ] || continue
              n=${line#RD6 }; n=${n%%:*}
              case $n in
                  not_ready_votes) kb_init "$T/$n" discovery; K=$T/$n; oadd "hypothesis(h1, defect, 'The amount and the tier decide the points.')" "budget(laps, 3)" >/dev/null
                      steps="vote:agent:go:1 vote:agent:hold:1 vote:human:go:1" ;;
                  ready_then_new_hypothesis) hy_disc "$T/$n"; steps="vote:agent:go:1 vote:human:go:1 build:hypothesis" ;;
                  approved_then_build) hy_disc "$T/$n"; steps="vote:agent:go:1 vote:human:go:1 approve:current build:claim" ;;
                  approved_then_back) hy_disc "$T/$n"; steps="vote:agent:go:1 vote:human:go:1 approve:current back" ;;
                  stale_approval) hy_disc "$T/$n"; steps="vote:agent:go:1 vote:human:go:1 approve:stale" ;;
                  vote_after_closure) hy_disc "$T/$n"; steps="vote:agent:go:1 vote:human:go:1 approve:current vote:agent:no_go:2 vote:human:no_go:2" ;;
                  *) note "RD6: no CLI case for the example $n of the Lean model"; continue ;;
              esac
              rd6_ticket; refused=; i=0
              for st in $steps; do
                  i=$((i+1))
                  case $st in
                      vote:*) IFS=: read -r _ by ch rd <<< "$st"
                          if [ "$by" = human ]; then okb --dir "$K" attest vote r1 "vote($rd, $ch)" --by human; else okb --dir "$K" attest vote r1 "vote($rd, $ch)"; fi ;;
                      build:hypothesis) oadd "hypothesis(h9, defect, 'Refunds take the points back.')" ;;
                      build:claim) oadd "claim(c7, introduce, 'A refund takes the points back.')" "cites(c7, 'Test request')" "check(t7, c7)" ;;
                      approve:current) okb --dir "$K" attest approval tk 'digest(current)' --by human ;;
                      approve:stale) okb --dir "$K" attest approval tk "digest('sha256:$(printf '0%.0s' $(seq 1 64))')" --by human ;;
                      back) okb --dir "$K" attest back h1 "back('The human cannot say what the hypothesis changes to.')" ;;
                  esac
                  [ "$rc" = 1 ] && refused=${refused:+$refused, }$i
              done
              q 'gate(V)' -n 0; if [ "$rc" = 0 ]; then gate=$(printf '%s\n' "$out" | sed -n 's/^V = //p' | head -n1); else gate=none; fi
              q 'discovery_closed'; if [ "$rc" = 0 ]; then closed=true; else closed=false; fi
              rl_is "example $n: the CLI and the Lean model" "$line" "RD6 $n: refused=[$refused] gate=$gate closed=$closed"
          done <<< "$LEAN_ROWS"
          [ "$(printf '%s\n' "$LEAN_ROWS" | grep -c .)" = 6 ] || note "the model has $(printf '%s\n' "$LEAN_ROWS" | grep -c .) examples, want 6"; }

# ---- 0.3.0 K-D: readiness and the vote (CONTRACT D33).
t_RD1() { hy_disc "$T/d"; is_true 'discovery_ready' "setup"
          oadd "claim(c2, introduce, 'A refund takes the points back.')" "cites(c2, 'Test request')" "check(t2, c2)" >/dev/null
          is_false 'discovery_ready' "a current claim with no example blocks readiness"
          is_true 'ready_blocker(no_example(c2))'
          okb --dir "$K" lint; out_has '^WD10 c2' "lint WD10 names the claim with no example"; out_hasnt '^WD10 c1'
          okb --dir "$K" show open; out_has '^- not_ready no_example c2:'
          oadd "example(c2, 'a refund of 40 takes 80 points back')" >/dev/null
          okb --dir "$K" lint; out_hasnt '^WD10'
          oadd "claim(c3, introduce, 'Points expire.')" "cites(c3, 'Test request')" "check(t3, c3)" "supersedes(c3, c2)" "example(c3, 'points expire after a year')" >/dev/null
          okb --dir "$K" lint; out_hasnt '^WD10' "a superseded claim needs no example"
          okb help codes; any_has '^ *WD10 ' "help codes lists WD10"; }
t_RD2() { hy_disc "$T/d"
          oadd "claim(c2, preserve, 'A purchase by a guest gets no points.')" "cites(c2, 'Test request')" \
               "example(c2, 'a guest who buys for 40 gets 0 points')" "check(t2, c2)" "discovery_evidence(t2, system)" >/dev/null
          is_true 'discovery_ready' "a preserve check that never ran does not block (it is the falsifier)"
          okb --dir "$K" run t2 -- false >/dev/null
          is_false 'discovery_ready' "a failing check of a preserve claim blocks readiness"
          is_set 'ready_blocker(X)' 'X = preserve_failing(t2)'
          okb --dir "$K" show open; out_has '^- not_ready preserve_failing t2:.*c2' "show open names the failing check"
          is_set 'artifact_vote(V)' 'V = hold'
          okb --dir "$K" run t2 -- true >/dev/null
          is_true 'discovery_ready' "the check passes again"; }
t_RD3() { hy_disc "$T/d"
          printf '(check-sat)\n' > "$K/m1.smt"; printf 'sat\n' > "$K/log1.log"
          okb --dir "$K" subject m1 "$K/m1.smt" >/dev/null; okb --dir "$K" subject log1 "$K/log1.log" >/dev/null
          oadd "model(m1, smt)" >/dev/null
          local dg; q 'subject(m1, _, D)'; dg=$(printf '%s\n' "$out" | grep -oE 'sha256:[0-9a-f]{64}')
          oadd "model_run(log1, m1, '$dg')" >/dev/null
          okb --dir "$K" attest model_result log1 'verdict(m1, sanity, sat)' >/dev/null
          okb --dir "$K" attest model_result log1 "calibration(m1, case('gold, 40, gives 80'), matches)"; rc_is 0 "the older case form is accepted"
          is_false 'model_trusted(m1)' "one matching case does not calibrate a model"
          okb --dir "$K" attest model_result log1 "calibration(m1, fails('gold, 40, gave 40'), matches)"; rc_is 0 "a failing case"
          is_false 'model_trusted(m1)' "a matching failing case alone does not calibrate"
          is_set 'model_calibration_case(m1, K)' 'K = fails'
          okb --dir "$K" attest model_result log1 "calibration(m1, passes('silver, 40, gives 40'), matches)"; rc_is 0 "a passing case"
          is_true 'model_calibrated(m1)'; is_true 'model_trusted(m1)' "a failing case and a passing case calibrate"
          printf '(check-sat)\n; target\n' > "$K/m2.smt"; okb --dir "$K" subject m2 "$K/m2.smt" >/dev/null
          printf 'sat\n' > "$K/log2.log"; okb --dir "$K" subject log2 "$K/log2.log" >/dev/null
          q 'subject(m2, _, D)'; dg=$(printf '%s\n' "$out" | grep -oE 'sha256:[0-9a-f]{64}')
          oadd "model(m2, smt)" "derived_from(m2, m1)" "model_run(log2, m2, '$dg')" >/dev/null
          okb --dir "$K" attest model_result log2 'verdict(m2, sanity, sat)' >/dev/null
          is_false 'model_trusted(m2)' "a model derived from a calibrated model needs its own two cases"
          okb --dir "$K" attest model_result log2 "calibration(m2, fails('gold, 40, gave 40'), matches)" >/dev/null
          okb --dir "$K" attest model_result log2 "calibration(m2, passes('silver, 40, gives 40'), matches)" >/dev/null
          is_true 'model_trusted(m2)' "with its own two cases"
          okb --dir "$K" attest model_result log1 "calibration(m1, passes('bronze, 40, gives 40'), differs)" >/dev/null
          is_false 'model_trusted(m1)' "a case that differs still breaks the trust"; }
t_RD4() { kb_init "$T/d" discovery; K=$T/d
          oadd "hypothesis(h1, defect, 'The amount and the tier decide the points.')" "budget(laps, 3)" \
               "claim(c1, introduce, 'Every purchase gets the points that its amount and tier give.')" "cites(c1, 'Test request')" \
               "example(c1, 'gold, 40, gives 80')" "check(t1, c1)" "discovery_evidence(t1, system)" >/dev/null
          okb --dir "$K" lint; out_has '^WD7 h1' "setup"
          okb --dir "$K" run t1 -- false >/dev/null
          okb --dir "$K" lint; out_hasnt '^WD7' "a red run of a system check of an introduce claim is the system result"
          is_true 'discovery_hypothesis_touched(h1)'; is_true 'discovery_ready' "no reproduction is needed on top"
          oadd "hypothesis(h2, defect, 'The tier on the day of the purchase decides its points.')" >/dev/null
          okb --dir "$K" lint; out_has '^WD7 h2' "a run made before a hypothesis existed is not its system result"
          okb --dir "$K" run t1 -- false >/dev/null
          okb --dir "$K" lint; out_hasnt '^WD7' "a later red run is the result of each current hypothesis (q_k_d_3b default a)"
          kb_init "$T/r" discovery; K=$T/r
          oadd "hypothesis(h1, defect, 'Guests get points.')" "budget(laps, 3)" "claim(c1, retire, 'A guest gets points.')" "cites(c1, 'Test request')" \
               "example(c1, 'a guest who buys for 40 gets 12 points')" "check(t1, c1)" "discovery_evidence(t1, system)" >/dev/null
          okb --dir "$K" run t1 -- false >/dev/null; okb --dir "$K" lint; out_hasnt '^WD7' "a retire claim counts too"
          kb_init "$T/p" discovery; K=$T/p
          oadd "hypothesis(h1, defect, 'Guests get points.')" "budget(laps, 3)" "claim(c1, preserve, 'A guest gets no points.')" "cites(c1, 'Test request')" \
               "example(c1, 'a guest who buys for 40 gets 0 points')" "check(t1, c1)" >/dev/null
          okb --dir "$K" run t1 -- false >/dev/null; okb --dir "$K" lint; out_has '^WD7 h1' "an untagged preserve check that fails is no system result"
          oadd "discovery_evidence(t1, system)" >/dev/null; okb --dir "$K" lint; out_has '^WD7 h1' "a tagged preserve check that fails is no system result"
          kb_init "$T/u" discovery; K=$T/u
          oadd "hypothesis(h1, defect, 'Guests get points.')" "budget(laps, 3)" "claim(c1, introduce, 'A guest gets no points.')" "cites(c1, 'Test request')" \
               "example(c1, 'a guest who buys for 40 gets 0 points')" "check(t1, c1)" >/dev/null
          okb --dir "$K" run t1 -- false >/dev/null; okb --dir "$K" lint; out_has '^WD7 h1' "a check not tagged as system evidence is no system result"; }
t_RD5() { kb_init "$T/n" discovery; K=$T/n; oadd "hypothesis(h1, defect, 'The amount and the tier decide the points.')" "budget(laps, 3)" >/dev/null
          is_false 'discovery_ready' "setup"
          rejects "an agent's GO while discovery is not ready" 'not ready' attest vote r1 'vote(1, go)'
          any_has 'untouched h1' "the refusal names what blocks readiness"
          okb --dir "$K" attest vote r1 'vote(1, hold)'; rc_is 0 "an agent's hold is accepted"
          okb --dir "$K" attest vote r1 'vote(1, go)' --by human; rc_is 0 "the human's vote is never refused"
          is_false 'gate(go)' "GO does not win while discovery is not ready"; is_set 'gate(V)' 'V = hold'
          # agent and human go, then readiness breaks before the approval: the GO stops counting
          hy_disc "$T/r"; okb --dir "$K" attest vote r1 'vote(1, go)'; rc_is 0 "an agent's GO while ready"
          okb --dir "$K" attest vote r1 'vote(1, go)' --by human; is_set 'gate(V)' 'V = go'
          oadd "hypothesis(h9, defect, 'Refunds take the points back.')" >/dev/null
          is_false 'discovery_ready' "setup"; is_set 'gate(V)' 'V = hold' "GO stops counting when readiness breaks (q_k_d_1b default a)"
          is_false 'gate_split' "a GO that cannot win is not a split vote"
          printf 'attest(v9, vote, r1, vote(1, go), agent, %s).\n' "'2026-11-12T10:00:00Z'" >> "$K/kb.pl"
          is_set 'gate(V)' 'V = hold' "an agent GO written by hand does not win either"
          # after the human approved the ticket, a later change of the build does not take the GO back
          hy_go "$T/a"; okb --dir "$K" uses build >/dev/null
          oadd "claim(c7, introduce, 'A refund takes the points back.')" "cites(c7, 'Test request')" "check(t7, c7)" >/dev/null
          is_set 'gate(V)' 'V = go' "the approved GO stays"
          okb --dir "$K" attest back h1 "back('The human cannot say what the hypothesis changes to.')" >/dev/null
          is_false 'discovery_ready' "after a return to discovery, readiness is asked again"
          is_false 'gate(V)' "and the votes of the earlier orbit do not count (D30 H5): a new round is needed"; }

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
pv9_body() {  # pv9_body DIR: the usage errors of prove; DIR holds the loose file (see t_PV9)
          okb --dir "$K" prove c9 "$LP/Fx/Good.lean" load_linear; rc_is 2 "no such claim"
          okb --dir "$K" prove c1 "$T/nope.lean" load_linear; rc_is 2 "no such file"
          printf 'theorem t : True := trivial\n' > "$1/loose.lean"; okb --dir "$K" prove c1 "$1/loose.lean" t; rc_is 2 "no Lake project"; any_has 'lakefile'
          okb --dir "$K" prove c1; rc_is 2 "usage"; }
lakefree_dir() {  # lakefree_dir: print a new dir with no lakefile in it or above it, or nothing. The "no Lake project"
    # case must not depend on what sits above $TMPDIR (T44 c3): a stray Lean project in /tmp made PV9 red.
    local root d p
    for root in /dev/shm /var/tmp "${XDG_RUNTIME_DIR:-}" "${HOME:-}"; do
        [ -n "$root" ] && [ -d "$root" ] && [ -w "$root" ] || continue
        d=$(mktemp -d "$root/orbit-kb-nolake.XXXXXX" 2>/dev/null) || continue
        d=$(cd "$d" && pwd -P); p=$d
        while :; do
            if [ -e "$p/lakefile.toml" ] || [ -e "$p/lakefile.lean" ]; then break; fi
            [ "$p" = / ] && { printf '%s\n' "$d"; return 0; }
            p=$(dirname "$p")
        done
        rmdir "$d"
    done
    return 1
}
t_PV9() { lean_proj || return 0; local d
          d=$(lakefree_dir) || { skip_test "no writable dir without a lakefile above it"; return 0; }
          pv9_body "$d"; rm -rf "$d"; }
# T44 c3: a lakefile.toml in the parent of the test's own temp dir does not change PV9. The parent is the run's
# private base dir; the file is removed at the end, and nothing is made outside it.
t_PV9b() { lean_proj || return 0; local d stray; stray=$(dirname "$T")/lakefile.toml
          [ -e "$stray" ] && { note "a lakefile.toml is already in the parent of the temp dir"; return 0; }
          printf 'name = "stray"\n' > "$stray"
          d=$(lakefree_dir) || { rm -f "$stray"; skip_test "no writable dir without a lakefile above it"; return 0; }
          pv9_body "$d"; rm -rf "$d"; rm -f "$stray"; }
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

t_GD() { # query done on 20 claims x 2 runs
         gd_kb "$T/k"; K=$T/k
         okb --dir "$K" lint; rc_is 0 "the generated KB is valid"
         q 'done'; rc_is 0 "every claim is fulfilled: done holds"; out_has '^true'
         add_result "$K" k20 41 fail
         q 'done'; rc_is 1 "k20 failed last: done is false"
         is_set 'under(X)' 'X = c20'; }

# ================================================================ 0.3.0: V-A, K-G, K-E, K-H, K-J, K-F (D34 to D39)
# VN (D34, c_v_a_2, c_v_a_3): the tool names the version of Sagittarius. The one source is the
# file VERSION at the root of the repository; the library holds kb/share/orbit-kb/VERSION, a
# link to it, so a copy of kb/bin and kb/share (a hub's .claude/orbit-kb) carries the number.
vn_want() { tr -d '[:space:]' < "$here/../../VERSION"; }
t_VN1() { local v; v=$(vn_want)
          [ -n "$v" ] || { note "no VERSION file at the root of the repository"; return; }
          okb version; rc_is 0 "orbit-kb version"; out_has "^orbit-kb ${v//./\\.}\$" "version prints the number of VERSION"
          okb --version; rc_is 0 "orbit-kb --version"; out_has "^orbit-kb ${v//./\\.}\$"
          okb help; rc_is 0; [[ $(first_line) == "orbit-kb $v:"* ]] || note "the first help line names the version: [$(first_line)]"
          okb version extra; rc_is 2 "version takes no arguments"; }
t_VN2() { local v; v=$(vn_want); K=$T/k; okb init "$K" --request 'a'; rc_is 0
          grep -qxF "% Made by orbit-kb $v." "$K/kb.pl" || note "init writes the version of the tool into kb.pl: [$(head -c 300 "$K/kb.pl" | tr '\n' '~')]"
          head -1 "$K/kb.pl" | grep -Eq '^uses\(\[\]\)\.$' || note "uses/1 stays the first line: [$(head -1 "$K/kb.pl")]"
          okb --dir "$K" lint; rc_is 0 "the line is a comment: lint is clean"; }
t_VN3() { local v h; v=$(vn_want); h=$T/hub/.claude/orbit-kb
          # a copy, as hubkit.py copies kit.json orbit_kb.paths: links are followed, no VERSION at a root
          mkdir -p "$h" && cp -RL "$here/../bin" "$here/../share" "$h/" || { note "setup: the copy"; return; }
          [ -L "$here/../share/orbit-kb/VERSION" ] || note "kb/share/orbit-kb/VERSION is a link to the one source"
          [ ! -e "$T/hub/VERSION" ] && [ ! -e "$T/hub/.claude/VERSION" ] || note "setup: a VERSION file above the copy"
          ( unset ORBIT_KB_LIB; cd "$T" && timeout "$TMO" "$h/bin/orbit-kb" version ) > "$T/.out" 2>&1
          grep -qx "orbit-kb $v" "$T/.out" || note "the hub's copy prints the version: [$(head -c 200 "$T/.out")]"
          # a link, as install.py makes ~/.local/bin/orbit-kb
          mkdir -p "$T/home/.local/bin" && ln -s "$OKB" "$T/home/.local/bin/orbit-kb"
          ( unset ORBIT_KB_LIB; cd "$T" && timeout "$TMO" "$T/home/.local/bin/orbit-kb" version ) > "$T/.out" 2>&1
          grep -qx "orbit-kb $v" "$T/.out" || note "the linked CLI prints the version: [$(head -c 200 "$T/.out")]"
          # a library with no VERSION file: no guess
          mkdir -p "$T/old" && cp -R "$h/bin" "$h/share" "$T/old/" && rm -f "$T/old/share/orbit-kb/VERSION"
          ( unset ORBIT_KB_LIB; cd "$T" && timeout "$TMO" "$T/old/bin/orbit-kb" version ) > "$T/.out" 2>&1; rc=$?
          [ "$rc" = 2 ] || note "no VERSION file: exit $rc, want 2"
          grep -q 'VERSION' "$T/.out" || note "no VERSION file: the message names the file: [$(head -c 200 "$T/.out")]"
          ( unset ORBIT_KB_LIB; cd "$T" && timeout "$TMO" "$T/old/bin/orbit-kb" help ) > "$T/.out" 2>&1
          head -1 "$T/.out" | grep -q '^orbit-kb (version unknown):' || note "no VERSION file: the first help line says so: [$(head -1 "$T/.out")]"; }

# SG (D35, c_k_g_1 to c_k_g_4b): signals have records. signal(Id, Kind, NoticedBy, Text), lean_back(Id, Text),
# a decision of the human in their words is a further request; report Signals is drafted from the records.
SG_SIG="signal(s1, divergence, system1, 'the suite showed 8 tests, not 7')"
t_SG1() { hy_build "$T/b"
          oadd "$SG_SIG"; rc_is 0 "signal/4 is a declared fact"; any_hasnt 'new predicate|first use' "signal is no first use"
          has_fact "$K/kb.pl" "signal(s1, divergence, system1, 'the suite showed 8 tests, not 7')"
          local k; for k in questions built_by_other burn handoff effort; do oadd "signal(x_$k, $k, agent, 'case')"; rc_is 0 "the kind $k"; done
          oadd "signal(x_h, effort, human, 'case')"; rc_is 0 "noticed by the human"
          rejects kind 'E3' add "signal(s2, bogus, agent, 'x')"
          rejects noticer 'E3' add "signal(s3, effort, nobody, 'x')"
          okb --dir "$K" lint; rc_is 0; out_hasnt '^W[0-9]+ .*signal' "lint has no warning on signal facts"
          okb --dir "$K" show kinds; out_has 'signal' "show kinds describes signal"
          okb help core; any_has 'signal\(Id, Kind, NoticedBy, Text\)' "help core lists signal/4"
          any_hasi 'questions, divergence, built_by_other, burn, handoff,? (or )?effort' "help core names the six kinds"; }
t_SG2() { hy_build "$T/b"
          oadd "lean_back(l1, 'the second round of questions stopped; the KB and claim c1 stay')"; rc_is 0 "lean_back/2 is a declared fact"
          any_hasnt 'new predicate|first use' "lean_back is no first use"
          okb --dir "$K" report; rc_is 0
          rp_sec Signals | grep -qF 'Leaning back (l1): the second round of questions stopped; the KB and claim c1 stay' || note "report Signals prints the lean back: [$(rp_sec Signals | tr '\n' '~')]"
          okb help core; any_has 'lean_back\(Id, Text\)' "help core lists lean_back/2"; }
t_SG3() { hy_build "$T/b"
          oadd "request(r2, 'only on the settings page')" --by human; rc_is 0 "a further request in the human's words"
          okb --dir "$K" report; rc_is 0
          local kb; kb=$(rp_sec KB)
          printf '%s\n' "$kb" | grep -qF -- "- Request r1, word for word: Test request" || note "KB prints the request word for word: [$(printf '%s' "$kb" | tr '\n' '~')]"
          printf '%s\n' "$kb" | grep -qF -- "- Request r2, word for word: only on the settings page" || note "KB prints the decision of the human: [$(printf '%s' "$kb" | tr '\n' '~')]"
          okb --dir "$K" report --html "$T/r.html"; rc_is 0
          grep -qF 'only on the settings page' "$T/r.html" || note "the page prints the decision of the human"
          okb help core; any_hasi 'decision.*(own )?words|words.*decision' "help core says where a decision in the human's words goes"; }
t_SG4() { hy_build "$T/b"; okb --dir "$K" report; rc_is 0
          local s; s=$(rp_sec Signals)
          rl_is "Signals with no record" "  - questions: no.|  - divergence: no.|  - someone else built: no.|  - burns: no.|  - handoff: no.|  - effort: no." "$(printf '%s\n' "$s" | paste -sd'|')"
          oadd "$SG_SIG" >/dev/null; okb --dir "$K" report; s=$(rp_sec Signals)
          printf '%s\n' "$s" | grep -qx '  - divergence: yes.' || note "divergence: yes: [$(printf '%s' "$s" | tr '\n' '~')]"
          printf '%s\n' "$s" | grep -qx '    - s1: the suite showed 8 tests, not 7 (noticed by System 1).' || note "what fired and who noticed it: [$(printf '%s' "$s" | tr '\n' '~')]"
          printf '%s\n' "$s" | grep -qx '  - effort: no.' || note "effort stays no"
          hy_build "$T/u"; oadd 'universal(c1)' >/dev/null; okb --dir "$K" report; s=$(rp_sec Signals)
          printf '%s\n' "$s" | grep -qx '  - burns: yes.' || note "a universal claim: burns yes: [$(printf '%s' "$s" | tr '\n' '~')]"
          printf '%s\n' "$s" | grep -qx '    - c1: the claim is universal (about every input).' || note "the universal claim is named"
          hy_build "$T/r"; oadd 'burn_requested(c1)' >/dev/null; okb --dir "$K" report; s=$(rp_sec Signals)
          printf '%s\n' "$s" | grep -qx '    - c1: the human asked for a proof.' || note "a requested proof is a burn: [$(printf '%s' "$s" | tr '\n' '~')]"
          hy_build "$T/v"; okb --dir "$K" attest divergence c1 'claim(c1)' >/dev/null; okb --dir "$K" report; s=$(rp_sec Signals)
          printf '%s\n' "$s" | grep -qx '  - divergence: yes.' || note "a divergence attestation: divergence yes: [$(printf '%s' "$s" | tr '\n' '~')]"
          printf '%s\n' "$s" | grep -qE '^    - a[0-9]+: a divergence on claim c1 \(attested by the agent\)\.$' || note "the attestation and who attested it"
          printf '%s\n' "$s" | grep -qx '  - burns: no.' || note "one divergence is no burn"
          okb --dir "$K" attest divergence c1 'claim(c1)' --by human >/dev/null; okb --dir "$K" report; s=$(rp_sec Signals)
          printf '%s\n' "$s" | grep -qx '    - c1: the claim was contested twice.' || note "contested twice is a burn: [$(printf '%s' "$s" | tr '\n' '~')]"
          printf '%s\n' "$s" | grep -qE 'attested by the human' || note "the human's divergence names the human"
          oadd 'visual(c1)' >/dev/null; okb --dir "$K" report; s=$(rp_sec Signals)
          printf '%s\n' "$s" | grep -qx '  - burns: no.' || note "a visual claim does not burn when contested (D21 F6): [$(printf '%s' "$s" | tr '\n' '~')]"
          okb --dir "$K" report --html "$T/r.html"; grep -qF 'divergence: yes.' "$T/r.html" || note "the page prints the signals"; }

# ================================================================ WN: whynot, Y: why
t_WN1() { kb_wn "$T/k"; K=$T/k; okb --dir "$K" whynot 'current(c1)'; rc_is 0; [ "$(first_line)" = holds ] || note "first line '$(first_line)'"; out_has 'because' "the clauses that prove it"; }
t_WN2() { # D20: absent names, for each rule, the literal that blocks, and why
          kb_wn "$T/k"; K=$T/k; okb --dir "$K" whynot 'done'; rc_is 0; [ "$(first_line)" = absent ] || note "first line '$(first_line)'"
          out_has 'stops at not any_under' "the blocking literal of done"; out_has 'claim c1 is current but not fulfilled' "the template text of the reason"; }
t_WN3() { kb_wn "$T/k"; K=$T/k; okb --dir "$K" whynot 'current(c9)'; rc_is 0; [ "$(first_line)" = absent ] || note "first line '$(first_line)'"; [ "$(printf '%s\n' "$out" | wc -l)" -ge 2 ] || note "a justification follows the verdict"; out_has 'claim\(c9' "names the missing fact"; }
t_WN4() { kb_wn "$T/k"; K=$T/k; okb --dir "$K" whynot 'world(door_closed)'; [ "$(first_line)" = holds ] || note "a fact holds: '$(first_line)'"; okb --dir "$K" whynot 'world(window)'; [ "$(first_line)" = absent ] || note "no clause for it: absent, got '$(first_line)'"; out_has 'nothing records world\(window\)'; }
t_WN5() { # D20: the default explanation stops at 6 levels; --long goes on
          kb_new "$T/k" <<'EOF'
uses([]).
request(r1, 'Chain').
decl(rule, d1, 'd1.', '').
decl(rule, d2, 'd2.', '').
decl(rule, d3, 'd3.', '').
decl(rule, d4, 'd4.', '').
decl(rule, d5, 'd5.', '').
decl(rule, d6, 'd6.', '').
decl(rule, d7, 'd7.', '').
decl(rule, d8, 'd8.', '').
decl(fact, d9, 'd9.', '').
EOF
          K=$T/k; printf 'd1 :- d2.\nd2 :- d3.\nd3 :- d4.\nd4 :- d5.\nd5 :- d6.\nd6 :- d7.\nd7 :- d8.\nd8 :- d9.\n' > "$K/rules.pl"
          okb --dir "$K" whynot d1; rc_is 0; out_has 'long shows more' "the default stops"; out_hasnt 'nothing records d9' "the default does not reach d9"
          okb --dir "$K" whynot d1 --long; rc_is 0; out_has 'nothing records d9' "--long reaches d9"; out_hasnt 'long shows more'; }

# ---- D21: a visual claim flares; a human approval of a demo closes the flare
fl_kb() {  # fl_kb: kb_done (done holds) plus visual(c1), so c1 flares
    kb_done "$T/k"; K=$T/k; printf "visual(c1).\n" >> "$K/kb.pl"
}
fl_demo() {  # fl_demo: a screenshot subject s1, demo(s1, c1)
    printf 'png v1\n' > "$K/shot.png"; okb --dir "$K" subject s1 shot.png >/dev/null; oadd 'demo(s1, c1)' >/dev/null
}
t_FL1() { fl_kb; is_true 'flare(c1)'; is_set 'flare_open(X)' 'X = c1'; is_true any_flare_open
          is_false 'done' "c1 is visual and no human approved a demo (F5)"; is_false 'burn(c1)' "visual alone does not burn"
          okb --dir "$K" show open; rc_is 0; out_has '^- flare_open c1: claim c1 needs a human to approve a demo\.'
          okb --dir "$K" lint; rc_is 0 "visual/1 and demo/2 are declared"; }
t_FL2() { fl_kb; fl_demo; is_true 'flare_open(c1)' "a demo with no approval does not close the flare"
          okb --dir "$K" attest approval s1 'digest(current)' --by human; rc_is 0
          is_true 'flare_shown(c1)'; is_false 'flare_open(c1)'; is_true 'done' "a human approved the demo (F3)"; }
t_FL3() { fl_kb; fl_demo; okb --dir "$K" attest approval s1 'digest(current)' --by human >/dev/null
          printf 'png v2\n' > "$K/shot.png"; okb --dir "$K" subject s1 shot.png >/dev/null
          is_false 'flare_shown(c1)' "the approval names the old digest"; is_true 'flare_open(c1)'; is_false 'done' "a new screenshot reopens the flare (F3)"; }
t_FL11() { fl_kb; fl_demo; okb --dir "$K" attest approval s1 'digest(current)' --by human >/dev/null
           is_true 'done' "setup: the approved demo closes the flare"; is_false 'demo_changed(s1)'
           cp "$K/shot.png" "$T/shot.keep"; printf 'png v2, edited on disk\n' > "$K/shot.png"
           is_true 'demo_changed(s1)' "the file differs from its recorded digest (F3b)"
           is_true 'flare_open(c1)' "an edit on disk with no subject run reopens the flare"; is_false 'done'
           cp "$T/shot.keep" "$K/shot.png"; is_false 'demo_changed(s1)'; is_true 'done' "the approved file is back"
           mv "$K/shot.png" "$T/shot.gone"; is_true 'flare_open(c1)' "a missing demo file reopens the flare"; is_false 'done'; }
t_FL4() { fl_kb; fl_demo; rejects agentok 'writer|human' attest approval s1 'digest(current)'
          local d; d=$(sha "$K/shot.png")
          printf "attest(a9, approval, s1, digest('sha256:%s'), agent, '2026-10-15T11:00:00Z').\n" "$d" >> "$K/kb.pl"
          okb --dir "$K" lint; rc_is 1; out_has '^E8'; is_false 'flare_shown(c1)' "an agent cannot approve a demo"; is_false 'done'; }
t_FL5() { fl_kb; okb --dir "$K" attest waiver c1 "waive(c1, '2999-01-01T00:00:00Z', 'Ship first')" --by human; rc_is 0
          is_true 'flare_waived(c1)'; is_false 'flare_open(c1)'; is_true 'done' "a human waived the demo (F4)"
          fl_kb; printf "attest(w1, waiver, c1, waive(c1, '2020-01-01T00:00:00Z', 'Old'), human, '2019-12-01T00:00:00Z').\n" >> "$K/kb.pl"
          is_false 'flare_waived(c1)'; is_true 'flare_open(c1)' "a lapsed waiver does not count"; is_false 'done'; }
t_FL6() { kb_burn "$T/k"; K=$T/k; printf "visual(c1).\n" >> "$K/kb.pl"
          is_false 'burn(c1)' "a visual claim contested twice does not burn (F6)"; is_true 'flare(c1)'
          is_set 'burn(X)' 'X = c3|X = c4'; printf "visual(c3).\nvisual(c4).\n" >> "$K/kb.pl"
          is_set 'burn(X)' 'X = c3|X = c4' "universal and burn_requested still burn a visual claim"; }
t_FL7() { kb_burndone "$T/k"; K=$T/k; printf "visual(c1).\n" >> "$K/kb.pl"; add_proof "$K" p1 c1
          is_true 'burn_proved(c1)'; is_true 'flare_open(c1)' "a proof does not show the look (F2)"; is_false 'done'
          fl_demo; okb --dir "$K" attest approval s1 'digest(current)' --by human >/dev/null
          is_false 'flare_open(c1)'; is_true 'done' "proved and shown"; }
t_FL8() { fl_kb; printf "supersedes(c3, c1).\nclaim(c3, preserve, 'One stays true, new name').\ncites(c3, 'Do two things').\ncheck(k3, c3).\nserves(x1, c3).\n" >> "$K/kb.pl"
          add_result "$K" k3 4 pass; is_true 'flare(c3)' "c3 replaces the visual claim c1 (F2)"
          is_set 'flare_open(X)' 'X = c3' "c1 is superseded, so only c3 is open"; is_false 'done'; }
t_FL9() { fl_kb; printf 'flare_shown(c1).\nflare_waived(C) :- claim(C, _, _).\n' > "$K/rules.pl"
          okb --dir "$K" lint; rc_is 1 "rules.pl cannot close a flare (F8)"
          [ "$(printf '%s\n' "$out" | grep -c '^E16 rules.pl')" = 2 ] || note "want E16 on each of the 2 clauses: $(snip "$out")"
          is_true 'flare_open(c1)' "the engines ignore the clause"; is_false 'done'; }
t_FL10() { fl_kb; okb --dir "$K" report; rc_is 0
           rl_is "c1 (flare open)" "  - c1 **preserve**: One stays true
    - Status: fulfilled.
    - Flare: NOT SHOWN.
      - A human must approve a demo of it.
    - Checks: k1 (passed)." "$(rp_item c1)"
           rp_sec Open | grep -q '^  - \*\*flare open\*\*: Claim c1 needs a human to approve a demo' || note "Open lists the flare: $(snip "$(rp_sec Open)")"
           okb --dir "$K" report --html "$T/r.html"; rc_is 0
           rh_has "$(rh_section "$T/r.html" open)" 'data-open="flare_open"[^>]*data-ref="c1"' "open flare c1 on the page"
           fl_demo; okb --dir "$K" attest approval s1 'digest(current)' --by human >/dev/null; okb --dir "$K" report; rc_is 0
           rl_is "c1 (flare shown)" "  - c1 **preserve**: One stays true
    - Status: fulfilled.
    - Flare: shown.
      - A human approved demo s1 (shot.png).
    - Checks: k1 (passed)." "$(rp_item c1)"
           fl_kb; printf "attest(w1, waiver, c1, waive(c1, '2020-01-01T00:00:00Z', 'Old'), human, '2019-12-01T00:00:00Z').\n" >> "$K/kb.pl"
           okb --dir "$K" report; rc_is 0
           rp_sec Open | grep -q 'Waiver w1 of the demo of claim c1 was due at 2020-01-01T00:00:00Z' || note "the lapsed waiver names the demo: $(snip "$(rp_sec Open)")"; }
t_Y1() { mkclaim; old_decl "decl(fact, gizmo(id, text), 'A gizmo.', '@(1) is a gizmo called @(2)')."; oadd "gizmo(g1, sprocket)" >/dev/null
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
t_E17() { fx_lint e17_scasp_syntax E17; any_hasi 's\(CASP\) syntax'; }
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
# ================================================================ D7: review fixes (contract D7, E14)
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
t_SH3() { kb_done "$T/k"; K=$T/k; printf "question(q2, c2, 'Is it two').\nassumed(q2, no).\nattest(d1, divergence, c2, claim(c2), agent, '2026-10-15T10:00:09Z').\nchange(x3, 'Unrelated').\n" >> $K/kb.pl
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
t_RP7() { kb_new "$T/k" <<'EOF'
uses([discovery]).
request(r1, 'Some totals look wrong.').
hypothesis(h1, defect, 'The inputs decide each total. Some totals differ.').
claim(c1, introduce, 'Each total matches its inputs.').
cites(c1, 'totals look wrong').
question(q1, c1, 'Which totals count?').
assumed(q1, all).
raised_by(q1, h1).
EOF
    K=$T/k; okb --dir "$K" report; rc_is 0
    local o; o=$(rp_sec Open)
    printf '%s\n' "$o" | grep -q 'Nothing is open' && note "Open says nothing is open while q1 waits: [$o]"
    printf '%s\n' "$o" | grep -q 'q1' || note "Open names the waiting question q1: [$o]"
    # D32 O2: one "not ready" item for each thing that blocks readiness
    printf '%s\n' "$o" | grep -q 'Discovery is not ready, untouched h1' || note "Open says discovery is not ready, and names h1: [$o]"
    printf '%s\n' "$o" | grep -q 'Discovery is not ready, no_falsifier c1' || note "Open names the claim with no falsifier: [$o]"; true; }
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
    rl_is "headings" "# Delivered:|# KB:|# Signals:|# Hypothesis:|# Claims:|# Formal:|# Guesses:|# Disclosures:|# Waivers:|# Not checked:|# Open:|# To land:" "$heads"
    printf '%s\n' "$out" | grep -qE '^[A-Z][A-Za-z ]*:$' && note "a heading without the # mark"
    local n; n=$(printf '%s\n' "$out" | awk '/^# / && NR > 1 && prev != "" {bad++} {prev = $0} END {print bad + 0}')
    rl_is "a blank line before every heading but the first" 0 "$n"
    [ "$(printf '%s\n' "$out" | sed -n 1p)" = "# Delivered:" ] || note "the first line is the Delivered heading"
    [ -n "$(printf '%s\n' "$out" | tail -n 1)" ] || note "the last line is blank"
    [ "$(printf '%s\n' "$out" | grep -c '^$')" = 11 ] || note "want exactly 11 blank lines (one between sections), got $(printf '%s\n' "$out" | grep -c '^$')"
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
    # D31 B2: c1 has an example, which nests under the claim (the one line would pass 100 columns)
    rl_is "c1 (fulfilled, with its example)" "  - c1 **introduce**: The widget can be saved
    - Status: fulfilled.
    - Example: Save a widget, close the app, open it again, and see the widget.
    - Checks: k1 (passed)." "$(rp_item c1)"
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
    # D31 B4: a proved burn names its theorem, and nests what the proof is about
    rl_is "c2 (burn proved) nests" "  - c2 **preserve**: Loading stays fast
    - Status: fulfilled.
    - Burn: proved in Lean: theorem load_fast.
      - The proof is about the Lean definitions, not the code. No conformance check carries the examples of the definitions to the code.
    - Checks: k2 (passed)." "$(rp_item c2)"
    rl_is "no line of a one-line claim is over 100 columns" 0 "$(printf '%s\n' "$out" | awk '/^  - c[0-9]+ \*\*[a-z]+\*\*: .*Status: fulfilled\. / && length($0) > 100 {n++} END {print n + 0}')"; }
t_RL4() { # more than one check: they nest under Checks
    rh_kb report_review; printf "check(k8, c1).\n" >> "$K/kb.pl"; okb --dir "$K" report; rc_is 0
    rl_is "c1 with two checks" "  - c1 **introduce**: The widget can be saved
    - Status: fulfilled.
    - Example: Save a widget, close the app, open it again, and see the widget.
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
    # D32 O1: the Open part names each answer of blocking(X): the under claims and the failing check too
    rl_is "Open: the kind in bold, the first sentence, then the rest nested" "  - **ask**: Ask question q1 now
  - **under**: Claim c2 is current but not fulfilled: Loading stays fast
  - **under**: Claim c6 is current but not fulfilled: The save button has a tooltip
  - **check failing**: Check k2 did not pass its last run: a check of claim c2: Loading stays fast
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
        # D31 B3: the KB field names the KB directory; the golden files have KBDIR in its place
        rh_kb "$k"; okb --dir "$K" report; rc_is 0 "report $k"; printf '%s\n' "$out" | sed "s#$K#KBDIR#g" > "$T/.outn"
        cmp -s "$T/.outn" "$GOLD/$k.txt" || note "report $k: the text differs from $GOLD/$k.txt: $(diff "$GOLD/$k.txt" "$T/.outn" | head -n 6 | tr '\n' '~')"
        okb --dir "$K" report --html "$T/$k.html"; rc_is 0 "report --html $k"; printf '%s\n' "$out" | sed "s#$K#KBDIR#g" > "$T/.outn"
        cmp -s "$T/.outn" "$GOLD/$k.txt" || note "report --html $k: stdout differs from $GOLD/$k.txt"
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
t_DR1() { okb doctor; rc_is 0 "doctor on this machine"; any_hasi 'swipl'; any_hasnti 'scasp:|s\(CASP\)' "D20: doctor does not look for scasp"; }
t_DR2() { okb doctor; dr_passes 'helper' "not with a helper rule"; dr_passes 'under\(_\)' "not under(_)"; dr_passes 'arithmetic' "arithmetic under not"; dr_passes 'E18' "E18"; dr_passes 'E17' "E17"; }
# A doctor line that reports a failure: the word fail, fails, failed, or failure. Whole words only,
# so a line that names the rule failed_after is no failure.
FAIL_WORD='\bfail(s|ed|ure)?\b'
dr_passes() {  # dr_passes ERE LABEL: doctor (in $out/$err) has a line matching ERE (case-insensitive), and each such line passes
    local lines; lines=$(anyout | grep -Ei -- "$1")
    [ -n "$lines" ] || { note "doctor has no line for $2 (/$1/): $(snip "$out")"; return 1; }
    printf '%s\n' "$lines" | grep -Eiv -- '\b(ok|pass(ed|es)?)\b' | grep -q . && note "a $2 line does not say ok or pass: $(snip "$lines")"
    printf '%s\n' "$lines" | grep -Eiq -- "$FAIL_WORD" && note "a $2 line reports a failure: $(snip "$lines")"
    return 0
}
t_DR3() { local e; e=$(mktemp -d "$base/emptylib.XXXXXX"); ( cd "$T" && ORBIT_KB_LIB="$e" exec timeout "$TMO" "$OKB" doctor ) >"$T/.out" 2>"$T/.err" </dev/null; rc=$?; out=$(<"$T/.out"); err=$(<"$T/.err")
         rc_is 2 "doctor with a broken library"; any_hasi 'librar'; }
t_HP1() { okb help; rc_is 0; any_hasi 'negation as failure'; any_hasi 'stratified'; any_hasi 'query'; any_hasi 'lint'; any_hasnti 'scasp|s\(CASP\)' "D20: no second engine"; }
t_HP2() { okb help query; rc_is 0; any_hasi 'query'; any_hasi -- '--why'; any_hasnti 'json' "D20: no --json"; }
t_HP3() { okb --help; rc_is 0 "--help"; any_hasi 'usage'; }
t_HP4() { okb help; rc_is 0; any_has 'How to use'; local t
          for t in core build discovery codes answers; do any_has "orbit-kb help $t" "general help names $t"; done; }
t_HP5() { local t; for t in core build discovery codes answers; do
            okb help "$t"; rc_is 0 "help $t"; any_hasi "$t" "help $t is not empty"; done; }
t_HP6() { okb help nosuchtopic; rc_is 2 "unknown topic"; }
t_HP7() { okb init "$T/hp7" --request 'x'; rc_is 0; any_has 'Next:.*help core'; }

# ================================================================ D22: the spec KB (ticket T03)
# FU: the schema is declared on first use (c1), lint lists it (c2, W7), the typo guard (c3,
# E19), declared predicates keep their types (c4), declare still works and is optional (c5).
t_FU1() { K=$T/k; kb_init "$K" build
          oadd 'colour_of(widget1, blue)'; rc_is 0 "a new predicate is declared by its first use"
          has_fact "$K/kb.pl" "colour_of(widget1, blue)" "the fact"
          has_fact "$K/kb.pl" "decl(fact, colour_of(_, _), _, _)" "a decl/4 line for colour_of/2"
          has_goal "$K/kb.pl" "kb(first_use(colour_of/2, agent, T)), atom(T), atom_length(T, 20), sub_atom(T, 19, 1, 0, 'Z')" "first_use records who (agent) and when"
          has_goal "$K/kb.pl" "kb_line(A, decl(fact, colour_of(_, _), _, _)), kb_line(B, colour_of(widget1, blue)), A < B" "the decl comes before the fact"
          oadd 'colour_of(widget2, red)'; rc_is 0 "a second use"
          fact_count "$K/kb.pl" "first_use(colour_of/2, _, _)" 1 "one first_use per predicate"
          fact_count "$K/kb.pl" "decl(_, colour_of(_, _), _, _)" 1 "one decl per predicate"
          oadd 'size_of(widget1, 3)' --by human; rc_is 0 "--by human"
          has_fact "$K/kb.pl" "first_use(size_of/2, human, _)" "first_use records the human"
          rejects arity 'colour_of/1 is not declared\. colour_of is declared with arity 2\.' add 'colour_of(widget3)'
          rejects batch '' add 'shape_of(w1, round)' "cites(c9, 'x')"
          no_fact "$K/kb.pl" "decl(_, shape_of(_, _), _, _)" "a rejected batch declares nothing"
          okb --dir "$K" add 'tint_of(w1, x)' --by robot; rc_is 2 "--by takes human or agent"; }
t_FU2() { K=$T/k; kb_init "$K" build; oadd 'colour_of(widget1, blue)' >/dev/null
          okb --dir "$K" lint; rc_is 0 "W7 is a warning"; out_has '^W7 .*colour_of/2' "lint lists the first-use predicate"
          out_has '^W7 .*colour_of/2.*agent' "W7 names who declared it"; out_hasnt '^W2 .*colour_of' "W7, not W2, lists a first-use declaration"
          okb --dir "$K" lint --strict; rc_is 1 "--strict makes W7 an error"
          okb help codes; rc_is 0; out_has '^ +W7 ' "help codes documents W7"; }
t_FU3() { K=$T/k; kb_init "$K" build
          old_decl "decl(fact, color_of(id, atom), 'The color of a thing.', '')."
          oadd 'colour_of(widget1, blue)'; rc_is 0 "add still succeeds near a declared name"
          oadd 'paint_of(widget1, blue)' 'colr_of(a, b, c)'; rc_is 0 "a far name, and a near name of another arity"
          okb --dir "$K" lint; rc_is 1 "the typo guard is an error"
          out_has '^E19 .*colour_of/2.*color_of/2' "E19 names both predicates"
          out_hasnt '^E19 .*paint_of' "a name more than 2 edits away"; out_hasnt '^E19 .*colr_of' "another arity"
          K=$T/k2; kb_init "$K" build; oadd "cite(c1, 'x')" >/dev/null
          okb --dir "$K" lint; rc_is 1; out_has '^E19 .*cite/2.*cites/2' "a near name of a core predicate"
          okb help codes; out_has '^ +E19 ' "help codes documents E19"; }
t_FU4() { mkclaim; rejects arity 'claim/1 is not declared\. claim is declared with arity 3\.' add 'claim(c1)'
          no_fact "$K/kb.pl" "first_use(_, _, _)" "a wrong arity of a declared name is no first use"
          rejects oneof 'E3' add "claim(c2, bogus, 'x')"
          rejects reftype 'E4' add "cites(c9, 'x')"; }
t_FU5() { mkclaim; old_decl "decl(fact, gizmo(id, text), 'A gizmo.', '')."
          oadd 'gizmo(g1, a)'; rc_is 0 "a predicate that a decl/4 line declares (an older KB)"; has_fact "$K/kb.pl" "gizmo(g1, a)"
          no_fact "$K/kb.pl" "first_use(gizmo/2, _, _)" "a declared predicate has no first use"
          rejects type 'E3' add 'gizmo(g2, 5)'
          okb --dir "$K" lint; out_hasnt '^W7' "no W7 for a declared predicate"; out_hasnt '^W9' "no W9 for a kind with a doc"; }
t_FU6() { okb help add; rc_is 0; any_hasi 'first use' "help add names the first use"; any_hasi '--doc' "help add names --doc"
          okb help core; rc_is 0; any_hasi 'first use' "help core names the first use"; any_hasi '--doc' "help core names --doc"; }

# KD: T26 (amends D22): declare is removed. The first add of a new kind may take --doc. show kinds.
t_KD1() { local repo f; repo=$LIB/../../..; mkclaim
          okb --dir "$K" declare 'gizmo(id, text)' --doc 'A gizmo.'   # KD1-call
          rc_is 2 "declare is gone"; any_hasi 'add.*--doc' "the line says to use add --doc"
          [ "$(printf '%s\n' "$err" | grep -c .)" = 1 ] || note "declare prints one line on stderr (stderr: $(snip "$err"))"
          no_fact "$K/kb.pl" "decl(_, gizmo(_, _), _, _)" "declare wrote nothing"
          okb help declare; rc_is 2 "no help topic for declare"
          okb help; any_hasnt '^ *declare ' "general help lists no declare command"   # KD1-call
          for f in "$LIB"/help/*.txt "$LIB/README.md" "$repo/prompt/SAGITTARIUS.md"; do
              grep -qE 'orbit-kb declare|^ +declare ' "$f" && note "${f##*/} still names the declare command"; done
          return 0; }
t_KD2() { mkclaim
          oadd 'gizmo(g1, a)' --doc 'A gizmo.'; rc_is 0 "the first add of a new kind takes --doc"
          has_fact "$K/kb.pl" "decl(fact, gizmo(_, _), 'A gizmo.', _)" "the doc is the description of the kind"
          has_fact "$K/kb.pl" "first_use(gizmo/2, agent, _)" "the first use is recorded"
          any_hasnt 'orbit-kb declare' "the NOTE does not name declare"
          oadd 'gizmo(g2, b)' --doc 'Again.'; rc_is 1 "--doc on a kind that exists is refused"
          rejects multiline '' add 'sprocket(s1)' --doc 'one
two'
          oadd 'widget(w1)'; rc_is 0 "--doc is optional"
          okb --dir "$K" lint; out_has '^W9 .*widget/1' "a W-lint names a kind with no description"
          out_hasnt '^W9 .*gizmo/2' "no W-lint for a kind with a --doc"
          okb --dir "$K" show kinds; rc_is 0; out_has 'widget/1.*no description' "show kinds names it"
          okb help codes; out_has '^ +W9 ' "help codes documents W9"; }
t_KD3() { mkclaim; oadd 'gizmo(g1, a)' --doc 'A gizmo.' >/dev/null
          okb --dir "$K" show kinds; rc_is 0 "show kinds"
          out_has '^- claim/3: .*[A-Za-z]' "a core kind with its decl doc"
          out_has '^- change/2: .*[A-Za-z]' "a module kind with its decl doc"
          out_has '^- gizmo/2: A gizmo\.' "a new kind with its --doc"
          okb --dir "$K" show nosuch; rc_is 2 "show takes only known sections"; any_has 'kinds' "the usage names kinds"; }
t_KD4() { K=$T/k; kb_new "$K" <<'EOF'
uses([]).
request(r1, 'x').
decl(fact, q(atom), 'A q.', '').
decl(rule, p(atom), 'A p.', '').
q(a).
EOF
          okb --dir "$K" lint; rc_is 0 "a KB with decl/4 lines loads"
          okb --dir "$K" show kinds; rc_is 0; out_has '^- q/1: A q\.' "the doc of a decl/4 line shows in show kinds"; }
t_KD6() { mkclaim
          printf "%%%% doc: Some person owns the claim.\nhas_owner(C) :- claim(C, _, _).\nlonely(C) :- claim(C, _, _), not has_owner(C).\n" > "$K/rules.pl"
          okb --dir "$K" lint; rc_is 0 "rules.pl heads are declared by their first definition: no E2"; out_hasnt '^E' "no error"
          out_has '^W9 rules\.pl:3.*lonely/1' "W9 names a rule head with no doc comment"; out_hasnt '^W9 .*has_owner' "no W9 for a head with a doc comment"
          okb --dir "$K" show kinds; rc_is 0; out_has '^- has_owner/1 \(rule\): Some person owns the claim\.' "show kinds lists the rule with its doc, marked as a rule"
          out_has '^- lonely/1 \(rule\): \(no description\)' "show kinds says a rule has no description"
          is_true 'has_owner(c1)'
          rejects ruledecl 'rules\.pl.*doc' add "decl(rule, other(id), 'x', '')"
          rejects factdecl '--doc' add "decl(fact, other(id), 'x', '')"
          printf "decl(rule, old_rule(atom), 'An old rule.', '').\n" >> "$K/kb.pl"; printf "old_rule(a).\n" >> "$K/rules.pl"
          okb --dir "$K" show kinds; out_has '^- old_rule/1 \(rule\): An old rule\.' "an old decl(rule, ...) line still loads, its doc shows"; }
# KD7 (T40 c8): a kind with no description can get one later. --doc on an add of an existing kind of
# kb.pl whose description is empty or the old W7 placeholder sets it (refused when it has one); W9's
# advice says so. A kb.pl decl(rule, H, '', T) takes the doc of a %% doc: line in rules.pl.
t_KD7() { mkclaim
          oadd 'widget(w1)'; rc_is 0 "setup: a kind with no description"
          oadd 'widget(w2)' --doc 'A widget of the shop.'; rc_is 0 "--doc on an existing kind with no description"
          has_fact "$K/kb.pl" "decl(fact, widget(_), 'A widget of the shop.', _)" "the kind has its description"
          no_fact "$K/kb.pl" "decl(fact, widget(_), '', _)" "the empty description is gone, not kept beside the new one"
          has_fact "$K/kb.pl" "widget(w2)" "the fact is written"
          okb --dir "$K" lint; out_hasnt '^W9 .*widget/1' "no W9 for widget/1"; out_hasnt '^E' "no lint error"
          rejects has-doc '' add 'widget(w3)' --doc 'Again.'
          printf "decl(fact, sprocket(term), 'Declared by its first use. Review it (lint W7).', '').\nsprocket(s1).\n" >> "$K/kb.pl"
          oadd 'sprocket(s2)' --doc 'A sprocket.'; rc_is 0 "--doc on a kind with the old W7 placeholder"
          has_fact "$K/kb.pl" "decl(fact, sprocket(_), 'A sprocket.', _)" "the placeholder is replaced"
          printf "decl(fact, cog(term), '', '').\ncog(c1).\n" >> "$K/kb.pl"
          okb --dir "$K" lint; out_has '^W9 .*cog/1' "setup: W9 for cog/1"
          printf '%s\n' "$out" | grep -E '^W9 .*cog/1' | grep -Eqi 'later|existing|next add|any add' \
              || note "W9 does not say that a later add can describe the kind: $(snip "$(printf '%s\n' "$out" | grep -E '^W9 .*cog/1')")"
          printf "decl(rule, hot(term), '', '').\n" >> "$K/kb.pl"
          printf "%%%% doc: A hot claim.\nhot(C) :- claim(C, _, _).\n" > "$K/rules.pl"
          okb --dir "$K" lint; out_hasnt '^W9 .*hot/1' "a %% doc: line in rules.pl describes the kb.pl rule with no description"
          okb --dir "$K" show kinds; rc_is 0; out_has '^- hot/1 \(rule\): A hot claim\.' "show kinds shows the rules.pl doc"; }

# KD8 (T40 c9): show kinds works while E19 or E2 fires (it is how the clash is found); a repeated
# --doc is refused, not silently the first.
t_KD8() { mkclaim
          rejects repeated-doc 'doc' add 'gear(g1)' --doc 'One.' --doc 'Two.'
          printf "claimm(C, L, X) :- claim(C, L, X).\n" > "$K/rules.pl"
          okb --dir "$K" lint; out_has '^E19 ' "setup: E19 fires"
          okb --dir "$K" show kinds; rc_is 0 "show kinds while E19 fires"; out_has '^- claim/3: ' "show kinds lists the kinds"
          out_has '^- claimm/3' "show kinds lists the clashing head"
          printf "lone(C) :- nosuch_pred(C).\n" > "$K/rules.pl"
          okb --dir "$K" lint; out_has '^E2 ' "setup: E2 fires"
          okb --dir "$K" show kinds; rc_is 0 "show kinds while E2 fires"; out_has '^- claim/3: ' "show kinds lists the kinds"
          okb --dir "$K" show claims; rc_is 2 "the answer gate still holds for the other sections"; }

# KD9 (T40 c9): CONTRACT D22 C1 and C3, D23 P7 and D25 T4 no longer name the removed declare command;
# evals/grade_tools.py WRITES drops declare.
t_KD9() { local c=$here/../CONTRACT.md g=$here/../../evals/grade_tools.py id l
          for id in '  - C1 (first use' '  - C3 (E19' '  - P7 (' '  - T4 ('; do
              l=$(grep -F -- "$id" "$c" | head -n1)
              [ -n "$l" ] || { note "CONTRACT has no item '$id'"; continue; }
              printf '%s\n' "$l" | grep -Eq '`declare`|orbit-kb declare' && note "CONTRACT item '$id' still names declare"
          done
          grep -E '^WRITES = ' "$g" | grep -q '"declare"' && note "evals/grade_tools.py WRITES still lists declare"; return 0; }

t_KD5() { local f n=0 hits=""; for f in "$here"/test_*.sh; do
              hits+=$(grep -nE "okb.* declare |orbit-kb declare " "$f" | grep -v 'KD1-call' | sed "s|^|${f##*/}:|"); done
          [ -z "$hits" ] || note "tests still call declare: $(snip "$hits")"; return 0; }

# RT: retired with D22 (c6): declare-attest and the depends fact kind.
t_RT1() { mkclaim; okb --dir "$K" declare-attest reading 'level(text, int)' --doc 'A reading.' --writers human,agent
          rc_is 2 "declare-attest is gone"; any_hasi 'unknown command'
          okb declare-attest x; rc_is 2; any_hasi 'unknown command'
          okb help; any_hasnt 'declare-attest' "general help"; okb help declare-attest; rc_is 2 "no help for it"
          grep -q 'declare-attest' "$LIB/README.md" && note "README.md still names declare-attest"; return 0; }
t_RT2() { mkclaim; q 'depends(X, Y)'; rc_is 2 "depends/2 is not declared any more"
          okb help core; any_hasnt 'depends\(' "help core"
          grep -q 'depends(' "$LIB/README.md" && note "README.md still names depends/2"; return 0; }

# BL: blocking/1 lists every item that blocks done, one kind per test (c7).
bl_base() { kb_new "$1" <<'EOF'
uses([build]).
request(r1, 'Block things').
claim(c1, preserve, 'Claim one').
cites(c1, 'Block things').
EOF
}
t_BL1() { bl_base "$T/k"; K=$T/k
          printf "question(q1, c1, 'Is it a').\nattest(d1, divergence, c1, claim(c1), agent, '2026-10-15T10:00:01Z').\n" >> "$K/kb.pl"
          is_set 'blocking(to_ask(X))' 'X = q1'
          echo "answer(q1, yes, human)." >> "$K/kb.pl"; is_false 'blocking(to_ask(X))'; }
t_BL2() { kb_burn "$T/k"; K=$T/k; is_set 'blocking(burn_open(X))' 'X = c1|X = c3|X = c4'; }
t_BL3() { bl_base "$T/k"; K=$T/k; echo "visual(c1)." >> "$K/kb.pl"; is_set 'blocking(flare_open(X))' 'X = c1'; }
bl_checks() { kb_new "$1" <<'EOF'
uses([build]).
request(r1, 'Check things').
claim(c1, introduce, 'Claim one').
claim(c2, preserve, 'Claim two').
cites(c1, 'Check things').
cites(c2, 'Check things').
check(k1, c1).
check(k2, c1).
check(k3, c2).
check(k4, c2).
check(k5, c2).
EOF
}
t_BL10() { bl_checks "$T/k"; K=$T/k; add_result "$K" k1 1 fail; add_result "$K" k3 2 pass
          is_set 'blocking(check_unrun(X))' 'X = k2' "k5 never ran, but its claim c2 is fulfilled"; }
t_BL4() { kb_new "$T/k" <<'EOF'
uses([build]).
request(r1, 'Check things').
claim(c1, introduce, 'Claim one').
claim(c2, preserve, 'Claim two').
cites(c1, 'Check things').
cites(c2, 'Check things').
check(k1, c1).
check(k2, c1).
check(k3, c2).
check(k4, c2).
EOF
          K=$T/k; add_result "$K" k1 1 fail; add_result "$K" k3 2 pass; add_result "$K" k4 3 fail
          is_set 'blocking(check_failing(X))' 'X = k1'; }
t_BL5() { kb_burndone "$T/k"; K=$T/k; wv_add w1 c1 2020-01-01T00:00:00Z
          is_set 'blocking(waiver_lapsed(X))' 'X = w1'; is_set 'blocking(burn_open(X))' 'X = c1'
          wv_add w2 c1 2999-01-01T00:00:00Z; is_false 'blocking(waiver_lapsed(X))' "a waiver in force closes the burn"
          is_true done; }
t_BL6() { kb_done "$T/k"; K=$T/k
          printf "claim(c3, preserve, 'Unchecked').\ncites(c3, 'Do two things').\ndue(c3, '2020-01-01T00:00:00Z').\ndue(c1, '2020-01-01T00:00:00Z').\ndue(q1, '2999-01-01T00:00:00Z').\n" >> "$K/kb.pl"
          okb --dir "$K" lint; out_hasnt '^E' "due/2 is declared"
          is_set 'blocking(past_due(X))' 'X = c3'; }
t_BL7() { kb_done "$T/k"; K=$T/k; is_true done; is_false 'blocking(X)' "done: nothing blocks"
          printf "change(x3, 'Unrelated').\n" >> "$K/kb.pl"; is_set 'blocking(X)' 'X = over(x3)'
          kb_done "$T/k2"; K=$T/k2; printf "claim(c3, preserve, 'Unchecked').\ncites(c3, 'Do two things').\n" >> "$K/kb.pl"
          is_set 'blocking(X)' 'X = under(c3)'
          K=$T/k3; kb_init "$K" build; is_set 'blocking(X)' 'X = no_claim'; }
t_BL8() { kb_done "$T/k"; K=$T/k; okb --dir "$K" show blocking; rc_is 0; out_has 'Nothing blocks done'
          printf "question(q2, c2, 'Is it two').\nattest(d1, divergence, c2, claim(c2), agent, '2026-10-15T10:00:09Z').\nclaim(c3, preserve, 'Unchecked claim').\ncites(c3, 'Do two things').\n" >> "$K/kb.pl"
          okb --dir "$K" show blocking; rc_is 0
          out_has 'to_ask q2.*Is it two' "the question with its text"; out_has 'under c3.*Unchecked claim' "the claim with its text"
          out_hasnt 'Nothing blocks done'; }
t_BL9() { kb_done "$T/k"; K=$T/k; printf 'blocking(nothing).\n' > "$K/rules.pl"
          okb --dir "$K" lint; rc_is 1; out_has '^E16 .*blocking/1' "rules.pl cannot add to blocking/1"
          is_false 'blocking(X)' "the engine ignores the clause"; }

# Added after review of de77192 (D22 c3, c6, c7).
t_FU7() { K=$T/k; kb_init "$K" build
          old_decl "decl(fact, color_of(id, atom), 'The color of a thing.', '')."
          oadd 'colr_ov(widget1, blue)' 'clr_ov(widget1, blue)'; rc_is 0 "add"
          okb --dir "$K" lint; rc_is 1 "edit distance 2 is an error"
          out_has '^E19 .*colr_ov/2.*color_of/2' "colr_ov is 2 edits from color_of"
          out_hasnt '^E19 .*clr_ov/2' "clr_ov is 3 edits from color_of: no finding"; }
# FU8 replaces FU7, which is wrong and stays as committed: in FU7, colr_ov/2 and clr_ov/2 are
# both new, and they are 1 edit apart, so E19 correctly names clr_ov/2 against colr_ov/2.
# FU8 puts each case in its own KB.
t_FU8() { K=$T/k; kb_init "$K" build
          old_decl "decl(fact, color_of(id, atom), 'The color of a thing.', '')."
          oadd 'colr_ov(widget1, blue)'; rc_is 0 "add"
          okb --dir "$K" lint; rc_is 1 "edit distance 2 is an error"
          out_has '^E19 .*colr_ov/2.*color_of/2' "colr_ov is 2 edits from color_of"
          K=$T/k2; kb_init "$K" build
          old_decl "decl(fact, color_of(id, atom), 'The color of a thing.', '')."
          oadd 'clr_ov(widget1, blue)'; rc_is 0 "add"
          okb --dir "$K" lint; rc_is 0 "distance 3: no error"
          out_hasnt '^E19' "clr_ov is 3 edits from color_of: no finding"; }
# CONTRACT keeps the history of the cut: a line that says the item was retired or removed is
# exempt (the D22 entry names both items there). Every other line must not name them.
t_RT3() { local f t; f=$LIB/../../CONTRACT.md
          [ -f "$f" ] || { note "no CONTRACT.md at $f"; return 0; }
          t=$(grep -nE 'depends\(|declare-attest' "$f" | grep -vE 'retire|removed')
          [ -z "$t" ] || note "CONTRACT.md names a cut item outside its history: $(snip "$t")"
          for t in build discovery codes answers; do
              okb help "$t"; rc_is 0 "help $t"; any_hasnt 'depends\(|declare-attest' "help $t"
          done; }
t_BL6b() { kb_done "$T/k"; K=$T/k
          printf "question(q2, c2, 'Is it two').\nquestion(q3, c2, 'Is it three').\nattest(d1, divergence, c2, claim(c2), agent, '2026-10-15T10:00:09Z').\nanswer(q3, yes, human).\nclaim(c3, preserve, 'Unchecked').\ncites(c3, 'Do two things').\ncheck(k9, c3).\ndue(q2, '2020-01-01T00:00:00Z').\ndue(q3, '2020-01-01T00:00:00Z').\ndue(k9, '2020-01-01T00:00:00Z').\ndue(k1, '2020-01-01T00:00:00Z').\n" >> "$K/kb.pl"
          is_set 'blocking(past_due(X))' 'X = k9|X = q2' "q3 is answered and k1 is a check of a fulfilled claim"; }
# AC (D29, ticket T29 c7): acceptance criteria are claims marked ac/1. An unmet AC is named as such in
# show blocking and draft blocking. done, blocking/1 and the burn rules do not change.
ac_kb() { kb_done "$1"; printf "claim(c3, introduce, 'Orders sort by date').\ncites(c3, 'Do two things').\ncheck(k3, c3).\nclaim(c4, preserve, 'Plain claim four').\ncites(c4, 'Do two things').\n" >> "$1/kb.pl"; }
t_AC1() { kb_done "$T/k"; K=$T/k
          oadd 'ac(c2)'; rc_is 0 "ac/1 is declared: add takes ac(c2)"
          no_fact "$K/kb.pl" "first_use(ac/1, _, _)" "ac/1 is declared by the library, not by its first use"
          okb --dir "$K" lint; rc_is 0 "lint is clean with ac(c2)"; out_hasnt '^W7' "no W7 for ac/1"
          rejects "ac of a question" 'E4|claim' add 'ac(q1)'
          okb help build; rc_is 0; any_hasi 'ac\(' "help build names ac/1"; any_hasi 'acceptance criteri' "help build says what ac/1 means"; }
t_AC2() { ac_kb "$T/k"; K=$T/k; echo "ac(c3)." >> "$K/kb.pl"; add_result "$K" k3 4 fail
          okb --dir "$K" show blocking; rc_is 0
          out_has '^- under c3: .*acceptance criterion.*not met.*Orders sort by date' "an unmet AC is named as an acceptance criterion"
          out_has '^- under c4: claim c4 is current but not fulfilled: Plain claim four' "a claim that is no AC keeps its line"
          if printf '%s\n' "$out" | grep -E '^- under c4' | grep -qi 'acceptance'; then note "c4 is no AC, but its line says acceptance"; fi; }
t_AC3() { ac_kb "$T/k"; K=$T/k; echo "ac(c3)." >> "$K/kb.pl"
          okb --dir "$K" draft blocking; rc_is 0
          out_has '^- under c3: .*acceptance criterion.*not met.*Orders sort by date' "draft blocking names the unmet AC"
          out_has '^- under c4: claim c4 is current but not fulfilled' "draft blocking: c4 keeps its line"; }
t_AC4() { ac_kb "$T/k"; K=$T/k; q 'blocking(X)' -n 0; local before=$out
          echo "ac(c3)." >> "$K/kb.pl"; q 'blocking(X)' -n 0
          [ "$out" = "$before" ] || note "ac/1 changed the answers of blocking(X): [$(snip "$before")] -> [$(snip "$out")]"
          is_false done "an unmet AC: not done"
          kb_done "$T/k2"; K=$T/k2; echo "ac(c2)." >> "$K/kb.pl"; is_true done "a met AC does not block done"
          okb --dir "$K" show blocking; out_has 'Nothing blocks done' "a met AC is not listed"
          q 'burn(X)' -n 0; rc_is 1 "ac/1 does not make a claim burn"; }
t_AC5() { ac_kb "$T/k"; K=$T/k; echo "ac(c3)." >> "$K/kb.pl"
          printf 'ac(c4).\n' > "$K/rules.pl"; okb --dir "$K" lint
          if printf '%s\n' "$out" | grep -q '^E16'; then note "ac/1 is a fact kind, not protected: rules.pl may not be refused for it"; fi
          rm -f "$K/rules.pl"
          q 'ac(X)' -n 0; rc_is 0 "query ac(X)"; out_has 'X = c3' "ac(c3) is queryable"; }

# ---------------------------------------------------------------- D28: verification records (T25)
# vr_kb DIR: a build KB with two claims and their checks, written by the CLI (no actor yet).
vr_kb() { kb_new "$1" <<'EOF2'
uses([build]).
request(r1, 'Verify two things').
claim(c1, introduce, 'One becomes true').
claim(c2, preserve, 'Two stays true').
cites(c1, 'Verify two things').
cites(c2, 'Verify two things').
check(k1, c1).
check(k2, c2).
EOF2
}
# vr_ind DIR: a KB in which c1 is independently verified (D28 V4): change x1 by (build, s1) at
# 10:00, run t1 of k1 by (review, s2) at 10:04, verdict v1 upheld by (review, s2) at 10:05.
vr_ind() { kb_new "$1" <<'EOF2'
uses([build]).
request(r1, 'Verify one thing').
claim(c1, introduce, 'One becomes true').
cites(c1, 'Verify one thing').
check(k1, c1).
change(x1, 'Edit one').
serves(x1, c1).
change_at(x1, '2026-11-01T10:00:00Z').
actor(x1, build, s1).
attest(t1, test_result, k1, result(k1, 1, pass), script, '2026-11-01T10:04:00Z').
actor(t1, review, s2).
attest(v1, disproof, c1, verdict(c1, upheld('reran k1; tried an empty input')), agent, '2026-11-01T10:05:00Z').
actor(v1, review, s2).
rests_on_run(v1, t1).
EOF2
}
# actor_of KB TYPE PATTERN ROLE SESSION: the attestation of TYPE whose predicate matches PATTERN has actor(A, ROLE, SESSION)
actor_of() { has_goal "$1/kb.pl" "kb(attest(A, $2, _, $3, _, _)), kb(actor(A, $4, $5))" "${6:-}"; }

t_VR1() { vr_kb "$T/k"; K=$T/k
          ORBIT_KB_ROLE=build ORBIT_KB_WRITER=w1 okb --dir "$K" run k1 -- true; rc_is 0 "run"
          actor_of "$K" test_result 'result(k1, _, pass)' build w1 "run records actor(A, ROLE, WRITER)"
          ORBIT_KB_LEASE=0 ORBIT_KB_ROLE=build CLAUDE_CODE_SESSION_ID=s9 okb --dir "$K" run k1 --as review -- true; rc_is 0 "run --as"
          actor_of "$K" test_result 'result(k1, 2, _)' review s9 "--as before -- wins over ORBIT_KB_ROLE; the session is CLAUDE_CODE_SESSION_ID"
          ORBIT_KB_LEASE=0 ORBIT_KB_ROLE=build ORBIT_KB_WRITER=w1 okb --dir "$K" run k2 -- echo --as x; rc_is 0 "run with --as after --"
          actor_of "$K" test_result 'result(k2, _, _)' build w1 "--as after -- belongs to the command"
          grep -q -- '--as x' "$K"/runs/*-k2.log || note "the command got --as x"
          ORBIT_KB_LEASE=0 ORBIT_KB_WRITER=w2 CLAUDE_CODE_SESSION_ID=s9 okb --dir "$K" attest disclosure c1 "unverified('not measured')" --as subagent_a; rc_is 0 "attest --as"
          actor_of "$K" disclosure "unverified(_)" subagent_a w2 "ORBIT_KB_WRITER comes before CLAUDE_CODE_SESSION_ID"
          ORBIT_KB_LEASE=0 CLAUDE_SESSION_ID=s7 HUB_SESSION=h1 ORBIT_KB_ROLE=discovery okb --dir "$K" attest divergence c1 'claim(c1)'; rc_is 0
          actor_of "$K" divergence "claim(c1)" discovery s7 "CLAUDE_SESSION_ID comes before HUB_SESSION"
          ORBIT_KB_LEASE=0 HUB_SESSION=h1 okb --dir "$K" attest disclosure c2 "other('x')" --by human; rc_is 0
          actor_of "$K" disclosure "other(_)" unknown h1 "HUB_SESSION last; no role is unknown"
          has_fact "$K/kb.pl" "attest(_, disclosure, c2, other(_), human, _)" "--by human keeps its meaning"
          ORBIT_KB_LEASE=0 okb --dir "$K" add "attest(m1, disclosure, c2, other('y'), agent, '2026-11-01T10:00:00Z')"; rc_is 0 "add of an attest fact"
          has_fact "$K/kb.pl" "actor(m1, unknown, unknown)" "add of an attest fact records its actor; no role and no session are unknown"
          fact_count "$K/kb.pl" "attest(_, _, _, _, _, _)" 7 "seven attestations"
          fact_count "$K/kb.pl" "actor(_, _, _)" 7 "one actor per attestation"
          rejects "add actor by hand" 'actor' add "actor(m1, review, s2)"
          okb --dir "$K" lint; rc_is 0 "lint after the actor facts"; out_hasnt '^E[0-9]'
          okb help core; rc_is 0
          out_has 'actor\(A, Role, Session\)' "help core names actor(A, Role, Session)"
          out_has 'self-reported' "help core says the role is self-reported"
          out_has 'mistakes, not cheating' "help core names it as a limit"; }

t_VR2() { vr_kb "$T/k"; K=$T/k; local r=$T/repo
          mkdir -p "$r"; git -C "$r" init -q; printf 'one\n' > "$r/a.txt"
          git -C "$r" add a.txt; git -C "$r" -c user.name=t -c user.email=t@example.invalid commit -q -m one
          printf 'two\n' >> "$r/a.txt"; git -C "$r" -c user.name=t -c user.email=t@example.invalid commit -q -am two
          printf 'Ticket T1: verify two things\n' > "$r/ticket.md"
          local dt dd dk
          dt=$(sha "$r/ticket.md"); dd=$(git -C "$r" diff HEAD~1..HEAD | sha256sum | cut -d' ' -f1)
          okb --dir "$K" pin; dk=$(printf '%s\n' "$out" | grep -oE 'sha256:[0-9a-f]{64}' | head -n1)
          ORBIT_KB_WRITER=r1 okb_in "$r" --dir "$K" review start --as review --ticket ticket.md --diff HEAD~1..HEAD; rc_is 0 "review start"
          has_fact "$K/kb.pl" "review_saw(review, ticket, 'sha256:$dt')" "the ticket digest"
          has_fact "$K/kb.pl" "review_saw(review, kb, '$dk')" "the spec-kb stamp before the command"
          has_fact "$K/kb.pl" "review_saw(review, diff, 'sha256:$dd')" "the sha256 of git diff A..B"
          fact_count "$K/kb.pl" "review_saw(_, _, _)" 3 "three facts"
          cp "$K/kb.pl" "$T/before"
          ORBIT_KB_WRITER=r1 okb_in "$r" --dir "$K" review start --ticket ticket.md --diff HEAD~1..HEAD; rc_is 2 "no role"
          ORBIT_KB_WRITER=r1 okb_in "$r" --dir "$K" review start --as review --diff HEAD~1..HEAD; rc_is 2 "no --ticket"
          ORBIT_KB_WRITER=r1 okb_in "$r" --dir "$K" review start --as review --ticket ticket.md; rc_is 2 "no --diff"
          ORBIT_KB_WRITER=r1 okb_in "$r" --dir "$K" review start --as review --ticket nope.md --diff HEAD~1..HEAD; rc_is 2 "a missing ticket file"
          ORBIT_KB_WRITER=r1 okb_in "$r" --dir "$K" review start --as review --ticket ticket.md --diff nosuch..HEAD; rc_is 2 "git diff fails"
          same_file "$K/kb.pl" "$T/before" "a refused review start writes nothing"
          ORBIT_KB_ROLE=fresh_eyes ORBIT_KB_WRITER=r1 okb_in "$r" --dir "$K" review start --ticket ticket.md --diff HEAD~1..HEAD; rc_is 0 "the role from ORBIT_KB_ROLE"
          has_fact "$K/kb.pl" "review_saw(fresh_eyes, diff, 'sha256:$dd')" "ORBIT_KB_ROLE names the reviewer"
          okb --dir "$K" lint; rc_is 0 "lint after review start"; out_hasnt '^E[0-9]'; }

t_VR3() { vr_kb "$T/k"; K=$T/k; add_result "$K" k1 1 fail; add_result "$K" k1 2 pass
          okb --dir "$K" attest disproof c1 "verdict(c1, upheld('reran k1; tried an empty input'))" --rests-on t2 --id v1; rc_is 0 "upheld(Text)"
          has_goal "$K/kb.pl" "kb(attest(V, disproof, _, verdict(c1, upheld(_)), _, _)), kb(rests_on_run(V, t2))" "rests_on_run(V, t2)"
          okb --dir "$K" attest disproof c2 "verdict(c2, inconclusive('ran out of time'))" --rests-on t1,t2; rc_is 0 "inconclusive(Text) and two runs"
          fact_count "$K/kb.pl" "rests_on_run(_, _)" 3 "one rests_on_run per run"
          okb --dir "$K" attest disproof c2 "verdict(c2, abstained('no way to run it'))"; rc_is 0 "abstained(Text)"
          okb --dir "$K" attest disproof c2 "verdict(c2, refuted('the empty input'))"; rc_is 0 "refuted(Text)"
          okb --dir "$K" attest disproof c2 "verdict(c2, inconclusive)"; rc_is 0 "bare inconclusive stays valid"
          okb --dir "$K" attest disproof c2 "verdict(c2, abstained)"; rc_is 0 "bare abstained stays valid"
          rejects "bare upheld" 'E3|upheld' attest disproof c1 "verdict(c1, upheld)"
          rejects "bare refuted" 'E3|refuted' attest disproof c1 "verdict(c1, refuted)"
          rejects "a run that is no test_result" '' attest disproof c1 "verdict(c1, upheld('x'))" --rests-on v1
          rejects "a run that does not exist" '' attest disproof c1 "verdict(c1, upheld('x'))" --rests-on nosuch
          rejects "--rests-on on another type" '' attest divergence c1 'claim(c1)' --rests-on t2
          okb --dir "$K" lint; rc_is 0 "every verdict form lints clean"; out_hasnt '^E[0-9]'
          is_set 'refuted(C)' 'C = c2' "upheld does not refute"
          is_true 'fulfilled(c1)' "an upheld verdict leaves fulfilled as it was"
          okb help core; rc_is 0
          out_has 'upheld\(Text\)' "help core lists upheld(Text)"
          out_has 'rests_on_run' "help core names rests_on_run"
          out_has '--rests-on' "help core names --rests-on"; }

t_VR4() { vr_ind "$T/a"; K=$T/a
          is_true 'independently_verified(c1)' "(a) another role and session, after the change, a fresh rerun"
          local v
          for v in "s/actor(v1, review, s2)/actor(v1, review, s1)/ @@ the same session as the change" \
                   "s/actor(v1, review, s2)/actor(v1, build, s2)/ @@ the same role as the change" \
                   "s/actor(t1, review, s2)/actor(t1, review, s3)/ @@ a run by another actor than the verdict" \
                   "s/10:04:00Z'/09:59:00Z'/ @@ a run before the change" \
                   "s/10:05:00Z'/09:00:00Z'/ @@ a verdict before the change" \
                   "/^rests_on_run/d @@ a verdict that rests on no run" \
                   "s/upheld('reran k1; tried an empty input')/inconclusive('ran out of time')/ @@ a verdict that is not upheld (choice)" \
                   "/^actor(x1/d @@ a last change with no actor" \
                   "s/result(k1, 1, pass)/result(k9, 1, pass)/;s/^check(k1, c1)./check(k1, c1).\ncheck(k9, c9).\nclaim(c9, preserve, 'Other')./ @@ a run of a check of another claim (choice)"; do
              cp -r "$T/a" "$T/b"; sed -i "${v%% @@ *}" "$T/b/kb.pl"; K=$T/b
              is_false 'independently_verified(c1)' "${v#* @@ }"; rm -rf "$T/b"
          done
          cp -r "$T/a" "$T/c"; K=$T/c
          printf "change(x2, 'Edit again').\nserves(x2, c1).\nchange_at(x2, '2026-11-01T10:10:00Z').\nactor(x2, build, s1).\n" >> "$K/kb.pl"
          is_false 'independently_verified(c1)' "a later change makes the old verdict and run stale"
          printf "attest(t2, test_result, k1, result(k1, 2, pass), script, '2026-11-01T10:11:00Z').\nactor(t2, review, s2).\nattest(v2, disproof, c1, verdict(c1, upheld('again')), agent, '2026-11-01T10:12:00Z').\nactor(v2, review, s2).\nrests_on_run(v2, t2).\n" >> "$K/kb.pl"
          is_true 'independently_verified(c1)' "a new verdict on a new rerun after the last change"
          kb_new "$T/d" <<'EOF2'
uses([build]).
request(r1, 'Keep it').
claim(c1, preserve, 'It stays').
cites(c1, 'Keep it').
check(k1, c1).
attest(t1, test_result, k1, result(k1, 1, pass), script, '2026-11-01T10:04:00Z').
actor(t1, review, s2).
attest(v1, disproof, c1, verdict(c1, upheld('reran k1')), agent, '2026-11-01T10:05:00Z').
actor(v1, review, s2).
rests_on_run(v1, t1).
EOF2
          K=$T/d; is_false 'independently_verified(c1)' "no change in the KB at all: no verdict counts (T38 c3 retires the choice of T25: fail closed)"
          vr_kb "$T/e"; K=$T/e
          ORBIT_KB_ROLE=build ORBIT_KB_WRITER=w1 okb --dir "$K" add "change(x1, 'Edit one')" "serves(x1, c1)"; rc_is 0 "add a change"
          has_fact "$K/kb.pl" "actor(x1, build, w1)" "add of a change records its actor"
          has_goal "$K/kb.pl" "kb(change_at(x1, T)), atom(T), atom_length(T, 20)" "add of a change records change_at(X, TIME)"
          rejects "add change_at by hand" 'change_at' add "change_at(x1, '2026-11-01T10:00:00Z')"
          okb --dir "$K" lint; rc_is 0; out_hasnt '^E[0-9]'
          printf 'independently_verified(c2).\n' > "$K/rules.pl"; okb --dir "$K" lint
          out_has '^E16' "rules.pl cannot add to independently_verified (E16)"; rm -f "$K/rules.pl"
          okb help build; rc_is 0; out_has 'independently_verified\(C\)' "help build names independently_verified(C)"; }

t_VR5() { vr_ind "$T/k"; K=$T/k
          printf "claim(c2, preserve, 'Two stays true').\ncites(c2, 'Verify one thing').\ncheck(k2, c2).\n" >> "$K/kb.pl"
          printf "attest(t3, test_result, k2, result(k2, 3, pass), script, '2026-11-01T10:06:00Z').\nactor(t3, build, s1).\n" >> "$K/kb.pl"
          printf "attest(t0, test_result, k1, result(k1, 0, fail), script, '2026-11-01T09:00:00Z').\nactor(t0, build, s1).\n" >> "$K/kb.pl"
          printf "change(x2, 'Edit two').\nserves(x2, c2).\nchange_at(x2, '2026-11-01T10:00:00Z').\nactor(x2, build, s1).\n" >> "$K/kb.pl"
          mkdir -p "$K/runs"
          printf '%% orbit-kb run 0 check=k1 result=fail exit=1 time=2026-11-01T09:00:00Z cmd=false\n' > "$K/runs/0-k1.log"
          printf '%% orbit-kb run 1 check=k1 result=pass exit=0 time=2026-11-01T10:04:00Z cmd=true\n' > "$K/runs/1-k1.log"
          printf '%% orbit-kb run 3 check=k2 result=pass exit=0 time=2026-11-01T10:06:00Z cmd=true\n' > "$K/runs/3-k2.log"
          is_true 'independently_verified(c1)'; is_false 'independently_verified(c2)'
          okb --dir "$K" report; rc_is 0 "report"
          local sec; sec=$(printf '%s\n' "$out" | awk '/^# Review:/{f=1;next} /^# /{f=0} f')
          [ -n "$sec" ] || note "report has no Review section"
          printf '%s\n' "$out" | grep -E '^# ' | paste -sd' ' | grep -qF '# Claims: # Review: # Formal: # Guesses:' \
              || note "the Review section comes after Claims, before Formal and Guesses (D31 B3)"
          printf '%s\n' "$sec" | grep -Eq '^  - c1: reviewer review \(session s2\), verdict upheld: reran k1; tried an empty input\.$' || note "c1: reviewer, verdict, text: [$(snip "$sec")]"
          printf '%s\n' "$sec" | grep -Eq '^    - Reruns: run 1 k1 pass\.$' || note "c1: its reruns: [$(snip "$sec")]"
          printf '%s\n' "$sec" | grep -Eq '^  - c2: no verdict\.$' || note "c2 has no verdict: [$(snip "$sec")]"
          printf '%s\n' "$sec" | grep -Eq '^  - Not independently verified: c2\.$' || note "the report names c2 as not independently verified: [$(snip "$sec")]"
          okb --dir "$K" lint; rc_is 0 "WR1 is a warning"
          out_has '^WR1 c2' "lint WR1 for c2"; out_hasnt '^WR1 c1' "no WR1 for c1"
          is_true done "WR1 does not block done"
          q 'blocking(X)' -n 0; rc_is 1 "nothing blocks: WR1 is no blocking item"
          valid_copy; okb --dir "$K" report; rc_is 0; out_hasnt '^# Review:' "a KB with no actor and no review_saw fact: no Review section"
          okb --dir "$K" lint; out_hasnt '^WR1' "a KB with no actor and no review_saw fact: no WR1"
          okb help codes; rc_is 0; out_has 'WR1' "help codes lists WR1"; }

t_VR6() { okb help build; rc_is 0
          local f; f=$(printf '%s\n' "$out" | awk '/^FULFILL/{f=1;print;next} f && /^[A-Z]/{exit} f')
          [ -n "$f" ] || { note "help build has no FULFILL section"; return; }
          local p
          for p in 'fresh' 'only the ticket, the KB,? and the diff' 'review start --as [A-Za-z_]+ --ticket' '--diff' \
                   'orbit-kb run --as' 'attest disproof' '--rests-on' 'upheld' 'every (current )?claim' 'orbit-kb report' 'WR1'; do
              printf '%s\n' "$f" | grep -Eq -- "$p" || note "FULFILL lacks /$p/"
          done
          local pr=$here/../../prompt
          grep -Eq 'help build.*FULFILL|FULFILL.*help build' "$pr/panes/review.md" || note "review.md (Verify) points to the FULFILL brief of help build"; }

# ---------------------------------------------------------------- T38: fixes of D28 found when T25 was verified
# VR7 (T38 c1): a digest is the sha256 of the bytes of the file, also for non-ASCII bytes:
# subject, the pin stamp, and review start (ticket and diff) agree with sha256sum.
t_VR7() { vr_kb "$T/k"; K=$T/k; local r=$T/repo d
          printf 'a \342\200\223 b\n' > "$T/dash.txt"                      # an en dash (UTF-8 e2 80 93)
          printf '\211PNG\r\n\032\n\000\377\376binary\n' > "$T/shot.png"    # bytes that are no UTF-8
          for f in dash.txt shot.png; do
              okb --dir "$K" subject "s_${f%%.*}" "$T/$f"; rc_is 0 "subject $f"
              d=$(sha "$T/$f")
              out_has "sha256:$d" "subject $f prints the sha256sum of its bytes"
              has_fact "$K/kb.pl" "subject(s_${f%%.*}, _, 'sha256:$d')" "subject $f records the sha256sum of its bytes"
          done
          okb --dir "$K" lint; out_hasnt '^W1 ' "W1: no subject file changed since it was recorded"
          printf "note(c1, 'Kept \342\200\224 with a dash').\n" >> "$K/kb.pl"
          okb --dir "$K" pin; out_has "spec-kb@sha256:$(sha "$K/kb.pl")" "the pin stamp of a kb.pl with non-ASCII text is its sha256sum"
          mkdir -p "$r"; git -C "$r" init -q; printf 'one\n' > "$r/a.txt"
          git -C "$r" add a.txt; git -C "$r" -c user.name=t -c user.email=t@example.invalid commit -q -m one
          printf 'two \342\200\223 en dash\n' >> "$r/a.txt"; git -C "$r" -c user.name=t -c user.email=t@example.invalid commit -q -am two
          printf 'Ticket T1 \342\200\223 verify two things\n' > "$r/ticket.md"
          local dt dd; dt=$(sha "$r/ticket.md"); dd=$(git -C "$r" diff HEAD~1..HEAD | sha256sum | cut -d' ' -f1)
          ORBIT_KB_WRITER=r1 okb_in "$r" --dir "$K" review start --as review --ticket ticket.md --diff HEAD~1..HEAD; rc_is 0 "review start"
          has_fact "$K/kb.pl" "review_saw(review, ticket, 'sha256:$dt')" "the ticket digest is the sha256sum of a ticket with an en dash"
          has_fact "$K/kb.pl" "review_saw(review, diff, 'sha256:$dd')" "the diff digest is the sha256 of git diff with an en dash"; }

# VR8 (T38 c2): independently_verified reads the latest verdict on the claim (the last in kb.pl).
t_VR8() { vr_ind "$T/a"; K=$T/a
          is_true 'independently_verified(c1)' "setup: v1 verifies c1"
          local v
          for v in "refuted('the empty input breaks it')" "inconclusive('ran out of time')" "inconclusive" "abstained('no way to run it')"; do
              rm -rf "$T/b"; cp -r "$T/a" "$T/b"; K=$T/b
              printf "attest(v2, disproof, c1, verdict(c1, %s), agent, '2026-11-01T10:06:00Z').\nactor(v2, review, s2).\nrests_on_run(v2, t1).\n" "$v" >> "$K/kb.pl"
              is_false 'independently_verified(c1)' "an upheld verdict followed by $v"
          done
          rm -rf "$T/b"; cp -r "$T/a" "$T/b"; K=$T/b
          printf "attest(v2, disproof, c1, verdict(c1, refuted('the empty input breaks it')), agent, '2026-11-01T10:05:00Z').\nactor(v2, review, s2).\n" >> "$K/kb.pl"
          is_false 'independently_verified(c1)' "a refuted verdict after the upheld one in kb.pl, in the same second"
          okb --dir "$K" report; rc_is 0 "report"
          local sec; sec=$(printf '%s\n' "$out" | awk '/^# Review:/{f=1;next} /^# /{f=0} f')
          printf '%s\n' "$sec" | grep -Eq 'c1: reviewer review \(session s2\), verdict refuted' || note "the report shows the latest verdict, refuted: [$(snip "$sec")]"
          printf '%s\n' "$sec" | grep -Fq 'Every current claim is independently verified' && note "the report says every claim is verified next to a refuted verdict"
          printf '%s\n' "$sec" | grep -Eq '^  - Not independently verified: c1\.$' || note "the report names c1 as not independently verified: [$(snip "$sec")]"
          # a later upheld verdict that counts verifies the claim again
          printf "attest(t2, test_result, k1, result(k1, 2, pass), script, '2026-11-01T10:07:00Z').\nactor(t2, review, s2).\nattest(v3, disproof, c1, verdict(c1, upheld('fixed; reran k1')), agent, '2026-11-01T10:08:00Z').\nactor(v3, review, s2).\nrests_on_run(v3, t2).\n" >> "$K/kb.pl"
          is_true 'independently_verified(c1)' "a new upheld verdict after the refuted one"
          printf 'later_verdict(v3).\n' > "$K/rules.pl"; okb --dir "$K" lint
          out_has '^E16' "rules.pl cannot add to the computed later verdicts (E16)"; rm -f "$K/rules.pl"; }

# VR9 (T38 c3): old data fails closed. A serving change with no change_at, or a claim that no change
# serves in a KB with no change, never lets a verdict count; a claim with no serving change is
# compared with every change of the KB (choice).
t_VR9() { vr_ind "$T/a"
          rm -rf "$T/b"; cp -r "$T/a" "$T/b"; K=$T/b
          sed -i '/^change_at(x1/d; s/actor(v1, review, s2)/actor(v1, build, s1)/; s/actor(t1, review, s2)/actor(t1, build, s1)/' "$K/kb.pl"
          is_false 'independently_verified(c1)' "a change with no change_at, and the builder's own verdict"
          rm -rf "$T/b"; cp -r "$T/a" "$T/b"; K=$T/b
          sed -i '/^change_at(x1/d' "$K/kb.pl"
          is_false 'independently_verified(c1)' "a change with no change_at fails closed, also for another actor (choice)"
          rm -rf "$T/b"; cp -r "$T/a" "$T/b"; K=$T/b
          printf "change(x0, 'Edit zero').\nserves(x0, c1).\nactor(x0, build, s1).\n" >> "$K/kb.pl"
          is_false 'independently_verified(c1)' "one of two serving changes has no change_at"
          kb_new "$T/d" <<'EOF2'
uses([build]).
request(r1, 'Keep it').
claim(c1, preserve, 'It stays').
cites(c1, 'Keep it').
check(k1, c1).
attest(t1, test_result, k1, result(k1, 1, pass), script, '2026-11-01T10:04:00Z').
actor(t1, build, s1).
attest(v1, disproof, c1, verdict(c1, upheld('reran k1')), agent, '2026-11-01T10:05:00Z').
actor(v1, build, s1).
rests_on_run(v1, t1).
EOF2
          K=$T/d; is_false 'independently_verified(c1)' "no change at all: the builder's own verdict does not count"
          sed -i 's/actor(t1, build, s1)/actor(t1, review, s2)/; s/actor(v1, build, s1)/actor(v1, review, s2)/' "$K/kb.pl"
          is_false 'independently_verified(c1)' "no change at all: nothing tells who built, so no verdict counts"
          # a claim with no serving change, in a KB whose change x1 (build, s1) at 10:00 serves another claim
          cp -r "$T/a" "$T/e"; K=$T/e
          printf "claim(c2, preserve, 'Two stays true').\ncites(c2, 'Verify one thing').\ncheck(k2, c2).\n" >> "$K/kb.pl"
          printf "attest(t2, test_result, k2, result(k2, 2, pass), script, '2026-11-01T10:06:00Z').\nactor(t2, review, s2).\n" >> "$K/kb.pl"
          printf "attest(v2, disproof, c2, verdict(c2, upheld('reran k2')), agent, '2026-11-01T10:07:00Z').\nactor(v2, review, s2).\nrests_on_run(v2, t2).\n" >> "$K/kb.pl"
          is_true 'independently_verified(c2)' "no serving change: another role and session than every change of the KB, after it"
          rm -rf "$T/f"; cp -r "$T/e" "$T/f"; K=$T/f
          sed -i 's/actor(v2, review, s2)/actor(v2, build, s1)/; s/actor(t2, review, s2)/actor(t2, build, s1)/' "$K/kb.pl"
          is_false 'independently_verified(c2)' "no serving change: the builder's own verdict does not count"
          rm -rf "$T/f"; cp -r "$T/e" "$T/f"; K=$T/f
          sed -i "s/10:06:00Z'/09:58:00Z'/; s/10:07:00Z'/09:59:00Z'/" "$K/kb.pl"
          is_false 'independently_verified(c2)' "no serving change: a verdict before the last change of the KB"
          rm -rf "$T/f"; cp -r "$T/e" "$T/f"; K=$T/f
          printf "change(x9, 'Edit nine').\n" >> "$K/kb.pl"
          is_false 'independently_verified(c2)' "no serving change: a change of the KB with no change_at fails closed"
          grep -q 'T38' "$here/../CONTRACT.md" && awk '/V4 \(claim c4/' "$here/../CONTRACT.md" | grep -Eqi 'fail(s)? closed' \
              || note "CONTRACT V4 states the fail-closed choice"; }

# VR10 (T38 c4): a builder's subagent follows the FULFILL brief of help build literally. It shares
# CLAUDE_CODE_SESSION_ID with the builder; the brief tells it to name itself, so its verdict counts.
# T40 c1 amends it: the brief puts the writer in front of each write command (VR12 runs each step
# in its own shell); here the subagent runs every step in one shell.
t_VR10() { local r=$T/repo f wl
           okb help build; rc_is 0
           f=$(printf '%s\n' "$out" | awk '/^FULFILL/{f=1;print;next} f && /^[A-Z]/{exit} f')
           # T40 c1 (amends T38 c4): the writer and the role stand in front of each write command;
           # the subagent here runs all steps in one shell, so it exports that prefix once.
           wl=$(printf '%s\n' "$f" | grep -E '^ *ORBIT_KB_WRITER=[^ ]+ +ORBIT_KB_ROLE=[^ ]+ +orbit-kb ' | head -n1 \
                | sed -E 's/^ *(ORBIT_KB_WRITER=[^ ]+ +ORBIT_KB_ROLE=[^ ]+) +orbit-kb .*/export \1/')
           [ -n "$wl" ] || note "FULFILL has no write line that sets ORBIT_KB_WRITER (ORBIT_KB_WRITER=... ORBIT_KB_ROLE=... orbit-kb ...)"
           printf '%s\n' "$wl" | grep -q 'ORBIT_KB_ROLE=' || note "the write line of FULFILL does not set ORBIT_KB_ROLE"
           printf '%s\n' "$f" | grep -Fq 'CLAUDE_CODE_SESSION_ID' || note "FULFILL does not say why: subagents share CLAUDE_CODE_SESSION_ID"
           printf '%s\n' "$f" | grep -Eq 'orbit-kb release' || note "FULFILL does not tell the builder to release the lock first"
           mkdir -p "$r"; git -C "$r" init -q; printf 'one\n' > "$r/a.txt"
           git -C "$r" add a.txt; git -C "$r" -c user.name=t -c user.email=t@example.invalid commit -q -m one
           printf 'Ticket T1: one becomes true\n' > "$r/TICKET.md"
           # the builder (one pane: CLAUDE_CODE_SESSION_ID=pane1, the build role)
           local B=(env CLAUDE_CODE_SESSION_ID=pane1 ORBIT_KB_ROLE=build)
           okb init "$T/k" --request 'One becomes true' --uses build; K=$T/k
           "${B[@]}" "$OKB" --dir "$K" add "claim(c1, introduce, 'One becomes true')" "cites(c1, 'One becomes true')" "check(k1, c1)" >/dev/null 2>&1
           "${B[@]}" "$OKB" --dir "$K" run k1 -- false >/dev/null 2>&1
           sleep 1
           printf 'two\n' >> "$r/a.txt"; git -C "$r" -c user.name=t -c user.email=t@example.invalid commit -q -am two
           "${B[@]}" "$OKB" --dir "$K" add "change(x1, 'Edit one')" "serves(x1, c1)" >/dev/null 2>&1
           "${B[@]}" "$OKB" --dir "$K" run k1 -- true >/dev/null 2>&1
           is_true 'fulfilled(c1)' "setup: the builder fulfilled c1"
           printf '%s\n' "$f" | grep -Eq 'orbit-kb release' && "${B[@]}" "$OKB" --dir "$K" release >/dev/null 2>&1
           sleep 1
           # the subagent: the same CLAUDE_CODE_SESSION_ID; it runs the brief as written
           local sub; sub=$(printf '%s\n' "$wl" | sed -E 's/<[^>]*>/t1/g; s/^ *//')
           ( export CLAUDE_CODE_SESSION_ID=pane1; [ -n "$sub" ] && eval "$sub"
             cd "$r" || exit 9
             XDG_CACHE_HOME="$T/.cache" "$OKB" --dir "$K" review start --as review --ticket TICKET.md --diff HEAD~1..HEAD || exit 3
             XDG_CACHE_HOME="$T/.cache" "$OKB" --dir "$K" run --as review k1 -- true || exit 4
             a=$(grep -oE '^attest\(a[0-9]+, test_result, k1, result\(k1, [0-9]+, pass\)' "$K/kb.pl" | tail -n1 | sed -E 's/^attest\((a[0-9]+).*/\1/')
             XDG_CACHE_HOME="$T/.cache" "$OKB" --dir "$K" attest disproof c1 "verdict(c1, upheld('reran k1; tried an empty input'))" --as review --rests-on "$a" || exit 5
           ) >"$T/.sub.out" 2>"$T/.sub.err"
           local src=$?; [ "$src" = 0 ] || note "the subagent's commands failed (step $src): $(snip "$(cat "$T/.sub.err")")"
           is_true 'independently_verified(c1)' "the subagent followed the brief literally"
           okb --dir "$K" lint; out_hasnt '^WR1 c1' "no WR1 for c1"; }

# VR12 (T40 c1): the FULFILL brief works when each Bash call is a new shell (Claude Code). Every
# write command of the subagent carries the writer and the role inline, and the subagent ends with
# orbit-kb release. The test runs each such line of the brief in its own shell, with only the pane's
# CLAUDE_CODE_SESSION_ID: the verdict is independent, and the builder's next add succeeds.
t_VR12() { local r=$T/repo f ls n line cmd a
           okb help build; rc_is 0
           f=$(printf '%s\n' "$out" | awk '/^FULFILL/{f=1;print;next} f && /^[A-Z]/{exit} f')
           ls=$(printf '%s\n' "$f" | grep -E '^ *ORBIT_KB_WRITER=[^ ]+ +ORBIT_KB_ROLE=[^ ]+ +orbit-kb ')
           for n in 'review start' 'run --as' 'attest disproof' 'release'; do
               printf '%s\n' "$ls" | grep -Eq "orbit-kb $n" || note "FULFILL has no line 'ORBIT_KB_WRITER=... ORBIT_KB_ROLE=... orbit-kb $n'"
           done
           printf '%s\n' "$f" | grep -Eqi 'new shell|each (Bash )?call' || note "FULFILL does not say why: each Bash call is a new shell"
           printf '%s\n' "$f" | grep -E 'orbit-kb (review start|run --as|attest disproof)' | grep -Ev '^ *ORBIT_KB_WRITER=' \
               | grep -q . && note "FULFILL has a subagent write line without the writer inline"
           mkdir -p "$r"; git -C "$r" init -q; printf 'one\n' > "$r/a.txt"
           git -C "$r" add a.txt; git -C "$r" -c user.name=t -c user.email=t@example.invalid commit -q -m one
           printf 'Ticket T1: one becomes true\n' > "$r/TICKET.md"
           local B=(env CLAUDE_CODE_SESSION_ID=pane1 ORBIT_KB_ROLE=build)
           okb init "$T/k" --request 'One becomes true' --uses build; K=$T/k
           "${B[@]}" "$OKB" --dir "$K" add "claim(c1, introduce, 'One becomes true')" "cites(c1, 'One becomes true')" "check(k1, c1)" >/dev/null 2>&1
           "${B[@]}" "$OKB" --dir "$K" run k1 -- false >/dev/null 2>&1
           sleep 1
           printf 'two\n' >> "$r/a.txt"; git -C "$r" -c user.name=t -c user.email=t@example.invalid commit -q -am two
           "${B[@]}" "$OKB" --dir "$K" add "change(x1, 'Edit one')" "serves(x1, c1)" >/dev/null 2>&1
           "${B[@]}" "$OKB" --dir "$K" run k1 -- true >/dev/null 2>&1
           is_true 'fulfilled(c1)' "setup: the builder fulfilled c1"
           "${B[@]}" "$OKB" --dir "$K" release >/dev/null 2>&1
           sleep 1
           # each step of the brief in its own shell: nothing carries over but the pane's session
           for n in 'review start' 'run --as' 'attest disproof' 'release'; do
               line=$(printf '%s\n' "$ls" | grep -E "orbit-kb $n" | head -n1)
               [ -n "$line" ] || continue
               a=$(grep -oE '^attest\(a[0-9]+, test_result, k1, result\(k1, [0-9]+, pass\)' "$K/kb.pl" | tail -n1 | sed -E 's/^attest\((a[0-9]+).*/\1/')
               cmd=$(printf '%s\n' "$line" | sed -E "s/^ *//; s/<[^>]*>/t1/g; s#orbit-kb #'$OKB' --dir '$K' #; s/BASE\.\.HEAD/HEAD~1..HEAD/; s/-- CMD\$/-- true/; s/--rests-on a[0-9]+/--rests-on $a/")
               ( cd "$r" && env -i PATH="$PATH" HOME="$HOME" XDG_CACHE_HOME="$T/.cache" ORBIT_KB_LIB="$ORBIT_KB_LIB" \
                     CLAUDE_CODE_SESSION_ID=pane1 bash -c "$cmd" ) >"$T/.step.out" 2>"$T/.step.err" \
                   || note "the step '$n' failed in its own shell: $(snip "$cmd") :: $(snip "$(cat "$T/.step.err")")"
           done
           is_true 'independently_verified(c1)' "each step in its own shell"
           okb --dir "$K" lint; out_hasnt '^WR1 c1' "no WR1 for c1"
           "${B[@]}" "$OKB" --dir "$K" add "note(c1, 'the builder writes after the review')" >"$T/.b.out" 2>&1
           [ $? = 0 ] || note "the builder's next add fails after the review: $(snip "$(cat "$T/.b.out")")"; }

# VR11 (T38 c5): WR1 waits until a review is due: no current claim is under.
t_VR11() { local W=(env ORBIT_KB_ROLE=build ORBIT_KB_WRITER=w1)
           okb init "$T/k" --request 'Make one thing true' --uses build; K=$T/k
           "${W[@]}" "$OKB" --dir "$K" add "claim(c1, introduce, 'One thing is true')" "cites(c1, 'Make one thing true')" "check(k1, c1)" >/dev/null 2>&1
           "${W[@]}" "$OKB" --dir "$K" run k1 -- false >/dev/null 2>&1
           has_goal "$K/kb.pl" "kb(actor(_, build, w1))" "setup: the red run recorded an actor"
           okb --dir "$K" lint; rc_is 0; out_hasnt '^WR1' "no WR1 during the red run"
           okb --dir "$K" lint --strict; rc_is 0 "lint --strict passes a fresh build KB"
           "${W[@]}" "$OKB" --dir "$K" add "claim(c2, preserve, 'Two stays true')" "cites(c2, 'Make one thing true')" "check(k2, c2)" "change(x1, 'Edit one')" "serves(x1, c1)" >/dev/null 2>&1
           "${W[@]}" "$OKB" --dir "$K" run k2 -- true >/dev/null 2>&1
           okb --dir "$K" lint; out_hasnt '^WR1' "no WR1 while c1 is under, also for the fulfilled c2"
           "${W[@]}" "$OKB" --dir "$K" run k1 -- true >/dev/null 2>&1
           okb --dir "$K" lint; rc_is 0; out_has '^WR1 c1' "WR1 c1 once every claim is fulfilled"; out_has '^WR1 c2' "WR1 c2 too"
           okb help codes; printf '%s\n' "$out" | grep -E 'WR1' | grep -Eqi 'under|fulfilled|due' || note "help codes does not say when WR1 fires"; }

# BL11 (T18 c5): the usage line of help show lists blocking among the parts (D22 C7).
t_BL11() { okb help show; rc_is 0 "help show"
           out_has '^orbit-kb show \[[^]]*\bblocking\b[^]]*\]' "the usage line of help show lists blocking"; }
t_BL8b() { kb_new "$T/k" <<'EOF'
uses([build]).
request(r1, 'Every kind').
claim(c1, preserve, 'Text of c1 contested').
claim(c2, preserve, 'Text of c2 universal').
claim(c3, preserve, 'Text of c3 visual').
claim(c4, introduce, 'Text of c4 checks').
claim(c5, preserve, 'Text of c5 cycle').
claim(c6, preserve, 'Text of c6 cycle').
cites(c1, 'Every kind').
cites(c2, 'Every kind').
cites(c3, 'Every kind').
cites(c4, 'Every kind').
cites(c5, 'Every kind').
cites(c6, 'Every kind').
question(q1, c1, 'Text of q1').
attest(d1, divergence, c1, claim(c1), agent, '2026-10-15T10:00:01Z').
universal(c2).
attest(w1, waiver, c2, waive(c2, '2020-01-01T00:00:00Z', 'Text of w1'), human, '2026-10-15T10:00:02Z').
visual(c3).
check(k1, c4).
check(k2, c4).
due(c4, '2020-01-01T00:00:00Z').
change(x1, 'Text of x1').
supersedes(c5, c6).
supersedes(c6, c5).
EOF
          K=$T/k; add_result "$K" k1 1 fail
          okb --dir "$K" show blocking; rc_is 0
          out_has 'to_ask q1.*Text of q1'; out_has 'burn_open c2.*Text of c2'; out_has 'flare_open c3.*Text of c3'
          out_has 'under c4.*Text of c4'; out_has 'check_failing k1.*Text of c4'; out_has 'check_unrun k2.*Text of c4'
          out_has 'waiver_lapsed w1.*Text of w1'; out_has 'past_due c4.*Text of c4'; out_has 'over x1.*Text of x1'
          out_has 'supersede_cycle c5.*Text of c5'
          K=$T/k2; kb_init "$K" build; okb --dir "$K" show blocking; rc_is 0; out_has 'no_claim: no claim is current'; }

# PN: the pin stamp (c8).
t_PN1() { mkclaim; local d s; d=$(sha "$K/kb.pl"); cp "$K/kb.pl" "$T/.b"
          okb --dir "$K" pin; rc_is 0; out_has "^spec-kb@sha256:$d [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z\$" "stamp and time"
          same_file "$K/kb.pl" "$T/.b" "pin writes nothing"
          s=$(first_line)
          okb --dir "$K" pin --check "$s"; rc_is 0 "unchanged, stamp with its time"
          okb --dir "$K" pin --check "${s%% *}"; rc_is 0 "unchanged, stamp alone"
          oadd "risk(rk1, 'a')" >/dev/null
          okb --dir "$K" pin --check "${s%% *}"; rc_is 1 "the KB changed"; any_hasi 'changed'; }
t_PN2() { mkclaim; okb --dir "$K" pin --check 'spec-kb@sha256:abc'; rc_is 2 "a malformed stamp"
          okb --dir "$K" pin --check; rc_is 2 "--check needs a stamp"
          okb --dir "$K" pin extra; rc_is 2 "pin takes no argument"; }

# PH: help names the phases and maps each move to its phase (c9).
t_PH1() { okb help; rc_is 0
          out_has 'discovery: research, specify' "the discovery orbit"; out_has 'build: build, verify' "the build orbit"
          out_has 'research +SIGNAL, SURVEY, FLYBY, TRAJECTORY, DISPROVE' "research moves"
          out_has 'specify +SPECTRUM, DECOMPOSE, the vote' "specify moves"
          out_has '^ +build +BUILD$' "build moves"; out_has 'verify +FULFILL, DISPROVE, BURN' "verify moves"; }

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
run_test t_K10 K10 "an unknown command shows the query form, for a query name such as to_ask"
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
run_test t_A4 A4 "add rejects a label outside oneof"
run_test t_A5 A5 "add rejects a dangling ref"
run_test t_A6 A6 "add rejects a duplicate id"
run_test t_A7 A7 "add rejects a non-ground fact"
run_test t_A8 A8 "add rejects a fact for a rule predicate"
run_test t_A9 A9 "add rejects test_result and points to run"
run_test t_A10 A10 "add batch is all or nothing"
run_test t_A11 A11 "facts in one batch may refer to each other"
run_test t_A12 A12 "trailing dot is optional"
run_test t_A13 A13 "D20: add rejects a -fact (E17)"
run_test t_A14 A14 "add rejects a wrong arity"
run_test t_A15 A15 "add rejects a syntax error"
run_test t_A16 A16 "add rejects a bad time"
run_test t_A17 A17 "add rejects a writer that is not allowed"
run_test t_A20 A20 "add says to give each fact as its own argument"
run_test t_A21 A21 "add explains that a ref argument names an existing id, as in note(Id, Text)"
run_test t_A22 A22 "attest with only an inner label shows the whole predicate"
run_test t_D1 D1 "T26: the first clause of a rules.pl head declares it (no E2, W9 without a doc comment)"
run_test t_D2 D2 "T26: the %% doc: comment above the first clause is the doc of the head"
run_test t_D3 D3 "T26: a reserved name is not a rules.pl head (E2)"
run_test t_D4 D4 "T26: a new arity of a core name is a new head; the core arity is an extension"
run_test t_D6 D6 "T26: add refuses facts of a rule head and every decl(...) term"
run_test t_D8 D8 "T26: a rules.pl head within 2 edits of a declared name is E19"
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
run_test t_WD8 WD8 "lint WD8 says when a newer result of the same check replaces an old one"
run_test t_LG1 LG1 "D18: attest model_result refuses a TLC contradiction; agreement and unknown are accepted"
run_test t_LG2 LG2 "D18: attest model_result refuses a z3 contradiction; agreement and unknown are accepted"
run_test t_LG3 LG3 "D18: calibration, an unclassified log, and a missing log are accepted (NOTE on stderr)"
run_test t_B8 B8 "under and over (a change that serves nothing is over)"
run_test t_B9 B9 "done is true when everything is clear"
run_test t_B10 B10 "done is false with an open claim among several facts (H1)"
run_test t_B11 B11 "done is false with an over change"
run_test t_B12 B12 "done is false with a question to ask (a contested claim, D22)"
run_test t_B13 B13 "burn: contested twice, universal, burn_requested"
run_test t_B14 B14 "to_ask: a human answer that defeats a default asks no other question (D22: no depends)"
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
run_test t_HY1 HY1 "0.3.0 c_k_a_1: a build KB and a core KB take the hypothesis of the ticket; the kind change"
run_test t_HY2 HY2 "0.3.0 c_k_a_1: WD7 and readiness still hold in a KB that uses discovery"
run_test t_HY3 HY3 "0.3.0 c_k_a_2: premise, premise_checked, no_premises, premise_unchecked; lint W10"
run_test t_HY4 HY4 "0.3.0 c_k_a_2: a premise of a superseded hypothesis is not asked for"
run_test t_HY5 HY5 "0.3.0 c_k_a_4: Guesses lists unchecked premises and the defaults of the hypothesis"
run_test t_HY6 HY6 "0.3.0 c_k_a_3b: a restated hypothesis in build needs no system result, also after an approved GO"
run_test t_HY7 HY7 "0.3.0 q_k_a_3b: after a recorded return to discovery, a new hypothesis needs its system result"
run_test t_HY8 HY8 "0.3.0 c_k_a_3b: an approval with no GO does not end the orbit; add refuses discovery_end"
run_test t_HY9 HY9 "review of K-A (1): after a return to discovery, closing needs a new round of votes and readiness"
run_test t_HY10 HY10 "review of K-A (2): no closure while not ready; a closed orbit keeps the record of its round"
run_test t_HY11 HY11 "review of K-A (3): a stale approval of the ticket does not close the orbit"
run_test t_HY12 HY12 "review of K-A (6): a vote after closure: the agent's is refused, the human's is noted and does not count"
run_test t_HY13 HY13 "review of K-A (7): lint ED11 on a discovery_end that is no human approval of the ticket"
run_test t_HY14 HY14 "review of K-A (9): lint W11 on a premise and no_premises together; the report shows it"
run_test t_HY15 HY15 "review of K-A (10): CONTRACT reserves each fact kind of the discovery module"
run_test t_HY16 HY16 "review of K-A (11): System does not say that a check fails now when a later run passed"
run_test t_HY17 HY17 "review of K-A (12): attest back needs a closed orbit and a hypothesis"
run_test t_HY18 HY18 "review of K-A (12): a newline in a hypothesis or premise keeps the bullets of the report"
run_test t_KR1 KR1 "0.3.0 c_k_b_1: report and show all print the current hypothesis with its premises before the claims"
run_test t_KR2 KR2 "0.3.0 c_k_b_2: report and show claims print the example of each claim"
run_test t_KR3 KR3 "0.3.0 c_k_b_3: report has KB, Signals and Formal in the order of the delivery block; the page too"
run_test t_KR4 KR4 "0.3.0 c_k_b_4: Formal gives the theorem and its statement; Burn names it, the Lean definitions, and conformance"
run_test t_KR5 KR5 "0.3.0 c_k_b_5: property(Model, Claim, Text); Formal gives the model and the property"
run_test t_KR6 KR6 "0.3.0 c_k_b_6b: the report of a discovery KB drafts the discovery report from the facts"
run_test t_KR7 KR7 "0.3.0 c_k_b_6b: the report never shows the agent vote before the human votes"
run_test t_OP1 OP1 "0.3.0 c_k_c_1b: show open and report Open name each answer of blocking(X); a case for each kind of the rules"
run_test t_OP2 OP2 "0.3.0 c_k_c_1b: show open and report Open name what blocks readiness; a case for each kind of ready_blocker"
run_test t_OP3 OP3 "0.3.0 c_k_c_2: a stale pin that the KB rests on: show open, report Open, lint WP8; a new pin of the source closes it"
run_test t_OP4 OP4 "0.3.0 c_k_c_1b: Nothing is open only when nothing blocks; the report names an under claim"
run_test t_RD1 RD1 "0.3.0 c_k_d_2: discovery is ready only when each current claim has an example; lint WD10"
run_test t_RD2 RD2 "0.3.0 c_k_d_4: a failing check of a preserve claim blocks readiness; show open names it"
run_test t_RD3 RD3 "0.3.0 c_k_d_5: a model is calibrated by a failing case and a passing case; a derived model needs its own"
run_test t_RD4 RD4 "0.3.0 c_k_d_3b: a red run of a system check of an introduce or retire claim is the system result; preserve is not"
run_test t_RD5 RD5 "0.3.0 c_k_d_1b: an agent GO is refused while not ready; GO cannot win then; the approved GO stays"
run_test t_OP5 OP5 "0.3.0 c_k_c_1b: show open agrees with the examples of the Lean model kb/proofs/open_items"
run_test t_RD6 RD6 "0.3.0 c_k_d_1b: attest and gate agree with the examples of the Lean model kb/proofs/gate_ready"
run_test t_VN1 VN1 "0.3.0 c_v_a_2: orbit-kb version prints the version of VERSION; the first help line names it"
run_test t_VN2 VN2 "0.3.0 c_v_a_3: orbit-kb init writes the version of the tool into kb.pl"
run_test t_VN3 VN3 "0.3.0 c_v_a_2: the version reaches a linked CLI and a hub's copy; no VERSION file: exit 2"
run_test t_SG1 SG1 "0.3.0 c_k_g_1: signal(Id, Kind, NoticedBy, Text): the six kinds, three noticers; lint clean"
run_test t_SG2 SG2 "0.3.0 c_k_g_2: lean_back(Id, Text); report Signals prints it"
run_test t_SG3 SG3 "0.3.0 c_k_g_3: a decision of the human is a further request in their words; report KB prints each request"
run_test t_SG4 SG4 "0.3.0 c_k_g_4b: report Signals comes from the records: signal facts, divergence attestations, burns"
run_test t_PV1 PV1 "D10: prove records a real proof; an edit of an imported file reopens it"
run_test t_PV2 PV2 "D10: prove rejects sorry"
run_test t_PV3 PV3 "D10: prove rejects native_decide"
run_test t_PV4 PV4 "D10: prove rejects a local axiom"
run_test t_PV5 PV5 "D10: prove rejects a def and a missing name"
run_test t_PV6 PV6 "D10: prove rejects a theorem from another module"
run_test t_PV7 PV7 "D10: prove rejects a declaration that skipped the kernel (leanchecker)"
run_test t_PV8 PV8 "D10: prove rejects a file that does not build"
run_test t_PV9 PV9 "D10: prove usage errors exit 2"
run_test t_PV9b PV9b "T44 c3: PV9 does not depend on a lakefile above its temp dir"
run_test t_PV10 PV10 "D10 follow-up: the log has the statement and absent config files; a config change reopens (F7, MS, MC)"
run_test t_PV11 PV11 "D10 follow-up: prove rejects a --module that is not the module of FILE (MF)"
run_test t_PV12 PV12 "D10 follow-up: prove rejects a file that changes during the checks (MN)"
run_test t_H3a H3a "H3: passed(K) -n 0 lists k2, k3, k4 (default flags)"
run_test t_H3c H3c "H3: ground passed(k1) is false, passed(k4) is true"
run_test t_Q1 Q1 "query with no answer exits 1"
run_test t_Q2 Q2 "declared empty predicate exits 1 without an error"
run_test t_Q3 Q3 "undeclared predicate in a query exits 2"
run_test t_Q4 Q4 "query syntax error exits 2"
run_test t_Q5 Q5 "output: true, X = v, and the -n default of 1"
run_test t_Q6 Q6 "output with two variables"
run_test t_Q7 Q7 "built-ins in a query"
run_test t_Q8 Q8 "D20: query --json is a usage error"
run_test t_Q9 Q9 "D20: query --html is a usage error"
run_test t_Q10 Q10 "--why adds a justification"
run_test t_Q11 Q11 "wrong arity in a query exits 2"
run_test t_Q12 Q12 "-n 2"
run_test t_Q13 Q13 "bad -n value is a usage error"
run_test t_X1 X1 "engine: H2 program: no answer, exit 1"
run_test t_X2 X2 "D20: not under(_) means no under at all"
run_test t_X3 X3 "engine: -n 0 gives exactly the answers"
run_test t_X4 X4 "D20: a named variable only under not; no E12"
run_test t_X5 X5 "D20: E18 rules that are not stratified; query exits 2"
run_test t_X6 X6 "H1 helper form is false"
run_test t_X7 X7 "D20: E17 s(CASP) forms in rules.pl; query exits 2"
run_test t_X8 X8 "D20: E17 for -p in a body"
run_test t_X9 X9 "D20: no command calls scasp"
run_test t_X10 X10 "D20 review: E17 in kb.pl and goals, no E2 for #<, E18 in rules.pl"
run_test t_GD GD "query done on 20 claims x 2 runs: correct"
run_test t_WN1 WN1 "whynot: holds"
run_test t_WN2 WN2 "D20: whynot absent names the blocking literal"
run_test t_WN3 WN3 "whynot: absent, with a justification"
run_test t_WN4 WN4 "whynot: a fact holds; no clause is absent and named"
run_test t_WN5 WN5 "D20: whynot --long"
run_test t_FL1 FL1 "D21: a visual claim flares; done waits; show open lists it"
run_test t_FL2 FL2 "D21: a human approval of the demo closes the flare"
run_test t_FL3 FL3 "D21: a new screenshot makes the approval stale and reopens the flare"
run_test t_FL4 FL4 "D21: an agent cannot approve a demo"
run_test t_FL5 FL5 "D21: a waiver closes a flare until its due time"
run_test t_FL6 FL6 "D21: a visual claim contested twice does not burn"
run_test t_FL7 FL7 "D21: a claim can burn and flare: proof and demo"
run_test t_FL8 FL8 "D21: a claim that replaces a visual claim flares"
run_test t_FL9 FL9 "D21: rules.pl cannot close a flare (E16)"
run_test t_FL10 FL10 "D21: report: Flare part, Open item, lapsed waiver of the demo"
run_test t_FL11 FL11 "D21 F3b: an edit of the demo file on disk reopens the flare"
run_test t_Y1 Y1 "why shows the template text of a local decl/4 line"
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
run_test t_E17 E17 "D20: lint E17 a form of s(CASP) (#include)"
run_test t_W1 W1 "lint W1 changed subject; --strict exits 1"
run_test t_W3 W3 "lint W3 claim without cites"
run_test t_W4 W4 "lint W4 fact predicate with no reader"
run_test t_W5 W5 "lint W5 check on a superseded claim"
run_test t_W5b W5b "lint W5 says to add a new check of the new claim, and stops when it has one"
run_test t_W5c W5c "lint W5 follows a supersede chain to the current claim"
run_test t_W6 W6 "lint W6 local rule extends a core predicate"
run_test t_LS LS "lint --strict turns W2 into exit 1"
run_test t_E14 E14 "lint E14 unsafe negation: head variable in no positive literal (D7)"
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
run_test t_RP7 RP7 "report Open lists what blocks discovery_ready"
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
run_test t_DR1 DR1 "doctor exits 0 on this machine"
run_test t_DR2 DR2 "doctor reports each self-test as passing"
run_test t_DR3 DR3 "doctor with a broken library exits 2"
run_test t_HP1 HP1 "help explains the engine"
run_test t_HP2 HP2 "help query"
run_test t_HP3 HP3 "--help"
run_test t_HP4 HP4 "general help starts with how to use and names each topic"
run_test t_HP5 HP5 "each help topic prints"
run_test t_HP6 HP6 "unknown help topic exits 2"
run_test t_HP7 HP7 "init prints a Next line"
run_test t_FU1 FU1 "D22 c1: add declares a new predicate by its first use (who, when)"
run_test t_FU2 FU2 "D22 c2: lint lists each first-use predicate as W7; help codes documents it"
run_test t_FU3 FU3 "D22 c3: a first-use name within 2 edits of a declared one (same arity) is E19"
run_test t_FU4 FU4 "D22 c4: a declared predicate keeps its arity and types"
run_test t_FU5 FU5 "T26 c4: a decl/4 line of an older KB keeps its doc and types; add of its facts works"
run_test t_FU6 FU6 "T26 c2: help add and help core name the first use and --doc"
# FU7 is not run: FU8 supersedes it (see the comment above t_FU8).
run_test t_FU8 FU8 "D22 c3: E19 at edit distance 2, none at distance 3 (each case alone)"
run_test t_KD1 KD1 "T26 c1: declare is removed: exit 2, one line that says add --doc; no help, README or prompt names it"
run_test t_KD2 KD2 "T26 c2: the first add of a new kind may take --doc; optional; a W-lint and show kinds name a kind without one"
run_test t_KD3 KD3 "T26 c3: show kinds lists each kind with its description"
run_test t_KD4 KD4 "T26 c4: a KB with decl/4 lines still loads; their docs show in show kinds"
run_test t_KD6 KD6 "T26 review: a rules.pl head is declared by its first definition, doc from a %% doc: comment; W9, show kinds; add refuses decl terms"
run_test t_KD5 KD5 "T26 c5: no test calls declare any more"
run_test t_KD7 KD7 "T40 c8: a kind with no description can get one later; rules.pl doc describes an empty kb.pl rule decl"
run_test t_KD8 KD8 "T40 c9: show kinds works while E19 or E2 fires; a repeated --doc is refused"
run_test t_KD9 KD9 "T40 c9: CONTRACT and grade_tools.py no longer name declare"
run_test t_RT1 RT1 "D22 c6: declare-attest is an unknown command"
run_test t_RT2 RT2 "D22 c6: depends/2 is not a fact kind"
run_test t_RT3 RT3 "D22 c6: CONTRACT and the help topics do not name the cut items"
run_test t_BL1 BL1 "D22 c7: blocking(to_ask(Q))"
run_test t_BL2 BL2 "D22 c7: blocking(burn_open(C))"
run_test t_BL3 BL3 "D22 c7: blocking(flare_open(C))"
run_test t_BL4 BL4 "D22 c7: blocking(check_failing(K))"
run_test t_BL10 BL10 "D22 c7: blocking(check_unrun(K))"
run_test t_BL5 BL5 "D22 c7: blocking(waiver_lapsed(W))"
run_test t_BL6 BL6 "D22 c7: blocking(past_due(X))"
run_test t_BL6b BL6b "D22 c7: blocking(past_due(X)) for a question and a check"
run_test t_BL7 BL7 "D22 c7: done holds exactly when nothing blocks (under, over, no_claim)"
run_test t_BL8 BL8 "D22 c7: show blocking prints each item with its text"
run_test t_BL8b BL8b "D22 c7: show blocking prints the text of every kind"
run_test t_BL9 BL9 "D22 c7: rules.pl cannot add to blocking/1 (E16)"
run_test t_BL11 BL11 "T18 c5: help show lists blocking in its usage line"
run_test t_PN1 PN1 "D22 c8: pin prints the stamp and the time; pin --check is 0 unchanged, 1 changed"
run_test t_PN2 PN2 "D22 c8: pin usage errors exit 2"
run_test t_PH1 PH1 "D22 c9: help names the phase tree and the moves of each phase"
run_test t_AC1 AC1 "D29 c7: ac/1 is a declared fact kind of the build module; help build names it"
run_test t_AC2 AC2 "D29 c7: show blocking names an unmet acceptance criterion as such"
run_test t_AC3 AC3 "D29 c7: draft blocking names an unmet acceptance criterion as such"
run_test t_AC4 AC4 "D29 c7: ac/1 changes neither blocking/1, nor done, nor burns"
run_test t_AC5 AC5 "D29 c7: ac/1 is a plain fact kind: queryable, not protected"
run_test t_VR1 VR1 "D28 c1: every attestation and every run records actor(A, Role, Session)"
run_test t_VR2 VR2 "D28 c2: review start records review_saw for the ticket, the KB stamp, and the diff"
run_test t_VR3 VR3 "D28 c3: verdicts carry what was tried, upheld(Text), and rests_on_run"
run_test t_VR4 VR4 "D28 c4: independently_verified(C)"
run_test t_VR5 VR5 "D28 c5: report Review section and lint WR1; done unchanged"
run_test t_VR6 VR6 "D28 c6: the FULFILL brief for the fresh-eyes subagent (0.3.0: the prompt no longer points to it; panes/review.md does)"
run_test t_VR7 VR7 "T38 c1: a digest is the sha256 of the bytes, also for non-ASCII files"
run_test t_VR8 VR8 "T38 c2: independently_verified reads the latest verdict on the claim"
run_test t_VR9 VR9 "T38 c3: old data fails closed"
run_test t_VR10 VR10 "T38 c4: a builder's subagent that follows the FULFILL brief literally is independent"
run_test t_VR11 VR11 "T38 c5: WR1 waits until no current claim is under"
run_test t_VR12 VR12 "T40 c1: the FULFILL brief works when each step runs in its own shell"

run_tests
echo "----"
echo "orbit-kb=$OKB lib=$LIB pass=$pass fail=$fail skip=$skip ${failed[*]:-}"
[ $fail = 0 ]
