#!/usr/bin/env python3
"""Tests of docs/check_terms.py (Sagittarius 0.3.0, claim c_sg5b, suggestion 5).

The check keeps each term to one meaning in the texts that an agent reads: the prompt, the pane
prompts, the help topics of orbit-kb, and the hub's text under hubkit/. A retired term fails the
check, and the failure names the file, the line, the retired term and the right term.

Usage: python3 -m unittest docs.test_check_terms      (or python3 docs/test_check_terms.py)
"""
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPT = "docs/check_terms.py"
PARTS = ["docs", "prompt", "hubkit", "kb/share/orbit-kb/help"]


def copy(dst):
    for rel in PARTS:
        shutil.copytree(os.path.join(ROOT, rel), os.path.join(dst, rel), symlinks=True,
                        ignore=shutil.ignore_patterns("__pycache__", "*.pyc", ".lake", "philosophy-orbit"))


def run(root):
    return subprocess.run([sys.executable, "-B", os.path.join(root, SCRIPT)], cwd=root,
                          capture_output=True, text=True, stdin=subprocess.DEVNULL, timeout=60)


def append(root, rel, text):
    with open(os.path.join(root, rel), "a", encoding="utf-8") as f:
        f.write(text)


def line_of_append(root, rel, line):
    """The line number that `line` gets when append() writes "\n" + line + "\n"."""
    with open(os.path.join(root, rel), encoding="utf-8") as f:
        return len((f.read() + "\n" + line).splitlines())


class Terms(unittest.TestCase):
    def setUp(self):
        d = tempfile.TemporaryDirectory()
        self.addCleanup(d.cleanup)
        self.dir = d.name
        copy(self.dir)

    def fails_with(self, rel, line, *words):
        n = line_of_append(self.dir, rel, line)
        append(self.dir, rel, "\n" + line + "\n")
        r = run(self.dir)
        self.assertEqual(r.returncode, 1, r.stdout + r.stderr)
        self.assertIn(f"{rel}:{n}", r.stdout)
        for w in words:
            self.assertIn(w, r.stdout)
        self.assertNotIn("Traceback", r.stdout + r.stderr)
        return r.stdout

    def test_the_tree_passes(self):
        r = run(ROOT)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)

    def test_the_copy_passes(self):
        r = run(self.dir)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)

    def test_trigger_in_a_pane_prompt(self):
        # the example of the claim: the check names the file and the right term
        self.fails_with("prompt/PANES.md", "- A handoff is a trigger: read the record.", '"trigger"', '"signal"')

    def test_lean_model_in_a_help_topic(self):
        self.fails_with("kb/share/orbit-kb/help/build.txt", "Write a Lean model of the behavior.",
                        '"Lean model"', "Lean definitions")

    def test_scoped_in_the_hub_text(self):
        self.fails_with("hubkit/hub/HUB-CORE.md", "The hypothesis is scoped to the report.", '"scoped"', "wide")

    def test_the_phase_tree_in_a_pane_prompt(self):
        self.fails_with("prompt/panes/discovery.md", 'See "The phase tree".', '"The phase tree"', '"Scope"')

    def test_the_move_signal_in_a_help_topic(self):
        self.fails_with("kb/share/orbit-kb/help/discovery.txt", "SIGNAL: pin the report", '"SIGNAL"', "RESTATE")

    def test_the_prompt_is_read(self):
        self.fails_with("prompt/SAGITTARIUS.md", "A handoff is a trigger.", '"trigger"')

    def test_the_word_signal_is_not_the_move(self):
        append(self.dir, "prompt/PANES.md", "\nA signal is not the move; a Signal either.\n")
        r = run(self.dir)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)

    def test_a_line_that_names_the_rename_is_history(self):
        append(self.dir, "kb/share/orbit-kb/help/discovery.txt", "\nRESTATE was renamed from SIGNAL in 0.3.0.\n")
        r = run(self.dir)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)

    def test_a_text_outside_the_list_is_not_read(self):
        append(self.dir, "docs/REFINING.md", "\nIt names the trigger in its own words.\n")
        r = run(self.dir)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)

    def test_no_text_found_is_a_failure(self):
        shutil.rmtree(os.path.join(self.dir, "kb"))
        r = run(self.dir)
        self.assertEqual(r.returncode, 1, r.stdout + r.stderr)
        self.assertIn("help", r.stdout)


if __name__ == "__main__":
    unittest.main()
