#!/usr/bin/env bash
# Conformance of the verdict rule of orbit-kb with the definition Warrants of
# kb/proofs/scientific_method/ScientificMethod.lean (scientific-method-overhaul, claim c25,
# experiment k25; the three verdicts are claim c7).
#
# The case is the timer example of the Lean file, in tenths of a second: the claim predicts an
# elapsed time of 590 to 610, and the clock is right within 2. The file proves:
#   Timer.reading_600   the reading 600 warrants meets        (each compatible value is predicted)
#   Timer.reading_611   the reading 611 warrants unresolved   (610 is predicted, 612 is not)
#   Timer.reading_615   the reading 615 warrants conflicts    (no compatible value is predicted)
#
# The script makes a scratch KB with TOOL and runs one check three times. The check is a small
# script that compares the compatible range [reading-2, reading+2] with the predicted range
# [590, 610]. It exits 0 when each compatible value is predicted, 1 when none is, and 77 when
# some are and some are not (77: "this check could not decide"). Then the script reads what the
# tool recorded, attest(_, test_result, _, result(k1, N, R), _, _): exactly one result for each
# run, pass (meets) for 600, unresolved for 611, fail (conflicts) for 615. When the tool knows
# verdict/2, each run must also have exactly one verdict there, with the name that Warrants gives.
#
# At 0.7.2 the case 611 FAILS: that tool records fail for exit 77.
#
# Usage: kb/tests/warrants_conformance.sh [TOOL]      (TOOL: an orbit-kb; default kb/bin/orbit-kb)
# Exit: 0 the three cases pass. 1 a case failed. 2 the setup failed.
set -u
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
repo=$(cd "$here/../.." && pwd -P)
TOOL=${1:-$repo/kb/bin/orbit-kb}
LEAN=$repo/kb/proofs/scientific_method/ScientificMethod.lean
me=warrants_conformance.sh
die() { echo "$me: $*" >&2; exit 2; }

case $TOOL in /*) ;; *) TOOL=$PWD/$TOOL ;; esac
[ -x "$TOOL" ] || die "no tool at $TOOL"
for t in mktemp sed grep; do command -v "$t" >/dev/null 2>&1 || die "required tool not found: $t"; done
# The tool under test uses its own library, not one that the environment names.
for v in $(compgen -e); do case $v in ORBIT_KB*) unset "$v" ;; esac; done

# The three cases: reading, the verdict that Warrants gives, the result that the tool records.
CASES=("600 meets pass" "611 unresolved unresolved" "615 conflicts fail")

# The expectations are the statements of the Lean file. docs/check_lean.py proves them.
[ -f "$LEAN" ] || die "no Lean file at $LEAN"
grep -qF 'abbrev timely (elapsed : Int) := 590 ≤ elapsed ∧ elapsed ≤ 610' "$LEAN" \
    || die "the Lean file does not state the predicted range 590 to 610"
grep -qF 'reading - 2 ≤ elapsed ∧ elapsed ≤ reading + 2' "$LEAN" \
    || die "the Lean file does not state the error bound 2"
for c in "${CASES[@]}"; do
    set -- $c
    grep -qF "theorem reading_$1 : Warrants timely (withinError $1) .$2 " "$LEAN" \
        || die "the Lean file has no theorem that the reading $1 warrants $2"
done

D=$(mktemp -d "${TMPDIR:-/tmp}/warrants-conformance.XXXXXX") || die "mktemp failed"
trap 'rm -rf "$D"' EXIT
k() { "$TOOL" --dir "$D/kb" "$@"; }

# The check: Warrants for two ranges of whole tenths of a second.
cat >"$D/reading.sh" <<'EOF'
#!/bin/sh
# reading.sh READING: compares [READING-2, READING+2] with the predicted range [590, 610].
reading=$1
x=$((reading - 2)); hi=$((reading + 2)); in=0; out=0
while [ "$x" -le "$hi" ]; do
    if [ "$x" -ge 590 ] && [ "$x" -le 610 ]; then in=$((in + 1)); else out=$((out + 1)); fi
    x=$((x + 1))
done
echo "reading $reading: compatible $((reading - 2)) to $hi; predicted 590 to 610; $in value(s) predicted, $out not"
[ "$out" -eq 0 ] && exit 0      # meets: each compatible value is predicted
[ "$in" -eq 0 ] && exit 1       # conflicts: no compatible value is predicted
exit 77                         # unresolved: the reading does not decide
EOF

# The check itself must give the exits of Warrants, or a red case below says nothing of the tool.
for c in "600 0" "611 77" "615 1"; do
    set -- $c
    sh "$D/reading.sh" "$1" >/dev/null; rc=$?
    [ "$rc" = "$2" ] || die "setup: reading.sh $1 exits $rc, want $2"
done

"$TOOL" init "$D/kb" --request 'The timer rings in time.' --uses build >"$D/setup.log" 2>&1 \
    || { cat "$D/setup.log" >&2; die "setup: init failed"; }
k add "hypothesis(h1, feature, 'On each uninterrupted run at the 60 s setting the timer rings 59.0 to 61.0 s after it starts.')" \
      'no_premises(h1)' \
      "claim(c1, introduce, 'The elapsed time of the run is 590 to 610 tenths of a second.')" \
      "cites(c1, 'The timer rings in time.')" \
      "example(c1, 'The clock reads 600, and it is right within 2: each value from 598 to 602 is in the range.')" \
      'check(k1, c1)' \
      "checks_that(k1, 'each elapsed time that fits the clock reading is in the range 590 to 610')" \
      >"$D/setup.log" 2>&1 || { cat "$D/setup.log" >&2; die "setup: add failed"; }

# One run for each reading. The run line is "run N k1 RESULT (exit E) log=...".
RUNS=()
for c in "${CASES[@]}"; do
    set -- $c
    line=$(k run k1 -- sh "$D/reading.sh" "$1" 2>&1 | grep -E '^run [0-9]+ k1 ' | head -n 1)
    n=$(printf '%s\n' "$line" | sed -n 's/^run \([0-9][0-9]*\) k1 .*/\1/p')
    [ -n "$n" ] || die "setup: the run of the reading $1 printed no run line"
    RUNS+=("$n")
    echo "     reading $1: ${line%% log=*}"
