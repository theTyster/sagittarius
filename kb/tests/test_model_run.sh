#!/usr/bin/env bash
# Tests of orbit model-run and orbit repo-map (spec KB orbit-front-door c1 to c5).
# Usage: kb/tests/test_model_run.sh [path-to-orbit-kb]   ONLY='<regex>' runs matching ids.
#   c1 orbit runs the solver or model checker itself and records the run   : MR1 MR6 MR9
#   c2 unknown, timeout, failure: recorded, exit 2, no result              : MR2 MR4 MR5 MR10
#   c3 a model run cannot be recorded by hand                              : MR3
#   c4 orbit repo-map is the repo-map beside it                            : MR8
#   c5 the old name is the same program                                    : MR11
#   c7 orbit migrate answers as orbit-kb migrate                            : MR21
#   a model file that changed since its subject is refused                 : MR7
#   the verdict follows the exit code (z3, TLC); TLC runs in a temp dir; --spec --cfg --with; batch gate; cvc5; log not refreshed : MR12-MR17
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
    [ "$(nfacts)" = 0 ] || note "an unknown run wrote model_run"
    "$ORB" --dir "$K" query "subject(m1_run1, _, _)" >/dev/null 2>&1 || note "the unknown log is not kept as a subject"
    "$ORB" --dir "$K" query "model_trusted(m1)" >/dev/null 2>&1 && note "an unknown run made the model trusted"; }
t_MR3() { fixture smt || return; echo unsat > "$K/typed.log"; "$ORB" --dir "$K" subject l1 typed.log >/dev/null 2>&1
    dg=$(grep -o "subject(m1, [^)]*" "$K/kb.pl" | grep -o "sha256:[0-9a-f]*")
    out=$("$ORB" --dir "$K" add "model_run(l1, m1, '$dg')" 2>&1); rc=$?
    [ $rc != 0 ] || note "model_run by hand was accepted"; printf '%s' "$out" | grep -q 'orbit model-run m1' || note "the refusal does not name orbit model-run m1: $out"
    [ "$(nfacts)" = 0 ] || note "a fact was written"; }
t_MR4() { fixture smt || return; fake z3 'sleep 30'; PATH=$T/bin:$PATH "$ORB" --dir "$K" model-run m1 --timeout 1 >/dev/null 2>&1; rc=$?
    [ $rc = 2 ] || note "exit $rc, want 2 for a timeout"; grep -q 'verdict=timeout' "$K"/runs/1-m1.log || note "the log header says no timeout"; [ "$(nfacts)" = 0 ] || note "a timeout wrote model_run"; }
t_MR5() { fixture smt || return; mkdir -p "$T/empty"
    for d in /usr/bin /bin; do [ -x "$d/cvc5" ] && return 0; done
    PATH=$T/empty:/usr/bin:/bin "$ORB" --dir "$K" model-run m1 --tool cvc5 >/dev/null 2>&1; rc=$?
    [ $rc = 2 ] || note "exit $rc, want 2 with no solver"; grep -q 'not on the PATH' "$K"/runs/1-m1.log || note "the log does not say the tool is missing"; [ "$(nfacts)" = 0 ] || note "a missing tool wrote model_run"; }
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
t_MR12() { fixture smt || return; fake z3 'echo unsat; exit 1'; PATH=$T/bin:$PATH "$ORB" --dir "$K" model-run m1 >/dev/null 2>&1; rc=$?
    [ $rc = 2 ] || note "z3 printed unsat and exited 1: orbit exits $rc, want 2"; [ "$(nfacts)" = 0 ] || note "a failing z3 wrote model_run"
    fake z3 'echo sat; echo "(error \"x\")"; exit 1'; PATH=$T/bin:$PATH "$ORB" --dir "$K" model-run m1 >/dev/null 2>&1; rc=$?
    [ $rc = 2 ] && [ "$(nfacts)" = 0 ] || note "sat then an error and exit 1 counted: exit $rc"
    fake z3 'echo unsat; echo sat'; PATH=$T/bin:$PATH "$ORB" --dir "$K" model-run m1 >/dev/null 2>&1; rc=$?
    [ $rc = 2 ] && [ "$(nfacts)" = 0 ] || note "a log with sat and unsat counted: exit $rc"; }
