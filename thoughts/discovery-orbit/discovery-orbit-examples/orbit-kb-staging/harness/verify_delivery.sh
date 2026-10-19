#!/usr/bin/env bash
# R9: the delivered module and fixture are byte-identical to the staged files, and
# `orbit-kb lint` on the delivered fixture gives no E code.
# Usage: harness/verify_delivery.sh      (run after the copy; reads only)
set -u
here=$(cd "$(dirname "$0")" && pwd)
stage=$(cd "$here/.." && pwd)
repo=/home/ty/.dotfiles
mod_dst=$repo/shared/link/.local/share/orbit-kb/modules/discovery.pl
fix_dst=$repo/scripts/orbit-kb/fixtures/discovery-a
fails=0

if cmp -s "$stage/modules/discovery.pl" "$mod_dst"; then
    echo "ok    R9 module is byte-identical"
else
    echo "FAIL  R9 module differs"; fails=$((fails + 1))
fi
if diff -r "$stage/fixtures/discovery-a" "$fix_dst" > /dev/null; then
    echo "ok    R9 fixture is byte-identical"
else
    echo "FAIL  R9 fixture differs:"; diff -rq "$stage/fixtures/discovery-a" "$fix_dst"
    fails=$((fails + 1))
fi
# Lint a copy, so that the CLI writes nothing into the delivered fixture.
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cp -r "$fix_dst" "$tmp/kb"
orbit-kb --dir "$tmp/kb" lint > "$tmp/lint.out" 2>&1
rc=$?
cat "$tmp/lint.out"
if [ $rc -eq 0 ]; then
    echo "ok    R9 orbit-kb lint on the delivered fixture (installed library): exit 0"
else
    echo "FAIL  R9 orbit-kb lint on the delivered fixture: exit $rc"; fails=$((fails + 1))
fi
[ $fails -eq 0 ]
