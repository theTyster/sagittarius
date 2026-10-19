#!/usr/bin/env bash
# R1: the real orbit-kb lint on fixtures/discovery-a, with a scratch library that holds
# the staged module. A negative control adds an unsafe negation (E14) and an H4 string
# (E13) to a copy of the module; lint must report both.
# Usage: harness/lint_cli.sh [MODULE]   (default: modules/discovery.pl in this folder)
set -u
here=$(cd "$(dirname "$0")" && pwd)
module=${1:-$here/../modules/discovery.pl}
lib_src=${ORBIT_KB_LIB_SRC:-$HOME/.local/share/orbit-kb}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

make_lib() {   # make_lib DIR MODULE
    mkdir -p "$1"
    cp -rL "$lib_src"/. "$1/"
    cp "$2" "$1/modules/discovery.pl"
}
fails=0

# The fixture, linted in a copy so that the CLI writes nothing into the staging folder.
make_lib "$tmp/lib" "$module"
cp -r "$here/../fixtures/discovery-a" "$tmp/kb"
ORBIT_KB_LIB="$tmp/lib" orbit-kb --dir "$tmp/kb" lint > "$tmp/lint.out" 2>&1
rc=$?
cat "$tmp/lint.out"
if [ $rc -eq 0 ] && ! grep -qE '\b(E|ED|W|WD)[0-9]+\b' "$tmp/lint.out"; then
    echo "ok    R1 orbit-kb lint: no E, ED, W, or WD code (exit 0)"
else
    echo "FAIL  R1 orbit-kb lint: exit $rc"; fails=$((fails + 1))
fi

# Negative control.
cp "$module" "$tmp/bad.pl"
cat >> "$tmp/bad.pl" <<'EOF'
decl(rule, disc_probe(ref), 'Probe.', 'probe @(1)').
decl(rule, disc_probe_text, 'Probe.', 'probe').
decl(rule, disc_probe_h1, 'Probe.', 'probe').
disc_probe(X) :- not model_trusted(X).
disc_probe_h1 :- not model_trusted(_).
disc_probe_text :- note(x, "order_4417").
EOF
make_lib "$tmp/libbad" "$tmp/bad.pl"
ORBIT_KB_LIB="$tmp/libbad" orbit-kb --dir "$tmp/kb" lint > "$tmp/bad.out" 2>&1
rc=$?
if [ $rc -eq 1 ] && grep -q 'E14' "$tmp/bad.out" && grep -q 'E13' "$tmp/bad.out" \
   && grep -q 'E12' "$tmp/bad.out"; then
    echo "ok    R1 control: lint reports E14, E13, and E12 on the bad copy (exit 1)"
else
    echo "FAIL  R1 control: exit $rc"; cat "$tmp/bad.out"; fails=$((fails + 1))
fi
[ $fails -eq 0 ]
