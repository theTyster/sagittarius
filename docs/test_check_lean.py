#!/usr/bin/env python3
"""Tests of docs/check_lean.py (Sagittarius 0.3.0, package L-A: claims c_l_a_1, c_l_a_2, c_l_a_3).

Each test copies the script and the files it reads into a scratch tree, changes one thing, and runs
the script there. A change that breaks a promise must make the script fail. The tree itself must pass.

Usage: python3 docs/test_check_lean.py [-k NAME]      (unittest; needs Lean 4 through elan)
The tests of "proofs" build Lake projects with no packages: they need no network.
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPT = "docs/check_lean.py"
PHIL = "docs/PHILOSOPHY.md"


def lean_path():
    with open(os.path.join(ROOT, PHIL), encoding="utf-8") as f:
        m = re.search(r"`([^`]*Hypothesis\.lean)`", f.read())
    return m.group(1) if m else None


def run(root, *args, timeout=900):
    r = subprocess.run([sys.executable, "-B", os.path.join(root, SCRIPT), *args], cwd=root,
                       capture_output=True, text=True, timeout=timeout)
    return r.returncode, r.stdout + r.stderr


class Tree:
    """A scratch copy of the files the script reads (sources only, never .lake)."""

    def __init__(self, d, projects=()):
        self.root = os.path.join(d, "tree")
        files = [SCRIPT, PHIL, lean_path()]
        for rel in files:
            self.copy(rel)
        for name in projects:
            src = os.path.join(ROOT, "kb", "proofs", name)
            for n in os.listdir(src):
                if n != ".lake" and os.path.isfile(os.path.join(src, n)):
                    self.copy(os.path.join("kb", "proofs", name, n))

    def copy(self, rel):
        dst = os.path.join(self.root, rel)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copy2(os.path.join(ROOT, rel), dst)

    def append(self, rel, text):
        with open(os.path.join(self.root, rel), "a", encoding="utf-8") as f:
            f.write(text)

    def replace(self, rel, old, new):
        p = os.path.join(self.root, rel)
        with open(p, encoding="utf-8") as f:
            t = f.read()
        assert old in t, f"{old!r} not in {rel}"
        with open(p, "w", encoding="utf-8") as f:
            f.write(t.replace(old, new, 1))


class Hypothesis(unittest.TestCase):
    def test_tree_passes_and_prints_the_count(self):
        rc, out = run(ROOT, "hypothesis")
        self.assertEqual(rc, 0, out)
        self.assertIn("68 theorems", out)

    def test_axiom_fails(self):
        with tempfile.TemporaryDirectory() as d:
            t = Tree(d)
            t.append(lean_path(), "\naxiom cheat : False\ntheorem bad_one : 1 = 2 := cheat.elim\n")
            rc, out = run(t.root, "hypothesis")
            self.assertNotEqual(rc, 0, out)
            self.assertIn("cheat", out)

    def test_standard_axiom_fails(self):
        # The philosophy says that no theorem uses an axiom: propext counts too.
        with tempfile.TemporaryDirectory() as d:
            t = Tree(d)
            t.append(lean_path(), "\ntheorem uses_propext (a b : Prop) (h : a ↔ b) : a = b := propext h\n")
            t.replace(PHIL, "and 68 theorems", "and 69 theorems")
            rc, out = run(t.root, "hypothesis")
            self.assertNotEqual(rc, 0, out)
            self.assertIn("propext", out)

    def test_sorry_fails(self):
        with tempfile.TemporaryDirectory() as d:
            t = Tree(d)
            t.append(lean_path(), "\ntheorem not_done : 1 = 2 := sorry\n")
            t.replace(PHIL, "and 68 theorems", "and 69 theorems")
            rc, out = run(t.root, "hypothesis")
            self.assertNotEqual(rc, 0, out)
            self.assertIn("sorryAx", out)

    def test_one_theorem_more_fails(self):
        with tempfile.TemporaryDirectory() as d:
            t = Tree(d)
            t.append(lean_path(), "\ntheorem extra_one : True := trivial\n")
            rc, out = run(t.root, "hypothesis")
            self.assertNotEqual(rc, 0, out)
            self.assertIn("69", out)

    def test_count_in_the_philosophy_is_the_source(self):
        with tempfile.TemporaryDirectory() as d:
            t = Tree(d)
            t.replace(PHIL, "and 68 theorems", "and 67 theorems")
            rc, out = run(t.root, "hypothesis")
            self.assertNotEqual(rc, 0, out)

    def test_lean_error_fails(self):
        with tempfile.TemporaryDirectory() as d:
            t = Tree(d)
            t.append(lean_path(), "\ntheorem broken : 1 = 2 := rfl\n")
            t.replace(PHIL, "and 68 theorems", "and 69 theorems")
            rc, out = run(t.root, "hypothesis")
            self.assertNotEqual(rc, 0, out)

    def test_the_file_is_not_changed(self):
        p = os.path.join(ROOT, lean_path())
        before = open(p, "rb").read()
        run(ROOT, "hypothesis")
        self.assertEqual(before, open(p, "rb").read())


class Names(unittest.TestCase):
    def test_tree_passes(self):
        rc, out = run(ROOT, "names")
        self.assertEqual(rc, 0, out)
        self.assertRegex(out, r"\b33\b")

    def test_renamed_cited_theorem_fails(self):
        with tempfile.TemporaryDirectory() as d:
            t = Tree(d)
            t.replace(lean_path(), "theorem proper_with_no_judgments", "theorem proper_with_no_judgments_x")
            rc, out = run(t.root, "names")
            self.assertNotEqual(rc, 0, out)
            self.assertIn("proper_with_no_judgments", out)

    def test_a_new_citation_must_exist(self):
        with tempfile.TemporaryDirectory() as d:
            t = Tree(d)
            t.replace(PHIL, "| `proper_with_no_judgments` |", "| `proper_with_no_judgments`, `no_such_theorem` |")
            rc, out = run(t.root, "names")
            self.assertNotEqual(rc, 0, out)
            self.assertIn("no_such_theorem", out)

    def test_a_def_is_not_a_theorem(self):
        with tempfile.TemporaryDirectory() as d:
            t = Tree(d)
            t.replace(lean_path(), "theorem proper_with_no_judgments", "def proper_with_no_judgments")
            rc, out = run(t.root, "names")
            self.assertNotEqual(rc, 0, out)

    def test_file_not_at_the_cited_path_fails(self):
        with tempfile.TemporaryDirectory() as d:
            t = Tree(d)
            os.remove(os.path.join(t.root, lean_path()))
            rc, out = run(t.root, "names")
            self.assertNotEqual(rc, 0, out)
            self.assertIn("Hypothesis.lean", out)


class Proofs(unittest.TestCase):
    def test_list_names_the_three_projects(self):
        rc, out = run(ROOT, "proofs", "--list")
        self.assertEqual(rc, 0, out)
        for name in ("state_cache", "question_server", "project_archive"):
            self.assertIn(f"kb/proofs/{name}", out)

    def test_list_finds_a_new_project(self):
        with tempfile.TemporaryDirectory() as d:
            t = Tree(d, projects=("question_server",))
            src = os.path.join(t.root, "kb", "proofs", "question_server")
            shutil.copytree(src, os.path.join(t.root, "kb", "proofs", "another_one"))
            rc, out = run(t.root, "proofs", "--list")
            self.assertEqual(rc, 0, out)
            self.assertIn("kb/proofs/another_one", out)

    def test_tree_passes(self):
        rc, out = run(ROOT, "proofs")
        self.assertEqual(rc, 0, out)
        for name in ("state_cache", "question_server", "project_archive"):
            self.assertIn(f"kb/proofs/{name}", out)

    def _mutant(self, text):
        with tempfile.TemporaryDirectory() as d:
            t = Tree(d, projects=("question_server",))
            t.append("kb/proofs/question_server/QuestionServer.lean", text)
            return run(t.root, "proofs")

    def test_axiom_fails(self):
        rc, out = self._mutant("\naxiom cheat : False\ntheorem bad_one : 1 = 2 := cheat.elim\n")
        self.assertNotEqual(rc, 0, out)
        self.assertIn("cheat", out)

    def test_sorry_fails(self):
        rc, out = self._mutant("\ntheorem not_done : 1 = 2 := sorry\n")
        self.assertNotEqual(rc, 0, out)
        self.assertIn("sorryAx", out)

    def test_native_decide_fails(self):
        rc, out = self._mutant("\ntheorem by_compiler : 2 + 2 = 4 := by native_decide\n")
        self.assertNotEqual(rc, 0, out)
        self.assertIn("ofReduceBool", out)

    def test_build_error_fails(self):
        rc, out = self._mutant("\ntheorem broken : 1 = 2 := rfl\n")
        self.assertNotEqual(rc, 0, out)


if __name__ == "__main__":
    unittest.main()