done

k query 'attest(A, test_result, _, result(k1, N, R), _, _)' -n 0 >"$D/results" 2>"$D/results.err"; rc=$?
[ "$rc" = 0 ] || { cat "$D/results" "$D/results.err" >&2; die "the query of the results exits $rc"; }

# verdict/2 is the view of 0.8.0. A tool that does not know it exits 2 here.
k query 'verdict(A, V)' -n 0 >"$D/verdicts" 2>/dev/null; vrc=$?
[ "$vrc" = 0 ] || echo "     note: this tool does not answer verdict(A, V) (exit $vrc): the verdict names are not compared"

pass=0 fail=0 i=0
for c in "${CASES[@]}"; do
    set -- $c
    reading=$1 verdict=$2 want=$3 n=${RUNS[$i]}; i=$((i + 1))
    why=""
    count=$(grep -c "^A = [^,]*, N = $n, R = " "$D/results")
    got=$(sed -n "s/^A = [^,]*, N = $n, R = \(.*\)$/\1/p" "$D/results" | tr '\n' ' ' | sed 's/ $//')
    att=$(sed -n "s/^A = \([^,]*\), N = $n, R = .*$/\1/p" "$D/results" | head -n 1)
    if [ "$count" != 1 ]; then
        why="the run $n has $count results (${got:-none}), want exactly one"
    elif [ "$got" != "$want" ]; then
        why="the tool recorded $got, want $want"
    elif [ "$vrc" = 0 ]; then
        vcount=$(grep -c "^A = $att, V = " "$D/verdicts")
        vgot=$(sed -n "s/^A = $att, V = \(.*\)$/\1/p" "$D/verdicts" | tr '\n' ' ' | sed 's/ $//')
        if [ "$vcount" != 1 ]; then
            why="the run $n ($att) has $vcount verdicts (${vgot:-none}), want exactly one"
        elif [ "$vgot" != "$verdict" ]; then
            why="the verdict of the run $n ($att) is $vgot, want $verdict"
        fi
    fi
    if [ -z "$why" ]; then
        pass=$((pass + 1)); echo "PASS reading $reading: Warrants gives $verdict, the tool recorded $want (run $n)"
    else
        fail=$((fail + 1)); echo "FAIL reading $reading: Warrants gives $verdict (result $want): $why"
    fi
done
echo "$me: $pass passed, $fail failed"
[ "$fail" = 0 ]
