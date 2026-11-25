"""Tests of the rules of the candidate questions (scientific-method-overhaul c30 to c33, c35):
the logic given the answers of the model. Fixture answers only; no call.

    python3 -m unittest s1.test_trees -v
"""
import json
import os
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import trees  # noqa: E402
from test_record import RECORD  # noqa: E402


def ch(c, p=0.9):
    return {"type": "choice", "choice": c, "confidence": p, "probabilities": {c: p}}


def no(p):
    return {"type": "noul", "noul": p}


TREE = trees.load()


class C35NotPromoted(unittest.TestCase):
    """c35, k35: the question file of the release holds only questions whose experiment gave meets.
    No replay was run, so no candidate is in s1/questions.json."""

    def test_no_candidate_is_in_the_question_file(self):
        with open(os.path.join(HERE, "questions.json")) as f:
            shipped = json.load(f)
        self.assertEqual(sorted(set(shipped) & set(TREE)), [])
        self.assertEqual(sorted(shipped), sorted(["h_work", "h_divergence", "h_change_of_plan", "h_effort",
                                                  "h_language", "h_questions", "h_proof"]))  # the set of 0.7.2

    def test_the_candidate_file_has_each_tree_in_the_format_of_the_question_file(self):
        for qid in trees.PROMPT_IDS + trees.STOP_IDS + ("d_drift",):
            self.assertIn(TREE[qid]["type"], ("noul", "choice"), qid)
            self.assertIsInstance(TREE[qid]["instructions"], str)
            self.assertLessEqual(set(TREE[qid]), {"type", "instructions", "criteria"})
        self.assertEqual(list(TREE["r_kind"]["criteria"])[:6], list(trees.KINDS))


PARTS = ["Q4: the default is good.", "Orbit is the front door to every store.", "It joins the ledger too.",
         "Thanks for the summary."]


class C33Requests(unittest.TestCase):
    """c33, k33: each request of a message gets a kind, and a goal or none."""

    def test_the_questions_of_the_tree_count_first(self):
        asked = trees.ask_requests(TREE, PARTS, RECORD)
        self.assertEqual(list(asked)[0], "r_count")
        self.assertIn("`sentences[1]`", asked["r_kind@1"]["instructions"])
        self.assertEqual(asked["r_goal@0"]["criteria"], {"g0": RECORD["goal_sentences"][0]["text"],
                                                         "none": "It serves none of these goals"})
        self.assertNotIn("r_goal@0", trees.ask_requests(TREE, PARTS, None))  # no goal sentences: not asked

    def test_each_request_gets_a_kind_and_a_goal_or_none(self):
        a = {"r_count": ch("two"), "r_kind@0": ch("answer"), "r_goal@0": ch("none"),
             "r_kind@1": ch("hypothesis"), "r_goal@1": ch("g0"), "r_kind@2": ch("more"), "r_goal@2": ch("g0"),
             "r_kind@3": ch("none"), "r_goal@3": ch("none")}
        out = trees.read_requests(a, PARTS, RECORD)
        self.assertEqual(out["count"], 2)
        self.assertEqual([(r["kind"], r["goal"]) for r in out["requests"]], [("answer", "none"), ("hypothesis", "pg1")])
        self.assertEqual(out["requests"][1]["text"], PARTS[1] + " " + PARTS[2])  # word for word, with its next part
        self.assertEqual(out["part"], 'requests: 2 (answer for no goal "Q4: the default is good."; hypothesis for pg1 "Orbit is the front door to…")')

    def test_a_sure_count_of_none_ends_the_tree(self):
        out = trees.read_requests({"r_count": ch("none"), "r_kind@0": ch("task")}, PARTS[:1], RECORD)
        self.assertEqual((out["requests"], out["part"]), ([], None))

    def test_an_unsure_kind_names_no_request_and_a_count_that_differs_is_said(self):
        a = {"r_count": ch("three"), "r_kind@0": ch("task"), "r_kind@1": ch("goal", 0.4)}
        out = trees.read_requests(a, PARTS[:2], None)
        self.assertEqual(out["part"], 'requests: 3 by count, 1 named (task "Q4: the default is good.")')
        self.assertIsNone(out["requests"][0]["goal"])
        self.assertIsNone(trees.read_requests({}, PARTS, None)["part"])


