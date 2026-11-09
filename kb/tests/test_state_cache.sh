#!/usr/bin/env bash
# Tests of the saved-state fast start of kb/bin/orbit-kb under deleters (cache-race ticket,
# claim c5: calls that share one cache directory each give the result of the same call with
# ORBIT_KB_NO_CACHE=1; claim c3: a state that does not match its .ok is never started).
#
# The race window is between the check of a state and the exec of swipl -x. A real deleter
# hits it about 1 time in 25 under load (repro.sh in the discovery KB). To hit it every
# time, each test runs a COPY of the CLI with one line patched: just before the exec of the
# fast start, the copy sleeps CR_PAUSE seconds when CR_PAUSE is set. Nothing else differs.
# The copy has its own path and its own cache directory, so its state key is its own.
#
# Requirement map:
#   CR1  prune counterexample (c5): call Y checks key K1 and pauses; the script is edited;
#        a cold call builds K2 and prunes K1; Y still gives the no-cache result.
#   CR2  60 s age counterexample (c5): STATE is older than 60 s; Y checks it and pauses; a
#        call that finds no .ok deletes STATE by the age rule; Y still gives the no-cache result.
#   CR3  c3: one byte appended to STATE; the next call exits 0 with the no-cache output.
#   CR4  no private link stays behind after warm calls.
#   CR5  prune removes a private link only when it is over 1 h old and its process is gone.
#
# Usage: kb/tests/test_state_cache.sh [path-to-orbit-kb]   ONLY='<regex>' selects tests.
# Exit: 0 all pass, 1 a test failed, 2 the suite cannot run.
set -u
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
repo=$(cd "$here/../.." && pwd -P)
SRC=${1:-$repo/kb/bin/orbit-kb}
LIB=$repo/kb/share/orbit-kb
for tool in swipl mktemp sed grep cmp touch; do
    command -v "$tool" >/dev/null 2>&1 || { echo "test_state_cache.sh: required tool not found: $tool" >&2; exit 2; }
done
[ -f "$SRC" ] || { echo "test_state_cache.sh: no CLI at $SRC" >&2; exit 2; }
for v in $(compgen -e); do case $v in ORBIT_KB*) unset "$v";; esac; done
export ORBIT_KB_LIB=$LIB

base=$(mktemp -d "${TMPDIR:-/tmp}/state-cache-test.XXXXXX") || exit 2
trap 'rm -rf "$base"' EXIT
pass=0 fail=0 FAILS=()
note() { FAILS+=("$*"); }

# The patched copy. The exec of the fast start is the only line "            exec(Cmd)"
# (12 spaces) in the script; exit_now/1 calls exec inside catch/3 on another line.
n=$(grep -c '^            exec(Cmd)$' "$SRC")
[ "$n" = 1 ] || { echo "test_state_cache.sh: want 1 fast-start exec line in $SRC, found $n" >&2; exit 2; }

setup() {  # setup: a fresh dir $T with the patched CLI $CLI and the cache $C
    T=$(mktemp -d "$base/t.XXXXXX"); mkdir -p "$T/bin" "$T/cache"
    CLI=$T/bin/orbit-kb
    sed 's/^            exec(Cmd)$/            ( getenv('"'"'CR_PAUSE'"'"', W) -> atom_number(W, N), sleep(N) ; true ), exec(Cmd)/' "$SRC" >"$CLI"
    chmod +x "$CLI"
    export XDG_CACHE_HOME=$T/cache
    C=$T/cache/orbit-kb
    ORBIT_KB_NO_CACHE=1 "$CLI" help >"$T/want" 2>/dev/null || note "setup: the no-cache call failed"
}
states() { ls "$C"/state-*.qs 2>/dev/null; }
same() {  # same RC OUT WHAT: the call exited 0 with the no-cache output
    [ "$1" = 0 ] || note "$3: exit $1, want 0 (stderr: $(head -c 300 "$T/y.err" 2>/dev/null | tr '\n' '~'))"
    cmp -s "$2" "$T/want" || note "$3: the output differs from the no-cache output"
}
warm_up() {  # build the state; wait for the sidecar
    "$CLI" help >/dev/null 2>&1
    ls "$C"/state-*.qs.ok >/dev/null 2>&1 || note "setup: no state was built"
}

