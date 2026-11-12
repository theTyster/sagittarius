"""Tests for s1/observe.py (0.3.0, suggestion 3, claim c_sg3_1b): the observation harness that compares
the System 1 log with the session transcripts after the fact. No network. Every transcript and log
line here is invented.

Run from the repo root:  python3 -m unittest s1.test_observe -v

The interface under test:
    python3 s1/observe.py --log FILE --transcripts DIR [--json] [--session ID]
    observe.observe(log_path, transcripts_dir, session=None) -> dict with the counts
        hints, shifted_after_hint, disputed, shifts_without_hint (and per session, and the limits)
"""
import json
import os
import subprocess
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
SCRIPT = os.path.join(HERE, "observe.py")
COUNTS = ("hints", "shifted_after_hint", "disputed", "shifts_without_hint")
NONE_SIGNALS = ("Signals:     questions: no, divergence: no, someone else built: no, burns: no, "
                "handoff: no, effort: no")


def observe():
    import observe as m  # imported per test, so a missing module fails each test alone
    return m


def answers(div=0.5, plan=0.5, effort=0.5, extra=None):
    a = {"h_work": {"type": "choice", "choice": "build", "confidence": 0.9, "probabilities": {"build": 0.9}},
         "h_divergence": {"type": "noul", "noul": div}, "h_change_of_plan": {"type": "noul", "noul": plan},
         "h_effort": {"type": "noul", "noul": effort},
         "h_language": {"type": "choice", "choice": "none", "confidence": 0.9, "probabilities": {"none": 0.9}}}
    a.update(extra or {})
    return a


def hint(t, ans, session="s-1", message=None):
    rec = {"time": t, "session_id": session, "transcript": session + ".jsonl", "model": "test",
           "questions": list(ans), "answers": ans, "latency": 0.1, "usage": None, "error": None}
    if message is not None:
        rec["state"] = {"message": message, "recent": []}
    return rec


def turn(t, user, agent, mid, session="s-1"):
    return [{"type": "user", "timestamp": t, "sessionId": session, "message": {"role": "user", "content": user}},
            {"type": "assistant", "timestamp": t[:-4] + "30Z", "sessionId": session,
             "message": {"id": mid, "role": "assistant", "content": [{"type": "text", "text": agent}]}}]


class Case(unittest.TestCase):
    def setUp(self):
        d = tempfile.TemporaryDirectory()
        self.addCleanup(d.cleanup)
        self.dir = d.name
        self.log = os.path.join(d.name, "s1.jsonl")
        self.tdir = os.path.join(d.name, "projects")
        os.makedirs(self.tdir)

    def write_log(self, *recs):
        with open(self.log, "w") as f:
            for r in recs:
                f.write((r if isinstance(r, str) else json.dumps(r)) + "\n")

    def write_session(self, lines, session="s-1", sub=""):
        d = os.path.join(self.tdir, sub)
        os.makedirs(d, exist_ok=True)
        with open(os.path.join(d, session + ".jsonl"), "w") as f:
            for e in lines:
                f.write(json.dumps(e) + "\n")

    def counts(self, **kw):
        got = observe().observe(self.log, self.tdir, **kw)
        return {k: got[k] for k in COUNTS}

    def cli(self, *args):
        return subprocess.run([sys.executable, SCRIPT, "--log", self.log, "--transcripts", self.tdir, *args],
                              capture_output=True, text=True, stdin=subprocess.DEVNULL, timeout=60)


class TicketExamples(Case):
    """The two examples of the claim."""

    def three_turns(self):
        self.write_log(hint("2026-11-12T10:00:00Z", answers(div=0.85)),
                       hint("2026-11-12T10:10:00Z", answers(effort=0.91)),
                       hint("2026-11-12T10:20:00Z", answers()))
        self.write_session(
            turn("2026-11-12T10:00:00Z", "no, that is not what I asked for",
                 "Shifting up: the result differs from the request. Next: the claim.", "m1")
            + turn("2026-11-12T10:10:00Z", "a long message about the totals",
                   "Delivered:   the totals are fixed\n" + NONE_SIGNALS, "m2")
            + turn("2026-11-12T10:20:00Z", "ok",
                   "Shifting up: I expected the check to fail, and it passed. Next: the check.", "m3"))

    def test_first_example(self):
        self.three_turns()
        self.assertEqual(self.counts(), {"hints": 2, "shifted_after_hint": 1, "disputed": 1, "shifts_without_hint": 1})

    def test_second_example(self):
        self.write_log(hint("2026-11-12T10:00:00Z", answers(div=0.85)))
        self.write_session(turn("2026-11-12T10:00:00Z", "no, that is wrong", "I will look again.", "m1"))
        self.assertEqual(self.counts(), {"hints": 1, "shifted_after_hint": 0, "disputed": 0, "shifts_without_hint": 0})

    def test_cli_json(self):
        self.three_turns()
        r = self.cli("--json")
        self.assertEqual(r.returncode, 0, r.stderr)
        got = json.loads(r.stdout)
        self.assertEqual({k: got[k] for k in COUNTS},
                         {"hints": 2, "shifted_after_hint": 1, "disputed": 1, "shifts_without_hint": 1})
        self.assertIn("s-1", got["sessions"])
        self.assertTrue(got["limits"])

    def test_cli_text_says_the_counts_and_the_limits(self):
        self.three_turns()
        r = self.cli()
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("2 hints named a signal", r.stdout)
        self.assertIn("shifted up after 1", r.stdout)
        self.assertIn("disputed 1", r.stdout)
        self.assertIn("1 time with no hint", r.stdout)
        self.assertIn("Shifting up:", r.stdout)  # a limit: other words for a shift are missed


