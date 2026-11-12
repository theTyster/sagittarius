#!/usr/bin/env python3
"""Tests of docs/check_mutants.py (Sagittarius 0.3.0, package D-A).

A mutant case counts only when its check passes on the unchanged copy and fails on the mutant.
A check that fails on both copies cannot fail because of the mutation: it is a quiet check.

Usage: python3 -m unittest docs.test_check_mutants      (or python3 docs/test_check_mutants.py)
"""
import contextlib
import io
import os
import sys
import unittest
from unittest import mock

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import check_mutants  # noqa: E402

P = "prompt/SAGITTARIUS.md"
ALWAYS_FAILS = ["-c", "import sys; sys.exit(1)"]
ALWAYS_PASSES = ["-c", "import sys; sys.exit(0)"]


def run(cases):
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf), mock.patch.object(check_mutants, "CASES", cases):
        rc = check_mutants.main()
    return rc, buf.getvalue()


class Baseline(unittest.TestCase):
    def test_a_check_that_always_fails_is_not_ok(self):
        rc, out = run([(ALWAYS_FAILS, P, "\n## Honesty\n", "\n## Manners\n", "no Honesty heading")])
        self.assertEqual(rc, 1, out)
        self.assertIn("unchanged copy", out)
        self.assertNotIn("ok ", out)

    def test_a_check_that_always_passes_is_not_ok(self):
        rc, out = run([(ALWAYS_PASSES, P, "\n## Honesty\n", "\n## Manners\n", "no Honesty heading")])
        self.assertEqual(rc, 1, out)

    def test_a_real_case_passes_then_fails(self):
        rc, out = run([(["docs/check_prompt_small.py"], P, "\n## Honesty\n", "\n## Manners\n", "no Honesty heading")])
        self.assertEqual(rc, 0, out)
        self.assertIn("ok ", out)


if __name__ == "__main__":
    unittest.main()
