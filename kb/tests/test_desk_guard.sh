#!/usr/bin/env bash
# The Desk guard (desk-agents q9, Ty: desk agents are on by default). A letter about a spec KB that nobody holds
# starts `claude -p`. So every harness of this repo that starts a Desk or runs desk.py must set DESK_AGENTS=off,
# or test agents with a fake claude first on its PATH and refuse to run when claude resolves elsewhere.
# This test reads the files; it runs none of them. Usage: kb/tests/test_desk_guard.sh [ROOT]
#   DG1 the harnesses that start a Desk or run desk.py are found (at least the six known ones)
#   DG2 each one sets DESK_AGENTS=off, or holds the fake-claude guard (agents tests only)
#   DG3 the agents test (test_desk_headless.sh) holds the fake-claude guard and a PATH with no other claude
set -u
ROOT=${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}
PASS=0; FAIL=0
ok() { echo "PASS $1"; PASS=$((PASS+1)); }; no() { echo "FAIL $1"; FAIL=$((FAIL+1)); }
cd "$ROOT" || exit 2
# A harness: a test or check file (not a spec KB's check: discovery owns those) whose text starts a Desk
# (`serve desk`) or runs desk.py with a command, or runs desk.py by its path from a subprocess (a file that only
# looks for desk.py, as hubkit-test.py and s1/test_install.py do, runs nothing).
cands=$(git ls-files 2>/dev/null | grep -E '(^|/)(test_[^/]*|[^/]*[-_]test\.py|[^/]*_check[^/]*)$|(^|/)(tests|checks)/[^/]*\.(sh|py|js)$' | grep -v '^specs/')
[ -n "$cands" ] || cands=$(find kb/tests hubkit s1 -type f \( -name 'test_*' -o -name '*-test.py' \) 2>/dev/null)
harness=""
for f in $cands; do
  [ -f "$f" ] || continue
  [ "$f" = kb/tests/test_desk_guard.sh ] && continue
  if grep -qE 'serve desk|desk\.py[^ ]* +(send|hook|join|agent|agents|agent-run|status)\b|desk\.py --hub|(sys\.executable|Popen|subprocess)[^#]*desk\.py' "$f"; then
    harness="$harness $f"
  fi
done
n=$(wc -w <<<"$harness")
known="kb/tests/test_desk_headless.sh kb/tests/test_desk_stores.sh kb/tests/test_desk_ux.sh kb/tests/test_migrations.sh kb/tests/test_question_server.sh hubkit/hub/.claude/scripts/desk-test.py"
miss=""; for k in $known; do grep -qw -- "$k" <<<"$harness" || miss="$miss $k"; done
if [ -z "$miss" ]; then ok "DG1 $n harnesses found:$harness"; else no "DG1 known harnesses not found:$miss (found:$harness)"; fi
off_re='export DESK_AGENTS=off|"DESK_AGENTS": "off"'
fake_re='claude resolves outside the fake'
for f in $harness; do
  if grep -qE "$off_re" "$f"; then ok "DG2 $f sets DESK_AGENTS=off"
  elif grep -q "$fake_re" "$f" && grep -q 'unset .*DESK_AGENTS\|DESK_AGENTS' "$f"; then ok "DG2 $f tests agents behind the fake-claude guard"
  else no "DG2 $f starts a Desk or runs desk.py with no guard (DESK_AGENTS=off, or a fake claude and the refusal)"; fi
done
h=kb/tests/test_desk_headless.sh
if grep -q "$fake_re" "$h" && grep -qE 'export PATH="\$T/bin:/usr/bin:/bin"' "$h"; then ok "DG3 $h: fake claude first, PATH has no other claude dir, refusal"
else no "DG3 $h lost its fake-claude guard"; fi
echo "desk_guard: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
