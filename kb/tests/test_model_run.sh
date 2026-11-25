#!/usr/bin/env bash
# Tests of orbit model-run and orbit repo-map (spec KB orbit-front-door c1 to c5).
# Usage: kb/tests/test_model_run.sh [path-to-orbit-kb]   ONLY='<regex>' runs matching ids.
#   c1 orbit runs the solver or model checker itself and records the run   : MR1 MR6 MR9
#   c2 unknown, timeout, failure: recorded, exit 2, no result              : MR2 MR4 MR5 MR10
#   c3 a model run cannot be recorded by hand                              : MR3
#   c4 orbit repo-map is the repo-map beside it                            : MR8
#   c5 the old name is the same program                                    : MR11
#   a model file that changed since its subject is refused                 : MR7
set -u
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
OKB=${1:-${ORBIT_KB_BIN:-$here/../bin/orbit-kb}}
OKB=$(cd "$(dirname "$OKB")" && pwd -P)/$(basename "$OKB"); ORB=$(dirname "$OKB")/orbit
export HUB_SESSION=model-run-test
pass=0 fail=0; failed=(); FAILS=()
note() { FAILS+=("$*"); }
fixture() {  # fixture KIND: a KB with model m1 (smt or tla)
    T=$(mktemp -d); K=$T/kb
    "$ORB" init "$K" --request fixture --uses discovery >/dev/null 2>&1 || { note "setup: init"; return 1; }
    if [ "$1" = smt ]; then printf '(declare-const x Int)\n(assert (and (> x 1) (< x 1)))\n(check-sat)\n' > "$K/m1.smt2"; f=m1.smt2
    else printf -- '---- MODULE m1 ----\nVARIABLE x\nInit == x = 0\nNext == x'"'"' = x\nSpec == Init /\\ [][Next]_x\n====\n' > "$K/m1.tla"; f=m1.tla; fi
    "$ORB" --dir "$K" add "goal(g1, feature, agent, 'g')" "claim(c1, preserve, 'x')" "example(c1, 'e')" >/dev/null 2>&1 || { note "setup: add"; return 1; }
    "$ORB" --dir "$K" subject m1 $f >/dev/null 2>&1 || { note "setup: subject"; return 1; }
    "$ORB" --dir "$K" add "model(m1, $1)" >/dev/null 2>&1 || { note "setup: model"; return 1; }
}
fake() {  # fake NAME 'SHELL BODY': a fake tool first on PATH
    mkdir -p "$T/bin"; printf '#!/bin/sh\n%s\n' "$2" > "$T/bin/$1"; chmod +x "$T/bin/$1"
}
nfacts() { "$ORB" --dir "$K" query "model_run(L, m1, D)" -n 0 2>/dev/null | grep -c "L = "; }
t_MR1() { fixture smt || return; PATH=$PATH out=$("$ORB" --dir "$K" model-run m1 2>&1); rc=$?
    [ $rc = 0 ] || note "exit $rc, want 0: $out"; [ "$(nfacts)" = 1 ] || note "model_run facts: $(nfacts), want 1"
    grep -q '^unsat$' "$K"/runs/1-m1.log || note "the log holds no unsat"
    "$ORB" --dir "$K" query "subject(m1_run1, P, _)" >/dev/null 2>&1 || note "the log is not a subject"
    "$ORB" --dir "$K" query "model_run_current(m1_run1, m1)" >/dev/null 2>&1 || note "the run is not current at the digest"
    "$ORB" --dir "$K" lint 2>&1 | grep -q ' 0 error' || note "lint finds an error"; }
t_MR2() { fixture smt || return; fake z3 'echo unknown'; PATH=$T/bin:$PATH "$ORB" --dir "$K" model-run m1 >/dev/null 2>&1; rc=$?
    [ $rc = 2 ] || note "exit $rc, want 2 for unknown"; grep -q '^unknown$' "$K"/runs/1-m1.log || note "the log holds no unknown"
    [ "$(nfacts)" = 1 ] || note "the unknown run is not recorded as it is"
    "$ORB" --dir "$K" query "model_trusted(m1)" >/dev/null 2>&1 && note "an unknown run made the model trusted"; }
