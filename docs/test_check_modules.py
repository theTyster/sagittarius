#!/usr/bin/env python3
"""Tests of docs/check_modules.py (spec KB module-versions, claim c6).

Each module that Sagittarius ships has one version in its source; MODULES.json at the repo root
names the file that holds it and the files the module covers. The check fails when the files of a
module differ from the last release tag and its version is not higher than there.

Each case builds a small git repo with a tag v1.0.0, changes it, and runs the check there.

Usage: python3 -m unittest docs.test_check_modules      (or python3 docs/test_check_modules.py)
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

MODULES = {"modules": [
    {"name": "core", "version": "VERSION", "covers": ["core"]},
    {"name": "tool", "version": "VERSION", "covers": ["tool"], "except": ["tool/mod"]},
    {"name": "mod", "version": "tool/mod/plugin.json#version", "covers": ["tool/mod"]},
]}


def git(d, *a):
    subprocess.run(["git", "-C", d, *a], check=True, capture_output=True, text=True)


def write(d, rel, text):
    p = os.path.join(d, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, "w", encoding="utf-8") as f:
        f.write(text)


class CheckModules(unittest.TestCase):
    def setUp(self):
        self.d = tempfile.mkdtemp(prefix="check-modules-")
        os.makedirs(os.path.join(self.d, "docs"))
        shutil.copy(os.path.join(ROOT, "docs", "check_modules.py"), os.path.join(self.d, "docs"))
        shutil.copy(os.path.join(ROOT, "modules.py"), self.d)
        git(self.d, "init", "-q", "-b", "main")
        git(self.d, "config", "user.email", "t@example.invalid")
        git(self.d, "config", "user.name", "t")
        write(self.d, "MODULES.json", json.dumps(MODULES))
        write(self.d, "VERSION", "1.0.0\n")
        write(self.d, "core/a.txt", "a\n")
        write(self.d, "tool/b.txt", "b\n")
        write(self.d, "tool/mod/plugin.json", json.dumps({"name": "mod", "version": "0.1.0"}))
        write(self.d, "tool/mod/c.txt", "c\n")
        self.commit("release 1.0.0")
        git(self.d, "tag", "v1.0.0")
        git(self.d, "tag", "v0.9.0-experiment")  # not a release tag: the check ignores it

    def tearDown(self):
        shutil.rmtree(self.d, ignore_errors=True)

    def commit(self, msg):
        git(self.d, "add", "-A")
        git(self.d, "commit", "-q", "-m", msg)

    def run_check(self):
        return subprocess.run([sys.executable, "-B", os.path.join(self.d, "docs", "check_modules.py")],
                              cwd=self.d, capture_output=True, text=True, stdin=subprocess.DEVNULL, timeout=60)

    def assertPass(self):
        r = self.run_check()
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        return r.stdout

    def assertFail(self, *words):
        r = self.run_check()
        self.assertEqual(r.returncode, 1, r.stdout + r.stderr)
        for w in words:
            self.assertIn(w, r.stdout)
        return r.stdout

    def test_unchanged_passes(self):
        out = self.assertPass()
        self.assertIn("v1.0.0", out)

    def test_changed_same_version_fails(self):
        write(self.d, "tool/mod/c.txt", "c2\n")
        self.commit("change mod")
        self.assertFail("FAIL", "mod", "0.1.0", "v1.0.0")

    def test_changed_higher_version_passes(self):
        write(self.d, "tool/mod/c.txt", "c2\n")
        write(self.d, "tool/mod/plugin.json", json.dumps({"name": "mod", "version": "0.2.0"}))
        self.commit("change mod, bump")
        self.assertPass()

    def test_lower_version_fails(self):
        write(self.d, "core/a.txt", "a2\n")
        write(self.d, "VERSION", "0.9.9\n")
        self.commit("lower")
        self.assertFail("FAIL", "core", "0.9.9")

    def test_shared_version_file(self):
        # tool reads VERSION too: a change of tool needs VERSION higher, and then core passes as well
        write(self.d, "tool/b.txt", "b2\n")
        self.commit("change tool")
        self.assertFail("tool")
        write(self.d, "VERSION", "1.1.0\n")
        self.commit("bump")
        self.assertPass()

    def test_except_is_not_the_parent(self):
        # a change under tool/mod is mod's, not tool's: tool keeps its version and passes
        write(self.d, "tool/mod/c.txt", "c2\n")
        write(self.d, "tool/mod/plugin.json", json.dumps({"name": "mod", "version": "0.1.1"}))
        self.commit("change mod only")
        out = self.assertPass()
        self.assertNotIn("FAIL", out)

    def test_version_through_a_link(self):
        # a version file that is a symbolic link (as kb/share/orbit-kb/VERSION is) is read at the tag too
        m = json.loads(open(os.path.join(self.d, "MODULES.json")).read())
        m["modules"].append({"name": "linked", "version": "lk/VERSION", "covers": ["lk"]})
        os.makedirs(os.path.join(self.d, "lk"))
        os.symlink("../VERSION", os.path.join(self.d, "lk", "VERSION"))
        write(self.d, "MODULES.json", json.dumps(m))
        self.commit("linked version")
        git(self.d, "tag", "v1.0.1")
        write(self.d, "lk/x.txt", "x\n")
        self.commit("change linked")
        self.assertFail("linked", "1.0.0", "v1.0.1")

    def test_new_module_passes(self):
        m = json.loads(open(os.path.join(self.d, "MODULES.json")).read())
        m["modules"].append({"name": "fresh", "version": "fresh/plugin.json#version", "covers": ["fresh"]})
        write(self.d, "MODULES.json", json.dumps(m))
        write(self.d, "fresh/plugin.json", json.dumps({"version": "0.1.0"}))
        self.commit("new module")
        self.assertPass()

    def test_module_with_no_version_fails(self):
        m = json.loads(open(os.path.join(self.d, "MODULES.json")).read())
        m["modules"].append({"name": "bare", "version": "bare/VERSION", "covers": ["bare"]})
        write(self.d, "MODULES.json", json.dumps(m))
        write(self.d, "bare/x.txt", "x\n")
        self.commit("module with no version file")
        self.assertFail("FAIL", "bare")

    def test_versions_listing(self):
        r = subprocess.run([sys.executable, "-B", os.path.join(self.d, "modules.py")], cwd=self.d,
                           capture_output=True, text=True, timeout=60)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(r.stdout.split("\n")[:3], ["core 1.0.0", "tool 1.0.0", "mod 0.1.0"])


class RealModules(unittest.TestCase):
    def test_every_shipped_module_is_listed(self):
        names = [m["name"] for m in json.load(open(os.path.join(ROOT, "MODULES.json")))["modules"]]
        for n in ("sagittarius", "orbit-kb", "system-1", "mindhole-kit", "s1-glance", "desk-toast"):
            self.assertIn(n, names)


if __name__ == "__main__":
    unittest.main()
