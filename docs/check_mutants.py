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
    # each delivery field and each rule sentence of the prompt has a key phrase (review finding 4)
    (["docs/check_prompt_small.py"], P, 'KB:          <"No KB"', 'Store:       <"No KB"', "no KB: field"),
    (["docs/check_prompt_small.py"], P, "Guesses:     <defaults", "Hunches:     <defaults", "no Guesses: field"),
    (["docs/check_prompt_small.py"], P, "Disclosures: <unverified", "Notes:       <unverified", "no Disclosures: field"),
    (["docs/check_prompt_small.py"], P, "Claims:      <each claim", "Results:     <each claim", "no Claims: field"),
    (["docs/check_prompt_small.py"], P, ' Never state a\n   bounded result as "always" or "never".', "", "the bounded-result rule is gone"),
    (["docs/check_prompt_small.py"], P, '"Tests pass" does not mean "correct". ', "", "the tests-pass rule is gone"),
    (["docs/check_prompt_small.py"], P, " A lead does not block readiness.", "", "the lead rule is gone"),
    (["docs/check_prompt_small.py"], P, "In a KB,\nrecord the waiver as the human's. ", "", "the record-the-waiver rule is gone"),
    (["docs/check_prompt_small.py"], P, "Include a screenshot when the change has a user\nsurface. ", "", "the screenshot rule is gone"),
    (["docs/check_prompt_small.py"], P, " Ask at most\nthree questions a round.", "", "the three-questions rule is gone"),
    (["docs/check_prompt_small.py"], P, "Do not edit a KB file by hand. ", "", "the no-hand-edit rule is gone"),
    (["docs/check_prompt_small.py"], P, "Seal your vote before the report. ", "", "the seal-the-vote rule is gone"),
    (["docs/check_prompt_small.py"], P, "- discovery: research, specify.", "- discovery: explore.", "the phases of discovery are gone"),
    (["docs/check_prompt_small.py"], P, "- build: build, verify.", "- build: make.", "the phases of build are gone"),
    (["docs/check_prompt_small.py"], P, "significant effort or verbosity from the human", "a long message", "the effort signal lost its words"),
    # c4 holds the route of a report in PANES.md, not four words anywhere in it (review finding 5)
    (["docs/check_consistency.py", "c4"], "prompt/PANES.md",
     "Intake is where new work starts: it finds the ticket that a\n  report is about and hands the report to the pane that holds it; a report with no ticket it\n  judges (regression or gap) and sends to discovery. ",
     "", "the intake routing sentence of review is gone"),
    (["docs/check_consistency.py", "c4"], "prompt/PANES.md",
     "- The usual path: review (intake: the ticket, or regression or gap), then research -> specify -> build -> verify.\n",
     "", "the usual-path line is gone"),
    (["docs/check_version.py"], "VERSION", "0.3.0", "9.9.9", "VERSION disagrees with the prompt"),
    # docs/check_mindhole.py (review finding 5, kit3): the MindHole checks can fail too
    (["docs/check_mindhole.py", "mg2"], "hubkit/README.md", "The **MindHole Kit** is the template that makes a hub",
     "The **MindHole Kit** is the hub", "the kit README says the MindHole Kit is the hub"),
    (["docs/check_mindhole.py", "mb7"], "hubkit/editions/informal/.claude/skills/hub-flow/SKILL.md",
     '$HF note T-0002 "vote: GO: ', '$HF note T-0002 "ballot: ', "the informal skill lost the vote note"),
    # 0.3.0 c_sg5b: a retired term in a text that an agent reads
    (["docs/check_terms.py"], "prompt/PANES.md", "A handoff is a signal", "A handoff is a trigger",
     "PANES.md calls a handoff a trigger (the term is signal)"),
    # 0.3.0 c_sg4b: the prompt gives the sentence with a cause another verdict than the Lean file and the help
    (["docs/check_examples.py", "c1"], P, '- Too strong: "The tier is read from a cache that loads once."',
     '- Fit: "The tier is read from a cache that loads once."', "the prompt calls the sentence with a cause Fit (Lean)"),
    (["docs/check_examples.py", "c2"], P, '- Too strong: "The tier is read from a cache that loads once."',
     '- Fit: "The tier is read from a cache that loads once."', "the prompt calls the sentence with a cause Fit (help)"),
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