class Rules(Case):
    def test_unsure_and_unlikely_answers_are_not_hints(self):
        self.write_log(hint("2026-11-12T10:00:00Z", answers(div=0.1, plan=0.2, effort=0.6)))
        self.write_session(turn("2026-11-12T10:00:00Z", "thanks", "Done.", "m1"))
        self.assertEqual(self.counts()["hints"], 0)

    def test_change_of_plan_and_the_new_answers_name_signals(self):
        self.write_log(hint("2026-11-12T10:00:00Z", answers(plan=0.8)),
                       hint("2026-11-12T10:01:00Z", answers(extra={"h_proof": {"type": "noul", "noul": 0.9}})),
                       hint("2026-11-12T10:02:00Z", answers(extra={"h_questions": {"type": "noul", "noul": 0.9}})))
        self.write_session(turn("2026-11-12T10:00:00Z", "a", "b", "m1") + turn("2026-11-12T10:01:00Z", "c", "d", "m2")
                           + turn("2026-11-12T10:02:00Z", "e", "f", "m3"))
        self.assertEqual(self.counts()["hints"], 3)

    def test_skipped_and_failed_lines_are_not_hints(self):
        self.write_log({"time": "2026-11-12T10:00:00Z", "skipped": "no API key", "session_id": "s-1",
                        "transcript": "s-1.jsonl", "answers": None, "error": "missing API key"},
                       dict(hint("2026-11-12T10:00:01Z", answers(div=0.9)), error="timeout", answers=None),
                       "not json")
        self.write_session(turn("2026-11-12T10:00:00Z", "a", "Shifting up: x. Next: y.", "m1"))
        got = self.counts()
        self.assertEqual(got["hints"], 0)
        self.assertEqual(got["shifts_without_hint"], 1)

    def test_a_dispute_needs_no_for_the_signal_that_the_hint_named(self):
        # the hint names effort; the delivery says "no" only for divergence: not a dispute
        self.write_log(hint("2026-11-12T10:00:00Z", answers(effort=0.9)))
        self.write_session(turn("2026-11-12T10:00:00Z", "a long message",
                                "Delivered:   done\nSignals:     divergence: no, effort: yes, the long message", "m1"))
        self.assertEqual(self.counts()["disputed"], 0)

    def test_a_dispute_in_one_line_with_no_delivery_is_not_counted(self):
        self.write_log(hint("2026-11-12T10:00:00Z", answers(div=0.9)))
        self.write_session(turn("2026-11-12T10:00:00Z", "hm", "I do not think that this is a divergence.", "m1"))
        self.assertEqual(self.counts()["disputed"], 0)

    def test_the_hint_goes_to_the_turn_of_its_prompt_by_the_message_text(self):
        # the log line has the prompt as sent: that decides the turn, not the clock
        self.write_log(hint("2026-11-12T10:05:00Z", answers(div=0.9), message="second"))
        self.write_session(turn("2026-11-12T10:04:59Z", "first", "Shifting up: x. Next: y.", "m1")
                           + turn("2026-11-12T10:05:30Z", "second", "Fine.", "m2"))
        got = self.counts()
        self.assertEqual((got["hints"], got["shifted_after_hint"], got["shifts_without_hint"]), (1, 0, 1))

    def test_the_agent_reply_is_the_whole_turn(self):
        # a shift in a later block of the same turn counts; tool results do not end the turn
        lines = turn("2026-11-12T10:00:00Z", "no", "Let me look.", "m1")
        lines += [{"type": "user", "timestamp": "2026-11-12T10:00:40Z", "sessionId": "s-1",
                   "message": {"role": "user", "content": [{"type": "tool_result", "tool_use_id": "t", "content": "ok"}]}},
                  {"type": "assistant", "timestamp": "2026-11-12T10:00:50Z", "sessionId": "s-1",
                   "message": {"id": "m2", "role": "assistant",
                               "content": [{"type": "text", "text": "**Shifting up:** the check passed. Next: the KB."}]}}]
        self.write_log(hint("2026-11-12T10:00:00Z", answers(div=0.9)))
        self.write_session(lines)
        self.assertEqual(self.counts()["shifted_after_hint"], 1)

    def test_transcripts_are_found_below_the_folder(self):
        self.write_log(hint("2026-11-12T10:00:00Z", answers(div=0.9)))
        self.write_session(turn("2026-11-12T10:00:00Z", "no", "Shifting up: x. Next: y.", "m1"), sub="-home-someone-proj")
        self.assertEqual(self.counts()["shifted_after_hint"], 1)

    def test_a_session_with_no_transcript_still_counts_its_hints(self):
        self.write_log(hint("2026-11-12T10:00:00Z", answers(div=0.9), session="gone"))
        got = observe().observe(self.log, self.tdir)
        self.assertEqual(got["hints"], 1)
        self.assertEqual(got["sessions"]["gone"]["transcript"], None)

    def test_session_filter(self):
        self.write_log(hint("2026-11-12T10:00:00Z", answers(div=0.9), session="s-1"),
                       hint("2026-11-12T10:00:00Z", answers(div=0.9), session="s-2"))
        self.write_session(turn("2026-11-12T10:00:00Z", "no", "ok", "m1"), session="s-1")
        self.write_session(turn("2026-11-12T10:00:00Z", "no", "ok", "m1"), session="s-2")
        self.assertEqual(self.counts(session="s-2")["hints"], 1)
        self.assertEqual(self.counts()["hints"], 2)

    def test_missing_log_is_an_error(self):
        r = subprocess.run([sys.executable, SCRIPT, "--log", os.path.join(self.dir, "none.jsonl"),
                            "--transcripts", self.tdir], capture_output=True, text=True, timeout=60)
        self.assertEqual(r.returncode, 2)
        self.assertIn("none.jsonl", r.stderr)


