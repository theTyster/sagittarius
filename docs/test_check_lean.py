#!/usr/bin/env python3
"""Tests of docs/check_lean.py (Sagittarius 0.3.0, package L-A: claims c_l_a_1, c_l_a_2, c_l_a_3;
the class ScientificMethod: scientific-method-overhaul, claim c25).

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
SM = "kb/proofs/scientific_method/ScientificMethod.lean"


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

    def __init__(self, d, projects=(), files=()):
        self.root = os.path.join(d, "tree")
        files = [SCRIPT, PHIL, lean_path(), *files]
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
        with open(p, "rb") as f:
            before = f.read()
        run(ROOT, "hypothesis")
        with open(p, "rb") as f:
            self.assertEqual(before, f.read())


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
        # Lean 4.35 states the result of the compiler as an axiom of its own (by_compiler._native...).
        self.assertIn("by_compiler", out)

    def test_build_error_fails(self):
        rc, out = self._mutant("\ntheorem broken : 1 = 2 := rfl\n")
        self.assertNotEqual(rc, 0, out)


class ScientificMethod(unittest.TestCase):
    """c25: the Lean file of the handoff has no sorry and no axiom of its own, and holds the nine theorems."""

    NAMED = ("unique_verdict", "conflict_rejects_joint", "agreement_establishes_run", "Timer.reading_600",
             "Timer.reading_611", "Timer.reading_615", "Timer.late_run_refutes_universal",
             "Statistical.equal_likelihood_no_preference", "revision_preserves_record")
    # The last line of the file closes the namespace: a mutant adds its text before that line.
    END = "\nend ScientificMethod\n"

    def _mutant(self, old, new):
        with tempfile.TemporaryDirectory() as d:
            t = Tree(d, files=(SM,))
            t.replace(SM, old, new)
            return run(t.root, "scientific")

    def _added(self, text):
        return self._mutant(self.END, "\n" + text + self.END)

    def test_tree_passes_and_counts_the_nine_theorems(self):
        rc, out = run(ROOT, "scientific")
        self.assertEqual(rc, 0, out)
        self.assertIn("9 of the 9 named theorems", out)
        self.assertNotIn("FAIL", out)

    def test_a_copy_passes(self):
        # The mutants below fail by their change, not because the copy is a copy.
        with tempfile.TemporaryDirectory() as d:
            rc, out = run(Tree(d, files=(SM,)).root, "scientific")
            self.assertEqual(rc, 0, out)

    def test_the_check_names_each_of_the_nine(self):
        with open(os.path.join(ROOT, SCRIPT), encoding="utf-8") as f:
            script = f.read()
        for n in self.NAMED:
            self.assertIn(f'"ScientificMethod.{n}"', script)

    def test_sorry_in_a_named_theorem_fails(self):
        rc, out = self._mutant("  exact ⟨⟨610, by decide, by decide⟩, ⟨612, by decide, by decide⟩⟩\n", "  sorry\n")
        self.assertNotEqual(rc, 0, out)
        self.assertIn("ScientificMethod.Timer.reading_611 uses the axiom(s) sorryAx", out)

    def test_sorry_in_a_new_theorem_fails(self):
        rc, out = self._added("theorem not_done : 1 = 2 := sorry")
        self.assertNotEqual(rc, 0, out)
        self.assertIn("ScientificMethod.not_done uses the axiom(s) sorryAx", out)

    def test_sorry_in_a_theorem_that_a_named_theorem_uses_fails(self):
        # late_run_refutes_universal rests on reading_615: the sorry shows on both.
        rc, out = self._mutant("  intro t ht ok\n  unfold withinError at ht\n  unfold timely at ok\n  omega\n",
                               "  sorry\n")
        self.assertNotEqual(rc, 0, out)
        self.assertIn("ScientificMethod.Timer.late_run_refutes_universal uses the axiom(s) sorryAx", out)

    def test_sorry_in_an_example_fails(self):
        # An example leaves no declaration: the check reads Lean's own warning.
        rc, out = self._added("example : 1 = 2 := sorry")
        self.assertNotEqual(rc, 0, out)
        self.assertIn("Lean reports a sorry", out)

    def test_axiom_that_a_theorem_uses_fails(self):
        rc, out = self._added("axiom cheat : False\ntheorem bad_one : 1 = 2 := cheat.elim")
        self.assertNotEqual(rc, 0, out)
        self.assertIn("declares the axiom ScientificMethod.cheat", out)
        self.assertIn("ScientificMethod.bad_one uses the axiom(s) ScientificMethod.cheat", out)

    def test_axiom_that_nothing_uses_fails(self):
        rc, out = self._added("axiom every_run_meets : ∀ v : Verdict, v = .meets")
        self.assertNotEqual(rc, 0, out)
        self.assertIn("declares the axiom ScientificMethod.every_run_meets", out)

    def test_native_decide_fails(self):
        rc, out = self._added("theorem by_compiler : 2 + 2 = 4 := by native_decide")
        self.assertNotEqual(rc, 0, out)
        self.assertIn("by_compiler", out)

    def test_standard_axioms_pass(self):
        # unique_verdict is classical: the three axioms of Lean's own logic are not axioms of the file.
        rc, out = self._added("theorem uses_propext (a b : Prop) (h : a ↔ b) : a = b := propext h")
        self.assertEqual(rc, 0, out)
        self.assertIn("10 theorems", out)

    def test_a_named_theorem_that_is_gone_fails(self):
        rc, out = self._mutant("theorem unique_verdict ", "theorem unique_verdict_x ")
        self.assertNotEqual(rc, 0, out)
        self.assertIn("declares no theorem ScientificMethod.unique_verdict", out)

    def test_a_def_is_not_a_theorem(self):
        rc, out = self._mutant("theorem revision_preserves_record ", "def revision_preserves_record ")
        self.assertNotEqual(rc, 0, out)
        self.assertIn("declares no theorem ScientificMethod.revision_preserves_record", out)

    def test_lean_error_fails(self):
        rc, out = self._added("theorem broken : 1 = 2 := rfl")
        self.assertNotEqual(rc, 0, out)
        self.assertIn("Lean rejects", out)

    def test_file_not_in_the_repository_fails(self):
        with tempfile.TemporaryDirectory() as d:
            t = Tree(d, files=(SM,))
            os.remove(os.path.join(t.root, SM))
            rc, out = run(t.root, "scientific")
            self.assertNotEqual(rc, 0, out)
            self.assertIn("ScientificMethod.lean is not in the repository", out)

    def test_the_file_is_not_changed_and_no_build_folder_is_left(self):
        p = os.path.join(ROOT, SM)
        with open(p, "rb") as f:
            before = f.read()
        run(ROOT, "scientific")
        with open(p, "rb") as f:
            self.assertEqual(before, f.read())
        self.assertEqual(sorted(os.listdir(os.path.dirname(p))), ["README.md", "ScientificMethod.lean"])


if __name__ == "__main__":
    unittest.main()