t_CR1() {
    setup; warm_up
    k1=$(states)
    CR_PAUSE=3 "$CLI" help >"$T/y.out" 2>"$T/y.err" & y=$!
    sleep 1
    printf '%% an edit: a new state key\n' >>"$CLI"
    "$CLI" help >/dev/null 2>&1                                  # cold: builds K2, prunes K1
    [ -e "$k1" ] && note "setup: K1 was not pruned"
    kill -0 "$y" 2>/dev/null || note "setup: Y ended before the prune"
    wait "$y"; rc=$?
    same "$rc" "$T/y.out" "the paused call after the prune"
}

t_CR2() {
    setup; warm_up
    st=$(states)
    touch -d '-120 seconds' "$st"
    CR_PAUSE=3 "$CLI" help >"$T/y.out" 2>"$T/y.err" & y=$!
    sleep 1
    rm -f "$st.ok"
    "$CLI" help >/dev/null 2>&1                                  # sees no .ok; age rule deletes STATE
    [ -e "$st" ] && note "setup: the age rule did not delete STATE"
    kill -0 "$y" 2>/dev/null || note "setup: Y ended before the delete"
    wait "$y"; rc=$?
    same "$rc" "$T/y.out" "the paused call after the age delete"
}

t_CR3() {
    setup; warm_up
    st=$(states)
    printf 'x' >>"$st"
    "$CLI" help >"$T/y.out" 2>"$T/y.err"; rc=$?
    same "$rc" "$T/y.out" "the call after a byte was appended to STATE"
}

t_CR4() {
    setup; warm_up
    for i in 1 2 3 4 5; do "$CLI" help >/dev/null 2>&1; done
    left=$(ls "$C" | grep -c '\.priv$')
    [ "$left" = 0 ] || note "$left private link(s) left after 5 warm calls: $(ls "$C" | tr '\n' ' ')"
}

t_CR5() {
    setup; warm_up
    st=$(states)
    old=$(( $(date +%s) - 7200 )) young=$(date +%s)
    # a dead pid: a finished subshell
    ( exit 0 ) & dead=$!; wait "$dead"
    while kill -0 "$dead" 2>/dev/null; do ( exit 0 ) & dead=$!; wait "$dead"; done
    ln "$st" "$st.$dead-$old.priv"        # old, process gone: pruned
    ln "$st" "$st.$$-$old.priv"           # old, process alive (this shell): kept
    ln "$st" "$st.$dead-$young.priv"      # young, process gone: kept
    printf '%% an edit: a new state key\n' >>"$CLI"
    "$CLI" help >/dev/null 2>&1                                  # cold: builds, prunes
    [ -e "$st.$dead-$old.priv" ] && note "an old private link of a gone process was not pruned"
    [ -e "$st.$$-$old.priv" ] || note "an old private link of a live process was pruned"
    [ -e "$st.$dead-$young.priv" ] || note "a young private link was pruned"
}

run_test() {  # run_test FN ID TITLE
    if [ -n "${ONLY:-}" ] && ! [[ $2 =~ $ONLY ]]; then return; fi
    FAILS=()
    "$1"
    if [ ${#FAILS[@]} = 0 ]; then pass=$((pass+1)); echo "PASS $2 $3"
    else fail=$((fail+1)); echo "FAIL $2 $3"; for f in "${FAILS[@]}"; do echo "     $f"; done; fi
}

run_test t_CR1 CR1 "c5 prune counterexample: the paused call gives the no-cache result"
run_test t_CR2 CR2 "c5 60 s age counterexample: the paused call gives the no-cache result"
run_test t_CR3 CR3 "c3: a state that does not match its .ok is not started"
run_test t_CR4 CR4 "no private link stays behind after warm calls"
run_test t_CR5 CR5 "prune removes only old private links of gone processes"
echo "test_state_cache.sh: $pass passed, $fail failed"
[ "$fail" = 0 ]
