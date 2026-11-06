"""Tests for s1/hook.py (T07, claims c1-c5). No network: every call goes through a fake
transport that returns a recorded response (s1/fixtures/hook_responses.json, invented data).

Run from the repo root:  python3 -m unittest s1.test_hook -v
One claim alone:         python3 -m unittest s1.test_hook.C2Output -v

The hook API under test:
    hook.run(raw_stdin_text, env, transport=None) -> stdout text ("" = print nothing)
    hook.main(transport=None) -> 0   reads sys.stdin, writes sys.stdout (the script entry)
Env: TYPESAFE_API_KEY, S1_OFF, S1_TIMEOUT, S1_QUESTIONS, S1_REDACT, S1_LOG.
"""
import json
import os
import re
import subprocess
import sys
import tempfile
import time
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import jev  # noqa: E402

KEY = "sk-test-HOOK-SECRET-456"
with open(os.path.join(HERE, "fixtures", "hook_responses.json")) as _f:
    RECORDED = json.load(_f)
QIDS = ["h_work", "h_divergence", "h_change_of_plan", "h_effort", "h_language"]
TICKET_LINE = ("System 1: work=build (0.83); divergence likely (0.85); effort significant (0.91): "
               "consider a shift up; formal tool: prolog (0.72)")


def hook():
    import hook as h  # imported per test, so a missing module fails each test on its own
    return h


class Fake:
    """Records calls; returns a recorded reply, raises, or sleeps."""

    def __init__(self, payload=None, status=200, exc=None, sleep=0):
        self.payload = RECORDED["ticket_example"] if payload is None else payload
        self.status, self.exc, self.sleep = status, exc, sleep
        self.calls = []

    def __call__(self, url, headers, body, timeout):
        self.calls.append({"url": url, "headers": headers, "body": body, "timeout": timeout})
        if self.sleep:
            time.sleep(self.sleep)
        if self.exc:
            raise self.exc
        text = self.payload if isinstance(self.payload, str) else json.dumps(self.payload)
        return self.status, text

    def state(self):
        return json.loads(self.calls[0]["body"])["state"]


def entry(role, text_blocks, msg_id, sidechain=False, extra_blocks=()):
    content = [{"type": "text", "text": t} for t in text_blocks] + list(extra_blocks)
    return {"type": role, "isSidechain": sidechain, "sessionId": "sess-fixture",
            "message": {"id": msg_id, "role": role, "content": content}}


class Base(unittest.TestCase):
    def setUp(self):
        d = tempfile.TemporaryDirectory()
        self.addCleanup(d.cleanup)
        self.dir = d.name
        self.log = os.path.join(d.name, "logs", "s1.jsonl")
        self.redact = os.path.join(d.name, "redact.txt")
        with open(self.redact, "w") as f:
            f.write("# invented names for tests\nAcme Widgets\n\nZorblax\n")
        self.transcript = os.path.join(d.name, "0000-fixture-session.jsonl")
        self.write_transcript([
            {"type": "user", "message": {"role": "user", "content": "Rename the tab."}},
            entry("assistant", [], "m1", extra_blocks=[{"type": "thinking", "thinking": "hm"}]),
            entry("assistant", ["I renamed the tab to Reports for Acme Widgets."], "m1"),
            entry("assistant", [], "m1", extra_blocks=[{"type": "tool_use", "name": "Bash",
                                                        "input": {}, "id": "t1"}]),
            {"type": "user", "message": {"role": "user", "content": [
                {"type": "tool_result", "tool_use_id": "t1", "content": "ok"}]}},
        ])
        self.env = {"TYPESAFE_API_KEY": KEY, "S1_LOG": self.log, "S1_REDACT": self.redact,
                    "S1_QUESTIONS": os.path.join(HERE, "questions.json")}

    def write_transcript(self, entries):
        with open(self.transcript, "w") as f:
            for e in entries:
                f.write(json.dumps(e) + "\n")

    def payload(self, prompt="Looks good. Ask Zorblax about it.", **kw):
        p = {"session_id": "sess-fixture-1", "transcript_path": self.transcript,
             "cwd": self.dir, "permission_mode": "default",
             "hook_event_name": "UserPromptSubmit", "prompt": prompt}
        p.update(kw)
        return json.dumps(p)

    def run_hook(self, fake=None, raw=None, env=None):
        return hook().run(self.payload() if raw is None else raw,
                          self.env if env is None else env, transport=fake)

    def context(self, out):
        d = json.loads(out)
        self.assertEqual(d["hookSpecificOutput"]["hookEventName"], "UserPromptSubmit")
        return d["hookSpecificOutput"]["additionalContext"]

    def log_lines(self):
        with open(self.log) as f:
            return [json.loads(x) for x in f.read().splitlines()]


