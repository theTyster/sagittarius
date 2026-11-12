"""0.3.0 S-C (c_s_c_3): the tracked calibration cases of the question set (s1/fixtures/calibration.json).
No network. Run: python3 -m unittest s1.test_calibration -v. To judge the cases with the live System 1
model (a few dozen calls), run s1/calibrate.py; this file never calls it."""
import json
import os
import re
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
PATH = os.path.join(HERE, "fixtures", "calibration.json")
# a client or company name, or a word from the sessions that the cases came from (0.3.0 rk8)
PRIVATE = re.compile(r"deltadental|delta dental|cobra|mindhub|hoggwood", re.I)


def load():
    with open(PATH, encoding="utf-8") as f:
        return json.load(f)


class CalibrationCases(unittest.TestCase):
    def test_the_file_has_cases_and_a_count_of_left_out_cases(self):
        d = load()
        self.assertIsInstance(d["cases"], list)
        self.assertIsInstance(d["left_out"], int)
        self.assertIsInstance(d["left_out_reason"], str)

    def test_the_25_known_cases_are_all_accounted_for(self):
        d = load()
        known = [c for c in d["cases"] if c["origin"] == "known"]
        self.assertEqual(len(known) + d["left_out"], 25)

    def test_each_case_has_the_state_and_the_expected_labels(self):
        with open(os.path.join(HERE, "questions.json"), encoding="utf-8") as f:
            q = json.load(f)
        ids = set()
        for c in load()["cases"]:
            self.assertNotIn(c["id"], ids)
            ids.add(c["id"])
            self.assertIsInstance(c["message"], str)
            self.assertTrue(c["message"].strip())
            for m in c["recent"]:
                self.assertIn(m["role"], ("you", "agent"))
                self.assertIsInstance(m["text"], str)
            self.assertTrue(c["expect"])
            for qid, want in c["expect"].items():
                self.assertIn(qid, q, c["id"])
                allowed = set(q[qid].get("criteria", {})) | {"yes", "no"}
                self.assertIn(want, allowed, (c["id"], qid))

    def test_each_new_signal_has_cases_that_expect_yes_and_no(self):
        cases = load()["cases"]
        for qid in ("h_questions", "h_proof"):
            wants = {c["expect"][qid] for c in cases if qid in c["expect"]}
            self.assertEqual(wants, {"yes", "no"}, qid)

    def test_no_client_content(self):
        with open(PATH, encoding="utf-8") as f:
            self.assertIsNone(PRIVATE.search(f.read()))

    def test_the_cases_are_judged_by_the_judge_of_the_calibration_script(self):
        import calibrate  # the script has a pure scoring function; no call is made here
        row = calibrate.score({"type": "noul", "noul": 0.9}, "yes")
        self.assertEqual(row, ("yes", 0.9, True))
        row = calibrate.score({"type": "noul", "noul": 0.5}, "yes")
        self.assertEqual(row, ("unsure", 0.5, False))
        row = calibrate.score({"type": "choice", "choice": "lean", "confidence": 0.9,
                               "probabilities": {"lean": 0.9}}, "lean")
        self.assertEqual(row, ("lean", 0.9, True))


if __name__ == "__main__":
    unittest.main()
