"""Variant-kill matrix for module mutants (LANDING review).

Same parsing as scratch/review/mut/run_mutants.py, but it records every expectation line
that changed, so each mutant maps to the set of variants that kill it.

Usage (run from a root that holds harness/run.pl, the review copy, and
modules/discovery.pl, the module under test):
    python3 -I run_mutants_matrix.py FIXTURE_DIR OUT_JSON MUT_DIR [MUT_DIR ...]
"""
import json
import os
import subprocess
import sys

ROOT = os.getcwd()
FIXTURE, OUT, MUT_DIRS = sys.argv[1], sys.argv[2], sys.argv[3:]


def run(module_path):
    env = dict(os.environ, SWI_ONLY="1", DISC_MODULE=module_path)
    p = subprocess.run(["swipl", "harness/run.pl", FIXTURE], cwd=ROOT, env=env,
                       capture_output=True, text=True, timeout=300)
    lines = p.stdout.splitlines()
    start = next(i for i, l in enumerate(lines) if l.startswith("== base"))
    variant, answers = None, set()
    for l in lines[start:]:
        if l.startswith("== "):
            variant = l[3:]
            continue
        if l.startswith("SWI engine:"):
            break
        s = l.strip()
        if s.startswith("lint:") or (len(s) > 2 and s[0] in "EW" and s[1].isdigit()):
            continue
        if s.startswith("H3 check") or s.startswith("ENGINE") or s.startswith("scasp:"):
            continue
        answers.add((variant, s))
    return answers


base = run(os.path.join(ROOT, "modules/discovery.pl"))
result = {}
for d in MUT_DIRS:
    with open(os.path.join(d, "index.txt")) as f:
        for line in f:
            mid, op, clause, lit = line.rstrip("\n").split("\t")
            got = run(os.path.join(d, mid + ".pl"))
            changed = sorted({v for (v, s) in got - base} | {v for (v, s) in base - got})
            result[mid] = {"op": op, "clause": clause, "detail": lit, "killed_by": changed}
with open(OUT, "w") as f:
    json.dump(result, f, indent=1)
print(f"{len(result)} mutants; {sum(1 for r in result.values() if r['killed_by'])} killed")
