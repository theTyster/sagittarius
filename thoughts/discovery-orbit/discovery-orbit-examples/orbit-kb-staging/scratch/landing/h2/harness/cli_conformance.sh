#!/usr/bin/env bash
# R2 (CLI clause): each base expectation in fixtures/discovery-a/expected.pl gives the
# expected answer through the real `orbit-kb query -n 0`, with a scratch library that
# holds the staged module. A control compares one query with a wrong answer set, which
# must not match.
# Usage: harness/cli_conformance.sh [MODULE]
set -u
here=$(cd "$(dirname "$0")" && pwd)
module=${1:-$here/../modules/discovery.pl}
lib_src=${ORBIT_KB_LIB_SRC:-$HOME/.local/share/orbit-kb}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/lib"
cp -rL "$lib_src"/. "$tmp/lib/"
cp "$module" "$tmp/lib/modules/discovery.pl"
cp -r "$here/../fixtures/discovery-a" "$tmp/kb"

# Each base expectation as GOAL<TAB>ANSWERS, with ANSWERS true, none, or atoms joined by |.
swipl -q -g "
    open('$tmp/kb/expected.pl', read, S),
    repeat, read_term(S, T, []),
    ( T == end_of_file -> !, close(S)
    ; T = expect(base, G, A),
      ( is_list(A) -> atomic_list_concat(A, '|', AT) ; AT = A ),
      format('~w\t~w~n', [G, AT]), fail )" -t halt > "$tmp/base.tsv"

ORBIT_KB_LIB="$tmp/lib" python3 -I - "$tmp" <<'EOF'
import os, subprocess, sys
tmp = sys.argv[1]
env = dict(os.environ)

def query(goal):
    r = subprocess.run(["orbit-kb", "--dir", tmp + "/kb", "query", goal, "-n", "0"],
                       capture_output=True, text=True, env=env)
    lines = [l.removesuffix(" (unchecked)").strip() for l in r.stdout.splitlines() if l.strip()]
    if r.returncode == 1 and lines in ([], ["false"]):
        got = "none"
    elif r.returncode == 0 and lines and all(l == "true" for l in lines):
        got = "true"
    elif r.returncode == 0:
        got = sorted(set(lines))
    else:
        got = f"exit {r.returncode}: {r.stdout.strip()} {r.stderr.strip()}"
    return got, r.stderr

def norm(goal, text):
    if text in ("true", "none"):
        return text
    # Names that start with _ are not shown, as in run.pl.
    return sorted(set(text.split("|")))

fails = skips = 0
rows = [l.rstrip("\n").split("\t") for l in open(tmp + "/base.tsv") if l.strip()]
for goal, ans in rows:
    want = norm(goal, ans)
    got, err = query(goal)
    skipped = "CROSS-CHECK SKIPPED" in err
    skips += skipped
    if "ENGINE DISAGREEMENT" in err:
        got = "ENGINE DISAGREEMENT"
    ok = got == want
    fails += not ok
    print(f"{'ok  ' if ok else 'FAIL'}  {goal}  want {want}  got {got}{'  (unchecked)' if skipped else ''}")

# Control: a wrong answer set must not match.
got, _ = query("model_trusted(M)")
control = got != ["M = m_now"]
print(f"{'ok  ' if control else 'FAIL'}  control: model_trusted(M) does not match the wrong set ['M = m_now'] (got {got})")
fails += not control
print(f"cli_conformance: {len(rows)} base expectations, {fails} failed, {skips} cross-checks skipped")
sys.exit(1 if fails else 0)
EOF
