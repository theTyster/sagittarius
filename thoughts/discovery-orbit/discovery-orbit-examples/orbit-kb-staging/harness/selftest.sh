#!/usr/bin/env bash
# Self-tests for harness/run.pl: the only= filter (R4) and s(CASP) timeouts (R5).
# Each test runs the harness on a copy of fixtures/discovery-a with a small expected.pl.
# Usage: harness/selftest.sh        Exit 0 when every test passes.
set -u
here=$(cd "$(dirname "$0")" && pwd)
fix="$here/../fixtures/discovery-a"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cp -r "$fix"/. "$tmp/"
cat > "$tmp/expected.pl" <<'EOF'
variant(v1, []).
variant(v2, []).
variant(v3, []).
expect(base, 'some_hypothesis', true).
expect(v1, 'some_hypothesis', true).
expect(v2, 'some_hypothesis', true).
% v3 expects a wrong answer, so the harness must fail on it.
expect(v3, 'some_hypothesis', none).
EOF

fails=0
ok()   { echo "ok    $1"; }
fail() { echo "FAIL  $1"; fails=$((fails + 1)); }
# run NAME [ENV=VALUE ...] -- ARGS: run the harness; output in $tmp/NAME.out, exit in $rc.
run() {
    local name=$1; shift
    local envs=()
    while [ "$1" != "--" ]; do envs+=("$1"); shift; done
    shift
    env "${envs[@]}" swipl "$here/run.pl" "$tmp" "$@" > "$tmp/$name.out" 2>&1
    rc=$?
}
ran()    { grep -qx "== $2" "$tmp/$1.out"; }
has()    { grep -qF -- "$2" "$tmp/$1.out"; }

# R4: only= runs only the named variants.
run t4a -- only=v1
if [ $rc -eq 0 ] && ran t4a v1 && ! ran t4a v2 && ! ran t4a v3 && ! ran t4a base; then
    ok "R4a only=v1 runs v1 alone and exits 0"
else
    fail "R4a only=v1 runs v1 alone and exits 0 (rc=$rc; ran: $(grep '^== ' "$tmp/t4a.out" | tr '\n' ' '))"
fi
run t4b -- only=v1 only=v2
if [ $rc -eq 0 ] && ran t4b v1 && ran t4b v2 && ! ran t4b v3 && ! ran t4b base; then
    ok "R4b only=v1 only=v2 runs v1 and v2 alone"
else
    fail "R4b only=v1 only=v2 runs v1 and v2 alone (rc=$rc; ran: $(grep '^== ' "$tmp/t4b.out" | tr '\n' ' '))"
fi

run t4c -- only=v9
if [ $rc -eq 1 ] && has t4c "only=v9 names no variant"; then
    ok "R4c only= with an unknown name fails (LM9)"
else
    fail "R4c only= with an unknown name fails (LM9) (rc=$rc)"
fi

# R5: an s(CASP) timeout is CROSS-CHECK SKIPPED, not a failure or a disagreement.
run t5a ORBIT_KB_SCASP_TIMEOUT=0.01 -- only=v1
if [ $rc -eq 0 ] && has t5a "CROSS-CHECK SKIPPED" && ! has t5a "ENGINE DISAGREEMENT" \
   && has t5a "s(CASP) cross-checks skipped (timeout): 1"; then
    ok "R5a a timeout is skipped, counted, and exits 0"
else
    fail "R5a a timeout is skipped, counted, and exits 0 (rc=$rc)"
fi
# Controls: a wrong answer still fails, also when s(CASP) times out.
run t5b -- only=v3
if [ $rc -eq 1 ] && has t5b "swi FAIL"; then ok "R5b a wrong answer exits 1"
else fail "R5b a wrong answer exits 1 (rc=$rc)"; fi
run t5c ORBIT_KB_SCASP_TIMEOUT=0.01 -- only=v3
if [ $rc -eq 1 ] && has t5c "swi FAIL"; then ok "R5c a timeout does not hide an SWI failure"
else fail "R5c a timeout does not hide an SWI failure (rc=$rc)"; fi

[ $fails -eq 0 ] && echo "selftest: all passed" || echo "selftest: $fails failed"
[ $fails -eq 0 ]