def subprocess_hook(stdin_text, env, fake_spec=None, timeout=20):
    """Run the hook as a child process. stdin is always given explicitly.
    fake_spec: None runs `python3 s1/hook.py` (real transport; tests use it only where no
    request is made). A dict runs hook.main() with a fake transport that returns
    fake_spec['payload'] after sleeping fake_spec.get('sleep', 0) seconds."""
    full_env = {"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": env.get("HOME", "/nonexistent")}
    full_env.update(env)
    if fake_spec is None:
        argv = [sys.executable, os.path.join(HERE, "hook.py")]
    else:
        code = (
            "import json, sys, time\n"
            f"sys.path.insert(0, {HERE!r})\n"
            "import hook\n"
            f"spec = json.loads({json.dumps(fake_spec)!r})\n"
            "def fake(url, headers, body, timeout):\n"
            "    time.sleep(spec.get('sleep', 0))\n"
            "    return 200, json.dumps(spec['payload'])\n"
            "sys.exit(hook.main(transport=fake))\n")
        argv = [sys.executable, "-c", code]
    t0 = time.monotonic()
    p = subprocess.run(argv, input=stdin_text, capture_output=True, text=True, env=full_env,
                       cwd=ROOT, timeout=timeout)
    return p, time.monotonic() - t0


class C1State(Base):
    """c1: the state sent is {message: prompt, recent: last agent message <= 600 chars},
    redacted with the names in redact.txt."""

    def test_c1_questions_file_is_the_calibrated_set(self):
        with open(os.path.join(HERE, "questions.json")) as f:
            q = json.load(f)
        self.assertEqual(sorted(q), sorted(QIDS))
        self.assertEqual(q["h_work"]["type"], "choice")
        self.assertEqual(q["h_language"]["type"], "choice")
        for k in ("h_divergence", "h_change_of_plan", "h_effort"):
            self.assertEqual(q[k]["type"], "noul")

    def test_c1_sends_the_questions_file(self):
        fake = Fake()
        self.run_hook(fake)
        with open(os.path.join(HERE, "questions.json")) as f:
            q = json.load(f)
        self.assertEqual(json.loads(fake.calls[0]["body"])["questions"], q)

    def test_c1_state_shape_and_redaction(self):
        fake = Fake()
        self.run_hook(fake)
        st = fake.state()
        self.assertEqual(sorted(st), ["message", "recent"])
        self.assertNotIn("zorblax", st["message"].lower())
        self.assertTrue(st["message"].startswith("Looks good. Ask "))
        self.assertIn("renamed the tab to Reports", st["recent"])
        self.assertNotIn("acme", st["recent"].lower())
        self.assertNotIn("acme", fake.calls[0]["body"].decode().lower())

    def test_c1_redaction_is_case_insensitive(self):
        fake = Fake()
        self.run_hook(fake, raw=self.payload(prompt="ACME WIDGETS and zorblax"))
        msg = fake.state()["message"].lower()
        self.assertNotIn("acme", msg)
        self.assertNotIn("zorblax", msg)

    def test_c1_recent_is_the_last_assistant_message_with_text(self):
        self.write_transcript([
            entry("assistant", ["An older answer."], "m0"),
            {"type": "user", "message": {"role": "user", "content": "next"}},
            entry("assistant", ["First part."], "m2"),
            entry("assistant", [], "m2", extra_blocks=[{"type": "tool_use", "name": "Read",
                                                        "input": {}, "id": "t2"}]),
            entry("assistant", ["Second part."], "m2"),
            entry("assistant", ["A subagent's words."], "s9", sidechain=True),
        ])
        fake = Fake()
        self.run_hook(fake)
        recent = fake.state()["recent"]
        self.assertIn("First part.", recent)
        self.assertIn("Second part.", recent)
        self.assertNotIn("older", recent)
        self.assertNotIn("subagent", recent)

    def test_c1_recent_cut_to_600(self):
        self.write_transcript([entry("assistant", ["x" * 5000], "m3")])
        fake = Fake()
        self.run_hook(fake)
        recent = fake.state()["recent"]
        self.assertLessEqual(len(recent), 600)
        self.assertGreaterEqual(len(recent), 590)

    def test_c1_no_transcript_gives_empty_recent(self):
        fake = Fake()
        self.run_hook(fake, raw=self.payload(transcript_path=os.path.join(self.dir, "none.jsonl")))
        self.assertEqual(fake.state()["recent"], "")

    def test_c1_missing_redact_file_sends_unredacted(self):
        env = dict(self.env, S1_REDACT=os.path.join(self.dir, "absent.txt"))
        fake = Fake()
        self.run_hook(fake, env=env)
        self.assertIn("Zorblax", fake.state()["message"])

    def test_c1_redact_example_committed_and_redact_txt_ignored(self):
        self.assertTrue(os.path.isfile(os.path.join(HERE, "redact.example.txt")))
        p = subprocess.run(["git", "check-ignore", "-q", "s1/redact.txt"], cwd=ROOT,
                           stdin=subprocess.DEVNULL, capture_output=True)
        self.assertEqual(p.returncode, 0, "s1/redact.txt is not gitignored")


