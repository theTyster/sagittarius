#!/usr/bin/env python3
"""Tests of docs/check_examples.py (Sagittarius 0.3.0, claim c_sg4b, suggestion 4).

The prompt gives each sentence of its worked examples a verdict (Fit, Too strong, Collapsed, ...).
Wherever such a sentence appears, it must have that verdict: in Hypothesis.lean (c1), in
`orbit-kb help discovery` (c2), in the philosophy (c3), and in the recording of s1/temper.py (c4).

Usage: python3 -m unittest docs.test_check_examples      (or python3 docs/test_check_examples.py)
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPT = "docs/check_examples.py"
PARTS = ["docs", "prompt", "s1", "kb/share/orbit-kb/help"]
P = "prompt/SAGITTARIUS.md"
HELP = "kb/share/orbit-kb/help/discovery.txt"
REC = "s1/fixtures/loopcal_trio.json"
FIT = "The amount of a purchase and the member's tier on that day decide its points."
CAUSE = "The tier is read from a cache that loads once."
VAGUE = "Points depend on something other than the purchase."
FINDING = "Some purchases get a different number."


def copy(dst):
    for rel in PARTS:
        shutil.copytree(os.path.join(ROOT, rel), os.path.join(dst, rel), symlinks=True,
                        ignore=shutil.ignore_patterns("__pycache__", "*.pyc", ".lake"))


def run(root, *ids):
    return subprocess.run([sys.executable, "-B", os.path.join(root, SCRIPT), *ids], cwd=root,
                          capture_output=True, text=True, stdin=subprocess.DEVNULL, timeout=60)


def step(statement, collapsed, adds="nothing", faithful=True):
    judge = {"collapsed": collapsed, "faithful": faithful}
    adds = {"j_adds": {"type": "choice", "choice": adds}}
    return {"statement": statement, "falsifier": "a case", "sonnet": judge, "jev": adds}


class Examples(unittest.TestCase):
    def setUp(self):
        d = tempfile.TemporaryDirectory()
        self.addCleanup(d.cleanup)
        self.dir = d.name
        copy(self.dir)

    def edit(self, rel, old, new):
        p = os.path.join(self.dir, rel)
        with open(p, encoding="utf-8") as f:
            t = f.read()
        self.assertIn(old, t)
        with open(p, "w", encoding="utf-8") as f:
            f.write(t.replace(old, new, 1))

    def record(self, *steps):
        with open(os.path.join(self.dir, REC), "w", encoding="utf-8") as f:
            json.dump({"c1": {"source": "Members got the wrong loyalty points.", "steps": list(steps)}}, f)

    def fails(self, ids, *words):
        r = run(self.dir, *ids)
        self.assertEqual(r.returncode, 1, r.stdout + r.stderr)
        self.assertNotIn("Traceback", r.stdout + r.stderr)
        for w in words:
            self.assertIn(w, r.stdout)
        return r.stdout

    def passes(self, ids):
        r = run(self.dir, *ids)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)

    # -- the tree
    def test_lean_help_and_philosophy_agree_with_the_prompt_in_the_tree(self):
        r = run(ROOT, "c1", "c2", "c3")
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)

    def test_list(self):
        r = run(ROOT, "--list")
        self.assertEqual(r.stdout.split(), ["c1", "c2", "c3", "c4"])

    # -- the prompt is the source of the verdict
    def test_the_prompt_calls_the_cause_fit(self):
        self.edit(P, f'- Too strong: "{CAUSE}"', f'- Fit: "{CAUSE}"')
        out = self.fails(["c1"], "Hypothesis.lean", CAUSE)
        self.assertIn("fit", out.lower())
        self.fails(["c2"], "discovery.txt")
        self.fails(["c3"], "PHILOSOPHY.md")

    def test_no_example_in_the_prompt_is_a_failure(self):
        self.edit(P, f'- Fit: "{FIT}"', "- Fit: (removed)")
        self.edit(P, f'- Too strong: "{CAUSE}"', "- Too strong: (removed)")
        self.edit(P, f'- Collapsed: "{VAGUE}"', "- Collapsed: (removed)")
        self.fails(["c1"])

    # -- c1: the Lean file
    def test_the_lean_label_disagrees(self):
        lean = "docs/philosophy-orbit/2026-11-11/fable/Hypothesis.lean"
        self.edit(lean, f'/-- Collapsed: "{VAGUE}"', f'/-- Fit: "{VAGUE}"')
        self.fails(["c1"], VAGUE)

    def test_the_lean_theorem_disagrees(self):
        lean = "docs/philosophy-orbit/2026-11-11/fable/Hypothesis.lean"
        self.edit(lean, "theorem vague_collapsed : Collapsed vagueHyp.req", "theorem vague_collapsed : True")
        self.fails(["c1"], VAGUE)

    # -- c2: the help
    def test_the_help_puts_the_finding_inside_the_fit_sentence(self):
        self.edit(HELP, f'- Fit: "{FIT}"', f'- Fit: "{FIT} {FINDING}"')
        self.fails(["c2"], "discovery.txt", "finding")

    def test_the_help_calls_the_vague_sentence_fit(self):
        self.edit(HELP, f'- Collapsed: "{VAGUE}"', f'- Fit: "{VAGUE}"')
        self.fails(["c2"], VAGUE)

    # -- c4: the recording of temper.py
    def test_a_recording_that_agrees_passes(self):
        self.record(step(FIT, False), step(CAUSE, False, adds="mechanism"), step(VAGUE, True, adds="cause"))
        self.passes(["c4"])

    def test_the_recording_calls_the_fit_sentence_collapsed(self):
        self.record(step(FIT, True))
        self.fails(["c4"], "temper", FIT)

    def test_the_recording_adds_a_cause_to_the_fit_sentence(self):
        self.record(step(FIT, False, adds="cause"))
        self.fails(["c4"], FIT)

    def test_the_recording_accepts_the_finding_inside(self):
        self.record(step(FIT + " " + FINDING, False))
        self.fails(["c4"], "finding")

    def test_the_recording_rejects_the_finding_inside(self):
        self.record(step(FIT + " " + FINDING, True))
        self.passes(["c4"])

    def test_the_recording_calls_the_cause_fit(self):
        self.record(step(CAUSE, False))
        self.fails(["c4"], CAUSE)


if __name__ == "__main__":
    unittest.main()
