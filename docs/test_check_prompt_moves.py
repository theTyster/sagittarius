#!/usr/bin/env python3
"""Tests of docs/check_prompt_moves.py c4 (review of 0.3.0, finding 10).

A "help general" row reads the CLI file kb/bin/orbit-kb. Only a known partial copy of the tree (no
kb/bin and no .git: the copy that the docs checks make) may skip those rows, and the skip is loud:
the result line counts it. In a checkout, a missing CLI file is a failure.

Usage: python3 -m unittest docs.test_check_prompt_moves      (or python3 docs/test_check_prompt_moves.py)
"""
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPT = "docs/check_prompt_moves.py"
PARTS = ["docs", "prompt", "s1", "kb/share/orbit-kb/help"]


def copy(dst, with_git):
    for rel in PARTS:
        shutil.copytree(os.path.join(ROOT, rel), os.path.join(dst, rel),
                        ignore=shutil.ignore_patterns("__pycache__", "*.pyc", "philosophy-orbit"))
    if with_git:
        with open(os.path.join(dst, ".git"), "w") as f:
            f.write("gitdir: /nonexistent\n")  # a worktree has a .git file


def run(root, *args):
    return subprocess.run([sys.executable, "-B", os.path.join(root, SCRIPT), "--only", "c4", *args],
                          cwd=root, capture_output=True, text=True, stdin=subprocess.DEVNULL, timeout=60)


class Skip(unittest.TestCase):
    def setUp(self):
        d = tempfile.TemporaryDirectory()
        self.addCleanup(d.cleanup)
        self.dir = d.name

    def test_the_tree_passes(self):
        r = run(ROOT)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertNotIn("skipped", r.stdout)

    def test_a_checkout_with_no_cli_fails(self):
        copy(self.dir, with_git=True)
        r = run(self.dir)
        self.assertEqual(r.returncode, 1, r.stdout + r.stderr)
        self.assertIn("help general", r.stdout)

    def test_a_partial_copy_skips_loudly(self):
        copy(self.dir, with_git=False)
        r = run(self.dir)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        first = r.stdout.splitlines()[0]
        self.assertRegex(first, r"c4 PASS: \d+ present, [1-9]\d* skipped")
        self.assertIn("partial copy", r.stderr)

    def test_a_named_cli_that_is_missing_fails(self):
        copy(self.dir, with_git=False)
        r = run(self.dir, "--cli", os.path.join(self.dir, "no-such-cli"))
        self.assertEqual(r.returncode, 1, r.stdout + r.stderr)


if __name__ == "__main__":
    unittest.main()
