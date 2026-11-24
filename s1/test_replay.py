"""Tests of the replay experiment harness (scientific-method-overhaul c35, rk10). No network: the
recorded answers of an invented case set (fixtures/replay_example.json).

    python3 -m unittest s1.test_replay -v
"""
import copy
import datetime as dt
import json
import os
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import replay  # noqa: E402

EXAMPLE = os.path.join(HERE, "fixtures", "replay_example.json")
NOW = dt.datetime(2026, 11, 25, tzinfo=dt.timezone.utc)


def load():
    with open(EXAMPLE) as f:
        return json.load(f)


class Verdict(unittest.TestCase):
    def run_doc(self, doc):
        replay.check_file(doc, NOW)
        return replay.run(doc, now=NOW)

    def test_meets_more_drifts_named_and_no_more_false_hints(self):
        out = self.run_doc(load())
        self.assertEqual(out["verdict"], "meets", out["reason"])
        self.assertEqual((out["arms"]["record"]["hits"], out["arms"]["today"]["hits"]), (2, 1))
        self.assertEqual((out["arms"]["record"]["false_hints"], out["arms"]["today"]["false_hints"]), (0, 0))
        d1 = out["cases"][0]
        self.assertEqual((d1["today"]["label"], d1["record"]["label"]), ("none", "drift"))
        self.assertIn("c1 of hy1", d1["record"]["hint"])
        self.assertEqual(d1["record"]["asked"][0], "d_success")
        self.assertEqual(d1["today"]["asked"], ["d_drift"])
        self.assertEqual(out["cases"][2]["record"]["label"], "revision")  # the human revised: no drift hint
        self.assertEqual(out["thresholds"]["written"], "2026-11-24T08:00:00Z")
        self.assertFalse(out["run"]["live"])

    def test_conflicts_as_many_drifts(self):
        doc = load()
        doc["cases"][0]["recorded"]["today"]["d_drift"]["noul"] = 0.9
        self.assertEqual(self.run_doc(doc)["verdict"], "conflicts")

    def test_conflicts_more_false_hints(self):
        doc = load()
        doc["cases"][3]["recorded"]["record"]["d_kept@0"] = {"type": "choice", "choice": "dropped", "confidence": 0.9}
        out = self.run_doc(doc)
        self.assertEqual(out["verdict"], "conflicts", out["reason"])
        self.assertEqual(out["arms"]["record"]["false_hints"], 1)

    def test_unresolved_between_the_thresholds_a_failed_call_or_a_case_with_no_label(self):
        doc = load()
        doc["thresholds"]["min_gain"] = 2
        self.assertEqual(self.run_doc(doc)["verdict"], "unresolved")
        doc = load()
        del doc["cases"][1]["recorded"]["record"]
        out = self.run_doc(doc)
        self.assertEqual(out["verdict"], "unresolved")
        self.assertTrue(out["cases"][1]["record"]["failed"])
        doc = load()
        doc["cases"][1]["unsure"] = True  # review marked it unsure, and the human has not judged it
        self.assertEqual(self.run_doc(doc)["verdict"], "unresolved")

    def test_the_accuracy_rule(self):
        doc = load()
        doc["thresholds"] = {"written": "2026-11-24T08:00:00Z", "rule": "accuracy", "arm": "record",
                             "meets_at": 0.9, "conflicts_below": 0.5}
        self.assertEqual(self.run_doc(doc)["verdict"], "meets")
        doc["thresholds"]["arm"] = "today"  # 3 of 4: between
        self.assertEqual(self.run_doc(doc)["verdict"], "unresolved")
        doc["thresholds"]["conflicts_below"] = 0.8
        self.assertEqual(self.run_doc(doc)["verdict"], "conflicts")


