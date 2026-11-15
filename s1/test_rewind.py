"""Tests for s1-rewind-context: System 1 is sent the conversation Claude holds (claims c1c, c2,
c3, c4, c6b, c7, c8, c9; guards G1-G7 of the ticket's TLA+ model). No network: every System 1 call goes
through a fake transport. Every transcript here is made by hand (invented text).

Run from the repo root:  python3 -m unittest s1.test_rewind -v

The examples of the Lean model (lean_proof/S1Proof/Examples.lean of the ticket) are the classes
LeanExamples (examples 1 to 4, the disprove run and the misfire). Each guard has a test named
test_gN_... that fails when that guard is removed from the code.
"""
import difflib
import json
import os
import subprocess
import sys
import tempfile
import threading
import time
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import hook  # noqa: E402
import posttool  # noqa: E402
from test_hook import Fake, KEY, RECORDED  # noqa: E402  (not TestCases: nothing runs twice)

SID = "sess-rewind-1"


# A transcript line of each kind. Each takes its uuid and its parent's uuid (None: no parent).
def u(uid, parent, text, pid=None, **kw):
    d = {"type": "user", "uuid": uid, "parentUuid": parent, "isSidechain": False,
         "sessionId": SID, "message": {"role": "user", "content": text}}
    if pid:
        d["promptId"] = pid
    d.update(kw)
    return d


def a(uid, parent, text, mid=None, **kw):
    d = {"type": "assistant", "uuid": uid, "parentUuid": parent, "isSidechain": False,
         "sessionId": SID, "message": {"id": mid or "m-" + uid, "role": "assistant",
                                       "content": [{"type": "text", "text": text}]}}
    d.update(kw)
    return d


def tool_use(uid, parent, mid):
    return {"type": "assistant", "uuid": uid, "parentUuid": parent, "isSidechain": False,
            "message": {"id": mid, "role": "assistant", "content": [
                {"type": "tool_use", "id": "t-" + uid, "name": "Bash", "input": {}}]}}


def tool_result(uid, parent, pid=None):
    d = {"type": "user", "uuid": uid, "parentUuid": parent, "isSidechain": False,
         "message": {"role": "user", "content": [
             {"type": "tool_result", "tool_use_id": "t-" + parent, "content": "ok"}]}}
    if pid:
        d["promptId"] = pid
    return d


def boundary(uid, logical):
    return {"type": "system", "subtype": "compact_boundary", "uuid": uid, "parentUuid": None,
            "logicalParentUuid": logical, "content": "Conversation compacted"}


def summary(uid, parent, text):
    return u(uid, parent, text, isCompactSummary=True, isVisibleInTranscriptOnly=True)


def side(uid, parent, kind, **kw):
    """A line that is no message: a snapshot (no uuid), a system line, an attachment."""
    d = {"type": kind, "uuid": uid, "parentUuid": parent}
    d.update(kw)
    return d


def msgs(*pairs):
    return [{"role": r, "text": t} for r, t in pairs]


