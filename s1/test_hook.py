"""Tests for s1/hook.py (T07, claims c1-c5). No network: every call goes through a fake
transport that returns a recorded response (s1/fixtures/hook_responses.json, invented data).

Run from the repo root:  python3 -m unittest s1.test_hook -v
One claim alone:         python3 -m unittest s1.test_hook.C2Output -v

The hook API under test:
    hook.run(raw_stdin_text, env, transport=None) -> stdout text ("" = print nothing)
    hook.main(transport=None) -> 0   reads sys.stdin, writes sys.stdout (the script entry)
Env: TYPESAFE_API_KEY, S1_OFF, S1_TIMEOUT, S1_QUESTIONS, S1_LOG. (T43 c2: S1_REDACT is gone; the tests
still set it to a name list, to show that the hook ignores it and sends the messages as written.)
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
TICKET_LINE = ("System 1: work=build (0.83); divergence likely (0.85); effort significant (0.91); "
               "formal tool: prolog (0.72)")  # 0.3.0 S-A: the line only reports (": consider a shift up" went)
UNSURE_LINE = "System 1: unsure"  # 0.3.0 S-A: every answer in the unsure band


def no_view(reason):
    """0.3.0 S-A: the one line of a hook that failed."""
    return "System 1: no view (%s)" % reason


LONG_CHARS = 262000 * 3  # T30: the long-context limit (262k tokens) at the hook's 3 chars/token
LONG_HEADER = "TypeSafe-Danger-Zone-Long-Context"  # TypeSafe docs, models page, "Long context"


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
        self.redact = os.path.join(d.name, "redact.txt")  # the old name list (T43 c2: ignored now)
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
    """c1: the state sent is {message: prompt, recent: the last messages} (T20 supersedes the
    600-character cut of T07 c1). T43 c2 supersedes the redaction of T07 c1: the names that the
    old list held are sent as written."""

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

    def test_c1_state_shape_names_as_written(self):  # T43 c2 changed it: was ..._and_redaction
        fake = Fake()
        self.run_hook(fake)
        st = fake.state()
        self.assertEqual(sorted(st), ["message", "recent"])
        self.assertEqual(st["message"], "Looks good. Ask Zorblax about it.")
        self.assertIn("I renamed the tab to Reports for Acme Widgets.", texts(st))
        self.assertIn("Acme Widgets", fake.calls[0]["body"].decode())

    def test_c1_names_in_any_case_as_written(self):  # T43 c2 changed it: was ..._redaction_is_case_insensitive
        fake = Fake()
        self.run_hook(fake, raw=self.payload(prompt="ACME WIDGETS and zorblax"))
        self.assertEqual(fake.state()["message"], "ACME WIDGETS and zorblax")

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
        recent = texts(fake.state())  # T20: the last 3 messages, so the older answer is in
        self.assertIn("First part.", recent)
        self.assertIn("Second part.", recent)
        self.assertIn("An older answer.", recent)
        self.assertNotIn("subagent", recent)

    def test_c1_recent_not_cut_to_600(self):  # T20 c2 supersedes T07 c1 (the 600 cut)
        self.write_transcript([entry("assistant", ["x" * 5000], "m3")])
        fake = Fake()
        self.run_hook(fake)
        self.assertEqual(fake.state()["recent"], [{"role": "agent", "text": "x" * 5000}])

    def test_c1_no_transcript_gives_empty_recent(self):
        fake = Fake()
        self.run_hook(fake, raw=self.payload(transcript_path=os.path.join(self.dir, "none.jsonl")))
        self.assertEqual(fake.state()["recent"], [])

    def test_c1_missing_redact_file_sends_as_written(self):
        env = dict(self.env, S1_REDACT=os.path.join(self.dir, "absent.txt"))
        fake = Fake()
        self.run_hook(fake, env=env)
        self.assertIn("Zorblax", fake.state()["message"])

    def test_c1_redact_example_gone_and_redact_txt_still_ignored(self):
        # T43 c2 changed it (was: redact.example.txt is committed). An old s1/redact.txt may still
        # hold real names on a machine, so it stays gitignored and is never committed.
        self.assertFalse(os.path.exists(os.path.join(HERE, "redact.example.txt")))
        p = subprocess.run(["git", "check-ignore", "-q", "s1/redact.txt"], cwd=ROOT,
                           stdin=subprocess.DEVNULL, capture_output=True)
        self.assertEqual(p.returncode, 0, "s1/redact.txt is not gitignored")

    def test_c1_non_utf8_transcript_still_calls(self):
        # review fix 1: 5 MB of random bytes as the transcript must not lose the call
        with open(self.transcript, "wb") as f:
            f.write(os.urandom(5 * 1024 * 1024))
        fake = Fake()
        out = self.run_hook(fake)
        self.assertEqual(len(fake.calls), 1)
        self.assertEqual(fake.state()["recent"], [])
        self.assertEqual(self.context(out), TICKET_LINE)

    def test_c1_large_sparse_transcript_reads_only_the_tail(self):
        # review fix 2: a 512 MB (sparse) transcript; only the tail is read
        with open(self.transcript, "wb") as f:
            f.write((json.dumps(entry("assistant", ["An old answer."], "m0")) + "\n").encode())
            f.seek(512 * 1024 * 1024)
            f.write(b"\n" + (json.dumps(entry("assistant", ["The newest answer."], "m9"))
                              + "\n").encode())
        fake = Fake()
        t0 = time.monotonic()
        self.run_hook(fake)
        took = time.monotonic() - t0
        self.assertLess(took, 0.5, f"took {took:.2f} s")
        self.assertIn("The newest answer.", texts(fake.state()))

    def test_c1_multi_mb_transcript_tail_finds_last_message(self):
        lines = [json.dumps(entry("assistant", ["filler " + "y" * 900], f"f{i}"))
                 for i in range(6000)]  # about 6 MB
        lines.append(json.dumps(entry("assistant", ["The last one."], "mz")))
        with open(self.transcript, "w") as f:
            f.write("\n".join(lines) + "\n")
        fake = Fake()
        t0 = time.monotonic()
        self.run_hook(fake)
        self.assertLess(time.monotonic() - t0, 0.5)
        # T20 c9: 6000 agent messages with no prompt between them are one turn, so one reply;
        # it is trimmed from its start and still ends with the last message
        last = fake.state()["recent"][-1]
        self.assertEqual(last["role"], "agent")
        self.assertTrue(last["text"].endswith("The last one."))

    def test_c1_transcript_read_inside_the_timeout(self):
        # review fix 2: a transcript that blocks on read (a FIFO with no writer) must not
        # hang the hook past the timeout. Run as a child so a hang cannot stall the suite.
        fifo = os.path.join(self.dir, "fifo.jsonl")
        os.mkfifo(fifo)
        p, took = subprocess_hook(self.payload(transcript_path=fifo),
                                  dict(self.env, S1_TIMEOUT="0.3"),
                                  fake_spec={"payload": RECORDED["ticket_example"]}, timeout=8)
        self.assertEqual((p.returncode, p.stdout), (0, ""))
        self.assertLess(took, 3)



def utext(text):
    return {"type": "user", "isSidechain": False, "message": {"role": "user", "content": text}}


def tool_result(tid, size=10):
    return {"type": "user", "message": {"role": "user", "content": [
        {"type": "tool_result", "tool_use_id": tid, "content": "r" * size}]}}


def texts(st):
    """All the text of recent, joined (for assertions that do not care about the items)."""
    return "\n".join(m["text"] for m in st["recent"])


class T20Context(Base):
    """T20: the state carries the complete last 3 messages (supersedes T07 c1, the 600 cut)."""

    def conv(self):
        return [
            utext("Rename the tab."),
            entry("assistant", [], "a1", extra_blocks=[{"type": "thinking", "thinking": "hm"}]),
            entry("assistant", ["I will rename it."], "a1"),
            entry("assistant", [], "a1", extra_blocks=[{"type": "tool_use", "name": "Bash",
                                                        "input": {}, "id": "t1"}]),
            tool_result("t1"),
            entry("assistant", ["Done: the tab is Reports."], "a2"),
            entry("assistant", ["A subagent's words."], "s9", sidechain=True),
            utext("And the menu entry too?"),
            entry("assistant", ["The menu says Reports as well."], "a3"),
        ]

    # c1 ------------------------------------------------------------------
    def test_t20_c9_last_three_messages_oldest_first_a_reply_is_the_whole_turn(self):
        # T20 c9 (supersedes c1): the agent text of one turn is one reply, whatever its ids
        self.write_transcript(self.conv())
        fake = Fake()
        self.run_hook(fake)
        st = fake.state()
        self.assertEqual(sorted(st), ["message", "recent"])
        self.assertEqual(st["recent"], [
            {"role": "agent", "text": "I will rename it.\nDone: the tab is Reports."},
            {"role": "you", "text": "And the menu entry too?"},
            {"role": "agent", "text": "The menu says Reports as well."}])

    def test_t20_c1_one_message_spread_over_lines_is_one_item(self):
        self.write_transcript([utext("Go."), entry("assistant", ["First part."], "m2"),
                               entry("assistant", [], "m2", extra_blocks=[
                                   {"type": "tool_use", "name": "Read", "input": {}, "id": "t2"}]),
                               tool_result("t2"),
                               entry("assistant", ["Second part."], "m2")])
        fake = Fake()
        self.run_hook(fake)
        self.assertEqual(fake.state()["recent"], [
            {"role": "you", "text": "Go."},
            {"role": "agent", "text": "First part.\nSecond part."}])

    def test_t20_c1_fewer_than_three_sends_what_exists(self):
        self.write_transcript([utext("Hello there.")])
        fake = Fake()
        self.run_hook(fake)
        self.assertEqual(fake.state()["recent"], [{"role": "you", "text": "Hello there."}])

    def test_t20_c9_the_new_prompt_is_not_repeated_in_recent(self):
        self.write_transcript(self.conv() + [utext("Looks good. Ask Zorblax about it.")])
        fake = Fake()
        self.run_hook(fake)
        self.assertEqual([m["text"] for m in fake.state()["recent"]],
                         ["I will rename it.\nDone: the tab is Reports.", "And the menu entry too?",
                          "The menu says Reports as well."])

    def test_t20_c9_count_from_env_never_below_three(self):
        es = []
        for i in range(4):
            es += [utext(f"Question {i}."), entry("assistant", [f"Answer {i}."], f"a{i}")]
        self.write_transcript(es)  # 8 messages
        for val, n in (("5", 5), ("1", 3), ("x", 3), ("", 3)):
            fake = Fake()
            self.run_hook(fake, env=dict(self.env, S1_CONTEXT_MESSAGES=val))
            self.assertEqual(len(fake.state()["recent"]), n, f"S1_CONTEXT_MESSAGES={val!r}")
        fake = Fake()
        self.run_hook(fake, env=dict(self.env, S1_CONTEXT_MESSAGES="5"))
        self.assertEqual(fake.state()["recent"][0], {"role": "agent", "text": "Answer 1."})

    def test_t20_c1_meta_and_command_lines_are_not_messages(self):
        self.write_transcript([utext("Real question."),
                               dict(utext("<local-command-stdout>x</local-command-stdout>"), isMeta=True),
                               entry("assistant", ["Real answer."], "m1")])
        fake = Fake()
        self.run_hook(fake)
        self.assertEqual([m["text"] for m in fake.state()["recent"]], ["Real question.", "Real answer."])

    # c2 ------------------------------------------------------------------
    def test_t20_c2_texts_are_sent_whole(self):
        long = "word " * 4000  # 20000 characters, far past the old 600 cut
        self.write_transcript([utext("Explain."), entry("assistant", [long.strip()], "m3")])
        fake = Fake()
        self.run_hook(fake)
        self.assertEqual(fake.state()["recent"][-1]["text"], long.strip())
        self.assertNotIn("trimmed", json.dumps(self.log_lines()[-1]))

    def test_t20_c2_over_budget_drops_extra_then_cuts_oldest_from_start(self):
        # T30 changed this test: the cut now happens only past the long-context limit (262k
        # tokens), not past the default 32k. Before T30 the oldest message was "B" * CONTEXT_CHARS.
        h = hook()
        big = "B" * LONG_CHARS  # one message alone fills the long-context budget
        self.write_transcript([utext("old one"), entry("assistant", ["old two"], "o2"),
                               utext("start-" + big), entry("assistant", ["middle"], "m"),
                               utext("newest")])
        fake = Fake()
        self.run_hook(fake, env=dict(self.env, S1_CONTEXT_MESSAGES="5"))
        st = fake.state()
        self.assertEqual([m["text"] for m in st["recent"]][1:], ["middle", "newest"])
        self.assertEqual(len(st["recent"]), 3, "the messages beyond 3 are dropped first")
        first = st["recent"][0]["text"]
        self.assertTrue(first.endswith("BBBB"), "the cut is at the start of the oldest")
        self.assertFalse(first.startswith("start-"))
        q = json.loads(fake.calls[0]["body"])["questions"]
        longest = max(len(json.dumps(v)) for v in q.values())
        self.assertLessEqual(len(json.dumps(st)) + longest, LONG_CHARS)
        self.assertTrue(self.log_lines()[-1].get("trimmed"), "the log line says trimmed")

    def test_t20_c2_extra_messages_dropped_before_any_cut(self):
        h = hook()
        over = "H" * h.CONTEXT_CHARS  # past the budget alone; it is beyond the last 3
        self.write_transcript([utext("x1 " + over), entry("assistant", ["x2"], "a"),
                               utext("x3"), entry("assistant", ["x4"], "b"), utext("x5")])
        fake = Fake()
        self.run_hook(fake, env=dict(self.env, S1_CONTEXT_MESSAGES="5"))
        # x1 is dropped (the oldest beyond 3); then the state fits, so x2 stays and nothing is cut
        self.assertEqual([m["text"] for m in fake.state()["recent"]], ["x2", "x3", "x4", "x5"])

    def test_t20_c2_no_long_context_header(self):
        # T30 changed this test: the header is absent only while the state fits the default
        # context; T30 c1 covers the other branches (class T30LongContext).
        self.write_transcript(self.conv())
        fake = Fake()
        self.run_hook(fake)
        self.assertEqual(sorted(fake.calls[0]["headers"]), ["Authorization", "Content-Type"])

    # c3 ------------------------------------------------------------------
    def test_t20_c3_read_goes_back_past_two_mib_for_three_messages(self):
        es = [utext("First, far back."), tool_result("t1", 3 * 1024 * 1024),
              entry("assistant", ["Second."], "a1"), tool_result("t2", 3 * 1024 * 1024),
              utext("Third.")]
        self.write_transcript(es)
        fake = Fake()
        self.run_hook(fake)
        self.assertEqual([m["text"] for m in fake.state()["recent"]], ["First, far back.", "Second.", "Third."])

    def test_t20_c3_read_is_bounded_at_eight_mib(self):
        with open(self.transcript, "wb") as f:
            f.write((json.dumps(utext("Beyond the bound.")) + "\n").encode())
            f.seek(9 * 1024 * 1024)
            f.write(b"\n" + (json.dumps(utext("Near the end.")) + "\n").encode())
        fake = Fake()
        t0 = time.monotonic()
        self.run_hook(fake)
        self.assertLess(time.monotonic() - t0, 1.0)
        self.assertEqual([m["text"] for m in fake.state()["recent"]], ["Near the end."])

    # c4 ------------------------------------------------------------------
    def test_t20_c4_every_message_sent_as_written(self):  # T43 c2 changed it: was ..._redaction_covers_every_message
        self.write_transcript([utext("Ask Acme Widgets."), entry("assistant", ["ZORBLAX said no."], "a"),
                               utext("And zorblax again?")])
        fake = Fake()
        self.run_hook(fake)
        self.assertEqual(fake.state()["recent"], [{"role": "you", "text": "Ask Acme Widgets."},
                                                  {"role": "agent", "text": "ZORBLAX said no."},
                                                  {"role": "you", "text": "And zorblax again?"}])
        self.assertNotIn("[redacted]", fake.calls[0]["body"].decode())

    # c5 ------------------------------------------------------------------
    def test_t20_c5_wording_is_the_conversation_in_recent_and_nothing_else(self):
        with open(os.path.join(HERE, "questions.json")) as f:
            now = f.read()
        self.assertNotIn("given `recent`", now)
        self.assertIn("the conversation in `recent`", now)
        old = subprocess.run(["git", "show", "redesign:s1/questions.json"], cwd=ROOT,
                             capture_output=True, text=True, stdin=subprocess.DEVNULL)
        if old.returncode == 0 and "given `recent`" in old.stdout:
            self.assertEqual(now, old.stdout.replace("given `recent`",
                                                     "given the conversation in `recent`"))

    # c7 ------------------------------------------------------------------
    def test_t20_c7_readme_and_docstring_say_what_is_sent(self):
        with open(os.path.join(HERE, "README.md")) as f:
            readme = f.read()
        sec = readme.split("## The hook", 1)[1].split("\n## ", 1)[0]
        doc = hook().__doc__
        for t in (sec, doc):
            self.assertIn("last 3 messages", t)
            self.assertIn("S1_CONTEXT_MESSAGES", t)
            self.assertIn("trimmed", t)
            self.assertNotIn("600", t)


class T30LongContext(Base):
    """T30: the hook never cuts the last 3 messages while the long-context header can hold them."""

    def sent(self, fake):
        return fake.calls[0]["headers"]

    def test_t30_c1_fits_default_context_no_header_no_trim(self):
        self.write_transcript(T20Context.conv(self))
        fake = Fake()
        self.run_hook(fake)
        self.assertNotIn(LONG_HEADER, self.sent(fake))
        self.assertNotIn("trimmed", self.log_lines()[-1])

    def test_t30_c1_extra_messages_dropped_first_then_it_fits_no_header(self):
        h = hook()
        over = "H" * h.CONTEXT_CHARS  # past the default budget, but beyond the last 3
        self.write_transcript([utext("x1 " + over), entry("assistant", ["x2"], "a"),
                               utext("x3"), entry("assistant", ["x4"], "b"), utext("x5")])
        fake = Fake()
        self.run_hook(fake, env=dict(self.env, S1_CONTEXT_MESSAGES="5"))
        self.assertNotIn(LONG_HEADER, self.sent(fake))
        self.assertEqual([m["text"] for m in fake.state()["recent"]], ["x2", "x3", "x4", "x5"])

    def test_t30_c1_three_over_default_sent_whole_with_header(self):
        h = hook()
        big = "start-" + "B" * (h.CONTEXT_CHARS + 5000)  # the 3 do not fit the default context
        self.write_transcript([utext(big), entry("assistant", ["middle"], "m"), utext("newest")])
        fake = Fake()
        out = self.run_hook(fake)
        self.assertEqual(self.sent(fake).get(LONG_HEADER), "true")
        self.assertEqual([m["text"] for m in fake.state()["recent"]], [big, "middle", "newest"])
        line = self.log_lines()[-1]
        self.assertNotIn("trimmed", line, "nothing was cut")
        self.assertTrue(out, "the answers are used as usual")

    def test_t30_c1_beyond_long_limit_cut_from_start_with_header_and_trimmed(self):
        big = "start-" + "B" * LONG_CHARS  # past 262k tokens alone
        self.write_transcript([utext(big), entry("assistant", ["middle"], "m"), utext("newest")])
        fake = Fake()
        self.run_hook(fake)
        self.assertEqual(self.sent(fake).get(LONG_HEADER), "true")
        st = fake.state()
        self.assertEqual([m["text"] for m in st["recent"]][1:], ["middle", "newest"])
        first = st["recent"][0]["text"]
        self.assertTrue(first.endswith("BBBB"))
        self.assertFalse(first.startswith("start-"), "the cut is at the start")
        q = json.loads(fake.calls[0]["body"])["questions"]
        longest = max(len(json.dumps(v)) for v in q.values())
        self.assertLessEqual(len(json.dumps(st)) + longest, LONG_CHARS)
        self.assertTrue(self.log_lines()[-1].get("trimmed"))

    def test_t30_c2_timeout_default_and_hook_timeout_are_unchanged(self):
        # c2's measurement is s1/measure_latency.py --long (live); the numbers are in the KB.
        self.assertEqual(hook().DEFAULT_TIMEOUT, 4.0)


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

    def test_c2_divergence_and_change_of_plan_both_reported(self):
        # 0.3.0 S-A (c_s_a_2): was "divergence or change of plan: check which (prompt rule)". The line
        # only reports; the prompt says what to do with a hint.
        ctx = self.context(self.run_hook(Fake(RECORDED["both_likely"])))
        self.assertEqual(ctx, "System 1: work=build (0.90); divergence likely (0.80); "
                              "change of plan likely (0.75); formal tool: tests (0.80)")

    def test_c2_change_of_plan_alone(self):
        ctx = self.context(self.run_hook(Fake(RECORDED["change_only"])))
        self.assertEqual(ctx, "System 1: work=build (0.77); divergence unlikely (0.10); "
                              "change of plan likely (0.89)")

    def test_c2_no_band_answers_shown(self):
        ctx = self.context(self.run_hook(Fake(RECORDED["thanks"])))
        # 0.3.0 S-A (c_s_a_3): no signal on the line, so no formal tool (was "formal tool: none (0.95)")
        self.assertEqual(ctx, "System 1: work=other (1.00); divergence unlikely (0.03); "
                              "change of plan unlikely (0.05); effort not significant (0.02)")

    def test_c2_unsure_answers_left_out(self):
        ctx = self.context(self.run_hook(Fake(RECORDED["mixed_unsure"])))
        self.assertEqual(ctx, "System 1: effort significant (0.81)")  # 0.3.0 S-A: no instruction

    def test_c2_choice_band_uses_probability_of_choice(self):
        # confidence 0.9 but P(choice) 0.45 -> unsure (as the calibration called it).
        # 0.3.0 S-A: the tool (z3, 0.50) shows only beside a signal, so here a divergence is added.
        resp = json.loads(json.dumps(RECORDED["choice_low_p"]))
        resp["answers"]["h_divergence"]["noul"] = 0.85
        ctx = self.context(self.run_hook(Fake(resp)))
        self.assertNotIn("work=", ctx)
        self.assertIn("formal tool: z3 (0.50)", ctx)

    def test_c2_nothing_outside_band_says_unsure(self):
        # 0.3.0 S-A (c_s_a_1): was "prints nothing". No line now means no outside view only when off.
        self.assertEqual(self.context(self.run_hook(Fake(RECORDED["all_unsure"]))), UNSURE_LINE)

    def test_c2_subprocess_prints_the_hook_result(self):
        p, _ = subprocess_hook(self.payload(), self.env,
                               fake_spec={"payload": RECORDED["ticket_example"]})
        self.assertEqual(p.returncode, 0)
        self.assertEqual(self.context(p.stdout), TICKET_LINE)


class C3FailOpen(Base):
    """c3: any error, timeout, missing key or questions file -> exit 0, never a block.
    0.3.0 S-A (c_s_a_1): a failure prints one short line "System 1: no view (<reason>)"; only S1_OFF
    prints nothing. (Was: no output on every failure.)"""

    def assertSilent(self, out):  # only S1_OFF
        self.assertEqual(out, "")

    def assertNoView(self, out, reason=None):
        ctx = self.context(out)
        self.assertTrue(ctx.startswith("System 1: no view ("), ctx)
        if reason:
            self.assertEqual(ctx, no_view(reason))

    def test_c3_missing_key(self):
        env = {k: v for k, v in self.env.items() if k != "TYPESAFE_API_KEY"}
        fake = Fake()
        self.assertNoView(self.run_hook(fake, env=env), "no API key")
        self.assertEqual(fake.calls, [])

    def test_c3_missing_questions_file(self):
        env = dict(self.env, S1_QUESTIONS=os.path.join(self.dir, "absent.json"))
        self.assertNoView(self.run_hook(Fake(), env=env), "no question set")

    def test_c3_bad_questions_file(self):
        bad = os.path.join(self.dir, "bad.json")
        with open(bad, "w") as f:
            f.write("{not json")
        self.assertNoView(self.run_hook(Fake(), env=dict(self.env, S1_QUESTIONS=bad)), "no question set")

    def test_c3_bad_stdin_json(self):
        for raw in ("{oops", "", "[1, 2]"):
            self.assertNoView(self.run_hook(Fake(), raw=raw), "bad input")

    def test_c3_no_prompt(self):
        self.assertNoView(self.run_hook(Fake(), raw=json.dumps({"session_id": "x"})), "bad input")

    def test_c3_transport_errors(self):
        for fake in (Fake(exc=TimeoutError("slow")), Fake(exc=OSError("down")),
                     Fake(status=500, payload="boom"), Fake(payload="not json")):
            self.assertNoView(self.run_hook(fake), "no answer")

    def test_c3_malformed_answers(self):
        self.assertNoView(self.run_hook(Fake(RECORDED["malformed"])), "bad answers")

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
        self.assertNoView(out, "timeout")
        self.assertLess(time.monotonic() - t0, 1.2)

    def test_c3_off(self):
        fake = Fake()
        self.assertSilent(self.run_hook(fake, env=dict(self.env, S1_OFF="1")))
        self.assertEqual(fake.calls, [])
        self.assertFalse(os.path.exists(self.log))

    def test_c3_subprocess_bad_stdin(self):
        for raw in ("{oops", "", "null"):
            p, _ = subprocess_hook(raw, self.env)
            self.assertEqual(p.returncode, 0, raw)
            self.assertNoView(p.stdout, "bad input")

    def test_c3_subprocess_missing_key(self):
        env = {k: v for k, v in self.env.items() if k != "TYPESAFE_API_KEY"}
        p, _ = subprocess_hook(self.payload(), env)
        self.assertEqual(p.returncode, 0)
        self.assertNoView(p.stdout, "no API key")

    def test_c3_subprocess_off(self):
        p, _ = subprocess_hook(self.payload(), dict(self.env, S1_OFF="1"))
        self.assertEqual((p.returncode, p.stdout), (0, ""))

    def test_c3_subprocess_missing_questions(self):
        env = dict(self.env, S1_QUESTIONS=os.path.join(self.dir, "absent.json"))
        p, _ = subprocess_hook(self.payload(), env, fake_spec={"payload": RECORDED["ticket_example"]})
        self.assertEqual(p.returncode, 0)
        self.assertNoView(p.stdout, "no question set")

    def test_c3_subprocess_hung_transport(self):
        p, took = subprocess_hook(self.payload(), dict(self.env, S1_TIMEOUT="0.5"),
                                  fake_spec={"payload": RECORDED["ticket_example"], "sleep": 30})
        self.assertEqual(p.returncode, 0)
        self.assertNoView(p.stdout, "timeout")
        self.assertLess(took, 5)


    def test_s_a_1_no_view_is_one_short_line_with_no_details(self):
        # 0.3.0 S-A (c_s_a_1): one short line; the details (the error text) stay in the log.
        ctx = self.context(self.run_hook(Fake(exc=OSError("down at 10.0.0.1"))))
        self.assertNotIn("\n", ctx)
        self.assertNotIn("10.0.0.1", ctx)
        self.assertLess(len(ctx), 60)


class C4Log(Base):
    """c4: each call is logged by jev.py (no key; the state as sent, T43 c2) with the session id and
    the transcript basename."""

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

    def test_c4_log_has_no_key_and_the_state_as_sent(self):  # T43 c2 changed it: was ..._no_key_and_no_names
        self.run_hook(Fake())
        with open(self.log) as f:
            text = f.read()
        self.assertNotIn(KEY, text)
        self.assertIn("Zorblax", text)  # no redaction: the log holds the state as sent
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

    def _one_reason(self, *, raw=None, env=None, fake=None, want=""):
        if os.path.exists(self.log):
            os.remove(self.log)
        out = self.run_hook(fake or Fake(), raw=raw, env=env)
        self.assertIn("System 1: no view (", out)  # 0.3.0 S-A: was "" (no output)
        with open(self.log) as f:
            text = f.read()
        self.assertNotIn(KEY, text)
        recs = [json.loads(x) for x in text.splitlines()]
        reasons = [r for r in recs if r.get("skipped")]
        self.assertEqual(len(reasons), 1, recs)
        self.assertIn(want, reasons[0]["skipped"])
        return reasons[0]

    def test_c4_every_skip_logs_one_reason(self):
        # review fix 1: each skip (except S1_OFF) writes one log line with the reason
        self._one_reason(raw="{oops", want="stdin")
        self._one_reason(raw=json.dumps({"session_id": "s"}), want="prompt")
        r = self._one_reason(env=dict(self.env, S1_QUESTIONS=os.path.join(self.dir, "no.json")),
                             want="questions")
        self.assertEqual(r["session_id"], "sess-fixture-1")
        self._one_reason(fake=Fake(RECORDED["malformed"]), want="answers")
        self._one_reason(fake=Fake(exc=OSError("down")), want="no answers")
        env = {k: v for k, v in self.env.items() if k != "TYPESAFE_API_KEY"}
        self._one_reason(env=env, want="key")

    def test_c4_timeout_skip_logs_one_reason(self):
        self.addCleanup(time.sleep, 2.0)
        self._one_reason(fake=Fake(sleep=1.5), env=dict(self.env, S1_TIMEOUT="0.3"),
                         want="timeout")


class C5Readme(unittest.TestCase):
    """c5: s1/README.md shows the settings.json snippet and S1_OFF=1.
    0.3.0 S-A (c_s_a_4): it says that the hook is recommended, not required (was: "not approved yet
    (u44)"), and which signals the hook cannot see. 0.3.0 S-D (c_s_d_1): the snippet names the
    installed link ~/.claude/sagittarius-s1 (was: /path/to/sagittarius, edited by hand)."""

    def setUp(self):
        with open(os.path.join(HERE, "README.md")) as f:
            self.text = f.read()

    def test_c5_settings_snippet_parses(self):
        blocks = re.findall(r"```json\n(.*?)```", self.text, re.S)
        snippets = [json.loads(b) for b in blocks if "UserPromptSubmit" in b]
        self.assertEqual(len(snippets), 1)
        h = snippets[0]["hooks"]["UserPromptSubmit"][0]["hooks"][0]
        self.assertEqual(h["type"], "command")
        self.assertEqual(h["command"], "python3 ~/.claude/sagittarius-s1/hook.py")
        self.assertGreater(h["timeout"], 4)

    def test_s_d_1_snippets_use_the_installed_link(self):
        self.assertNotIn("/path/to/sagittarius", self.text)
        self.assertIn("~/.claude/sagittarius-s1/statusline.py", self.text)

    def test_c5_off_switch(self):
        self.assertIn("S1_OFF=1", self.text)

    def test_s_a_4_recommended_not_required(self):
        # 0.3.0 S-A (c_s_a_4): was test_c5_not_approved_u44 ("not approved yet"). No code turns the hook
        # off until an approval, so the README does not say so.
        flat = " ".join(self.text.split())
        self.assertIn("recommended, not required", flat)
        self.assertNotRegex(flat, r"(?i)not (yet )?approved")

    def test_s_a_4_says_which_signals_the_hook_cannot_see(self):
        flat = " ".join(self.text.split())
        for word in ("inside a turn", "subagent", "compaction", "peer"):
            self.assertIn(word, flat)

    def test_s_a_1_readme_says_no_view_and_unsure(self):
        flat = " ".join(self.text.split())
        self.assertIn("System 1: no view (", flat)
        self.assertIn("System 1: unsure", flat)
        self.assertNotIn("prints nothing and exits 0", flat)

    def test_c5_installed_by_ty_not_a_script(self):
        self.assertRegex(self.text, r"(?i)paste")
        for name in os.listdir(HERE):
            if name.endswith(".py") and not name.startswith("test_"):
                with open(os.path.join(HERE, name)) as f:
                    self.assertNotIn("settings.json", f.read(), name)


class Discovery(unittest.TestCase):
    """Review fix 3: the tests are found by discovery, and hook.py still runs as a script."""

    def test_s1_is_a_package(self):
        self.assertTrue(os.path.isfile(os.path.join(HERE, "__init__.py")))

    def test_discover_loads_without_errors(self):
        code = ("import sys, unittest\n"
                "l = unittest.TestLoader()\n"
                "s = l.discover('s1', top_level_dir='.')\n"
                "sys.exit(1 if l.errors or s.countTestCases() == 0 else 0)\n")
        p = subprocess.run([sys.executable, "-c", code], cwd=ROOT, stdin=subprocess.DEVNULL,
                           capture_output=True, text=True, timeout=60)
        self.assertEqual(p.returncode, 0, p.stderr[-2000:])

    def test_hook_runs_as_a_script(self):
        p = subprocess.run([sys.executable, os.path.join(HERE, "hook.py")], input="{}",
                           capture_output=True, text=True, cwd=ROOT, timeout=20,
                           env={"PATH": os.environ.get("PATH", ""), "S1_LOG": os.devnull})
        # 0.3.0 S-A: "{}" has no prompt, so the hook says it has no view (was: stdout "")
        self.assertEqual((p.returncode, p.stderr), (0, ""))
        self.assertIn("System 1: no view (bad input)", p.stdout)


class T43C1Questions(unittest.TestCase):
    """T43 c1 (u123 + u44): h_divergence takes the tested candidate wording (fy28,
    tmp/hub-design-kb/s1/hook_cal2_v2.py) word for word; the other four questions keep the
    shipped text (as of e040de6). No model call (u119): this reads the file only."""

    H_DIVERGENCE = ("Does the newest message in `message` say or suggest that the agent's own result, plan, or "
                    "reading of the request is wrong, missed something, or is not what was meant? Doubt, surprise or a "
                    "pointed question about the agent's work counts. A report of a problem in the system that the agent "
                    "did not cause, a new request, or a change of preference does not count.")
    SHIPPED = {
        "h_work": {
            "type": "choice",
            "instructions": "What kind of work does the newest message in `message` ask for, given the conversation in `recent`?",
            "criteria": {
                "research": "Learn how something behaves now, or whether a problem is real",
                "specify": "Decide or state what must become true: requirements, examples, a plan",
                "build": "Change code, configuration or documents",
                "verify": "Check, test or review work that was done",
                "question": "An answer or advice only, with no change to make",
                "other": "None of these, such as a greeting or thanks",
            },
        },
        "h_change_of_plan": {
            "type": "noul",
            "instructions": "Does the newest message in `message` change what is wanted: a new goal, a dropped part, or a new preference, while the earlier result did match what was asked at the time?",
        },
        "h_effort": {
            "type": "noul",
            "instructions": "Does the newest message in `message` show significant effort by its writer: long, detailed, carefully reasoned, or a decision written out in full?",
        },
        "h_language": {
            "type": "choice",
            "instructions": "If the work in `message` needs a formal tool to settle what is meant, which fits the claim best?",
            "criteria": {
                "prolog": "Decisions, rules, ownership, who knows what: facts and rules to query",
                "lean": "A property for every input, or a proof is asked for",
                "z3": "Combinations of rules, limits, prices or permissions",
                "tla": "Orders of steps, retries, timeouts, concurrency",
                "tests": "Behavior on concrete cases is enough",
                "none": "No formal tool is needed",
            },
        },
    }

    def load(self):
        with open(os.path.join(HERE, "questions.json"), encoding="utf-8") as f:
            return json.load(f)

    def test_t43_c1_h_divergence_is_the_tested_wording(self):
        q = self.load()
        self.assertEqual(q["h_divergence"], {"type": "noul", "instructions": self.H_DIVERGENCE})

    def test_t43_c1_other_four_questions_unchanged(self):
        q = self.load()
        self.assertEqual(sorted(q), sorted(QIDS))
        for k, v in self.SHIPPED.items():
            self.assertEqual(q[k], v, k)


class T43C2NoRedaction(Base):
    """T43 c2 (u123 + u106): the hook sends the messages as written. The name-list redaction is
    gone from hook.py (S1_REDACT, load_redactions, the redact step), s1/redact.example.txt is
    removed, and the docs say that the hook sends the complete messages with no redaction."""

    def test_t43_c2_a_listed_name_reaches_the_request_body_unchanged(self):
        # self.env sets S1_REDACT to a list that holds Zorblax and Acme Widgets (the old fixture)
        fake = Fake()
        self.run_hook(fake, raw=self.payload(prompt="Ask Zorblax and Acme Widgets."))
        body = json.loads(fake.calls[0]["body"])
        self.assertEqual(body["state"]["message"], "Ask Zorblax and Acme Widgets.")
        self.assertIn("I renamed the tab to Reports for Acme Widgets.", texts(body["state"]))

    def test_t43_c2_hook_has_no_redaction(self):
        h = hook()
        self.assertFalse(hasattr(h, "load_redactions"))
        self.assertFalse(hasattr(h, "REDACTED"))
        with open(os.path.join(HERE, "hook.py"), encoding="utf-8") as f:
            src = f.read()
        self.assertNotIn("S1_REDACT", src)
        self.assertNotIn("redact(", src)
        self.assertIn("no redaction", " ".join((h.__doc__ or "").split()))

    def test_t43_c2_redact_example_removed(self):
        self.assertFalse(os.path.exists(os.path.join(HERE, "redact.example.txt")))
        p = subprocess.run(["git", "ls-files", "s1/redact.example.txt"], cwd=ROOT,
                           stdin=subprocess.DEVNULL, capture_output=True, text=True)
        self.assertEqual(p.stdout.strip(), "")

    def test_t43_c2_docs_say_complete_messages_with_no_redaction(self):
        for rel in ("s1/README.md",):
            with open(os.path.join(ROOT, rel), encoding="utf-8") as f:
                text = " ".join(f.read().split())
            self.assertNotIn("S1_REDACT", text, rel)
            self.assertNotIn("redact.example.txt", text, rel)
            self.assertRegex(text, r"(?i)complete messages[^.]*no redaction", rel)
            self.assertNotRegex(text, r"(?i)every text is redacted|redacts names|names to redact", rel)


if __name__ == "__main__":
    unittest.main()


class SA3FormalTool(Base):
    """0.3.0 S-A (c_s_a_3): the line names a formal tool only beside a signal (a likely divergence, a
    likely change of plan, significant effort), or when the tool is Lean (a proof is asked for).
    (c_s_a_2): the line only reports; it gives no instruction."""

    def answers(self, div=0.5, plan=0.5, effort=0.5, lang="z3", lang_p=0.9, extra=None):
        probs = {k: 0.02 for k in ("prolog", "lean", "z3", "tla", "tests", "none")}
        probs[lang] = lang_p
        a = {"h_work": {"type": "choice", "choice": "build", "confidence": 0.9,
                        "probabilities": {"build": 0.9, "research": 0.02, "specify": 0.02,
                                          "verify": 0.02, "question": 0.02, "other": 0.02}},
             "h_divergence": {"type": "noul", "noul": div},
             "h_change_of_plan": {"type": "noul", "noul": plan},
             "h_effort": {"type": "noul", "noul": effort},
             "h_language": {"type": "choice", "choice": lang, "confidence": lang_p, "probabilities": probs}}
        a.update(extra or {})
        return {"model": "test", "usage": None, "answers": a}

    def line(self, **kw):
        return self.context(self.run_hook(Fake(self.answers(**kw))))

    def test_no_signal_no_tool(self):
        self.assertEqual(self.line(), "System 1: work=build (0.90)")

    def test_unlikely_answers_are_not_signals(self):
        self.assertNotIn("formal tool", self.line(div=0.1, plan=0.1, effort=0.1))

    def test_tool_beside_each_signal(self):
        for kw in ({"div": 0.85}, {"plan": 0.85}, {"effort": 0.85}):
            self.assertIn("formal tool: z3 (0.90)", self.line(**kw), kw)

    def test_lean_alone_is_named(self):
        self.assertEqual(self.line(lang="lean"), "System 1: work=build (0.90); formal tool: lean (0.90)")

    def test_a_proof_answer_decides_when_present(self):
        # after c_s_c_1 a proof that is asked for is the answer h_proof; a response without it stays valid
        no = {"h_proof": {"type": "noul", "noul": 0.1}}
        self.assertNotIn("formal tool", self.line(lang="lean", extra=no))
        yes = {"h_proof": {"type": "noul", "noul": 0.9}}
        self.assertIn("formal tool: z3 (0.90)", self.line(lang="z3", extra=yes))

    def test_the_line_gives_no_instruction(self):
        for kw in ({"div": 0.9, "plan": 0.9, "effort": 0.9}, {"effort": 0.95}, {"div": 0.9}):
            ctx = self.line(**kw)
            self.assertNotRegex(ctx, r"(?i)consider|check which|prompt rule|shift up|should|please")


class SA1Silence(Base):
    """0.3.0 S-A (c_s_a_1): the hook prints nothing only when it is off."""

    def test_off_is_the_only_silence(self):
        cases = [dict(raw="{oops"), dict(env={k: v for k, v in self.env.items() if k != "TYPESAFE_API_KEY"}),
                 dict(fake=Fake(exc=OSError("down"))), dict(fake=Fake(RECORDED["malformed"])),
                 dict(fake=Fake(RECORDED["all_unsure"]))]
        for c in cases:
            out = self.run_hook(c.get("fake") or Fake(), raw=c.get("raw"), env=c.get("env"))
            self.assertTrue(out, c)
            self.assertTrue(self.context(out).startswith("System 1: "), c)
        self.assertEqual(self.run_hook(Fake(), env=dict(self.env, S1_OFF="1")), "")

    def test_main_never_raises_and_returns_zero(self):
        p, _ = subprocess_hook("{oops", self.env)
        self.assertEqual((p.returncode, p.stderr), (0, ""))