t_MR3() { fixture smt || return; echo unsat > "$K/typed.log"; "$ORB" --dir "$K" subject l1 typed.log >/dev/null 2>&1
    dg=$(grep -o "subject(m1, [^)]*" "$K/kb.pl" | grep -o "sha256:[0-9a-f]*")
    out=$("$ORB" --dir "$K" add "model_run(l1, m1, '$dg')" 2>&1); rc=$?
    [ $rc != 0 ] || note "model_run by hand was accepted"; printf '%s' "$out" | grep -q 'orbit model-run m1' || note "the refusal does not name orbit model-run m1: $out"
    [ "$(nfacts)" = 0 ] || note "a fact was written"; }
t_MR4() { fixture smt || return; fake z3 'sleep 30'; PATH=$T/bin:$PATH "$ORB" --dir "$K" model-run m1 --timeout 1 >/dev/null 2>&1; rc=$?
    [ $rc = 2 ] || note "exit $rc, want 2 for a timeout"; grep -q 'verdict=timeout' "$K"/runs/1-m1.log || note "the log header says no timeout"; }
t_MR5() { fixture smt || return; mkdir -p "$T/empty"
    for d in /usr/bin /bin; do [ -x "$d/cvc5" ] && return 0; done
    PATH=$T/empty:/usr/bin:/bin "$ORB" --dir "$K" model-run m1 --tool cvc5 >/dev/null 2>&1; rc=$?
    [ $rc = 2 ] || note "exit $rc, want 2 with no solver"; grep -q 'not on the PATH' "$K"/runs/1-m1.log || note "the log does not say the tool is missing"; }
t_MR6() { fixture tla || return; fake tlc 'echo "Model checking completed. No error has been found."'; PATH=$T/bin:$PATH "$ORB" --dir "$K" model-run m1 >/dev/null 2>&1; rc=$?
    [ $rc = 0 ] || note "exit $rc, want 0 for a TLC result"; grep -q 'tool=tlc' "$K"/runs/1-m1.log || note "the log is not of tlc"; [ "$(nfacts)" = 1 ] || note "model_run facts: $(nfacts)"; }
t_MR7() { fixture smt || return; echo '; changed' >> "$K/m1.smt2"; "$ORB" --dir "$K" model-run m1 >/dev/null 2>&1; rc=$?
    [ $rc = 2 ] || note "exit $rc, want 2 for a changed model file"; [ ! -e "$K/runs" ] || note "a run was made"; [ "$(nfacts)" = 0 ] || note "a fact was written"; }
t_MR8() { a=$("$ORB" repo-map --help 2>&1); ra=$?; b=$("$(dirname "$ORB")/repo-map" --help 2>&1)
    [ $ra = 0 ] || note "orbit repo-map --help exits $ra"; [ "$a" = "$b" ] || note "the text differs from repo-map --help"
    "$ORB" repo-map >/dev/null 2>&1; r1=$?; "$(dirname "$ORB")/repo-map" >/dev/null 2>&1; r2=$?; [ "$r1" = "$r2" ] || note "exit codes differ with no arguments: $r1 $r2"; }
t_MR9() { fixture smt || return; "$ORB" --dir "$K" model-run m1 >/dev/null 2>&1; "$ORB" --dir "$K" model-run m1 >/dev/null 2>&1
    [ -f "$K/runs/1-m1.log" ] && [ -f "$K/runs/2-m1.log" ] || note "two runs, two logs: $(ls "$K/runs")"; [ "$(nfacts)" = 2 ] || note "model_run facts: $(nfacts), want 2"; }
t_MR10() { fixture smt || return; "$ORB" --dir "$K" model-run m9 >/dev/null 2>&1; rc=$?; [ $rc = 2 ] || note "exit $rc for an unknown model, want 2"; [ ! -e "$K/runs" ] || note "a run was made"; }
t_MR11() { a=$("$ORB" version 2>&1); b=$("$OKB" version 2>&1); [ -n "$a" ] && [ "${a#* }" = "${b#* }" ] || note "orbit: $a; orbit-kb: $b"; }
for id in 1 2 3 4 5 6 7 8 9 10 11; do
    [ -n "${ONLY:-}" ] && ! [[ MR$id =~ $ONLY ]] && continue
    FAILS=(); "t_MR$id" </dev/null >/dev/null 2>&1 || true
    if [ ${#FAILS[@]} -eq 0 ]; then pass=$((pass+1)); echo "PASS MR$id"; else fail=$((fail+1)); failed+=("MR$id"); echo "FAIL MR$id"; printf '     - %s\n' "${FAILS[@]}"; fi
done
echo "orbit-kb=$OKB pass=$pass fail=$fail ${failed[*]:-}"
[ "$fail" -eq 0 ]
