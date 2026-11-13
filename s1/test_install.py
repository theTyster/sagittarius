"""Tests for the install of the System 1 hook (0.3.0 S-D: c_s_d_1, c_s_d_2b, c_s_d_3). No network.
install.py runs only with a scratch HOME. Nothing here writes a settings file.

Run from the repo root:  python3 -m unittest s1.test_install -v
"""
import os
import re
import subprocess
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
INSTALL = os.path.join(ROOT, "install.py")


def read(rel):
    with open(os.path.join(ROOT, rel), encoding="utf-8") as f:
        return f.read()


def section(text, title):
    """The Markdown section whose heading is TITLE, to the next heading (code fences skipped)."""
    out, on, fence = [], False, False
    for ln in text.splitlines():
        if ln.lstrip().startswith("```"):
            fence = not fence
        head = not fence and re.match(r"#+ ", ln)
        if head and on:
            break
        if head and re.match(r"#+ +" + re.escape(title) + r"\s*$", ln):
            on = True
        if on:
            out.append(ln)
    return "\n".join(out)


class InstallLink(unittest.TestCase):
    """c_s_d_1: install.py links s1/ to ~/.claude/sagittarius-s1, and no script writes settings.json."""

    def setUp(self):
        d = tempfile.TemporaryDirectory()
        self.addCleanup(d.cleanup)
        self.home = os.path.join(d.name, "home")
        os.makedirs(self.home)
        self.env = {k: v for k, v in os.environ.items() if not k.startswith("XDG_")}
        self.env["HOME"] = self.home
        self.env["USERPROFILE"] = self.home

    def install(self, *args):
        return subprocess.run([sys.executable, "-I", INSTALL, *args], env=self.env, capture_output=True,
                              text=True, stdin=subprocess.DEVNULL, timeout=60)

    def test_the_hook_link(self):
        r = self.install()
        self.assertEqual(r.returncode, 0, r.stderr)
        link = os.path.join(self.home, ".claude", "sagittarius-s1")
        self.assertTrue(os.path.islink(link))
        self.assertEqual(os.path.realpath(link), os.path.realpath(HERE))
        self.assertTrue(os.path.isfile(os.path.join(link, "hook.py")))
        self.assertTrue(os.path.isfile(os.path.join(link, "statusline.py")))

    def test_check_reports_the_hook_link(self):
        r = self.install("--check")
        self.assertEqual(r.returncode, 1)
        self.assertIn("missing", r.stdout)
        self.assertIn("sagittarius-s1", r.stdout)
        self.install()
        r = self.install("--check")
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertRegex(r.stdout, r"ok +\S*sagittarius-s1")

    def test_the_prompt_link_stays(self):
        self.install()
        self.assertTrue(os.path.islink(os.path.join(self.home, ".claude", "sagittarius")))

    def test_no_settings_file(self):
        self.install()
        for root, _, files in os.walk(self.home):
            self.assertFalse([f for f in files if f.startswith("settings")], root)
        self.assertNotIn("settings", read("install.py"))

    def test_the_installed_hook_runs_from_the_link(self):
        self.install()
        hook = os.path.join(self.home, ".claude", "sagittarius-s1", "hook.py")
        env = dict(self.env, S1_OFF="1")
        r = subprocess.run([sys.executable, hook], input="{}", env=env, capture_output=True, text=True, timeout=60)
        self.assertEqual((r.returncode, r.stdout, r.stderr), (0, "", ""))

    def test_readme_names_the_links(self):
        flat = " ".join(read("README.md").split())
        self.assertNotIn("four links", flat)
        self.assertIn("~/.claude/sagittarius-s1", flat)


class InstallSequence(unittest.TestCase):
    """c_s_d_2b: README.md "Install" holds a sequence for an agent: link, the shell function, one
    session, ask it for the last line of its prompt."""

    def setUp(self):
        self.sec = section(read("README.md"), "Install")
        self.flat = " ".join(self.sec.split())

    def test_order_of_the_steps(self):
        self.assertIn("shell function", self.flat)
        pos = [self.flat.find(w) for w in ("./install.py", "--append-system-prompt", "start one session", "last line")]
        self.assertTrue(all(p >= 0 for p in pos), pos)
        self.assertEqual(pos, sorted(pos))

    def test_for_an_agent(self):
        self.assertRegex(self.flat, r"(?i)\bagent\b")

    def test_names_the_answer_from_the_prompt(self):
        lines = [ln for ln in read("prompt/SAGITTARIUS.md").splitlines() if ln.strip()]
        m = re.search(r"Sagittarius \d+\.\d+\.\d+", lines[-1])
        self.assertIsNotNone(m, lines[-1])
        self.assertIn(m.group(0), self.flat)

    def test_bash_zsh_and_fish(self):
        for shell in ("bash", "zsh", "fish"):
            self.assertIn(shell, self.flat)

    def test_the_hook_stays_a_paste(self):
        self.assertIn("No script writes `settings.json`", self.flat)


class ReleaseSaysRunAgain(unittest.TestCase):
    """c_s_d_3: a release that adds a link says "run ./install.py again"."""

    def test_changelog_entry(self):
        # The claim binds only a release that adds a link (0.4.0 adds none). Each Sagittarius
        # entry that says install.py makes a link says "Run ./install.py again"; at least one does.
        c = read("CHANGELOG.md")
        entries = re.findall(r"\n## Sagittarius [^\n]*.*?(?=\n## |\Z)", c, re.S)
        adds = [e for e in entries if re.search(r"`install\.py` makes a [^.]*link", " ".join(e.split()))]
        self.assertTrue(adds, "no Sagittarius entry says that install.py makes a link")
        for e in adds:
            self.assertRegex(e, r"Run `\./install\.py` again", e.splitlines()[1])

    def test_readme_says_run_again_after_an_update(self):
        self.assertRegex(" ".join(read("README.md").split()), r"(?i)run `\./install\.py` again")


if __name__ == "__main__":
    unittest.main()
