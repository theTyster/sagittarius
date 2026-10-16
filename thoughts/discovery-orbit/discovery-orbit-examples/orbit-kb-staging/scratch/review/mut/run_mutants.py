"""Run the review copy of the harness (SWI engine only) for each module mutant.

Usage: python3 -I mut/run_mutants.py FIXTURE_DIR MUT_DIR OUT_FILE
Run from scratch/review. A mutant is killed when any expectation line (verdict or the
printed answer) differs from the run with the unmutated module. Lint-only changes are
reported separately.
"""
import os
import subprocess
import sys

ROOT = os.getcwd()
FIXTURE, MUT_DIR, OUT = sys.argv[1], sys.argv[2], sys.argv[3]


def run(module_path):
    env = dict(os.environ, SWI_ONLY="1", DISC_MODULE=module_path)
    p = subprocess.run(["swipl", "harness/run.pl", FIXTURE], cwd=ROOT, env=env,
                       capture_output=True, text=True, timeout=300)
    lines = p.stdout.splitlines()
    start = next(i for i, l in enumerate(lines) if l.startswith("== base"))
    body = lines[start:]
    variant = None
    answers, lint = [], []
    for l in body:
        if l.startswith("== "):
            variant = l[3:]
            continue
        if l.startswith("SWI engine:"):
            break
        s = l.strip()
        if s.startswith("lint:") or (len(s) > 2 and s[0] in "EW" and s[1].isdigit()):
            lint.append(f"{variant}: {s}")
        elif s.startswith("H3 check") or s.startswith("ENGINE") or s.startswith("scasp:"):
            continue
        else:
            answers.append(f"{variant}: {s}")
    return answers, lint, p.stderr


base_answers, base_lint, err = run(os.path.join(ROOT, "modules/discovery.pl"))
index = {}
with open(os.path.join(MUT_DIR, "index.txt")) as f:
    for line in f:
        mid, op, clause, lit = line.rstrip("\n").split("\t")
        index[mid] = (op, clause, lit)

out = []
survivors = []
for mid in sorted(index):
    op, clause, lit = index[mid]
    answers, lint, err = run(os.path.join(ROOT, MUT_DIR, mid + ".pl"))
    changed = [a for a in answers if a not in base_answers]
    lint_changed = [l for l in lint if l not in base_lint]
    status = "KILLED" if changed else ("LINT-ONLY" if lint_changed else "SURVIVED")
    if status != "KILLED":
        survivors.append(mid)
    out.append(f"{mid}\t{status}\t{op}\t{clause}\t{lit}")
    for c in changed[:3]:
        out.append(f"      by {c}")
    for c in lint_changed[:2]:
        out.append(f"      lint {c}")

with open(OUT, "w") as f:
    f.write("\n".join(out) + "\n")
    f.write(f"\n{len(index)} mutants, {len(index) - len(survivors)} killed by an answer, "
            f"{len(survivors)} not killed by any answer\n")
print(f"{len(index)} mutants, {len(survivors)} not killed by any answer")