class Rules(unittest.TestCase):
    def test_thresholds_must_be_written_before_the_run(self):
        for change in (lambda d: d.pop("thresholds"), lambda d: d["thresholds"].pop("written"),
                       lambda d: d["thresholds"].update(written="2026-12-01T00:00:00Z"),
                       lambda d: d.update(question="mood"), lambda d: d.update(cases=[])):
            doc = load()
            change(doc)
            with self.assertRaises(ValueError):
                replay.check_file(doc, NOW)

    def test_rk10_a_case_from_the_log_must_be_of_the_one_hub(self):
        d = tempfile.mkdtemp()
        hub = os.path.join(d, "hub")
        projects = os.path.join(d, "projects")
        import s1inspect
        pd = os.path.join(projects, s1inspect.project_dirname(hub))
        os.makedirs(pd)
        open(os.path.join(pd, "sess-in.jsonl"), "w").close()
        doc = load()
        replay.check_hub(doc, None, projects)  # invented cases only: no hub needed
        doc["cases"][0]["source"] = {"kind": "log", "session_id": "sess-in"}
        with self.assertRaises(ValueError):
            replay.check_hub(doc, None, projects)
        replay.check_hub(doc, hub, projects)
        doc["cases"][1]["source"] = {"kind": "log", "session_id": "sess-of-another-hub"}
        with self.assertRaisesRegex(ValueError, "d2"):
            replay.check_hub(doc, hub, projects)

    def test_the_command_exits_by_the_verdict_and_calls_nothing_without_live(self):
        d = tempfile.mkdtemp()
        out = os.path.join(d, "out.json")
        calls = []
        self.assertEqual(replay.main(["run", "--cases", EXAMPLE, "--out", out],
                                     transport=lambda *a: calls.append(a)), 0)
        self.assertEqual(calls, [])
        rec = json.load(open(out))
        self.assertEqual((rec["verdict"], len(rec["case_file_sha256"])), ("meets", 64))
        doc = load()
        doc["thresholds"]["min_gain"] = 2
        p = os.path.join(d, "c.json")
        json.dump(doc, open(p, "w"))
        self.assertEqual(replay.main(["run", "--cases", p, "--out", out]), 77)
        doc["thresholds"].pop("written")
        json.dump(doc, open(p, "w"))
        self.assertEqual(replay.main(["run", "--cases", p, "--out", out]), 2)

    def test_live_asks_each_arm_through_the_bench_log(self):
        import bench
        d = tempfile.mkdtemp()
        old, bench.BENCH_LOG = bench.BENCH_LOG, os.path.join(d, "bench.jsonl")
        self.addCleanup(setattr, bench, "BENCH_LOG", old)
        doc = load()
        bodies = []

        def fake(url, headers, body, timeout):
            b = json.loads(body)
            bodies.append(b)
            arm = "record" if "record" in b["state"] else "today"
            return 200, json.dumps({"answers": doc["cases"][0]["recorded"][arm]})
        os.environ.setdefault("TYPESAFE_API_KEY", "sk-test")
        out = replay.run(doc, live=True, transport=fake, now=NOW)
        self.assertEqual(len(bodies), 8)  # 4 cases, 2 arms
        self.assertNotIn("record", bodies[0]["state"])
        self.assertIn("record", bodies[1]["state"])
        self.assertTrue(out["run"]["live"])
        tags = {json.loads(x)["bench"] for x in open(bench.BENCH_LOG)}
        self.assertEqual(tags, {"replay:drift:today", "replay:drift:record"})

    def test_the_other_questions_have_a_rule(self):
        import trees
        from test_record import RECORD
        tree = trees.load()
        st = {"message": "m", "recent": [], "sentences": ["Do a.", "Do b."], "record": RECORD}
        self.assertIn("r_count", replay.asked_for("requests", "record", st, tree))
        self.assertEqual(replay.asked_for("difference", "today", {"message": "m"}, tree), {})
        self.assertEqual(replay.label_of("difference", "today", {}, {"message": "m"})[0], "none")
        self.assertEqual(replay.label_of("dispute", "today", {}, st)[0], "neither")
        self.assertEqual(replay.label_of("requests", "record", {}, st)[0], "none")


if __name__ == "__main__":
    unittest.main()
