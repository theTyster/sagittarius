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
    """c1: the state sent is {message: prompt, recent: the last messages} (T20 supersedes the
    600-character cut of T07 c1), redacted with the names in redact.txt."""

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
        self.assertIn("renamed the tab to Reports", texts(st))
        self.assertNotIn("acme", texts(st).lower())
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
    def test_t20_c4_redaction_covers_every_message(self):
        self.write_transcript([utext("Ask Acme Widgets."), entry("assistant", ["ZORBLAX said no."], "a"),
                               utext("And zorblax again?")])
        fake = Fake()
        self.run_hook(fake)
        body = fake.calls[0]["body"].decode().lower()
        self.assertNotIn("acme", body)
        self.assertNotIn("zorblax", body)
        self.assertEqual([m["role"] for m in fake.state()["recent"]], ["you", "agent", "you"])
        self.assertIn("[redacted]", texts(fake.state()))

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

    def _one_reason(self, *, raw=None, env=None, fake=None, want=""):
        if os.path.exists(self.log):
            os.remove(self.log)
        self.assertEqual(self.run_hook(fake or Fake(), raw=raw, env=env), "")
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
        self.assertEqual((p.returncode, p.stdout, p.stderr), (0, "", ""))


if __name__ == "__main__":
    unittest.main()
