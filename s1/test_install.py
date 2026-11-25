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

    def test_the_signals_plugin_link(self):
        """specs/s1-glance c1 (Ty): the Sagittarius Signals mod loads in every session, from s1/glance."""
        r = self.install()
        self.assertEqual(r.returncode, 0, r.stderr)
        link = os.path.join(self.home, ".claude", "skills", "s1-glance")
        self.assertTrue(os.path.islink(link))
        self.assertEqual(os.path.realpath(link), os.path.realpath(os.path.join(HERE, "glance")))
        self.assertTrue(os.path.isfile(os.path.join(link, ".claude-plugin", "plugin.json")))
        self.assertTrue(os.path.isfile(os.path.join(link, "hooks", "hooks.json")))
        r = self.install("--check")
        self.assertRegex(r.stdout, r"ok +\S*skills.s1-glance")

    def test_the_desk_toast_link(self):
        """spec KB desk-letter-toast c9 (Ty: "link it like s1-glance"): the Desk toast mod loads in every
        session, from its source beside desk.py."""
        r = self.install()
        self.assertEqual(r.returncode, 0, r.stderr)
        link = os.path.join(self.home, ".claude", "skills", "desk-toast")
        self.assertTrue(os.path.islink(link))
        src = os.path.join(ROOT, "hubkit", "hub", ".claude", "scripts", "desk-toast")
        self.assertEqual(os.path.realpath(link), os.path.realpath(src))
        self.assertTrue(os.path.isfile(os.path.join(os.path.dirname(src), "desk.py")))
        self.assertTrue(os.path.isfile(os.path.join(link, ".claude-plugin", "plugin.json")))
        self.assertTrue(os.path.isfile(os.path.join(link, "hooks", "hooks.json")))
        r = self.install("--check")
        self.assertRegex(r.stdout, r"ok +\S*skills.desk-toast")

    def test_each_link_names_its_module_and_version(self):
        """spec KB module-versions c2: install.py and --check print, beside each link, the module that it
        installs and that module's version (from MODULES.json), e.g. `ok ~/.claude/skills/s1-glance (s1-glance 0.14.0)`."""
        import json
        def ver(rel, key=None):
            text = read(rel)
            return json.loads(text)[key] if key else text.strip()
        sag = ver("VERSION")
        want = {
            os.path.join(".local", "bin", "orbit-kb"): ("orbit-kb", sag),
            os.path.join(".local", "bin", "orbit"): ("orbit-kb", sag),
            os.path.join(".local", "share", "orbit-kb"): ("orbit-kb", sag),
            os.path.join(".claude", "sagittarius"): ("sagittarius", sag),
            os.path.join(".claude", "sagittarius-s1"): ("system-1", sag),
            os.path.join(".claude", "skills", "s1-glance"): ("s1-glance", ver("s1/glance/.claude-plugin/plugin.json", "version")),
            os.path.join(".claude", "skills", "desk-toast"):
                ("desk-toast", ver("hubkit/hub/.claude/scripts/desk-toast/.claude-plugin/plugin.json", "version")),
        }
        for args in ((), ("--check",)):
            r = self.install(*args)
            self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
            for rel, (name, v) in want.items():
                line = [ln for ln in r.stdout.splitlines() if ln.split()[1:2] == [os.path.join(self.home, rel)]]
                self.assertEqual(len(line), 1, (rel, r.stdout))
                self.assertTrue(line[0].endswith(f"({name} {v})"), (line, name, v))

    def test_a_wrong_link_names_the_version_there(self):
        """spec KB module-versions c2, c7 (Ty, q1: s1-glance stays on the workbench): --check names the
        version and whether the files are this checkout's, for a link that points to another tree."""
        import json, shutil
        self.install()
        other = os.path.join(self.home, "wb", "s1", "glance")
        shutil.copytree(os.path.join(HERE, "glance"), other, ignore=shutil.ignore_patterns("node_modules"))
        pj = os.path.join(other, ".claude-plugin", "plugin.json")
        meta = json.loads(open(pj, encoding="utf-8").read())
        meta["version"] = "0.0.1"
        with open(pj, "w", encoding="utf-8") as f:
            json.dump(meta, f)
        link = os.path.join(self.home, ".claude", "skills", "s1-glance")
        os.remove(link)
        os.symlink(other, link)
        r = self.install("--check")
        self.assertEqual(r.returncode, 1)
        self.assertIn(f"wrong    {link} -> {other} (s1-glance 0.0.1 there, not the files of this checkout)", r.stdout)

    def test_readme_names_the_links(self):
        flat = " ".join(read("README.md").split())
        self.assertNotIn("four links", flat)
        self.assertIn("~/.claude/sagittarius-s1", flat)
        self.assertIn("~/.claude/skills/desk-toast", flat)


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
