#!/usr/bin/env python3
"""Offline tests of the eval harness and of the eval specs. No model call, no credential.

Usage: python3 evals/test_evals.py
Never reads evals/heldout/. The leak check runs on a copy that holds the tuning specs only.
"""
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import grade_tools as g  # noqa: E402


def load(name):
    with open(os.path.join(HERE, name), encoding="utf-8") as f:
        return json.load(f)["evals"]


PLAN, TOOLS = load("evals.json"), load("tools.json")
by_plan = {c["id"]: c for c in PLAN}
by_tools = {c["id"]: c for c in TOOLS}
NEW_CASES = ["hypothesis-with-premises", "wide-default", "kept-changed", "adds-on-top-new-ticket",
             "typo-no-kb", "formal-beside-plain", "edge-case-shown"]
words = lambda t: re.findall(r"[a-z0-9']+", t.lower())


def texts(case):
    return case.get("turns") or [case.get("prompt", "")]


class RunShPrompt(unittest.TestCase):
    """evals/run.sh --prompt FILE reaches the claude command line. A stub claude() in a fake
    ~/.zshenv records its arguments, so no model runs."""

    def run_sh(self, *args):
        tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, tmp, True)
        ev = os.path.join(tmp, "evals")
        os.makedirs(ev)
        for f in ("run.sh", "evals.json"):
            shutil.copy(os.path.join(HERE, f), ev)
        home = os.path.join(tmp, "home")
        os.makedirs(home)
        log = os.path.join(tmp, "args.log")
        with open(os.path.join(home, ".zshenv"), "w") as f:
            f.write('claude-personal() { return 0 }\nclaude() { printf "%s\\0" "$@" > "$STUB_LOG"; print stub answer }\n')
        with open(os.path.join(tmp, "p.md"), "w") as f:
            f.write("PROMPT-COPY-WITHOUT-ONE-RULE\nsecond line")
        env = dict(os.environ, HOME=home, STUB_LOG=log)
        p = subprocess.run(["zsh", os.path.join(ev, "run.sh"), *[a.replace("@P", os.path.join(tmp, "p.md")) for a in args]],
                           capture_output=True, text=True, env=env, cwd=tmp, timeout=60)
        argv = open(log, encoding="utf-8").read().split("\0")[:-1] if os.path.exists(log) else None
        return p, argv

    def test_prompt_file_is_appended(self):
        p, argv = self.run_sh("--prompt", "@P", "1")
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertIn("--append-system-prompt", argv)
        self.assertEqual(argv[argv.index("--append-system-prompt") + 1], "PROMPT-COPY-WITHOUT-ONE-RULE\nsecond line")
        self.assertIn("Sometimes the Export button", argv[-1])  # the eval prompt is still the last argument

    def test_prompt_none_appends_a_blank(self):
        p, argv = self.run_sh("--prompt", "none", "1")
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertEqual(argv[argv.index("--append-system-prompt") + 1], " ")

    def test_missing_prompt_file_is_refused_before_any_call(self):
        p, argv = self.run_sh("--prompt", "/no/such/file.md", "1")
        self.assertEqual(p.returncode, 2, p.stderr)
        self.assertIsNone(argv)

    def test_no_option_leaves_the_live_prompt_to_claude(self):
        p, argv = self.run_sh("1")
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertNotIn("--append-system-prompt", argv)


class CheckLeaksReadsPlanningEvals(unittest.TestCase):
    """check_leaks.py reads evals.json as well as tools.json. It runs in a temporary git repo
    that holds the tuning specs only, so it never sees the held-out set."""

    def leaks(self, spec, case_id):
        tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, tmp, True)
        os.makedirs(os.path.join(tmp, "evals"))
        os.makedirs(os.path.join(tmp, "prompt"))
        for f in ("check_leaks.py", "tools.json", "evals.json"):
            shutil.copy(os.path.join(HERE, f), os.path.join(tmp, "evals"))
        git = lambda *a: subprocess.run(["git", "-C", tmp, "-c", "user.name=t", "-c", "user.email=t@t", *a], capture_output=True, text=True, check=True)
        git("init", "-q")
        pf = os.path.join(tmp, "prompt", "SAGITTARIUS.md")
        open(pf, "w").write("A base prompt.\n")
        git("add", "-A")
        git("commit", "-qm", "base")
        case = (by_plan if spec == "evals.json" else by_tools)[case_id]
        w = words(texts(case)[0])
        open(pf, "a").write("A rule that copies " + " ".join(w[5:10]) + " from a case.\n")
        p = subprocess.run([sys.executable, os.path.join(tmp, "evals", "check_leaks.py")], capture_output=True, text=True, cwd=tmp)
        return p

    def test_tools_overlap_is_found(self):
        p = self.leaks("tools.json", 4)
        self.assertEqual(p.returncode, 1, p.stdout + p.stderr)

    def test_planning_overlap_is_found(self):
        p = self.leaks("evals.json", 2)
        self.assertEqual(p.returncode, 1, p.stdout + p.stderr)
        self.assertIn("eval 2:", p.stdout)