t_MR13() { fixture tla || return
    fake tlc 'echo "Model checking completed. No error has been found."; exit 11'; PATH=$T/bin:$PATH "$ORB" --dir "$K" model-run m1 >/dev/null 2>&1; rc=$?
    [ $rc = 2 ] && [ "$(nfacts)" = 0 ] || note "No error has been found with exit 11 counted: exit $rc"
    fake tlc 'echo "Error: Deadlock reached."; exit 11'; PATH=$T/bin:$PATH "$ORB" --dir "$K" model-run m1 >/dev/null 2>&1; rc=$?
    [ $rc = 0 ] && grep -q 'class=tlc_violated' "$K"/runs/2-m1.log || note "a deadlock counterexample (exit 11) is not a decided violation: exit $rc"
    fake tlc 'echo "Temporal properties were violated."; exit 13'; PATH=$T/bin:$PATH "$ORB" --dir "$K" model-run m1 >/dev/null 2>&1; rc=$?
    [ $rc = 0 ] || note "Temporal properties were violated (exit 13) is not decided: exit $rc"
    fake tlc 'echo "Error: Invariant Small is violated."; exit 1'; PATH=$T/bin:$PATH "$ORB" --dir "$K" model-run m1 >/dev/null 2>&1; rc=$?
    [ $rc = 2 ] || note "a violation line with exit 1 (a crash) counted: exit $rc"; }
t_MR14() { fixture tla || return; printf 'INIT Init\nNEXT Next\n' > "$K/m1.cfg"; printf -- '---- MODULE Harness ----\nEXTENDS m1\n====\n' > "$K/Harness.tla"; printf 'x\n' > "$K/Extra.tla"
    printf 'INIT Init\n' > "$K/H.cfg"
    fake tlc 'pwd > "$TLC_OUT/pwd"; ls > "$TLC_OUT/ls"; echo "$@" > "$TLC_OUT/args"; mkdir -p states; echo "Model checking completed. No error has been found."'
    TLC_OUT=$T PATH=$T/bin:$PATH "$ORB" --dir "$K" model-run m1 >/dev/null 2>&1; rc=$?
    [ $rc = 0 ] || note "exit $rc"; [ "$(cat "$T/pwd")" != "$K" ] || note "TLC ran in the KB directory"; [ ! -e "$K/states" ] && [ ! -e "$K/models/states" ] || note "TLC left states in the KB"
    grep -q 'm1.cfg' "$T/args" || note "the config beside the model was not passed: $(cat "$T/args")"
    TLC_OUT=$T PATH=$T/bin:$PATH "$ORB" --dir "$K" model-run m1 --spec Harness.tla --cfg H.cfg --with Extra.tla >/dev/null 2>&1; rc=$?
    [ $rc = 0 ] || note "harness run: exit $rc"; grep -q 'Harness.tla' "$T/args" && grep -q 'H.cfg' "$T/args" || note "spec and cfg not passed: $(cat "$T/args")"
    for f in m1.tla Harness.tla Extra.tla H.cfg; do grep -qx "$f" "$T/ls" || note "$f was not staged: $(cat "$T/ls" | tr '\n' ' ')"; done
    head -1 "$K"/runs/2-m1.log | grep -q 'cfg=sha256:' || note "the log header does not name the digest of the cfg"
    "$ORB" --dir "$K" model-run m1 --cfg nope.cfg >/dev/null 2>&1; [ $? = 2 ] || note "a missing cfg did not exit 2"; }