class ReviewForms(Case):
    """Review of 0.3.0 (finding 6): the forms of a dispute that a delivery uses, a repeated short prompt,
    and limits that say what the counts are."""

    def test_a_bare_no_disputes_every_signal(self):
        self.write_log(hint("2026-11-12T10:00:00Z", answers(div=0.9)))
        self.write_session(turn("2026-11-12T10:00:00Z", "hm", "Delivered:   done\nSignals:     no", "m1"))
        self.assertEqual(self.counts()["disputed"], 1)

    def test_a_bold_field_name_counts(self):
        self.write_log(hint("2026-11-12T10:00:00Z", answers(div=0.9)))
        self.write_session(turn("2026-11-12T10:00:00Z", "hm",
                                "**Delivered:** done\n**Signals:** divergence: no, effort: no", "m1"))
        self.assertEqual(self.counts()["disputed"], 1)

    def test_a_repeated_prompt_goes_to_the_turn_nearest_in_time(self):
        self.write_log(hint("2026-11-12T10:00:00Z", answers(div=0.9), message="ok"))
        self.write_session(turn("2026-11-12T10:00:00Z", "ok", "Shifting up: x. Next: y.", "m1")
                           + turn("2026-11-12T10:20:00Z", "ok", "Fine.", "m2"))
        got = self.counts()
        self.assertEqual((got["shifted_after_hint"], got["shifts_without_hint"]), (1, 0))

    def test_a_hint_by_time_alone_stays_within_the_window(self):
        self.write_log(hint("2026-11-12T10:00:00Z", answers(div=0.9)))
        self.write_session(turn("2026-11-12T11:00:00Z", "later", "Shifting up: x. Next: y.", "m1"))
        got = observe().observe(self.log, self.tdir)
        self.assertEqual((got["unmatched_hints"], got["shifts_without_hint"]), (1, 1))

    def test_the_limits_say_what_is_missed(self):
        limits = " ".join(observe().observe(self.write_log() or self.log, self.tdir)["limits"])
        self.assertIn("table", limits)  # a Signals field in a table is not read
        self.assertRegex(limits, r"shifts_without_hint counts turns")
        self.assertIn("same text", limits)  # prompts with the same text: the nearest in time


class NoHookChange(unittest.TestCase):
    """q_sg3 default (a): the agent is not made to acknowledge a hint. The harness reads afterwards."""

    def test_the_hook_does_not_ask_for_an_acknowledgment(self):
        text = open(os.path.join(HERE, "hook.py")).read()
        self.assertNotRegex(text, r"(?i)acknowledge|reply with|answer this")

    def test_observe_reads_only(self):
        text = open(SCRIPT).read()
        for word in ("urllib", "http.client", "socket", "settings.json"):
            self.assertNotIn(word, text)


if __name__ == "__main__":
    unittest.main()
