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
# The version in the tree now, so the VERSION mutant case applies at every release (it was "0.3.0").
VERSION_NOW = open(os.path.join(ROOT, "VERSION"), encoding="utf-8").read().strip()
COPY = ["docs", "prompt", "hubkit", "kb/share/orbit-kb/help", "kb/share/orbit-kb/core.pl", "kb/share/orbit-kb/vocabulary.json",
        "kb/CONTRACT.md", "README.md",
        "CLAUDE.md", "CHANGELOG.md", "VERSION", "s1"]
P = "prompt/SAGITTARIUS.md"
CASES = [
    (["docs/check_consistency.py", "c1"], P, "- **Effort:**", "**Effort:**", "five bullets under Signals"),
    (["docs/check_consistency.py", "c9"], P, "more than 0.5", "more than 0.4", "the vote needs 0.4"),
    (["docs/check_consistency.py", "c9"], P, "\n## The vote\n", "\n## The ballot\n", "no heading The vote (a failure, not a stop)"),
    (["docs/check_words.py", "c2"], P, "Oscillation is an intentional heuristic", "Oscillation is a habit", "no oscillation sentence"),
    (["docs/check_words.py", "c2"], P, "\n## The vote\n", "\n## The ballot\n", "a section that a principle names is gone"),
    (["docs/check_hub_guidance.py", "c5"], P, "`orbit show\nopen`", "`orbit lint`", "the prompt does not name orbit show open"),
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
    (["docs/check_version.py"], "VERSION", VERSION_NOW, "9.9.9", "VERSION disagrees with the prompt"),
    # docs/check_mindhole.py (review finding 5, kit3): the MindHole checks can fail too
    (["docs/check_mindhole.py", "mg2"], "hubkit/README.md", "The **MindHole Kit** is the template that makes a hub",
     "The **MindHole Kit** is the hub", "the kit README says the MindHole Kit is the hub"),
    # scientific-method-overhaul c22: the kit names no release with no tool, and the check can fail
    (["docs/check_kit_release.py", "c2"], "hubkit/hub/HUB-CORE.md", "## Panes\n", "## Without orbit-kb\n\nA hub with no tool.\n\n## Panes\n",
     "HUB-CORE.md has a section Without orbit-kb again"),
    # 0.3.0 c_sg5b: a retired term in a text that an agent reads
    (["docs/check_terms.py"], "prompt/PANES.md", "A handoff is a signal", "A handoff is a trigger",
     "PANES.md calls a handoff a trigger (the term is signal)"),
    # 0.3.0 c_sg4b: the prompt gives the sentence with a cause another verdict than the Lean file and the help
    (["docs/check_examples.py", "c1"], P, '- Too strong: "The tier is read from a cache that loads once."',
     '- Fit: "The tier is read from a cache that loads once."', "the prompt calls the sentence with a cause Fit (Lean)"),
    (["docs/check_examples.py", "c2"], P, '- Too strong: "The tier is read from a cache that loads once."',
     '- Fit: "The tier is read from a cache that loads once."', "the prompt calls the sentence with a cause Fit (help)"),
    # 0.8.0 scientific-method-overhaul c12: a hand edit of one copy of the vocabulary
    (["docs/check_vocabulary.py", "panes"], "prompt/PANES.md", "It names no avenue.", "It names one avenue.",
     "a hand edit of the goal sentence in PANES.md"),
    (["docs/check_vocabulary.py", "prompt"], P, "meets, conflicts, or unresolved.\n- A hypothesis is tempered",
     "meets or conflicts.\n- A hypothesis is tempered", "a hand edit of the verdict sentence in the prompt"),
    (["docs/check_vocabulary.py", "help"], "kb/share/orbit-kb/help/core.txt", "how we think we will get there",
     "how we will get there", "a hand edit of the hypothesis sentence in help core"),
    (["docs/check_vocabulary.py", "temper"], "s1/temper.py", "when one admissible case can demonstrate", "when a case can demonstrate",
     "a hand edit of TEMPERED_DEFINITION"),
    (["docs/check_vocabulary.py", "desk"], "kb/share/orbit-kb/vocabulary.json", "A claim is a prediction", "A claim is a wish",
     "a hand edit of the Desk copy"),
    (["docs/check_vocabulary.py", "principles"], "hubkit/hub/PRINCIPLES.md", "<!-- vocabulary:end -->", "",
     "the block of PRINCIPLES.md lost its end marker"),
    # 0.8.0 scientific-method-overhaul: the phrase tests of the method (docs/check_method_texts.py)
    (["docs/check_method_texts.py", "c7"], P, "An unresolved\n  verdict fulfils nothing, defeats nothing, and keeps its claim open.", "",
     "the unresolved rule is gone"),
    (["docs/check_method_texts.py", "c9"], P, "Before you reopen anything, locate\nthe conflict", "Reopen the hypothesis",
     "the prompt does not locate first"),
    (["docs/check_method_texts.py", "c10"], P, "the case defeats the\n  hypothesis that allowed it, not the build", "the build is wrong",
     "a not-wanted case with every claim meeting blames the build"),
    (["docs/check_method_texts.py", "c11"], "kb/share/orbit-kb/help/discovery.txt", "It is the statement of the intent",
     "It is your closest statement of the intent", "the old definition is back in help discovery"),
    (["docs/check_method_texts.py", "c13"], P, "formalize the\nsmallest claim whose precision", "formalize each claim whose precision",
     "the one rule of formal language lost its words"),
    (["docs/check_method_texts.py", "c14"], P, "say that they are yours\n  (\"Goal (mine): ... Hypothesis (mine): ...\")", "show them",
     "the agent does not say that its drafts are its own"),
    (["docs/check_method_texts.py", "c15"], "prompt/panes/build.md", "record\n  the new goal in the words of the human: it supersedes the old one",
     "restate the hypothesis", "build.md tells build to restate the hypothesis"),
    (["docs/check_method_texts.py", "c16"], P, "Existing behavior is presumed to be\npreserved.", "Existing behavior is preserved.",
     "Sound Basis is not in the words of Ty"),
    (["docs/check_method_texts.py", "c45"], P, "7. The ticket does not end at the delivery.", "7. Ask the human to adopt the hypothesis.\n8. The ticket does not end at the delivery.",
     "the light path has an eighth Build step"),
    (["docs/check_panes.py", "--only", "c5"], "prompt/panes/discovery.md", "Re-evaluate the goal, the premises and the\n  measurement, and temper a new hypothesis",
     "Ask build", "discovery does not temper a new hypothesis"),
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