class Base(unittest.TestCase):
    def setUp(self):
        d = tempfile.TemporaryDirectory()
        self.addCleanup(d.cleanup)
        self.dir = d.name
        self.transcript = os.path.join(d.name, SID + ".jsonl")
        self.log = os.path.join(d.name, "logs", "s1.jsonl")
        self.state = os.path.join(d.name, "latefix")
        self.env = {"TYPESAFE_API_KEY": KEY, "S1_LOG": self.log, "S1_LATEFIX_DIR": self.state,
                    "S1_QUESTIONS": os.path.join(HERE, "questions.json"), "S1_WORKBENCH": "off",
                    "S1_FANOUT": "0"}  # the plain path, with recorded responses; the fan-out: test_fanout.py
        self.spawned = []

    def write(self, lines):
        with open(self.transcript, "w") as f:
            for e in lines:
                f.write(json.dumps(e) + "\n")

    def append(self, *lines):
        with open(self.transcript, "a") as f:
            for e in lines:
                f.write(json.dumps(e) + "\n")

    def recent(self, prompt=None, n=6):
        return hook.recent_messages(self.transcript, n, prompt)

    def payload(self, prompt, pid=None, **kw):
        p = {"session_id": SID, "transcript_path": self.transcript, "cwd": self.dir,
             "hook_event_name": "UserPromptSubmit", "prompt": prompt}
        if pid:
            p["prompt_id"] = pid
        p.update(kw)
        return json.dumps(p)

    def first_call(self, prompt, pid, fake=None, n=6):
        """The hook's first call; the late fix is recorded, not started. Returns the state sent."""
        fake = fake or Fake()
        env = dict(self.env, S1_CONTEXT_MESSAGES=str(n))
        hook.run(self.payload(prompt, pid), env,
                 transport=fake, spawn=lambda argv, e: self.spawned.append(argv))
        return fake.state()

    def late(self, fake, wait=0.5):
        """Run the late fix that the last first call started, here, with a fake transport."""
        argv = self.spawned[-1]
        self.assertEqual(argv[-2], "--late-fix")
        return hook.late_fix(argv[-1], dict(self.env), transport=fake, wait=wait)

    def ptu(self, pid, **kw):
        d = {"session_id": SID, "prompt_id": pid, "hook_event_name": "PostToolUse",
             "tool_name": "Bash", "transcript_path": self.transcript}
        d.update(kw)
        out = posttool.run(json.dumps(d), dict(self.env))
        return json.loads(out)["hookSpecificOutput"]["additionalContext"] if out else None

    def log_lines(self):
        with open(self.log) as f:
            return [json.loads(x) for x in f.read().splitlines()]


def branchy():
    """Prompt 1, a reply; prompt 2 (later abandoned), its reply; Ty rewinds to reply 1 and sends
    prompt 3; its reply. The transcript ends on the live branch."""
    return [
        side(None, None, "file-history-snapshot"),
        u("u1", None, "Fix the parser so it reads dates.", pid="P1"),
        a("a1", "u1", "The parser reads dates now."),
        u("u2", "a1", "Now add tests for the date parser please.", pid="P2"),
        a("a2", "u2", "ABANDONED reply with tests."),
        u("u2i", "a2", "[Request interrupted by user]"),
        u("u3", "a1", "Write the docs for the date parser instead.", pid="P3"),
        a("a3", "u3", "The docs are written."),
        side("s3", "a3", "system", subtype="turn_duration"),
    ]