class C2Output(Base):
    """c2: one short line of the answers outside the unsure band, in the ticket's words."""

    def test_c2_ticket_example_exact(self):
        out = self.run_hook(Fake(RECORDED["ticket_example"]))
        self.assertEqual(self.context(out), TICKET_LINE)

    def test_c2_output_is_only_the_hook_result(self):
        d = json.loads(self.run_hook(Fake()))
        self.assertEqual(list(d), ["hookSpecificOutput"])
        self.assertEqual(sorted(d["hookSpecificOutput"]), ["additionalContext", "hookEventName"])
        self.assertNotIn("\n", d["hookSpecificOutput"]["additionalContext"])

    def test_c2_divergence_and_change_of_plan_combined(self):
        ctx = self.context(self.run_hook(Fake(RECORDED["both_likely"])))
        self.assertEqual(ctx, "System 1: work=build (0.90); divergence or change of plan: check "
                              "which (prompt rule); formal tool: tests (0.80)")

    def test_c2_change_of_plan_alone(self):
        ctx = self.context(self.run_hook(Fake(RECORDED["change_only"])))
        self.assertEqual(ctx, "System 1: work=build (0.77); divergence unlikely (0.10); "
                              "change of plan likely (0.89)")

    def test_c2_no_band_answers_shown(self):
        ctx = self.context(self.run_hook(Fake(RECORDED["thanks"])))
        self.assertEqual(ctx, "System 1: work=other (1.00); divergence unlikely (0.03); "
                              "change of plan unlikely (0.05); effort not significant (0.02); "
                              "formal tool: none (0.95)")

    def test_c2_unsure_answers_left_out(self):
        ctx = self.context(self.run_hook(Fake(RECORDED["mixed_unsure"])))
        self.assertEqual(ctx, "System 1: effort significant (0.81): consider a shift up")

    def test_c2_choice_band_uses_probability_of_choice(self):
        # confidence 0.9 but P(choice) 0.45 -> unsure (as the calibration called it)
        ctx = self.context(self.run_hook(Fake(RECORDED["choice_low_p"])))
        self.assertNotIn("work=", ctx)
        self.assertIn("formal tool: z3 (0.50)", ctx)

    def test_c2_nothing_outside_band_prints_nothing(self):
        self.assertEqual(self.run_hook(Fake(RECORDED["all_unsure"])), "")

    def test_c2_subprocess_prints_the_hook_result(self):
        p, _ = subprocess_hook(self.payload(), self.env,
                               fake_spec={"payload": RECORDED["ticket_example"]})
        self.assertEqual(p.returncode, 0)
        self.assertEqual(self.context(p.stdout), TICKET_LINE)