class C31Dispute(unittest.TestCase):
    """c31, k31: a formal tool for the first kind, a judgment of the human for the second, and
    neither when the answer is in the unsure band."""

    def test_same_inputs_and_rule_other_outputs_names_a_formal_tool(self):
        out = trees.read_dispute({"x_dispute": no(0.9), "x_kind": ch("outputs"), "h_language": ch("z3", 0.6)})
        self.assertEqual((out["kind"], out["tool"]), ("outputs", "z3"))
        self.assertIn("a formal tool can settle it (z3)", out["part"])
        lang = {"type": "choice", "choice": "none", "confidence": 0.5, "probabilities": {"none": 0.5, "lean": 0.3, "prolog": 0.1}}
        self.assertEqual(trees.read_dispute({"x_dispute": no(0.9), "x_kind": ch("outputs"), "h_language": lang})["tool"], "lean")
        self.assertEqual(trees.read_dispute({"x_dispute": no(0.9), "x_kind": ch("outputs")})["tool"], "prolog")

    def test_agreed_output_not_yet_judged_needs_the_human(self):
        out = trees.read_dispute({"x_dispute": no(0.8), "x_kind": ch("wanted")})
        self.assertEqual(out["kind"], "wanted")
        self.assertIn("judgment of that case by the human", out["part"])
        self.assertNotIn("formal tool", out["part"])

    def test_neither_in_the_unsure_band_or_for_another_kind(self):
        for a in ({"x_dispute": no(0.6), "x_kind": ch("outputs")},      # the gate is unsure
                  {"x_dispute": no(0.9), "x_kind": ch("outputs", 0.45)},  # the kind is unsure
                  {"x_dispute": no(0.9), "x_kind": ch("inputs")},
                  {"x_dispute": no(0.1), "x_kind": ch("wanted")}, {}):
            self.assertEqual(trees.read_dispute(a), {"kind": None, "tool": None, "part": None}, a)


class C32Difference(unittest.TestCase):
    """c32, k32: a second hypothesis that differs for a user raises one question on the goal; a
    pair that differs only inside raises none."""

    def test_one_question_for_each_pair_and_none_for_a_pair_seen_before(self):
        asked = trees.ask_difference(TREE, RECORD)
        self.assertEqual(list(asked), ["y_differs@0_1"])
        self.assertIn("`record.hypotheses[0]`", asked["y_differs@0_1"]["instructions"])
        self.assertIn("`record.hypotheses[1]`", asked["y_differs@0_1"]["instructions"])
        self.assertEqual(trees.ask_difference(TREE, RECORD, seen=["hy1|hy2"]), {})
        self.assertEqual(trees.ask_difference(TREE, dict(RECORD, hypotheses=RECORD["hypotheses"][:1])), {})

    def test_a_difference_for_a_user_raises_one_question(self):
        out = trees.read_difference({"y_differs@0_1": ch("user")}, RECORD)
        self.assertEqual(len(out), 1)
        self.assertEqual((out[0]["a"], out[0]["b"], out[0]["differs"]), ("hy1", "hy2", "user"))
        self.assertIn("a question for the human", out[0]["part"])
        self.assertIn("hy1 and hy2", out[0]["question"])

    def test_a_difference_only_inside_raises_none(self):
        for a in (ch("inside"), ch("same"), ch("user", 0.4)):
            out = trees.read_difference({"y_differs@0_1": a}, RECORD)
            self.assertEqual((out[0]["part"], out[0]["question"]), (None, None))


