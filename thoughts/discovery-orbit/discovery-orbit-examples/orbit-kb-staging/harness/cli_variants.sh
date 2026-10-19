#!/usr/bin/env bash
# End-to-end check through the real CLI: every variant of fixtures/discovery-a as a KB
# directory (harness/emit_variants.pl), each expectation through `orbit-kb query -n 0`,
# and `orbit-kb lint` on each variant. Uses a scratch library that holds the staged
# module. A core lint error (E1 to E14) in any variant, a wrong answer, or an ENGINE
# DISAGREEMENT is a failure. Module lint codes (WD, ED) are expected in some variants.
# NOTE lines (s(CASP) ran the raw program) and CROSS-CHECK SKIPPED are counted.
# Usage: harness/cli_variants.sh [MODULE]      Exit 0 when nothing fails.
set -u
here=$(cd "$(dirname "$0")" && pwd)
module=${1:-$here/../modules/discovery.pl}
lib_src=${ORBIT_KB_LIB_SRC:-$HOME/.local/share/orbit-kb}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/lib" "$tmp/cache"
export XDG_CACHE_HOME="$tmp/cache"   # fresh cross-checks: no cached s(CASP) results
cp -rL "$lib_src"/. "$tmp/lib/"
cp "$module" "$tmp/lib/modules/discovery.pl"
swipl "$here/emit_variants.pl" "$here/../fixtures/discovery-a" "$tmp/v" || exit 1

ORBIT_KB_LIB="$tmp/lib" python3 -I - "$tmp/v" <<'EOF'
import os, re, subprocess, sys
vdir = sys.argv[1]

def cli(kb, *args):
    return subprocess.run(["orbit-kb", "--dir", kb, *args], capture_output=True, text=True)

fails = skips = notes = total = 0
note_rules = set()
for name in ["base"] + sorted(d for d in os.listdir(vdir) if os.path.isdir(os.path.join(vdir, d)) and d != "base"):
    kb = os.path.join(vdir, name)
    lint = cli(kb, "lint")
    core_errors = sorted(set(re.findall(r"\bE[0-9]+\b", lint.stdout + lint.stderr)))
    module_codes = sorted(set(re.findall(r"\b[WE]D[0-9]+\b", lint.stdout)))
    lint_ok = not core_errors and lint.returncode in (0, 1) and (lint.returncode == 0 or module_codes)
    if name == "base":
        lint_ok = lint_ok and lint.returncode == 0 and not module_codes
    fails += not lint_ok
    print(f"== {name}  lint exit {lint.returncode}  core E codes {core_errors or 'none'}  module codes {module_codes or 'none'}{'' if lint_ok else '  FAIL'}")
    for line in open(os.path.join(vdir, name + ".tsv")):
        goal, ans = line.rstrip("\n").split("\t")
        want = ans if ans in ("true", "none") else sorted(set(ans.split("|")))
        r = cli(kb, "query", goal, "-n", "0")
        lines = [l.removesuffix(" (unchecked)").strip() for l in r.stdout.splitlines() if l.strip()]
        if r.returncode == 1 and lines in ([], ["false"]):
            got = "none"
        elif r.returncode == 0 and lines and all(l == "true" for l in lines):
            got = "true"
        elif r.returncode == 0:
            got = sorted(set(lines))
        else:
            got = f"exit {r.returncode}: {r.stdout.strip()} {r.stderr.strip()[-300:]}"
        if "ENGINE DISAGREEMENT" in r.stderr:
            got = "ENGINE DISAGREEMENT: " + r.stderr.strip()[-300:]
        skipped = "CROSS-CHECK SKIPPED" in r.stderr
        noted = [l for l in r.stderr.splitlines() if l.startswith("NOTE")]
        skips += skipped
        notes += bool(noted)
        note_rules.update(noted)
        ok = got == want
        fails += not ok
        total += 1
        flag = ("  (unchecked)" if skipped else "") + ("  " + " | ".join(noted) if noted else "")
        print(f"  {'ok  ' if ok else 'FAIL'}  {goal}  want {want}  got {got}{flag}")
print(f"\ncli_variants: {total} expectations, {fails} failed (answers and lint), "
      f"{skips} cross-checks skipped, {notes} queries with a NOTE")
for n in sorted(note_rules):
    print("  " + n)
sys.exit(1 if fails else 0)
EOF
