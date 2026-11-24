"""Tests of the hook with decision trees that shipped (scientific-method-overhaul c31 to c34):
the questions file of these tests holds the candidate trees, as after a promotion. No network.

    python3 -m unittest s1.test_trees_hook -v
"""
import json
import os
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import test_record as tr  # noqa: E402
import trees  # noqa: E402
from test_hook import Fake, RECORDED  # noqa: E402
from test_trees import ch, no  # noqa: E402

PROMPT = "Q4: the default is good. Orbit is the front door to every store. Fix the typo in the help."


class Base(tr.Base):
    def setUp(self):
        super().setUp()
        with open(self.env["S1_QUESTIONS"]) as f:
            self.shipped = json.load(f)
        cand = trees.load()
        qs = dict(self.shipped, **{k: cand[k] for k in trees.PROMPT_IDS})
        p = os.path.join(self.dir, "promoted.json")
        with open(p, "w") as f:
            json.dump(qs, f)
        self.kb = os.path.join(self.dir, "specs", "replayed-imports")
        os.makedirs(self.kb)
        self.hub()
        self.env = dict(self.env, S1_QUESTIONS=p, S1_SESSION_DIR=os.path.join(self.dir, "sess"),
                        S1_ORBIT=self.stub(f"if argv[0] == 's1-record':\n    print(json.dumps({tr.RECORD!r}))\n"))

    def go(self, tree_answers, prompt=PROMPT, env=None):
        resp = json.loads(json.dumps(RECORDED["thanks"]))
        resp["answers"].update(tree_answers)
        fake = Fake(resp)
        line = self.context(self.run_hook(fake, raw=self.payload(prompt=prompt), env=env))
        return line, fake

    def proposals(self):
        return [c for c in self.calls() if c[0] == "propose"]


ANSWERS = {"r_count": ch("three"),
           "r_kind@0": ch("answer"), "r_goal@0": ch("none"),
           "r_kind@1": ch("hypothesis"), "r_goal@1": ch("g0"),
           "r_kind@2": ch("task"), "r_goal@2": ch("g0", 0.3),
           "x_dispute": no(0.1), "x_kind": ch("none"), "y_differs@0_1": ch("inside")}


