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
        self.assertEqual(out["part"], "requests: 2 (answer for no goal; hypothesis for pg1)")

    def test_a_sure_count_of_none_ends_the_tree(self):
        out = trees.read_requests({"r_count": ch("none"), "r_kind@0": ch("task")}, PARTS[:1], RECORD)
        self.assertEqual((out["requests"], out["part"]), ([], None))

    def test_an_unsure_kind_names_no_request_and_a_count_that_differs_is_said(self):
        a = {"r_count": ch("three"), "r_kind@0": ch("task"), "r_kind@1": ch("goal", 0.4)}
        out = trees.read_requests(a, PARTS[:2], None)
        self.assertEqual(out["part"], "requests: 3 by count, 1 named (task)")
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


if __name__ == "__main__":
    unittest.main()
