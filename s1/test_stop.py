"""Tests of the stop event of System 1 (scientific-method-overhaul c30, c35). No network.

    python3 -m unittest s1.test_stop -v
"""
import json
import os
import subprocess
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import test_record as tr  # noqa: E402
import trees  # noqa: E402
from test_hook import Fake  # noqa: E402
from test_trees import ch, no  # noqa: E402

DRIFT = {"d_success": no(0.9), "d_kept@0": ch("accounted"), "d_revised@0": no(0.1),
         "d_kept@1": ch("dropped"), "d_revised@1": no(0.1)}
REVISED = dict(DRIFT, **{"d_revised@1": no(0.9)})


class Base(tr.Base):
    def setUp(self):
        super().setUp()
        with open(self.env["S1_QUESTIONS"]) as f:
            qs = json.load(f)
        self.shipped = self.env["S1_QUESTIONS"]
        cand = trees.load()
        qs.update({k: cand[k] for k in trees.STOP_IDS})  # as after a promotion
        self.promoted = os.path.join(self.dir, "promoted.json")
        with open(self.promoted, "w") as f:
            json.dump(qs, f)
        stub = self.stub(f"if argv[0] == 's1-record':\n    print(json.dumps({tr.RECORD!r}))\n")
        os.makedirs(os.path.join(self.dir, "specs", "replayed-imports"))
        self.hub()
        self.env = dict(self.env, S1_QUESTIONS=self.promoted, S1_ORBIT=stub,
                        S1_SESSION_DIR=os.path.join(self.dir, "sess"))

    def stop(self, answers, env=None, **kw):
        import stop
        p = {"session_id": "sess-fixture-1", "transcript_path": self.transcript, "cwd": self.dir,
             "hook_event_name": "Stop", "stop_hook_active": False, "prompt_id": "P1",
             "last_assistant_message": "The replay is safe: the member count matches. Done."}
        p.update(kw)
        fake = Fake({"model": "jev-1.14.0", "answers": answers})
        return stop.run(json.dumps(p), self.env if env is None else env, transport=fake), fake


class C30Stop(Base):
    def test_inert_until_the_drift_questions_ship(self):
        out, fake = self.stop(DRIFT, env=dict(self.env, S1_QUESTIONS=self.shipped))
        self.assertEqual((out, fake.calls, self.calls()), ("", [], []))
        self.assertFalse(os.path.exists(self.log))
        p = subprocess.run([sys.executable, os.path.join(HERE, "hook.py"), "--event", "stop"],
                           input=json.dumps({"hook_event_name": "Stop", "session_id": "s", "cwd": self.dir}),
                           capture_output=True, text=True, env={"PATH": os.environ["PATH"], "HOME": self.dir,
                                                                "S1_WORKBENCH": "off", "TYPESAFE_API_KEY": "k"})
        self.assertEqual((p.returncode, p.stdout), (0, ""))  # the released file: nothing live

    def test_a_prompt_is_not_asked_the_questions_of_a_tree_that_shipped(self):
        fake = Fake()
        self.assertEqual(self.context(self.run_hook(fake)), tr.TICKET_LINE)
        sent = json.loads(fake.calls[0]["body"])["questions"]
        self.assertEqual(sorted(sent), sorted(json.load(open(self.shipped))))

    def test_a_drift_gives_one_hint_that_names_the_prediction(self):
        out, fake = self.stop(DRIFT)
        d = json.loads(out)["hookSpecificOutput"]
        self.assertEqual(d["hookEventName"], "Stop")
        self.assertIn("The original prediction included c2 of hy1", d["additionalContext"])
        self.assertIn("What happened to that part?", d["additionalContext"])
        st = fake.state()
        self.assertEqual(list(st), ["context", "delivery", "recent", "record"])
        self.assertTrue(st["delivery"].startswith("The replay is safe"))
        line = [r for r in self.log_lines() if r.get("stop")][0]
        self.assertEqual((line["event"], line["stop"]["drifts"]), ("stop", ["c2"]))
        self.assertIn("claim:c2", line["record_sent"])

    def test_it_never_loops(self):
        self.assertEqual(self.stop(DRIFT, stop_hook_active=True)[0], "")
        self.assertNotEqual(self.stop(DRIFT)[0], "")
        out, fake = self.stop(DRIFT)  # the same prompt again: no second hint, no second call
        self.assertEqual((out, fake.calls), ("", []))
        self.assertNotEqual(self.stop(DRIFT, prompt_id="P2")[0], "")

    def test_block_mode_is_a_setting(self):
        out, _ = self.stop(DRIFT, env=dict(self.env, S1_STOP_MODE="block"))
        self.assertEqual(json.loads(out)["decision"], "block")

    def test_a_revision_by_the_human_gives_no_hint_and_is_proposed(self):
        out, _ = self.stop(REVISED)
        self.assertEqual(out, "")
        props = [c for c in self.calls() if c[0] == "propose"]
        self.assertEqual(len(props), 1)
        self.assertEqual(props[0][1:3], ["--from", "system1"])
        self.assertTrue(props[0][3].startswith("note(c2, '"))
        self.assertEqual(props[0][-2:], ["--dir", os.path.join(self.dir, "specs", "replayed-imports")])

    def test_fails_open(self):
        import stop
        self.assertEqual(stop.run("not json", self.env), "")
        self.assertEqual(self.stop({})[0], "")  # no answers
        self.assertEqual(self.stop(DRIFT, env=dict(self.env, S1_ORBIT="/no/such"))[0], "")  # no record
        self.assertEqual(self.stop(DRIFT, env=dict(self.env, S1_OFF="1"))[0], "")
        self.assertEqual(self.stop(DRIFT, agent_id="a1")[0], "")


if __name__ == "__main__":
    unittest.main()