class Reader(Base):
    """G5 (c1c, c2, c3, c4): the hook follows parentUuid from the last line, stops at a
    compaction and leaves out the lines that Ty did not type."""

    def test_g5_later_prompt_after_rewind_gets_no_removed_message(self):
        self.write(branchy())
        got = self.recent("Thanks, now commit it.")
        self.assertEqual(got, msgs(("you", "Fix the parser so it reads dates."),
                                   ("agent", "The parser reads dates now."),
                                   ("you", "Write the docs for the date parser instead."),
                                   ("agent", "The docs are written.")))
        self.assertNotIn("ABANDONED", json.dumps(got))

    def test_g5_compaction_summary_stands_for_what_came_before(self):
        self.write([u("o1", None, "Old question."), a("o2", "o1", "OLD answer."),
                    boundary("b1", "o2"),
                    summary("s1", "b1", "This session is being continued: a summary."),
                    u("u5", "s1", "Go on with the plan."), a("a5", "u5", "Going on.")])
        self.assertEqual(self.recent("Next step?"),
                         msgs(("you", "This session is being continued: a summary."),
                              ("you", "Go on with the plan."), ("agent", "Going on.")))

    def test_g5_summary_out_of_the_last_n_once_more_came_after(self):
        es = [boundary("b1", None), summary("s1", "b1", "Summary.")]
        p = "s1"
        for i in range(4):
            es += [u(f"u{i}", p, f"Q{i}."), a(f"a{i}", f"u{i}", f"A{i}.")]
            p = f"a{i}"
        self.write(es)
        self.assertEqual([m["text"] for m in self.recent(n=3)], ["A2.", "Q3.", "A3."])

    def test_g5_lines_ty_did_not_type_are_not_messages(self):
        tags = ["[Request interrupted by user for tool use]",
                "<command-name>/compact</command-name>",
                "<local-command-stdout>\x1b[2mCompacted\x1b[22m</local-command-stdout>",
                "<task-notification><task-id>x</task-id></task-notification>",
                "<bash-input>ls</bash-input>", "<bash-stdout>a b</bash-stdout>"]
        es, p = [u("u0", None, "Real question."), a("a0", "u0", "Real answer.")], "a0"
        for i, t in enumerate(tags):
            es.append(u(f"t{i}", p, t))
            p = f"t{i}"
        es.append(u("m1", p, "Caveat: meta line.", isMeta=True))
        es.append(u("mix", "m1", None))
        es[-1]["message"]["content"] = [{"type": "text", "text": "<system-reminder>x</system-reminder>"},
                                        {"type": "text", "text": "Typed part."}]
        self.write(es)
        self.assertEqual(self.recent(), msgs(("you", "Real question."), ("agent", "Real answer."),
                                             ("you", "Typed part.")))

    def test_g5_plain_stretch_is_sent_what_it_was_before(self):
        es, p = [], None
        for i in range(5):
            es += [u(f"u{i}", p, f"Question number {i}."),
                   a(f"x{i}", f"u{i}", f"Part one of {i}.", mid=f"r{i}"),
                   tool_use(f"y{i}", f"x{i}", f"r{i}"), tool_result(f"z{i}", f"y{i}"),
                   a(f"w{i}", f"z{i}", f"Part two of {i}.", mid=f"q{i}")]
            p = f"w{i}"
        self.write(es)
        with open(self.transcript) as f:
            today = hook._messages(f.read().splitlines())[-6:]  # file order: the hook before the change
        self.assertEqual(self.recent("Another question here."), today)

    def test_rk1_broken_chain_falls_back_to_file_order(self):
        self.write([u("u1", None, "First."), a("a1", "u1", "Second."),
                    u("u2", "gone", "Third."), a("a2", "u2", "Fourth.")])
        self.assertEqual([m["text"] for m in self.recent()], ["First.", "Second.", "Third.", "Fourth."])

    def test_rk1_no_uuid_reads_file_order(self):
        es = [{"type": "user", "message": {"role": "user", "content": "One."}},
              {"type": "assistant", "message": {"id": "m", "content": [{"type": "text", "text": "Two."}]}}]
        self.write(es)
        self.assertEqual([m["text"] for m in self.recent()], ["One.", "Two."])

    def test_chain_found_past_the_first_tail_read(self):
        big = "r" * (3 * 1024 * 1024)
        es = [u("u1", None, "Far back."), a("a1", "u1", "Reply far back."),
              u("u2", "a1", "Off branch."), a("a2", "u2", "OFF reply.")]
        tr = tool_result("big", "a1")
        tr["message"]["content"][0]["content"] = big
        es += [tr, u("u3", "big", "On branch.")]
        self.write(es)
        self.assertEqual([m["text"] for m in self.recent()], ["Far back.", "Reply far back.", "On branch."])

    def test_the_prompt_is_not_in_recent_when_already_written(self):
        self.write(branchy() + [u("u4", "s3", "ok go")])
        self.assertEqual(self.recent("ok go")[-1], {"role": "agent", "text": "The docs are written."})


def rewound_file():
    """Ty rewound to reply 1 after the abandoned turn of prompt 2: the transcript still ends on
    the abandoned branch (nothing is written at a rewind)."""
    return [u("u1", None, "Fix the parser so it reads dates.", pid="P1"),
            a("a1", "u1", "The parser reads dates now."),
            u("u2", "a1", "Now add tests for the date parser please.", pid="P2"),
            a("a2", "u2", "ABANDONED reply with tests."),
            u("u2i", "a2", "[Request interrupted by user]")]


