"""Tests of s1/bench.py: no network (a fake transport answers), invented logs only."""
import io
import json
import os
import tempfile
import unittest
from contextlib import redirect_stdout

from s1 import bench

QS = {"h_divergence": {"type": "noul", "instructions": "x"},
      "h_work": {"type": "choice", "instructions": "y", "criteria": {"build": "b", "verify": "v"}}}


def rec(t, sid, div, work_p):
    return {"time": t, "session_id": sid, "model": "jev", "questions": list(QS),
            "state": {"message": f"msg {t}", "recent": []},
            "answers": {"h_divergence": {"type": "noul", "noul": div},
                        "h_work": {"type": "choice", "choice": "build", "confidence": work_p,
                                   "probabilities": {"build": work_p, "verify": 1 - work_p}}},
            "latency": 0.1, "usage": None, "error": None}


def fake(div):
    calls = []

    def transport(url, headers, body, timeout):
        calls.append(json.loads(body))
        return 200, json.dumps({"answers": {
            "h_divergence": {"type": "noul", "noul": div},
            "h_work": {"type": "choice", "choice": "build", "confidence": 0.9,
                       "probabilities": {"build": 0.9, "verify": 0.1}}}})
    return transport, calls


class Bench(unittest.TestCase):
    def setUp(self):
        self.d = tempfile.mkdtemp()
        self.log = os.path.join(self.d, "s1.jsonl")
        with open(self.log, "w") as f:
            for r in (rec("2026-11-13T01:00:00+00:00", "aaa", 0.1, 0.9), rec("2026-11-13T02:00:00+00:00", "bbb", 0.2, 0.9)):
                f.write(json.dumps(r) + "\n")
            f.write(json.dumps({"skipped": "no answers", "session_id": "bbb"}) + "\n")
        self.q = os.path.join(self.d, "q.json")
        with open(self.q, "w") as f:
            json.dump(QS, f)
        self.bench_log = os.path.join(self.d, "bench.jsonl")
        bench.BENCH_LOG = self.bench_log
        os.environ["TYPESAFE_API_KEY"] = os.environ.get("TYPESAFE_API_KEY") or "test-key"

    def args(self, *extra):
        return ["--questions", self.q, "--log", self.log, "--projects", self.d, *extra]

    def test_band_change_is_marked(self):
        t, calls = fake(0.9)  # divergence now yes: a change on both judgments
        out = bench.run(bench.parser().parse_args(self.args()), t)
        self.assertEqual(out["judgments"], 2)
        self.assertEqual(len(calls), 2)
        self.assertEqual(calls[0]["questions"], QS)
        rows = {x["question"]: x for x in out["results"][0]["rows"]}
        self.assertTrue(rows["h_divergence"]["changed"])
        self.assertFalse(rows["h_work"]["changed"])
        self.assertIn("changed bands: h_divergence 2", bench.render(out))

    def test_the_state_sent_is_the_logged_state(self):
        t, calls = fake(0.1)
        bench.run(bench.parser().parse_args(self.args("--last", "1")), t)
        self.assertEqual(calls[0]["state"], {"message": "msg 2026-11-13T02:00:00+00:00", "recent": []})

    def test_calls_go_to_the_bench_log_only(self):
        t, _ = fake(0.1)
        bench.run(bench.parser().parse_args(self.args()), t)
        with open(self.log) as f:
            self.assertEqual(len(f.readlines()), 3)
        with open(self.bench_log) as f:
            self.assertEqual(len(f.readlines()), 2)

    def test_baseline_doubles_the_calls(self):
        t, calls = fake(0.1)
        out = bench.run(bench.parser().parse_args(self.args("--baseline")), t)
        self.assertEqual(out["calls"], 4)
        self.assertEqual(len(calls), 4)

    def test_dry_run_asks_nothing(self):
        t, calls = fake(0.1)
        buf = io.StringIO()
        with redirect_stdout(buf):
            bench.main(self.args("--dry-run"), t)
        self.assertEqual(calls, [])
        self.assertIn("2 judgments, 2 calls", buf.getvalue())

    def test_pipeline_routes_in_stages(self):
        t, calls = fake(0.9)
        pipe = os.path.join(self.d, "pipe.py")
        with open(pipe, "w") as f:
            f.write(
                "def run(state, ask, questions):\n"
                "    first = ask({'h_work': questions['h_work']})\n"
                "    if first is None: return None\n"
                "    if first['h_work']['choice'] == 'build':\n"
                "        second = ask({'h_divergence': questions['h_divergence']}) or {}\n"
                "        return {**first, **second}\n"
                "    return first\n"
                "def hint(answers, questions):\n"
                "    return 'custom ' + answers['h_work']['choice']\n")
        out = bench.run(bench.parser().parse_args(self.args("--pipeline", pipe, "--last", "1")), t)
        self.assertEqual([list(c["questions"]) for c in calls], [["h_work"], ["h_divergence"]])
        r = out["results"][0]
        self.assertEqual(r["new_hint"], "custom build")
        self.assertTrue({x["question"]: x for x in r["rows"]}["h_divergence"]["changed"])

    def test_a_pipeline_without_run_is_refused(self):
        pipe = os.path.join(self.d, "bad.py")
        with open(pipe, "w") as f:
            f.write("x = 1\n")
        with self.assertRaises(ValueError):
            bench.run(bench.parser().parse_args(self.args("--pipeline", pipe)), fake(0.1)[0])


if __name__ == "__main__":
    unittest.main()
