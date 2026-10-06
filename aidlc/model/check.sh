#!/usr/bin/env bash
# Model-check the AIDLC process model (AIDLC.tla) with TLC.
#
# Three groups of checks. The script exits nonzero if any result differs
# from its expectation.
#   main      every safety invariant and Termination hold; no deadlock.
#   witness   each anti-vacuity witness is violated, so its path is reachable.
#   mutation  each counterfactual drops one guard; its invariant must fail.
#
# Needs Java and tla2tools.jar. Uses the `tlc` wrapper when it is on PATH
# (it honors JAVA_HOME and TLA_TOOLS_JAR). TLC runs in a temp dir, so no
# state or trace files land in the repo.
#
# Usage: ./check.sh [budget]    budget = disruptions per behavior (default 2)
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
budget="${1:-2}"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
cp "$here/AIDLC.tla" "$work/"

if command -v tlc >/dev/null 2>&1; then
  run_tlc() { tlc "$@"; }
else
  jar="${TLA_TOOLS_JAR:-${XDG_DATA_HOME:-$HOME/.local/share}/tlaplus/tla2tools.jar}"
  java_bin="${JAVA_HOME:+$JAVA_HOME/bin/}java"
  run_tlc() { "$java_bin" -cp "$jar" tlc2.TLC "$@"; }
fi

invariants=(TypeOK ManifestFirst TierShape TestFirst Authoritative SetsHonest
  FindingsBlock Closure ReviewCurrent ReleaseGate PokayokeOnDisk HandoffOnDisk
  ReadOnlyClean TestFirstStrict ReviewFresh RetroRecheck FMSourceCurrent
  DocOrder)

# cfg <file> <mutation> <section-keyword> <names...>
cfg() {
  local file="$1" mutation="$2" section="$3"
  shift 3
  {
    printf 'SPECIFICATION Spec\nCONSTANTS\n'
    printf '    MaxSessions = 2\n    Budget = %s\n    Mutation = "%s"\n' "$budget" "$mutation"
    printf '%s\n' "$section"
    printf '    %s\n' "$@"
  } >"$work/$file"
}

fail=0
# check <group> <label> <cfg> <expect: pass|violated> [<name>]
check() {
  local group="$1" label="$2" file="$3" expect="$4" name="${5:-}" out observed states
  out="$(cd "$work" && run_tlc -workers auto -nowarning -config "$file" \
    -metadir "$work/meta-${file%.cfg}" AIDLC.tla 2>&1 || true)"
  if grep -q "No error has been found" <<<"$out"; then
    observed=pass
  elif [[ -n "$name" ]] && grep -qE "(Invariant|Action property) $name is violated" <<<"$out"; then
    observed=violated
  elif grep -q "Temporal properties were violated" <<<"$out"; then
    observed=liveness-violated
  elif grep -q "Deadlock reached" <<<"$out"; then
    observed=deadlock
  else
    observed=error
  fi
  states="$(grep -oE '[0-9]+ distinct states found' <<<"$out" | tail -1 | cut -d' ' -f1)"
  if [[ "$observed" == "$expect" ]]; then
    printf 'ok    %-9s %-24s expected %-8s states %s\n' "$group" "$label" "$expect" "${states:-?}"
  else
    printf 'FAIL  %-9s %-24s expected %-8s got %s\n' "$group" "$label" "$expect" "$observed"
    grep -E "Error|violated|Deadlock|Exception" <<<"$out" | head -5 | sed 's/^/      /'
    fail=1
  fi
}

echo "AIDLC model check, budget $budget"

# 1. Main run: all invariants, termination, and the release step property.
cfg main.cfg none INVARIANTS "${invariants[@]}"
printf 'PROPERTIES\n    Termination\n    ReleaseStep\n' >>"$work/main.cfg"
check main all-invariants main.cfg pass

# 2. Anti-vacuity witnesses: each path must be reachable.
for w in NeverCloseWiffled NeverCloseAimed NeverClosePokayoke NeverReadOnlyEnd \
  NeverStale NeverAcceptedClose NeverLoweredClose NeverPaused NeverHandoffClose \
  NeverEmergencyRelease NeverEmergencyClose NeverChatClose NeverLMBeforeTEL \
  NeverPostReleaseWait; do
  cfg "w-$w.cfg" none INVARIANTS "$w"
  check witness "$w" "w-$w.cfg" violated "$w"
done
for w in NeverRaise NeverReadOnlyUpgrade NeverResume; do
  cfg "w-$w.cfg" none PROPERTIES "$w"
  check witness "$w" "w-$w.cfg" violated "$w"
done

# 3. Counterfactuals: drop one guard, expect its invariant or property to fail.
while read -r mutation section target; do
  cfg "m-$mutation.cfg" "$mutation" "$section" "$target"
  check mutation "$mutation->$target" "m-$mutation.cfg" violated "$target"
done <<'EOF'
test_first INVARIANTS TestFirst
set_order INVARIANTS Authoritative
stale_downstream INVARIANTS Authoritative
finding_block INVARIANTS FindingsBlock
review_reset INVARIANTS ReviewCurrent
closure_review INVARIANTS Closure
pokayoke_disk INVARIANTS PokayokeOnDisk
handoff_disk INVARIANTS HandoffOnDisk
waiver_expiry INVARIANTS TestFirstStrict
post_release_test_first INVARIANTS TestFirstStrict
retro_recheck INVARIANTS RetroRecheck
raise_review_reset INVARIANTS ReviewFresh
lower_review_reset INVARIANTS ReviewFresh
raise_stale INVARIANTS Authoritative
lower_stale INVARIANTS FMSourceCurrent
release_ignition PROPERTIES ReleaseStep
lm_telemetry INVARIANTS DocOrder
EOF

if ((fail)); then
  echo "RESULT: FAIL"
  exit 1
fi
echo "RESULT: all checks matched expectations"