class TextMatch(Base):
    """G6 (c6b): on the first prompt after a rewind, a prompt that matches a prompt of the branch
    the transcript ends in (ratio >= 0.9, 15 chars or more) continues from its parent."""

    def test_g6_resent_prompt_continues_from_the_rewind_point(self):
        self.write(rewound_file())
        got = self.recent("Now add tests for the date parser, please!")
        self.assertEqual(got, msgs(("you", "Fix the parser so it reads dates."),
                                   ("agent", "The parser reads dates now.")))

    def test_g6_short_prompt_is_not_matched(self):
        self.write(rewound_file() + [a("a3", "u2i", "Short reply."), u("u4", "a3", "go on"),
                                     a("a4", "u4", "Went on.")])
        self.assertIn("Went on.", [m["text"] for m in self.recent("go on")])

    def test_g6_below_the_ratio_is_not_matched(self):
        old = "Now add tests for the date parser please."
        new = "Now add tests for the date parsing module please."
        r = difflib.SequenceMatcher(None, hook._norm(new), hook._norm(old), autojunk=False).ratio()
        self.assertTrue(0.85 < r < 0.9, r)
        self.write(rewound_file())
        self.assertIn("ABANDONED reply with tests.", [m["text"] for m in self.recent(new)])

    def test_g6_the_best_match_wins(self):
        es = [u("u1", None, "Please run the parser tests now."), a("a1", "u1", "Ran them."),
              u("u2", "a1", "Please run the parser tests again now."), a("a2", "u2", "Ran again.")]
        self.write(es)
        got = self.recent("Please run the parser tests again now!")
        self.assertEqual([m["text"] for m in got], ["Please run the parser tests now.", "Ran them."])


