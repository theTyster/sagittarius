#!/usr/bin/env bash
# Rerun the Lean work of orbit-kb D10 (SIMULATION, TELEMETRY, RENDEZVOUS):
#   1. build the Lean project (requirements, implementation model, proofs,
#      generator);
#   2. print the witness table and check the axioms of every theorem;
#   3. generate the KBs and compare the CLI with the implementation model;
#   4. discriminating runs: six mutant libraries, each with one literal or
#      clause of build.pl dropped (MA, MB, MC from the Lean phases; MI and MY
#      from the D10 follow-up, MZ from D17). Each must differ from the model on exactly the
#      KBs that the model predicts, and match the mutant on all KBs.
# Exit 0 when every step passes.
#
# Environment: CONFORM_JOBS (default 3) parallel CLI calls. SKIP_MUTANTS=1
# skips step 4. The CLI and the library are the ones in this checkout.
set -euo pipefail

# `heavy` is a job queue that some machines have. Without it, run the command directly.
command -v heavy >/dev/null 2>&1 || heavy() { "$@"; }

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../../.." && pwd)
lib=$repo/kb/share/orbit-kb
jobs=${CONFORM_JOBS:-3}
work=$(mktemp -d "${TMPDIR:-/tmp}/burn_model.XXXXXX")
trap 'rm -rf "$work"' EXIT

# As the test suite does: no ORBIT_KB_* variable of the caller reaches the CLI.
for v in $(compgen -e); do case $v in ORBIT_KB*) unset "$v";; esac; done
export XDG_CACHE_HOME=$work/cache   # a private s(CASP) cache, deleted at exit

cd "$here"
echo "== versions"
echo "commit $(git -C "$repo" rev-parse --short HEAD)$(git -C "$repo" diff --quiet HEAD -- kb/share/orbit-kb kb/bin/orbit-kb || echo ' (CLI or library dirty)')"
echo "inputs sha256 $(cat "$lib/core.pl" "$lib/modules/build.pl" "$repo/kb/bin/orbit-kb" | sha256sum | cut -c1-16) (core.pl, build.pl, orbit-kb)"
echo "model sha256 $(cat BurnModel/Requirements.lean BurnModel/Impl.lean BurnModel/Rendezvous.lean Conform.lean conform_run.py | sha256sum | cut -c1-16) (Requirements, Impl, Rendezvous, Conform, conform_run.py)"
echo "requirements sha256 $(sha256sum BurnModel/Requirements.lean | cut -d' ' -f1)"
lean --version
swipl --version
scasp --version 2>&1 | head -n1 || true
python3 --version

echo "== 1. build"
heavy lake build

echo "== 2. witnesses and axioms"
lake env lean Check.lean | tee "$work/axioms.txt"
n_thm=$(grep -c "depends on axioms\|does not depend on any axioms" "$work/axioms.txt" || true)
bad=$(grep "depends on axioms" "$work/axioms.txt" | sed 's/.*depends on axioms: \[\(.*\)\]/\1/' | tr ',' '\n' | tr -d ' ' \
      | grep -v -x -e propext -e Classical.choice -e Quot.sound -e '' || true)
if [ -n "$bad" ]; then echo "FAIL: an axiom that is not allowed: $bad"; exit 1; fi
want=$(grep -c '^#print axioms' Check.lean)
[ "$n_thm" -eq "$want" ] || { echo "FAIL: want $want axiom reports, got $n_thm"; exit 1; }
echo "axioms: $n_thm theorems, only propext, Classical.choice, Quot.sound"

echo "== 3. conformance: the CLI against the implementation model"
.lake/build/bin/conform gen "$work/gen"
heavy python3 -I conform_run.py "$work/gen" --jobs "$jobs"

[ "${SKIP_MUTANTS:-0}" = 1 ] && { echo "== 4. skipped (SKIP_MUTANTS=1)"; echo "ALL PASS (without mutants)"; exit 0; }

echo "== 4. discriminating runs: mutant libraries"
mutate() {  # mutate NAME OLD NEW: a copy of the library with one line of build.pl replaced
    local m=$1 old=$2 new=$3 d=$work/lib-$1
    cp -a "$lib" "$d"
    python3 -I - "$d/modules/build.pl" "$old" "$new" <<'PY'
import sys
p, old, new = sys.argv[1:]
s = open(p).read()
assert s.count(old) == 1, "the line to mutate must occur once"
open(p, "w").write(s.replace(old, new))
PY
    echo "$m: $(diff "$lib/modules/build.pl" "$d/modules/build.pl" | grep '^>' )"
}
open_rule='burn_open(C) :- burn(C), current(C), not burn_proved(C), not burn_waived(C).'
proved_rule='burn_proved(C) :- attest(A, lean_proof, _, proof(C, _), script, _), not proof_changed(A).'
mutate MA "$open_rule" 'burn_open(C) :- burn(C), not burn_proved(C), not burn_waived(C).'
mutate MB "$open_rule" 'burn_open(C) :- burn(C), current(C), not burn_proved(C).'
mutate MC "$proved_rule" 'burn_proved(C) :- attest(A, lean_proof, _, proof(C, _), script, _).'
# D10 follow-up: MI drops the inherited burn; MY drops the supersede cycle from done.
mutate MI 'burn(C) :- supersedes_closure(C, O), burn_reason(O).' '% (MI: the inherited clause of burn/1 is dropped)'
done_rule=$'done :- not any_under, not any_over, not any_to_ask, not any_burn_open,\n        not any_supersede_cycle, not no_current_claim.'
mutate MY "$done_rule" 'done :- not any_under, not any_over, not any_to_ask, not any_burn_open, not no_current_claim.'
# D17: MZ drops the current claim from done.
mutate MZ "$done_rule" 'done :- not any_under, not any_over, not any_to_ask, not any_burn_open, not any_supersede_cycle.'
for m in MA MB MC MI MY MZ; do
    echo "-- mutant $m"
    ORBIT_KB_LIB=$work/lib-$m heavy python3 -I conform_run.py "$work/gen" --mutant "$m" --jobs "$jobs"
done
echo "ALL PASS"