class C30Drift(unittest.TestCase):
    """c30, k30: a delivery that says success, a prediction that the message does not account for
    and no revision by the human give a hint that names the prediction."""

    def test_the_questions_name_each_prediction_by_its_path(self):
        asked = trees.ask_drift(TREE, RECORD)
        self.assertEqual(list(asked), ["d_success", "d_kept@0", "d_revised@0", "d_kept@1", "d_revised@1"])
        self.assertIn("`record.hypotheses[0].predictions[1]`", asked["d_kept@1"]["instructions"])

    def test_a_dropped_prediction_with_no_revision_is_named(self):
        a = {"d_success": no(0.9), "d_kept@0": ch("accounted"), "d_revised@0": no(0.1),
             "d_kept@1": ch("dropped"), "d_revised@1": no(0.1)}
        out = trees.read_drift(a, RECORD)
        self.assertEqual([d["id"] for d in out["drifts"]], ["c2"])
        self.assertEqual(out["hint"], "System 1: the delivery reports success. The original prediction included "
                         "c2 of hy1 (\"A replay finishes in the time of one run.\"). What happened to that part?")

    def test_a_revision_by_the_human_is_not_a_drift(self):
        a = {"d_success": no(0.9), "d_kept@1": ch("changed"), "d_revised@1": no(0.9)}
        out = trees.read_drift(a, RECORD)
        self.assertEqual((out["drifts"], out["hint"]), ([], None))
        self.assertEqual([(r["id"], r["how"]) for r in out["revisions"]], [("c2", "changed")])

    def test_no_hint_with_no_success_an_accounted_prediction_or_an_unsure_answer(self):
        for a in ({"d_success": no(0.5), "d_kept@1": ch("dropped"), "d_revised@1": no(0.1)},
                  {"d_success": no(0.9), "d_kept@1": ch("accounted"), "d_revised@1": no(0.1)},
                  {"d_success": no(0.9), "d_kept@1": ch("apart"), "d_revised@1": no(0.1)},
                  {"d_success": no(0.9), "d_kept@1": ch("dropped", 0.4), "d_revised@1": no(0.1)},
                  {"d_success": no(0.9), "d_kept@1": ch("dropped"), "d_revised@1": no(0.5)}, {}):
            out = trees.read_drift(a, RECORD)
            self.assertEqual((out["drifts"], out["revisions"], out["hint"]), ([], [], None), a)

    def test_the_arm_without_the_record_names_no_prediction(self):
        self.assertIsNotNone(trees.read_drift_today({"d_drift": no(0.8)})["hint"])
        self.assertIsNone(trees.read_drift_today({"d_drift": no(0.6)})["hint"])


def _big_record(n=12, words=30):
    """The largest state of the stop event: n predictions of one hypothesis, each a long text."""
    text = " ".join(f"word{i}" for i in range(words))
    return {"hypotheses": [{"id": "hy1", "predictions": [{"id": f"c{i}", "text": f"{i} {text}"} for i in range(n)]}]}