class LeanExamples(Base):
    """The examples of lean_proof/S1Proof/Examples.lean, as transcripts."""

    def test_example1_new_text_late_fix_corrects_and_agent_gets_it_once(self):
        # prompt 1, a reply, rewind to before prompt 1, prompt 2 with new text
        self.write([u("u1", None, "Fix the parser so it reads dates.", pid="P1"),
                    a("a1", "u1", "The parser reads dates now.")])
        sent = self.first_call("Something else entirely: rename the module.", "P2")
        self.assertEqual(len(sent["recent"]), 2, "the first call sees the abandoned branch")
        self.append(u("u2", None, "Something else entirely: rename the module.", pid="P2"))
        fix = Fake()
        self.assertEqual(self.late(fix), "corrected")
        self.assertEqual(fix.state()["recent"], [], "the right context: nothing before prompt 2")
        line = self.log_lines()[-1]
        self.assertEqual((line["kind"], line["prompt_id"], line["session_id"]), ("correction", "P2", SID))
        got = self.ptu("P2")
        self.assertTrue(got.startswith(hook.CORRECTION_PREFIX), got)
        self.assertIsNone(self.ptu("P2"), "at most once")

    def test_example2_resent_text_first_call_right_no_correction(self):
        self.write([u("u1", None, "Fix the parser so it reads dates.", pid="P1"),
                    a("a1", "u1", "The parser reads dates now.")])
        sent = self.first_call("Fix the parser so it reads dates!", "P2")
        self.assertEqual(sent["recent"], [])
        self.append(u("u2", None, "Fix the parser so it reads dates!", pid="P2"))
        fix = Fake()
        self.assertEqual(self.late(fix), "right")
        self.assertEqual(fix.calls, [])
        self.assertIsNone(self.ptu("P2"))

    def test_example3_slow_fix_keeps_its_prompt_context_and_not_in_the_next_turn(self):
        self.write([u("u1", None, "Fix the parser so it reads dates.", pid="P1"),
                    a("a1", "u1", "The parser reads dates now.")])
        self.first_call("Something else entirely: rename the module.", "P2")
        self.append(u("u2", None, "Something else entirely: rename the module.", pid="P2"),
                    u("u3", "u2", "And the third prompt arrives first.", pid="P3"))
        fix = Fake()
        self.assertEqual(self.late(fix), "corrected")
        self.assertEqual(fix.state()["recent"], [], "the correction has prompt 2's context")
        self.assertIsNone(self.ptu("P3"), "not given in prompt 3's turn")

    def test_example4_subagent_gets_nothing_main_agent_gets_it(self):
        self.write([u("u1", None, "Fix the parser so it reads dates.", pid="P1"),
                    a("a1", "u1", "The parser reads dates now.")])
        self.first_call("Something else entirely: rename the module.", "P2")
        self.append(u("u2", None, "Something else entirely: rename the module.", pid="P2"))
        self.assertEqual(self.late(Fake()), "corrected")
        self.assertIsNone(self.ptu("P2", agent_id="sub-1", agent_type="Explore"))
        self.assertIsNotNone(self.ptu("P2"))

    def test_disprove_run_a_prompt_off_the_visible_branch_is_not_matched(self):
        # prompts 1 and 2 with replies; rewind to the start; prompt 3; prompt 4 resends prompt 2,
        # which is not on the branch the transcript ends in: no match, and 4 gets the right context
        self.write([u("u1", None, "Fix the parser so it reads dates.", pid="P1"),
                    a("a1", "u1", "The parser reads dates now."),
                    u("u2", "a1", "Now add tests for the date parser please.", pid="P2"),
                    a("a2", "u2", "ABANDONED reply with tests."),
                    u("u3", None, "Start over: a new parser.", pid="P3")])
        sent = self.first_call("Now add tests for the date parser please.", "P4")
        self.assertEqual(sent["recent"], msgs(("you", "Start over: a new parser.")))

    def test_misfire_later_prompt_sends_only_conversation_and_late_fix_corrects(self):
        self.write([u("u1", None, "Please run the full test suite now.", pid="P1"),
                    a("a1", "u1", "All green."),
                    u("u2", "a1", "Fix the failing one.", pid="P2"), a("a2", "u2", "Fixed.")])
        sent = self.first_call("Please run the full test suite now.", "P3")
        self.assertEqual(sent["recent"], [], "a misfire: not exact, but nothing off the conversation")
        self.append(u("u3", "a2", "Please run the full test suite now.", pid="P3"))
        fix = Fake()
        self.assertEqual(self.late(fix), "corrected")
        self.assertEqual([m["text"] for m in fix.state()["recent"]],
                         ["Please run the full test suite now.", "All green.", "Fix the failing one.", "Fixed."])