class C3FailOpen(Base):
    """c3: any error, timeout, missing key or questions file -> no output, exit 0."""

    def assertSilent(self, out):
        self.assertEqual(out, "")

    def test_c3_missing_key(self):
        env = {k: v for k, v in self.env.items() if k != "TYPESAFE_API_KEY"}
        fake = Fake()
        self.assertSilent(self.run_hook(fake, env=env))
        self.assertEqual(fake.calls, [])

    def test_c3_missing_questions_file(self):
        env = dict(self.env, S1_QUESTIONS=os.path.join(self.dir, "absent.json"))
        self.assertSilent(self.run_hook(Fake(), env=env))

    def test_c3_bad_questions_file(self):
        bad = os.path.join(self.dir, "bad.json")
        with open(bad, "w") as f:
            f.write("{not json")
        self.assertSilent(self.run_hook(Fake(), env=dict(self.env, S1_QUESTIONS=bad)))

    def test_c3_bad_stdin_json(self):
        self.assertSilent(self.run_hook(Fake(), raw="{oops"))
        self.assertSilent(self.run_hook(Fake(), raw=""))
        self.assertSilent(self.run_hook(Fake(), raw="[1, 2]"))

    def test_c3_no_prompt(self):
        self.assertSilent(self.run_hook(Fake(), raw=json.dumps({"session_id": "x"})))

    def test_c3_transport_errors(self):
        for fake in (Fake(exc=TimeoutError("slow")), Fake(exc=OSError("down")),
                     Fake(status=500, payload="boom"), Fake(payload="not json")):
            self.assertSilent(self.run_hook(fake))

    def test_c3_malformed_answers(self):
        self.assertSilent(self.run_hook(Fake(RECORDED["malformed"])))

    def test_c3_timeout_default_and_env(self):
        fake = Fake()
        self.run_hook(fake)
        self.assertEqual(fake.calls[0]["timeout"], 4.0)
        fake = Fake()
        self.run_hook(fake, env=dict(self.env, S1_TIMEOUT="1.5"))
        self.assertEqual(fake.calls[0]["timeout"], 1.5)

    def test_c3_bad_timeout_value_uses_default(self):
        fake = Fake()
        self.run_hook(fake, env=dict(self.env, S1_TIMEOUT="soon"))
        self.assertEqual(fake.calls[0]["timeout"], 4.0)

    def test_c3_hung_transport_is_cut_off(self):
        self.addCleanup(time.sleep, 2.0)  # let the abandoned call finish before the tmp dir goes
        t0 = time.monotonic()
        out = self.run_hook(Fake(sleep=1.5), env=dict(self.env, S1_TIMEOUT="0.3"))
        self.assertSilent(out)
        self.assertLess(time.monotonic() - t0, 1.2)

    def test_c3_off(self):
        fake = Fake()
        self.assertSilent(self.run_hook(fake, env=dict(self.env, S1_OFF="1")))
        self.assertEqual(fake.calls, [])
        self.assertFalse(os.path.exists(self.log))

    def test_c3_subprocess_bad_stdin(self):
        for raw in ("{oops", "", "null"):
            p, _ = subprocess_hook(raw, self.env)
            self.assertEqual((p.returncode, p.stdout), (0, ""), raw)

    def test_c3_subprocess_missing_key(self):
        env = {k: v for k, v in self.env.items() if k != "TYPESAFE_API_KEY"}
        p, _ = subprocess_hook(self.payload(), env)
        self.assertEqual((p.returncode, p.stdout), (0, ""))

    def test_c3_subprocess_off(self):
        p, _ = subprocess_hook(self.payload(), dict(self.env, S1_OFF="1"))
        self.assertEqual((p.returncode, p.stdout), (0, ""))

    def test_c3_subprocess_missing_questions(self):
        env = dict(self.env, S1_QUESTIONS=os.path.join(self.dir, "absent.json"))
        p, _ = subprocess_hook(self.payload(), env, fake_spec={"payload": RECORDED["ticket_example"]})
        self.assertEqual((p.returncode, p.stdout), (0, ""))

    def test_c3_subprocess_hung_transport(self):
        p, took = subprocess_hook(self.payload(), dict(self.env, S1_TIMEOUT="0.5"),
                                  fake_spec={"payload": RECORDED["ticket_example"], "sleep": 30})
        self.assertEqual((p.returncode, p.stdout), (0, ""))
        self.assertLess(took, 5)