class C33C34Requests(Base):
    def test_each_request_is_proposed_with_its_kind_and_its_goal(self):
        line, fake = self.go(ANSWERS)
        sent = json.loads(fake.calls[0]["body"])
        self.assertEqual(sent["state"]["sentences"][1], "Orbit is the front door to every store.")
        for qid in list(self.shipped) + ["r_count", "r_kind@2", "r_goal@0", "x_dispute", "x_kind", "y_differs@0_1"]:
            self.assertIn(qid, sent["questions"])
        self.assertNotIn("r_kind", sent["questions"])  # the entry with a placeholder is never sent as it is
        self.assertIn("requests: 3 (answer for no goal; hypothesis for pg1; task)", line)
        self.assertTrue(line.endswith("3 proposals wait (orbit show proposals)"), line)
        props = self.proposals()
        self.assertEqual([p[1:3] for p in props], [["--from", "system1"]] * 3)
        self.assertRegex(props[0][3], r"^request\(s1_r[0-9a-f]{8}, 'Q4: the default is good\.'\)$")
        # c34: the hypothesis of the human, word for word, under the goal of the record
        self.assertRegex(props[1][3], r"^hypothesis\(s1_h[0-9a-f]{8}, g1, human, 'Orbit is the front door to every store\.'\)$")
        self.assertEqual(props[1][4:6], ["--note", "System 1: a request of kind hypothesis; serves pg1"])
        self.assertEqual(props[2][5], "System 1: a request of kind task; serves goal not known")
        self.assertEqual(props[0][-2:], ["--dir", self.kb])
        t = [r for r in self.log_lines() if r.get("trees")][0]["trees"]
        self.assertEqual((t["count"], t["proposed"], [r["kind"] for r in t["requests"]]), (3, 3, ["answer", "hypothesis", "task"]))

    def test_the_same_request_is_not_proposed_twice_in_a_session(self):
        self.go(ANSWERS)
        line, _ = self.go(ANSWERS)
        self.assertEqual(len(self.proposals()), 3)
        self.assertNotIn("proposal", line)

    def test_a_tool_with_no_propose_is_tolerated(self):
        env = dict(self.env, S1_ORBIT=self.stub(
            f"if argv[0] == 's1-record':\n    print(json.dumps({tr.RECORD!r}))\nelse:\n    sys.exit(2)\n"))
        line, _ = self.go(ANSWERS, env=env)
        self.assertIn("requests: 3", line)
        self.assertNotIn("proposal", line)

    def test_a_message_that_the_human_did_not_write_has_no_requests(self):
        line, fake = self.go(ANSWERS, prompt="<task-notification>The subagent ended. Fix it.</task-notification>")
        sent = json.loads(fake.calls[0]["body"])["questions"]
        self.assertNotIn("r_count", sent)
        self.assertNotIn("x_dispute", sent)
        self.assertNotIn("requests", line)
        self.assertEqual(self.proposals(), [])

    def test_with_no_ticket_a_goal_and_a_hypothesis_are_what_the_session_stated(self):
        none = dict(tr.RECORD, ticket=None, goal=None, hypotheses=[], questions=[])
        env = dict(self.env, S1_ORBIT=self.stub(f"if argv[0] == 's1-record':\n    print(json.dumps({none!r}))\n"))
        a = dict(ANSWERS, **{"r_kind@0": ch("goal")})
        del a["y_differs@0_1"]
        self.go(a, env=env)
        self.assertEqual(self.proposals(), [])  # no KB of a ticket: nothing to propose into
        _, fake = self.go(a, env=env)  # the next prompt has them in its state (q24, c29)
        r = fake.state()["record"]
        self.assertEqual(r["goal"]["text"], "Q4: the default is good.")
        self.assertEqual([h["text"] for h in r["hypotheses"]], ["Orbit is the front door to every store."])


class C31C32(Base):
    def test_the_line_names_the_kind_of_dispute(self):
        line, _ = self.go(dict(ANSWERS, r_count=ch("none"), x_dispute=no(0.9), x_kind=ch("outputs")))
        self.assertIn("a formal tool can settle it (prolog)", line)
        line, _ = self.go(dict(ANSWERS, r_count=ch("none"), x_dispute=no(0.9), x_kind=ch("wanted")))
        self.assertIn("judgment of that case by the human", line)
        line, _ = self.go(dict(ANSWERS, r_count=ch("none"), x_dispute=no(0.5), x_kind=ch("outputs")))
        self.assertNotIn("dispute", line)

    def test_a_difference_for_a_user_is_one_question_on_the_goal_asked_once(self):
        line, _ = self.go(dict(ANSWERS, r_count=ch("none"), **{"y_differs@0_1": ch("user")}))
        self.assertIn("hypotheses hy1 and hy2 differ in what a user experiences: a question for the human", line)
        props = self.proposals()
        self.assertEqual(len(props), 1)
        self.assertRegex(props[0][3], r"^question\(s1_q[0-9a-f]{8}, g1, 'Hypotheses hy1 and hy2 differ")
        line, fake = self.go(dict(ANSWERS, r_count=ch("none")))  # the pair is not asked again
        self.assertNotIn("y_differs@0_1", json.loads(fake.calls[0]["body"])["questions"])
        self.assertEqual(len(self.proposals()), 1)

    def test_a_difference_only_inside_raises_no_question(self):
        line, _ = self.go(dict(ANSWERS, r_count=ch("none")))
        self.assertNotIn("differ", line)
        self.assertEqual(self.proposals(), [])


if __name__ == "__main__":
    unittest.main()