class LateFix(Base):
    """G1, G4, G7 (c7, c9) and the late fix's limits."""

    def setup_rewind(self):
        self.write([u("u1", None, "Fix the parser so it reads dates.", pid="P1"),
                    a("a1", "u1", "The parser reads dates now.", promptId="P1"),
                    u("u2", "a1", "Abandoned prompt about tests.", pid="P2"),
                    a("a2", "u2", "ABANDONED reply.")])
        sent = self.first_call("Write the docs for it.", "P3")
        self.assertEqual(len(sent["recent"]), 4)

    def test_g1_the_prompt_line_is_found_by_its_prompt_id(self):
        self.setup_rewind()
        # a user line of another prompt comes first (another branch); then this prompt's line
        self.append(u("ux", "a2", "Some other prompt line.", pid="PX"),
                    u("u3", "a1", "Write the docs for it.", pid="P3"))
        fix = Fake()
        self.assertEqual(self.late(fix), "corrected")
        self.assertEqual([m["text"] for m in fix.state()["recent"]],
                         ["Fix the parser so it reads dates.", "The parser reads dates now."])

    def test_g1_no_line_with_the_prompt_id_no_correction(self):
        self.setup_rewind()
        self.append(u("u3", "a1", "Write the docs for it.", pid="OTHER"))
        fix = Fake()
        t0 = time.monotonic()
        self.assertEqual(self.late(fix, wait=0.3), "no prompt line")
        self.assertLess(time.monotonic() - t0, 2)
        self.assertEqual(fix.calls, [])

    def test_g1_the_line_written_while_it_waits_is_found(self):
        self.setup_rewind()
        threading.Timer(0.2, lambda: self.append(u("u3", "a1", "Write the docs for it.", pid="P3"))).start()
        self.assertEqual(self.late(Fake(), wait=3), "corrected")

    def test_g4_no_call_when_the_first_context_was_right(self):
        self.write([u("u1", None, "Fix the parser so it reads dates.", pid="P1"),
                    a("a1", "u1", "The parser reads dates now.")])
        self.first_call("Write the docs for it.", "P2")
        self.append(u("u2", "a1", "Write the docs for it.", pid="P2"))
        fix = Fake()
        self.assertEqual(self.late(fix), "right")
        self.assertEqual(fix.calls, [])
        self.assertFalse(os.path.exists(os.path.join(self.state, SID, "P2.correction.json")))

    def test_at_most_once_per_prompt(self):
        self.setup_rewind()
        self.append(u("u3", "a1", "Write the docs for it.", pid="P3"))
        sent = self.spawned[-1][-1]
        with open(sent) as f:
            keep = f.read()
        self.assertEqual(self.late(Fake()), "corrected")
        with open(sent, "w") as f:  # a second late fix for the same prompt
            f.write(keep)
        fix = Fake()
        self.assertEqual(hook.late_fix(sent, dict(self.env), transport=fix, wait=0.2), "already")
        self.assertEqual(fix.calls, [])

    def test_no_prompt_id_no_late_fix(self):
        self.write(rewound_file())
        self.first_call("Write the docs for it.", None)
        self.assertEqual(self.spawned, [])

    def test_latefix_off(self):
        self.write(rewound_file())
        self.env["S1_LATEFIX"] = "0"
        self.first_call("Write the docs for it.", "P3")
        self.assertEqual(self.spawned, [])

    def test_late_fix_jev_fails_no_correction(self):
        self.setup_rewind()
        self.append(u("u3", "a1", "Write the docs for it.", pid="P3"))
        self.assertEqual(self.late(Fake(status=500)), "no answer")
        self.assertIsNone(self.ptu("P3"))
        self.assertEqual(self.log_lines()[-1]["kind"], "correction")

    def test_g7_spawn_is_detached(self):
        seen = {}

        class P:
            def __init__(self, argv, **kw):
                seen.update(kw, argv=argv)

        real = subprocess.Popen
        subprocess.Popen = P
        try:
            hook._spawn(["x"], {"A": "1"})
        finally:
            subprocess.Popen = real
        self.assertTrue(seen.get("start_new_session"))
        for k in ("stdin", "stdout", "stderr"):
            self.assertEqual(seen.get(k), subprocess.DEVNULL, k)

    def test_g7_the_hook_never_waits_on_the_late_fix(self):
        # the real hook in a child process, with the real spawn; the late fix waits 4 s for a
        # prompt line that never comes. The hook returns at once, its output pipe closed.
        self.write(rewound_file())
        env = {"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": self.dir,
               "S1_LATEFIX_WAIT": "4", **self.env}
        code = ("import json, sys\n"
                f"sys.path.insert(0, {HERE!r})\n"
                "import hook\n"
                f"payload = {json.dumps(RECORDED['ticket_example'])!r}\n"
                "def fake(url, headers, body, timeout):\n"
                "    return 200, payload\n"
                "sys.exit(hook.main(transport=fake))\n")
        t0 = time.monotonic()
        p = subprocess.run([sys.executable, "-c", code], input=self.payload("Write the docs.", "P9"),
                           capture_output=True, text=True, env=env, cwd=ROOT, timeout=30)
        took = time.monotonic() - t0
        self.assertIn("System 1:", p.stdout)
        self.assertLess(took, 3, "the hook waited on the late fix")
        lock = os.path.join(self.state, SID, "P9.lock")
        sent = os.path.join(self.state, SID, "P9.sent.json")
        deadline = time.monotonic() + 3
        while not os.path.exists(lock) and time.monotonic() < deadline:
            time.sleep(0.05)
        self.assertTrue(os.path.exists(lock), "the late fix started")
        self.assertTrue(os.path.exists(sent), "the late fix still runs after the hook returned")
        deadline = time.monotonic() + 10
        while os.path.exists(sent) and time.monotonic() < deadline:
            time.sleep(0.1)
        self.assertFalse(os.path.exists(sent), "the late fix ended by itself")


