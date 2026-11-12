#!/usr/bin/env python3
"""0.3.0 D-A: each docs check that holds the new texts must FAIL when the thing that it holds is gone.

For each case, the check runs twice on a scratch copy of the tree: first unchanged, where it must
pass (a check that fails there cannot show the change), then with one sentence or heading changed,
where it must fail. The copy holds only the files that the docs checks read. A check that still passes on
its case is a quiet check (it cannot fail), and this script fails.

Usage: python3 docs/check_mutants.py
Exit 0: every check passed on the unchanged copy and failed on its case. Exit 1: one failed on the\nunchanged copy, passed on its case, or a case did not apply.
"""
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
COPY = ["docs", "prompt", "hubkit", "kb/share/orbit-kb/help", "kb/share/orbit-kb/core.pl", "README.md",
        "CLAUDE.md", "CHANGELOG.md", "VERSION", "s1"]
P = "prompt/SAGITTARIUS.md"
CASES = [
    (["docs/check_consistency.py", "c1"], P, "- **Effort:**", "**Effort:**", "five bullets under Signals"),
    (["docs/check_consistency.py", "c9"], P, "more than 0.5", "more than 0.4", "the vote needs 0.4"),
    (["docs/check_consistency.py", "c9"], P, "\n## The vote\n", "\n## The ballot\n", "no heading The vote (a failure, not a stop)"),
    (["docs/check_words.py", "c2"], P, "Oscillation is an intentional heuristic", "Oscillation is a habit", "no oscillation sentence"),
    (["docs/check_words.py", "c2"], P, "\n## The vote\n", "\n## The ballot\n", "a section that a principle names is gone"),
    (["docs/check_hub_guidance.py", "c5"], P, "`orbit-kb show\nopen`", "`orbit-kb lint`", "the prompt does not name orbit-kb show open"),
    (["docs/check_hub_fixes.py", "t31c9"], P, "Err toward the general and soft", "Err toward the exact", "no err-soft sentence"),
    (["docs/check_prompt_small.py"], P, "Signals:     <questions", "Triggers:    <questions", "no Signals: field in the delivery block"),
    (["docs/check_prompt_small.py"], P, "Formal:      <the formal statement", "Form:        <the formal statement", "no Formal: field"),
    (["docs/check_prompt_small.py"], P, "A check that cannot fail is not evidence", "A check is evidence", "a rule of Honesty is gone"),
    (["docs/check_prompt_small.py"], P, "\n## Honesty\n", "\n## Manners\n", "no Honesty heading"),
    (["docs/check_version.py"], "VERSION", "0.3.0", "9.9.9", "VERSION disagrees with the prompt"),
]


def main():
    bad = 0
    with tempfile.TemporaryDirectory() as d:
        for i, (cmd, rel, old, new, what) in enumerate(CASES):
            root = os.path.join(d, str(i))
            for r in COPY:
                src, dst = os.path.join(ROOT, r), os.path.join(root, r)
                if os.path.isdir(src):
                    shutil.copytree(src, dst, ignore=shutil.ignore_patterns("__pycache__", "*.pyc"), symlinks=True)
                elif os.path.isfile(src):
                    os.makedirs(os.path.dirname(dst), exist_ok=True)
                    shutil.copy2(src, dst)
            label = " ".join(cmd)
            base = subprocess.run([sys.executable, "-B"] + cmd, cwd=root, capture_output=True, text=True)
            if base.returncode != 0:
                print(f"FAIL {label} fails on the unchanged copy, so its failure on the case ({what}) shows nothing")
                bad += 1
                continue
            p = os.path.join(root, rel)
            t = open(p, encoding="utf-8").read()
            if old not in t:
                print(f"FAIL case did not apply ({' '.join(cmd)}: {what}): {old!r} is not in {rel}")
                bad += 1
                continue
            open(p, "w", encoding="utf-8").write(t.replace(old, new, 1))
            r = subprocess.run([sys.executable, "-B"] + cmd, cwd=root, capture_output=True, text=True)
            if r.returncode == 0:
                print(f"FAIL {' '.join(cmd)} passes on a copy where {what}")
                bad += 1
            elif "Traceback" in r.stdout + r.stderr:
                print(f"FAIL {' '.join(cmd)} stops with a traceback on a copy where {what}")
                bad += 1
            else:
                print(f"ok   {label} passes unchanged, fails where {what}")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