class C3HintLines(unittest.TestCase):
    """c3, k3: each tree gives its hint as one line of at most 240 characters, at 12 predictions,
    3 pairs and 30 parts. Fixture answers only; no call."""

    def one_line(self, line, *words):
        self.assertIsInstance(line, str)
        self.assertNotIn("\n", line)
        self.assertNotIn("\r", line)
        self.assertLessEqual(len(line), 240, line)
        for w in words:
            self.assertIn(w, line)

    def drift(self, n_dropped, n=12):
        rec = _big_record(n)
        a = {"d_success": no(0.9)}
        for i in range(n):
            a[f"d_kept@{i}"] = ch("dropped" if i < n_dropped else "accounted")
            a[f"d_revised@{i}"] = no(0.1)
        return trees.read_drift(a, rec)["hint"]

    def test_drift_names_the_dropped_prediction_by_id_and_first_words(self):
        line = self.drift(1)
        self.one_line(line, "c0 of hy1", "0 word0 word1 word2")
        self.assertIn("What happened to that part?", line)

    def test_drift_stays_in_240_with_three_long_predictions_and_with_twelve(self):
        three = self.drift(3)
        self.one_line(three, "c0 of hy1", "c1 of hy1", "c2 of hy1", "word0")
        twelve = self.drift(12)
        self.one_line(twelve, "c0 of hy1", "word0", "more")
        self.assertIn("and 9 more", twelve)

    def test_dispute_names_the_kind_and_what_settles_it(self):
        for kind, words in (("outputs", ("outputs differ", "a formal tool can settle it (prolog)")),
                            ("wanted", ("needs a judgment of that case by the human",))):
            out = trees.read_dispute({"x_dispute": no(0.9), "x_kind": ch(kind)})
            self.assertEqual(out["kind"], kind)
            self.one_line(out["part"], "dispute:", *words)

    def test_difference_names_the_two_hypotheses_of_each_pair_that_differs(self):
        rec = {"hypotheses": [{"id": f"hypothesis-{k}-with-a-long-id"} for k in "abcd"]}
        pairs = trees.pairs(rec)
        self.assertEqual(len(pairs), 3)
        a = {f"y_differs@{i}_{j}": ch("user") for i, j in pairs}
        items = trees.read_difference(a, rec)
        self.one_line(items[0]["part"], "hypothesis-a-with-a-long-id and hypothesis-b-with-a-long-id")
        line = trees.difference_part(items)
        self.one_line(line, "hypothesis-a-with-a-long-id and hypothesis-b-with-a-long-id", "differ in what a user experiences")
        self.assertIn("hypothesis-a-with-a-long-id and hypothesis-c-with-a-long-id", line)
        self.assertIsNone(trees.difference_part(trees.read_difference({k: ch("inside") for k in a}, rec)))

    def test_requests_names_each_request_by_kind_and_first_words_and_30_parts_fit(self):
        parts = [f"Request number {i} asks for a change in the thing that you know about" for i in range(30)]
        a = {"r_count": ch("five_or_more")}
        for k in range(30):
            a[f"r_kind@{k}"] = ch("task")
        out = trees.read_requests(a, parts, None)
        self.assertEqual(len(out["requests"]), 30)
        self.one_line(out["part"], "requests:", 'task "Request number…"')
        self.assertIn("more)", out["part"])
        few = trees.read_requests({"r_count": ch("two"), "r_kind@0": ch("task"), "r_kind@1": ch("goal")}, parts[:2], None)
        self.one_line(few["part"], 'task "Request number 0', 'goal "Request number 1')
        self.assertNotIn("more", few["part"])


class C3OffByDefault(unittest.TestCase):
    """c3, k3: with the question file of 0.8.0 (no id of a tree) the hook asks and prints none of the lines."""

    def test_the_hook_prints_no_hint_of_a_tree(self):
        import test_record as tr
        from test_hook import Fake, RECORDED
        outer = self

        class T(tr.Base):
            def runTest(self):
                self.hub()
                self.env = dict(self.env, S1_QUESTIONS=os.path.join(HERE, "questions.json"),
                                S1_SESSION_DIR=os.path.join(self.dir, "sess"),
                                S1_ORBIT=self.stub(f"if argv[0] == 's1-record':\n    print(json.dumps({tr.RECORD!r}))\n"))
                resp = json.loads(json.dumps(RECORDED["thanks"]))
                resp["answers"].update({"r_count": ch("three"), "r_kind@0": ch("task"), "x_dispute": no(0.9),
                                        "x_kind": ch("outputs"), "y_differs@0_1": ch("user")})
                fake = Fake(resp)
                line = self.context(self.run_hook(fake, raw=self.payload(prompt="Fix the typo. Do it now.")))
                sent = json.loads(fake.calls[0]["body"])["questions"]
                outer.assertEqual(sorted(set(sent) & set(TREE)), [])
                for w in ("requests:", "dispute:", "differ in what a user", "System 1: the delivery"):
                    outer.assertNotIn(w, line)

        r = unittest.TextTestRunner(stream=open(os.devnull, "w")).run(T())
        self.assertTrue(r.wasSuccessful(), r.errors + r.failures)


if __name__ == "__main__":
    unittest.main()