class C4Log(Base):
    """c4: each call is logged by jev.py (no key, redacted state) with the session id and the
    transcript basename."""

    def test_c4_hook_call_logged_with_session_and_transcript(self):
        self.run_hook(Fake())
        lines = self.log_lines()
        self.assertEqual(len(lines), 1)
        rec = lines[0]
        self.assertEqual(rec["session_id"], "sess-fixture-1")
        self.assertEqual(rec["transcript"], "0000-fixture-session.jsonl")
        self.assertEqual(sorted(rec["questions"]), sorted(QIDS))
        self.assertIsNotNone(rec["answers"])
        self.assertIsNone(rec["error"])

    def test_c4_log_has_no_key_and_no_names(self):
        self.run_hook(Fake())
        with open(self.log) as f:
            text = f.read()
        self.assertNotIn(KEY, text)
        self.assertNotIn("acme", text.lower())
        self.assertNotIn("zorblax", text.lower())
        self.assertNotIn(self.dir, text)  # basename only, not the full transcript path

    def test_c4_failed_call_logged_with_fields(self):
        self.run_hook(Fake(exc=OSError("down")))
        rec = self.log_lines()[0]
        self.assertIn("down", rec["error"])
        self.assertEqual(rec["session_id"], "sess-fixture-1")

    def test_c4_missing_key_logged(self):
        env = {k: v for k, v in self.env.items() if k != "TYPESAFE_API_KEY"}
        self.run_hook(Fake(), env=env)
        rec = self.log_lines()[0]
        self.assertIn("missing API key", rec["error"])
        self.assertEqual(rec["transcript"], "0000-fixture-session.jsonl")

    def test_c4_hung_call_logged_as_timeout(self):
        self.run_hook(Fake(sleep=1.5), env=dict(self.env, S1_TIMEOUT="0.3"))
        time.sleep(2.0)  # the abandoned call logs too, when it ends
        recs = self.log_lines()
        self.assertTrue(any("timeout" in (r.get("error") or "") for r in recs))
        self.assertTrue(all(r.get("session_id") == "sess-fixture-1" for r in recs))

    def test_c4_jev_extra_fields_parameter(self):
        jev.judge("s", {"q1": {"type": "noul", "instructions": "?"}}, key=KEY, log_path=self.log,
                  transport=Fake({"answers": {"q1": {"type": "noul", "noul": 0.9}}}),
                  log_extra={"session_id": "abc", "transcript": "t.jsonl"})
        rec = self.log_lines()[0]
        self.assertEqual((rec["session_id"], rec["transcript"]), ("abc", "t.jsonl"))
        self.assertIsNone(rec["error"])

    def test_c4_jev_extra_fields_cannot_overwrite_core_fields(self):
        jev.judge("s", {"q1": {"type": "noul", "instructions": "?"}}, key=KEY, log_path=self.log,
                  transport=Fake({"answers": {"q1": {"type": "noul", "noul": 0.9}}}),
                  log_extra={"error": "fake", "state": "fake"})
        rec = self.log_lines()[0]
        self.assertIsNone(rec["error"])
        self.assertEqual(rec["state"], "s")


class C5Readme(unittest.TestCase):
    """c5: s1/README.md shows the settings.json snippet, S1_OFF=1, and says the question set is
    not approved yet (u44)."""

    def setUp(self):
        with open(os.path.join(HERE, "README.md")) as f:
            self.text = f.read()

    def test_c5_settings_snippet_parses(self):
        blocks = re.findall(r"```json\n(.*?)```", self.text, re.S)
        snippets = [json.loads(b) for b in blocks if "UserPromptSubmit" in b]
        self.assertEqual(len(snippets), 1)
        h = snippets[0]["hooks"]["UserPromptSubmit"][0]["hooks"][0]
        self.assertEqual(h["type"], "command")
        self.assertIn("s1/hook.py", h["command"])
        self.assertGreater(h["timeout"], 4)

    def test_c5_off_switch(self):
        self.assertIn("S1_OFF=1", self.text)

    def test_c5_not_approved_u44(self):
        self.assertIn("u44", self.text)
        self.assertRegex(self.text, r"(?i)not (yet )?approved")

    def test_c5_installed_by_ty_not_a_script(self):
        self.assertRegex(self.text, r"(?i)paste")
        for name in os.listdir(HERE):
            if name.endswith(".py") and not name.startswith("test_"):
                with open(os.path.join(HERE, name)) as f:
                    self.assertNotIn("settings.json", f.read(), name)


if __name__ == "__main__":
    unittest.main()