t_MR15() { fixture smt || return; echo unsat > "$K/typed.log"; "$ORB" --dir "$K" subject l1 typed.log >/dev/null 2>&1
    dg=$(grep -o "subject(m1, [^)]*" "$K/kb.pl" | grep -o "sha256:[0-9a-f]*")
    out=$("$ORB" --dir "$K" add "note(c1, 'x')" "model_run(l1, m1, '$dg')" 2>&1); rc=$?
    [ $rc != 0 ] || note "a batch with a model_run was accepted"; grep -q '^note(c1' "$K/kb.pl" && note "the other fact of the batch was written"
    out=$("$ORB" --dir "$K" add "model_run(l1, m1, '$dg')" "note(c1, 'x')" 2>&1); [ $? != 0 ] || note "a batch with the model_run first was accepted"; }
t_MR16() { fixture smt || return; mkdir -p "$T/bin"; fake cvc5 'echo unsat'
    for d in /usr/bin /bin; do [ -x "$d/z3" ] && return 0; done
    PATH=$T/bin:/usr/bin:/bin "$ORB" --dir "$K" model-run m1 >/dev/null 2>&1; rc=$?
    [ $rc = 0 ] || note "exit $rc with only cvc5"; head -1 "$K"/runs/1-m1.log | grep -q 'tool=cvc5' || note "the run was not on cvc5: $(head -1 "$K"/runs/1-m1.log | cut -c1-80)"; }
t_MR17() { fixture smt || return; "$ORB" --dir "$K" model-run m1 >/dev/null 2>&1
    "$ORB" --dir "$K" subject m1_run1 runs/1-m1.log >/dev/null 2>&1 || note "re-recording an unchanged log failed"
    echo unsat >> "$K/runs/1-m1.log"; out=$("$ORB" --dir "$K" subject m1_run1 runs/1-m1.log 2>&1); rc=$?
    [ $rc != 0 ] || note "subject refreshed the digest of an edited model-run log"; printf '%s' "$out" | grep -q 'model-run' || note "the refusal does not name orbit model-run: $out"
    echo a > "$K/o.txt"; "$ORB" --dir "$K" subject o1 o.txt >/dev/null 2>&1; echo b >> "$K/o.txt"; "$ORB" --dir "$K" subject o1 o.txt >/dev/null 2>&1 || note "an ordinary subject can no longer be refreshed"; }
t_MR18() { fixture tla || return; printf 'INIT Init\nNEXT Next\n' > "$K/m1.cfg"; printf -- '---- MODULE Harness ----\nEXTENDS m1\n====\n' > "$K/Harness.tla"; printf 'x\n' > "$K/Extra.tla"
    fake tlc 'echo "Model checking completed. No error has been found."'
    export PATH=$T/bin:$PATH
    "$ORB" --dir "$K" model-run m1 --spec Harness.tla --cfg m1.cfg --with Extra.tla >/dev/null 2>&1; rc=$?
    [ $rc = 0 ] || { note "first run: exit $rc"; return; }
    nf=$("$ORB" --dir "$K" query "model_run_file(R, F, D)" -n 0 2>/dev/null | grep -c "F = "); [ "$nf" = 3 ] || note "model_run_file facts: $nf, want 3 (spec, cfg, with)"
    "$ORB" --dir "$K" query "model_run_current(m1_run1, m1)" >/dev/null 2>&1 || note "the run is not current after it was made"
    echo 'INVARIANT Small' >> "$K/m1.cfg"
    "$ORB" --dir "$K" lint 2>&1 | grep -q "W1.*m1_m1" || note "lint does not name the changed cfg"
    "$ORB" --dir "$K" model-run m1 --spec Harness.tla --cfg m1.cfg --with Extra.tla >/dev/null 2>&1; rc=$?
    [ $rc = 2 ] && [ ! -e "$K/runs/2-m1.log" ] || note "a run with a changed cfg that is not re-recorded was made (exit $rc)"
    "$ORB" --dir "$K" subject m1_m1 m1.cfg >/dev/null 2>&1 || note "re-recording the cfg failed"
    "$ORB" --dir "$K" query "model_run_stale(m1_run1, m1)" >/dev/null 2>&1 || note "an edit of the cfg did not make the run stale"
    "$ORB" --dir "$K" query "model_run_current(m1_run1, m1)" >/dev/null 2>&1 && note "the run still counts after the cfg changed"
    "$ORB" --dir "$K" model-run m1 --spec Harness.tla --cfg m1.cfg --with Extra.tla >/dev/null 2>&1 || note "the new run failed"
    "$ORB" --dir "$K" query "model_run_current(m1_run2, m1)" >/dev/null 2>&1 || note "the new run does not count"
    echo more >> "$K/Extra.tla"; "$ORB" --dir "$K" subject m1_Extra Extra.tla >/dev/null 2>&1
    "$ORB" --dir "$K" query "model_run_current(m1_run2, m1)" >/dev/null 2>&1 && note "an edit of a --with module did not make the run stale"
    "$ORB" --dir "$K" add "model_run_file(m1_run2, m1_m1, 'sha256:0000000000000000000000000000000000000000000000000000000000000000')" >/dev/null 2>&1 && note "model_run_file by hand was accepted"; }