class NoExampleOfThePrompt(unittest.TestCase):
    EXAMPLES = ("dark mode", "dark-mode", "loyalty", "reports page")

    def test_no_case_uses_an_example_of_the_prompt(self):
        for c in PLAN + TOOLS:
            for t in texts(c):
                for ex in self.EXAMPLES:
                    self.assertNotIn(ex, t.lower(), f"case {c['id']} {c['name']} uses the prompt's example {ex!r}")

    def test_new_cases_share_no_four_word_run_with_the_prompt(self):
        prompt = " " + " ".join(words(open(os.path.join(ROOT, "prompt", "SAGITTARIUS.md"), encoding="utf-8").read())) + " "
        for c in PLAN + TOOLS:
            if c["name"] not in NEW_CASES:
                continue
            for t in texts(c):
                w = words(t)
                for i in range(len(w) - 3):
                    self.assertNotIn(" " + " ".join(w[i:i + 4]) + " ", prompt, f"case {c['name']} copies the prompt")


class WhatThePromptChanged(unittest.TestCase):
    def test_planning_9_has_no_tools_and_asks_for_no_command(self):
        c = by_plan[9]
        self.assertNotIn("command", c["prompt"].lower())
        self.assertFalse([a for a in c["assertions"] + c["fails"] if "command" in a.lower() or "--by" in a])
        self.assertNotIn("orbit-kb", c["expected_output"])

    def test_change_of_plan_is_a_supersession(self):
        for i in (16, 17, 20):
            checks = by_tools[i]["checks"]
            self.assertNotIn("query:divergence_recorded", checks, f"tool eval {i}")
            self.assertTrue([k for k in checks if k.startswith("query:") and "supersedes" in k], f"tool eval {i} asks for no supersession")
            a = " ".join(by_tools[i]["assertions"])
            self.assertNotRegex(a, r"(?i)records? the divergence", f"tool eval {i}")
            self.assertIn("supersedes", a)

    def test_notes_of_5_18_19_follow_the_default(self):
        for i in (5, 18, 19):
            self.assertRegex(by_tools[i].get("notes", ""), r"supersession", f"tool eval {i}")

    def test_notes_of_21_do_not_send_the_agent_back_to_discovery(self):
        self.assertNotIn("go back to discovery", json.dumps(by_tools[21]))

    def test_no_lean_model_wording(self):
        self.assertNotIn("Lean model", json.dumps(PLAN) + json.dumps(TOOLS))

    @unittest.skipUnless(shutil.which("swipl"), "needs swipl")
    def test_the_supersession_query_can_fail_and_can_pass(self):
        q = [k for k in by_tools[16]["checks"] if "supersedes" in k][0][len("query:"):]
        env = dict(os.environ, PATH=os.path.join(ROOT, "kb", "bin") + os.pathsep + os.environ["PATH"])
        tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, tmp, True)
        run = lambda *a, cwd=tmp: subprocess.run(["orbit-kb", *a], capture_output=True, text=True, env=env, cwd=cwd)
        run("init", "kb", "--request", "x", "--uses", "build")
        kb = os.path.join(tmp, "kb")
        run("add", "claim(c1, introduce, 'a')", "cites(c1,'x')", "example(c1,'e')", "check(k1,c1)", cwd=kb)
        self.assertEqual(run("query", q, cwd=kb).returncode, 1)
        run("add", "claim(c2, introduce, 'b')", "supersedes(c2,c1)", "cites(c2,'x')", "example(c2,'e')", "check(k2,c2)", cwd=kb)
        self.assertEqual(run("query", q, cwd=kb).returncode, 0)