class PostToolUse(Base):
    """G2, G3 (c8; q7; rk3)."""

    def correction(self, pid, line="System 1 (correction): work=build (0.83)"):
        os.makedirs(os.path.join(self.state, SID), exist_ok=True)
        with open(os.path.join(self.state, SID, pid + ".correction.json"), "w") as f:
            json.dump({"line": line}, f)

    def test_output_shape(self):
        self.correction("P2")
        out = posttool.run(json.dumps({"session_id": SID, "prompt_id": "P2"}), dict(self.env))
        self.assertEqual(json.loads(out), {"hookSpecificOutput": {
            "hookEventName": "PostToolUse", "additionalContext": "System 1 (correction): work=build (0.83)"}})

    def test_g2_only_the_correction_of_its_own_prompt(self):
        self.correction("P2")
        self.assertIsNone(self.ptu("P3"))
        self.assertIsNone(self.ptu("P2", session_id="other-session"))
        self.assertIsNotNone(self.ptu("P2"))

    def test_g3_claimed_once(self):
        self.correction("P2")
        self.assertIsNotNone(self.ptu("P2"))
        self.assertIsNone(self.ptu("P2"))

    def test_g3_parallel_tool_calls_get_it_once(self):
        self.correction("P2")
        got, go = [], threading.Event()

        def one():
            go.wait()
            got.append(self.ptu("P2"))

        ts = [threading.Thread(target=one) for _ in range(8)]
        for t in ts:
            t.start()
        go.set()
        for t in ts:
            t.join()
        self.assertEqual(sum(1 for g in got if g), 1)

    def test_q7_subagent_gets_nothing(self):
        self.correction("P2")
        self.assertIsNone(self.ptu("P2", agent_id="a-1"))
        self.assertIsNotNone(self.ptu("P2"))

    def test_bad_input_and_off_print_nothing(self):
        self.correction("P2")
        for raw in ("", "not json", "[]", json.dumps({"session_id": SID}),
                    json.dumps({"session_id": "../x", "prompt_id": "P2"})):
            self.assertEqual(posttool.run(raw, dict(self.env)), "", raw)
        self.assertEqual(posttool.run(json.dumps({"session_id": SID, "prompt_id": "P2"}),
                                      dict(self.env, S1_OFF="1")), "")

    def test_rk3_script_is_fast_and_silent_with_nothing_to_give(self):
        env = {"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": self.dir, **self.env}
        t0 = time.monotonic()
        p = subprocess.run([sys.executable, os.path.join(HERE, "posttool.py")],
                           input=json.dumps({"session_id": SID, "prompt_id": "P2"}),
                           capture_output=True, text=True, env=env, timeout=30)
        self.assertEqual((p.returncode, p.stdout, p.stderr), (0, "", ""))
        self.assertLess(time.monotonic() - t0, 2)
        with open(os.path.join(HERE, "posttool.py")) as f:
            src = f.read()
        self.assertNotIn("import jev", src)
        self.assertNotIn("import hook", src)


class Docs(unittest.TestCase):
    def test_readme_has_the_post_tool_use_snippet(self):
        with open(os.path.join(HERE, "README.md")) as f:
            readme = f.read()
        self.assertIn('"PostToolUse"', readme)
        self.assertIn("python3 ~/.claude/sagittarius-s1/posttool.py", readme)
        self.assertIn("parentUuid", readme)


if __name__ == "__main__":
    unittest.main()