t_MR19() { fixture smt || return; "$ORB" --dir "$K" model-run m1 >/dev/null 2>&1; echo unsat >> "$K/runs/1-m1.log"
    out=$("$ORB" --dir "$K" lint 2>&1); printf '%s' "$out" | grep -q 'W1' || note "lint does not warn of the edited log"
    printf '%s' "$out" | grep -Eq 'Refresh with orbit(-kb)? subject' && note "lint still says to refresh the log with subject"
    printf '%s' "$out" | grep -q 'orbit model-run' || note "lint does not say to run orbit model-run again"
    echo a > "$K/o.txt"; "$ORB" --dir "$K" subject o1 o.txt >/dev/null 2>&1; echo b >> "$K/o.txt"
    "$ORB" --dir "$K" lint 2>&1 | grep -Eq 'Refresh with orbit(-kb)? subject o1' || note "an ordinary subject lost its refresh hint"; }
t_MR20() { fixture tla || return; fake tlc 'echo "Error: Deadlock reached."; echo "State 1: x = 0"; exit 11'
    PATH=$T/bin:$PATH "$ORB" --dir "$K" model-run m1 >/dev/null 2>&1; rc=$?
    [ $rc = 0 ] && grep -q 'class=tlc_violated' "$K"/runs/1-m1.log || note "a plain TLC deadlock (exit 11) is not a decided result: exit $rc"
    "$ORB" help model-run 2>&1 | grep -qi 'deadlock' || note "the help does not say that a deadlock is a result"; }
t_MR21() { fixture smt || return   # c7: orbit migrate answers as orbit-kb migrate (check, plan)
    a=$("$ORB" --dir "$K" migrate check 2>&1); ra=$?; b=$("$OKB" --dir "$K" migrate check 2>&1); rb=$?
    [ "$ra" = "$rb" ] && [ "$a" = "$b" ] || note "migrate check differs: $ra $rb"
    printf '%s' "$a" | grep -qi 'unknown command' && note "orbit does not know migrate"
    a=$("$ORB" --dir "$K" migrate plan 2>&1); ra=$?; b=$("$OKB" --dir "$K" migrate plan 2>&1); rb=$?
    [ "$ra" = "$rb" ] && [ "$a" = "$b" ] || note "migrate plan differs: $ra $rb"; }
for id in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21; do
    [ -n "${ONLY:-}" ] && ! [[ MR$id =~ $ONLY ]] && continue
    FAILS=(); "t_MR$id" </dev/null >/dev/null 2>&1 || true
    if [ ${#FAILS[@]} -eq 0 ]; then pass=$((pass+1)); echo "PASS MR$id"; else fail=$((fail+1)); failed+=("MR$id"); echo "FAIL MR$id"; printf '     - %s\n' "${FAILS[@]}"; fi
done
echo "orbit-kb=$OKB pass=$pass fail=$fail ${failed[*]:-}"
[ "$fail" -eq 0 ]