class NewCases(unittest.TestCase):
    def case(self, name):
        found = [c for c in PLAN + TOOLS if c["name"] == name]
        self.assertEqual(len(found), 1, f"{name}: {len(found)} cases")
        return found[0]

    def test_each_new_case_exists_with_assertions_that_can_fail(self):
        for n in NEW_CASES:
            c = self.case(n)
            self.assertGreaterEqual(len(c["assertions"]), 3, n)
            if c in PLAN:
                self.assertTrue(c.get("fails") and c.get("expected_output") and c.get("area"), n)
            else:
                self.assertTrue(c["checks"] and c["fixture"], n)
                self.assertTrue(os.path.isdir(os.path.join(HERE, "fixtures", c["fixture"])), n)

    def test_ids_are_unique(self):
        for cases in (PLAN, TOOLS):
            ids = [c["id"] for c in cases]
            self.assertEqual(len(ids), len(set(ids)))

    def test_planning_prompts_do_not_name_the_step(self):
        for n in NEW_CASES:
            c = self.case(n)
            if c in PLAN:
                self.assertNotRegex(c["prompt"].lower(), r"hypothesis|premise|supersede|kept:|changed:", n)

    # --- the two cases that run with tools: the scripted checks must fail before the work and pass after it
    def graded(self, name, patch):
        c = self.case(name)
        tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, tmp, True)
        work = os.path.join(tmp, "w")
        shutil.copytree(os.path.join(HERE, "fixtures", c["fixture"]), work)
        if patch:
            patch(work)
        scripted = [k for k in c["checks"] if k.startswith(("python:", "unittest_pass"))]
        self.assertTrue(scripted)
        return {k: g.check(k, [], [], work)[0] for k in scripted}

    def test_typo_no_kb_check_fails_before_and_passes_after(self):
        def fix(w):
            for f in ("banner.py", "test_banner.py"):
                p = os.path.join(w, f)
                open(p, "w").write(open(p).read().replace("Welcom back", "Welcome back"))
        before, after = self.graded("typo-no-kb", None), self.graded("typo-no-kb", fix)
        self.assertTrue([k for k, v in before.items() if not v and k.startswith("python:")], before)
        self.assertTrue(all(after.values()), after)

    def test_wide_default_check_fails_when_one_place_changes_and_passes_when_all_do(self):
        def screen_only(w):
            p = os.path.join(w, "times.py")
            open(p, "w").write('def format_time(hour, minute):\n    return f"{hour:02d}:{minute:02d}"\n')
            p = os.path.join(w, "test_times.py")
            open(p, "w").write(open(p).read().replace("3:05 PM", "15:05"))

        def everywhere(w):
            screen_only(w)
            for f in ("reminder.py", "export.py"):
                p = os.path.join(w, f)
                s = open(p).read()
                s = re.sub(r"\{h\}:\{minute:02d\} \{ampm\}", "{hour:02d}:{minute:02d}", s)
                open(p, "w").write(s)
            p = os.path.join(w, "test_times.py")
            open(p, "w").write(re.sub(r"\d{1,2}:\d\d [AP]M", lambda m: "15:05", open(p).read()))
        before = self.graded("wide-default", None)
        narrow = self.graded("wide-default", screen_only)
        wide = self.graded("wide-default", everywhere)
        self.assertTrue([k for k, v in before.items() if not v and k.startswith("python:")], before)
        self.assertTrue([k for k, v in narrow.items() if not v and k.startswith("python:")], "a change of one place must fail", narrow)
        self.assertTrue(all(v for k, v in wide.items() if k.startswith("python:")), wide)


class TranscriptChecks(unittest.TestCase):
    """said: and final: read what the agent wrote, for a format that the prompt defines."""

    def transcript(self, texts, final):
        f = tempfile.NamedTemporaryFile("w", suffix=".jsonl", delete=False)
        self.addCleanup(os.unlink, f.name)
        for t in texts:
            f.write(json.dumps({"type": "assistant", "message": {"content": [{"type": "text", "text": t}]}}) + "\n")
        f.write(json.dumps({"type": "result", "subtype": "success", "result": final}) + "\n")
        f.close()
        return f.name

    def run_check(self, name, path):
        return g.check(name, g.tool_calls(path), [], "/nonexistent", path)[0]

    def test_said_finds_a_premises_line_before_the_delivery(self):
        p = self.transcript(["Hypothesis: x holds.\nPremises: none\n", "working"], "Delivered: ok")
        self.assertTrue(self.run_check(r"said:(?i)premises\W{0,4}none", p))
        self.assertFalse(self.run_check(r"said:(?i)premises\W{0,4}(?!none)\w", p))

    def test_said_fails_when_nothing_was_said(self):
        p = self.transcript(["working"], "Delivered: ok")
        self.assertFalse(self.run_check(r"said:(?i)premises\W{0,4}none", p))

    def test_final_reads_the_last_result_only(self):
        p = self.transcript(["KB: No KB"], "Delivered: ok\nKB: a_dir")
        self.assertFalse(self.run_check(r"final:(?im)^\W*KB:\W*No KB", p))
        p = self.transcript([], "Delivered: ok\nKB:          No KB\n")
        self.assertTrue(self.run_check(r"final:(?im)^\W*KB:\W*No KB", p))


if __name__ == "__main__":
    unittest.main()
