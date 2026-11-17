"""The live view (s1/live.py) and the fan-out parts of the status line. No network.
Run: python3 -m unittest s1.test_live -v"""
import datetime as dt
import io
import json
import os
import sys
import tempfile
import unittest
from contextlib import redirect_stdout

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import live  # noqa: E402
import statusline  # noqa: E402


def N(p):
    return {"type": "noul", "noul": p}


def turn(session, div=0.05, rev=0.05, texts=("Looks good.", "Did you test this?"), doubt=0.05, old=False, tool="tests"):
    """One fan-out call. old: the keys of a line written before the contradiction rename (2026-11-17)."""
    now = dt.datetime.now(dt.timezone.utc).isoformat(timespec="milliseconds")
    a = {"h_work": {"type": "choice", "choice": "build", "confidence": 0.9, "probabilities": {"build": 0.9}},
         "h_language": {"type": "choice", "choice": tool, "confidence": 0.8, "probabilities": {tool: 0.8}},
         "h_divergence": N(div), "h_change_of_plan": N(0.05), "h_questions": N(0.0), "h_effort": N(0.1), "h_proof": N(0.02), ("h_reversal" if old else "h_contradiction"): N(rev)}
    for k in range(len(texts)):
        a[f"react@{k}"] = {"type": "choice", "choice": "doubts" if k else "accepts", "probabilities": {"doubts": 0.8, "accepts": 0.9}}
        for name in live.PART_KEYS:
            name = "reverses" if old and name == "contradiction" else name
            a[f"{name}@{k}"] = N(doubt if (name == "doubts" and k == 1) else 0.03)
    call = {"time": now, "session_id": session, "model": "jev-test", "latency": 0.25, "usage": {"input_tokens": 2000}, "parts": len(texts),
            "answers": dict(a, h_divergence=N(0.5)), "error": None}
    comb = {"time": now, "session_id": session, "combined": True, "parts": len(texts), "answers": a, "error": None, "part_text": list(texts)}
    return [call, comb]


class Live(unittest.TestCase):
    def setUp(self):
        d = tempfile.TemporaryDirectory()
        self.addCleanup(d.cleanup)
        self.log = os.path.join(d.name, "s1.jsonl")

    def write(self, recs):
        with open(self.log, "w") as f:
            for r in recs:
                f.write(json.dumps(r) + "\n")

    def out(self, *args):
        buf = io.StringIO()
        with redirect_stdout(buf):
            self.assertEqual(live.main(["--log", self.log, "--no-color", *args]), 0)
        return buf.getvalue()

    def test_a_call_line_and_its_combined_line_are_one_turn_with_the_combined_answers(self):
        self.write(turn("s1", div=0.93, doubt=0.93) + turn("other"))
        _, ts = live.turns(self.log, "s1")
        self.assertEqual(len(ts), 1)
        t = ts[0]
        self.assertEqual((t["signals"]["divergence"], t["fired"], t["latency"], t["tokens"], t["model"]), (0.93, ["divergence"], 0.25, 2000, "jev-test"))
        self.assertEqual([p["text"] for p in t["parts"]], ["Looks good.", "Did you test this?"])
        self.assertEqual(t["parts"][1]["doubts"], 0.93)

    def test_a_plain_line_with_no_fan_out_is_a_turn_too(self):
        r = turn("s1", div=0.8)[1]
        del r["combined"], r["part_text"], r["parts"]
        self.write([r])
        _, ts = live.turns(self.log, "s1")
        self.assertEqual((len(ts), ts[0]["parts"], ts[0]["fired"]), (1, [], ["divergence"]))

    def test_pane_names_the_part_that_fired(self):
        self.write(turn("s1") + turn("s1", div=0.93, doubt=0.93))
        text = self.out("--format", "pane", "--session", "s1")
        self.assertIn("FIRED", text)
        self.assertIn("part 2: “Did you test this?”", text)
        self.assertIn("history, last 2 messages", text)
        self.assertNotIn("\033[", text)

    def test_toast_only_when_the_newest_message_fired(self):
        self.write(turn("s1", div=0.93, doubt=0.93))
        self.assertIn("System 1: divergence 0.93", self.out("--format", "toast", "--session", "s1"))
        self.write(turn("s1", div=0.93, doubt=0.93) + turn("s1"))
        self.assertEqual(self.out("--format", "toast", "--session", "s1"), "")

    def test_corner_and_json(self):
        self.write(turn("s1", rev=0.9))
        self.assertIn("rev 0.90", self.out("--format", "corner", "--session", "s1"))
        d = json.loads(self.out("--format", "json", "--session", "s1"))
        self.assertEqual((d["session"], d["turns"][0]["fired"]), ("s1", ["reversal"]))

    def test_the_newest_session_is_the_default_and_an_error_line_is_counted(self):
        self.write(turn("old") + turn("new") + [{"time": "x", "session_id": "new", "skipped": "timeout", "answers": None}])
        s, ts = live.turns(self.log)
        self.assertEqual((s, len(ts)), ("new", 2))
        self.assertIn("1 call with no view", self.out("--format", "pane", "--session", "new"))

    def test_fails_quiet(self):
        self.assertEqual(self.out("--format", "pane", "--log", "/nonexistent/log"), "")
        self.write([{"session_id": "s1"}])
        self.assertIn("no judged message", self.out("--format", "pane", "--session", "s1"))

    def test_status_line_shows_the_reversal_and_the_parts(self):
        self.write(turn("s1", rev=0.9, texts=("a.", "b.", "c.")))
        seg = statusline.render("s1", self.log)
        self.assertIn("rev 0.90", seg)
        self.assertIn("3 parts", seg)
        self.write(turn("s1", rev=0.1, texts=("a.",)))
        seg = statusline.render("s1", self.log)
        self.assertNotIn("rev", seg)
        self.assertNotIn("parts", seg)

    def test_an_older_line_with_the_old_keys_still_shows_the_reversal(self):
        self.write(turn("s1", rev=0.9, texts=("a.", "b. no wait", "c."), old=True))
        self.assertIn("rev 0.90", statusline.render("s1", self.log))
        d = json.loads(self.out("--format", "json", "--session", "s1"))
        self.assertEqual(d["turns"][0]["fired"], ["reversal"])
        self.assertEqual(d["turns"][0]["parts"][0]["contradiction"], 0.03)

    def test_tla_plus_reads_TLA_plus(self):  # kb-s1-glance-consolidate c7 (Ty: "TLAplus ... more readable")
        for key in ("tlaplus", "tla"):  # tla: a line written before the rename
            self.write(turn("s1", div=0.9, tool=key))
            self.assertIn("tool TLA+ 0.80", self.out("--format", "pane", "--session", "s1"))
            self.assertTrue(statusline.render("s1", self.log).endswith("| tool TLA+"), key)


if __name__ == "__main__":
    unittest.main()
