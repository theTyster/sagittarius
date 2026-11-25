"""Tests of the time limit of the hook with every candidate question on (system-1-questions c4,
preserve). The questions file of these tests holds all ten ids of the trees; the state is the
largest one (12 predictions, 3 pairs of hypotheses, 30 parts). A stubbed transport: no network,
no model call. The live measure is c17, not here.

    python3 -m unittest s1.test_latency -v
"""
import io
import json
import os
import sys
import time
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import hook as hook_mod  # noqa: E402
import test_record as tr  # noqa: E402
import trees  # noqa: E402
from test_hook import Fake, RECORDED  # noqa: E402
from test_trees import ch, no  # noqa: E402

LIMIT = hook_mod.DEFAULT_TIMEOUT  # 4 s
SLOW = 3.0  # the stub is slower than the limit that the slow tests set
SHORT = 1.0  # S1_TIMEOUT of the slow tests, to keep them short; the rule is the same as for 4 s

BIG_RECORD = dict(tr.RECORD, hypotheses=[
    {"id": f"hy{h}", "author": "human", "state": "adopted", "text": f"Hypothesis {h}.", "defeating_case": None,
     "predictions": [{"id": f"c{h}{i}", "text": f"Prediction {h}{i} " + "of the matter in hand " * 6} for i in range(3)]}
    for h in range(4)])  # 12 predictions; 6 pairs, of which 3 are asked
# 175 sentences are packed by hook.split_parts into exactly 30 parts
MESSAGE = " ".join(f"Please do item number {i} of the list with care, and tell me once it is done and checked."
                   for i in range(175))
SLACK = 0.1  # seconds of scheduling past "the limit plus 0.5 s"


def drift_answers():
    a = {"d_success": no(0.9)}
    for i in range(12):
        a[f"d_kept@{i}"] = ch("dropped")
        a[f"d_revised@{i}"] = no(0.1)
    return a


class Echo(Fake):
    """A stub that answers every question that it is asked (sleep: after that many seconds)."""

    def __init__(self, sleep=0):
        super().__init__({}, sleep=sleep)

    def __call__(self, url, headers, body, timeout):
        qs = json.loads(body)["questions"]
        self.payload = {"model": "jev-1.14.0", "answers": {
            k: no(0.1) if q["type"] == "noul" else ch("five_or_more" if k == "r_count" else "task" if k.startswith("r_kind")
                                                      else list(q.get("criteria") or {"none": 0})[0]) for k, q in qs.items()}}
        return super().__call__(url, headers, body, timeout)


class Base(tr.Base):
    def setUp(self):
        super().setUp()
        cand = trees.load()
        qs = json.load(open(self.env["S1_QUESTIONS"]))
        qs.update({k: cand[k] for k in trees.PROMPT_IDS + trees.STOP_IDS + ("d_drift",)})
        self.assertEqual(len([k for k in qs if k in cand and not k.startswith("_")]), 10)
        p = os.path.join(self.dir, "all-ten.json")
        with open(p, "w") as f:
            json.dump(qs, f)
        os.makedirs(os.path.join(self.dir, "specs", "replayed-imports"))
        self.hub()
        self.env = dict(self.env, S1_QUESTIONS=p, S1_SESSION_DIR=os.path.join(self.dir, "sess"),
                        S1_ORBIT=self.stub(f"if argv[0] == 's1-record':\n    print(json.dumps({BIG_RECORD!r}))\n"))

    def stop_payload(self):
        return json.dumps({"session_id": "sess-fixture-1", "transcript_path": self.transcript, "cwd": self.dir,
                           "hook_event_name": "Stop", "stop_hook_active": False, "prompt_id": "P1",
                           "last_assistant_message": "All done: every item of the list is finished."})

    def timed(self, fn):
        t0 = time.monotonic()
        out = fn()
        return out, time.monotonic() - t0

    def main_exit(self, module, raw, fake, env):
        """The script entry of a module: its exit code and stdout, with stdin given."""
        old = sys.stdin, sys.stdout, os.environ.copy()
        sys.stdin, sys.stdout = io.StringIO(raw), io.StringIO()
        os.environ.clear()
        os.environ.update(env)
        try:
            code = module.main(transport=fake)
            return code, sys.stdout.getvalue()
        finally:
            sys.stdin, sys.stdout = old[0], old[1]
            os.environ.clear()
            os.environ.update(old[2])


class C4PromptEvent(Base):
    def test_all_ten_on_the_largest_state_the_prompt_answers_inside_the_limit(self):
        import stop  # noqa: F401  (the event of the prompt is the hook itself)
        fake = Echo()
        out, took = self.timed(lambda: hook_mod.run(self.payload(prompt=MESSAGE), self.env, transport=fake))
        sent = json.loads(fake.calls[0]["body"])
        self.assertEqual(len(sent["state"]["sentences"]), 30)  # the largest state: 30 parts ...
        self.assertEqual(len([q for q in sent["questions"] if q.startswith("y_differs@")]), 3)  # ... 3 pairs
        self.assertIn("r_kind@29", sent["questions"])
        self.assertLess(took, LIMIT, f"took {took:.2f} s")
        self.assertIn("requests:", self.context(out))

    def test_a_slow_model_gives_no_hint_and_exit_0_inside_the_limit_plus_half_a_second(self):
        env = dict(self.env, S1_TIMEOUT=str(SHORT))
        fake = Echo(sleep=SLOW)
        (code, out), took = self.timed(lambda: self.main_exit(hook_mod, self.payload(prompt=MESSAGE), fake, env))
        self.assertEqual(code, 0)
        self.assertLessEqual(took, SHORT + 0.5 + SLACK, f"took {took:.2f} s")
        for w in ("requests:", "dispute:", "differ in what a user"):
            self.assertNotIn(w, out)
        # the hook says "no view" in one short line when it gave up (0.3.0 S-A); that is its own rule
        self.assertTrue(out == "" or "no view" in out, out)


class C4StopEvent(Base):
    def test_all_ten_on_the_largest_state_the_stop_event_answers_inside_the_limit(self):
        import stop
        fake = Fake({"model": "jev-1.14.0", "answers": drift_answers()})
        out, took = self.timed(lambda: stop.run(self.stop_payload(), self.env, transport=fake))
        asked = json.loads(fake.calls[0]["body"])["questions"]
        self.assertEqual(len([q for q in asked if q.startswith("d_kept@")]), 12)  # 12 predictions
        self.assertLess(took, LIMIT, f"took {took:.2f} s")
        self.assertIn("What happened to those parts?", json.loads(out)["hookSpecificOutput"]["additionalContext"])

    def test_a_slow_model_gives_no_output_and_exit_0_inside_the_limit_plus_half_a_second(self):
        import stop
        env = dict(self.env, S1_TIMEOUT=str(SHORT))
        fake = Fake({"model": "jev-1.14.0", "answers": drift_answers()}, sleep=SLOW)
        (code, out), took = self.timed(lambda: self.main_exit(stop, self.stop_payload(), fake, env))
        self.assertEqual((code, out), (0, ""))
        self.assertLessEqual(took, SHORT + 0.5 + SLACK, f"took {took:.2f} s")


if __name__ == "__main__":
    unittest.main()
