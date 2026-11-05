"""Tests for s1/jev.py (T04). No network: every call goes through a fake transport.

Run from the repo root:  python3 -m unittest s1.test_jev -v   (or: python3 s1/test_jev.py)

Fake transport contract (see jev.py): transport(url, headers, body_bytes, timeout)
returns (status_int, response_text), or raises (TimeoutError, OSError).
"""
import json
import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import jev  # noqa: E402

KEY = "sk-test-SECRET-123"
Q = {"q1": {"type": "noul", "instructions": "Is it so?"}}


class Fake:
    """Records calls; returns a canned reply or raises."""

    def __init__(self, status=200, payload=None, exc=None):
        self.status, self.exc = status, exc
        self.payload = payload if payload is not None else {
            "model": "jev-1.14.0",
            "answers": {"q1": {"type": "noul", "noul": 0.93}},
            "usage": {"input_tokens": 12, "output_tokens": 3},
        }
        self.calls = []

    def __call__(self, url, headers, body, timeout):
        self.calls.append({"url": url, "headers": headers, "body": body, "timeout": timeout})
        if self.exc:
            raise self.exc
        text = self.payload if isinstance(self.payload, str) else json.dumps(self.payload)
        return self.status, text


class Base(unittest.TestCase):
    def setUp(self):
        d = tempfile.TemporaryDirectory()
        self.addCleanup(d.cleanup)
        self.log = os.path.join(d.name, "sub", "s1.jsonl")
        self._env = os.environ.pop("TYPESAFE_API_KEY", None)
        self.addCleanup(self._restore)

    def _restore(self):
        os.environ.pop("TYPESAFE_API_KEY", None)
        if self._env is not None:
            os.environ["TYPESAFE_API_KEY"] = self._env

    def call(self, fake, state="hello", questions=Q, **kw):
        kw.setdefault("key", KEY)
        return jev.judge(state, questions, transport=fake, log_path=self.log, **kw)

    def lines(self):
        with open(self.log) as f:
            return [json.loads(x) for x in f.read().splitlines()]


class C1Judge(Base):
    def test_c1_returns_answers_by_qid(self):
        fake = Fake()
        out = self.call(fake)
        self.assertEqual(out, {"q1": {"type": "noul", "noul": 0.93}})

    def test_c1_request_shape(self):
        fake = Fake()
        self.call(fake, state={"a": "b"}, timeout=7)
        c = fake.calls[0]
        self.assertEqual(c["url"], "https://api.typesafe.ai/v1/systemone")
        self.assertEqual(c["headers"]["Authorization"], "Bearer " + KEY)
        self.assertEqual(c["timeout"], 7)
        body = json.loads(c["body"])
        self.assertEqual(body["model"], "jev-1.14.0")
        self.assertEqual(body["state"], {"a": "b"})
        self.assertEqual(body["questions"], Q)

    def test_c1_model_override(self):
        fake = Fake()
        self.call(fake, model="jev-latest")
        self.assertEqual(json.loads(fake.calls[0]["body"])["model"], "jev-latest")

    def test_c1_key_from_env(self):
        os.environ["TYPESAFE_API_KEY"] = KEY
        fake = Fake()
        out = jev.judge("s", Q, transport=fake, log_path=self.log)
        self.assertIsNotNone(out)
        self.assertEqual(fake.calls[0]["headers"]["Authorization"], "Bearer " + KEY)


class C2Redact(Base):
    PAIRS = [("Acme Corp", "[ORG]"), ("jane", "[PERSON]")]

    def test_c2_redact_nested_case_insensitive(self):
        obj = {"a": "ACME corp pays Jane", "b": ["x jane", {"c": "acme CORP"}], "n": 5, "t": True}
        out = jev.redact(obj, self.PAIRS)
        self.assertEqual(out, {"a": "[ORG] pays [PERSON]", "b": ["x [PERSON]", {"c": "[ORG]"}],
                               "n": 5, "t": True})

    def test_c2_redact_does_not_mutate_input(self):
        obj = {"a": "Jane"}
        jev.redact(obj, self.PAIRS)
        self.assertEqual(obj, {"a": "Jane"})

    def test_c2_redact_plain_string_and_regex_chars(self):
        self.assertEqual(jev.redact("a.b (x) A.B", [("a.b", "Z")]), "Z (x) Z")

    def test_c2_replacement_not_rescanned(self):
        self.assertEqual(jev.redact("jane", [("jane", "jane doe"), ("doe", "X")]), "jane doe")

    def test_c2_request_body_holds_no_original(self):
        fake = Fake()
        state = {"msg": "Mail JANE at acme corp", "list": ["Acme Corp"]}
        self.call(fake, state=state, redactions=self.PAIRS)
        raw = fake.calls[0]["body"].decode("utf-8")
        for orig in ("jane", "acme corp"):
            self.assertNotIn(orig, raw.lower())
        self.assertIn("[PERSON]", raw)
        self.assertIn("[ORG]", raw)

    def test_c2_question_text_redacted_but_ids_kept(self):
        fake = Fake()
        qs = {"jane": {"type": "noul", "instructions": "Is Jane happy?"}}
        self.call(fake, questions=qs, redactions=self.PAIRS)
        body = json.loads(fake.calls[0]["body"])
        self.assertEqual(list(body["questions"]), ["jane"])
        self.assertEqual(body["questions"]["jane"]["instructions"], "Is [PERSON] happy?")


class C3Band(unittest.TestCase):
    def test_c3_yes_at_and_above_07(self):
        self.assertEqual(jev.band(0.7), "yes")
        self.assertEqual(jev.band(0.93), "yes")
        self.assertEqual(jev.band(1.0), "yes")

    def test_c3_no_at_and_below_03(self):
        self.assertEqual(jev.band(0.3), "no")
        self.assertEqual(jev.band(0.0), "no")

    def test_c3_unsure_between(self):
        self.assertEqual(jev.band(0.5), "unsure")
        self.assertEqual(jev.band(0.31), "unsure")
        self.assertEqual(jev.band(0.69), "unsure")


class C4Log(Base):
    def test_c4_one_line_per_call_with_fields(self):
        fake = Fake()
        self.call(fake)
        self.call(fake)
        rows = self.lines()
        self.assertEqual(len(rows), 2)
        r = rows[0]
        for k in ("time", "model", "questions", "answers", "latency", "usage", "error"):
            self.assertIn(k, r)
        self.assertEqual(r["model"], "jev-1.14.0")
        self.assertEqual(r["questions"], ["q1"])
        self.assertEqual(r["answers"], {"q1": {"type": "noul", "noul": 0.93}})
        self.assertEqual(r["usage"], {"input_tokens": 12, "output_tokens": 3})
        self.assertIsNone(r["error"])
        self.assertIsInstance(r["latency"], (int, float))

    def test_c4_log_has_no_key_and_no_original(self):
        fake = Fake()
        state = {"msg": "Jane works at Acme Corp", "leak": "token " + KEY}
        self.call(fake, state=state, redactions=[("Jane", "[P]"), ("Acme Corp", "[O]")])
        text = open(self.log).read()
        self.assertNotIn(KEY, text)
        self.assertNotIn("Jane", text)
        self.assertNotIn("Acme", text)
        self.assertIn("[P]", text)  # the redacted state is what is logged

    def test_c4_error_line_has_no_key(self):
        fake = Fake(exc=OSError("failed with Bearer " + KEY))
        self.call(fake)
        self.assertNotIn(KEY, open(self.log).read())

    def test_c4_default_path(self):
        self.assertEqual(jev.DEFAULT_LOG, os.path.expanduser("~/.claude/logs/s1.jsonl"))

    def test_c4_env_override_path(self):
        os.environ["S1_LOG"] = self.log
        self.addCleanup(os.environ.pop, "S1_LOG", None)
        jev.judge("s", Q, key=KEY, transport=Fake())
        self.assertEqual(len(self.lines()), 1)


class C5FailOpen(Base):
    def assert_failed_open(self, out, needle=None):
        self.assertIsNone(out)
        rows = self.lines()
        self.assertEqual(len(rows), 1)
        self.assertTrue(rows[0]["error"])
        self.assertIsNone(rows[0]["answers"])
        if needle:
            self.assertIn(needle, rows[0]["error"].lower())

    def test_c5_timeout(self):
        self.assert_failed_open(self.call(Fake(exc=TimeoutError("slow"))), "timeout")

    def test_c5_http_error(self):
        self.assert_failed_open(self.call(Fake(status=500, payload={"detail": "boom"})), "500")

    def test_c5_http_400(self):
        self.assert_failed_open(self.call(Fake(status=400, payload={"detail": "bad"})), "400")

    def test_c5_missing_key(self):
        fake = Fake()
        out = jev.judge("s", Q, transport=fake, log_path=self.log)
        self.assert_failed_open(out, "key")
        self.assertEqual(fake.calls, [])  # no request without a key

    def test_c5_garbage_body(self):
        self.assert_failed_open(self.call(Fake(payload="not json")))

    def test_c5_unwritable_log_does_not_raise(self):
        d = tempfile.TemporaryDirectory()
        self.addCleanup(d.cleanup)
        out = jev.judge("s", Q, key=KEY, transport=Fake(), log_path=d.name)  # a directory
        self.assertIsNotNone(out)


class C6Prolog(unittest.TestCase):
    def test_c6_noul(self):
        out = jev.to_prolog("run1", {"q1": {"type": "noul", "noul": 0.93}})
        self.assertEqual(out, "s1_answer(run1, q1, noul, 0.93, yes).")

    def test_c6_noul_bands(self):
        out = jev.to_prolog("r", {"a": {"type": "noul", "noul": 0.5}, "b": {"type": "noul", "noul": 0.1}})
        self.assertEqual(out.splitlines(), ["s1_answer(r, a, noul, 0.5, unsure).",
                                            "s1_answer(r, b, noul, 0.1, no)."])

    def test_c6_choice(self):
        a = {"type": "choice", "choice": "calm", "confidence": 0.7, "probabilities": {"calm": 0.8}}
        self.assertEqual(jev.to_prolog("r", {"q": a}), "s1_answer(r, q, choice, 0.7, calm).")

    def test_c6_score(self):
        a = {"type": "score", "score": 1.7, "confidence": 0.55}
        self.assertEqual(jev.to_prolog("r", {"q": a}), "s1_answer(r, q, score, 1.7, 2).")

    def test_c6_quoting_qid(self):
        a = {"type": "noul", "noul": 0.9}
        self.assertIn("'it\\'s'", jev.to_prolog("r", {"it's": a}))
        self.assertIn("'Upper'", jev.to_prolog("r", {"Upper": a}))
        self.assertIn("'has space'", jev.to_prolog("r", {"has space": a}))
        self.assertIn("'1abc'", jev.to_prolog("r", {"1abc": a}))
        self.assertIn("''", jev.to_prolog("r", {"": a}))

    def test_c6_quoting_run_id_choice_and_backslash(self):
        a = {"type": "choice", "choice": "Not Sure\\", "confidence": 0.4}
        out = jev.to_prolog("Run 1", {"q": a})
        self.assertEqual(out, "s1_answer('Run 1', q, choice, 0.4, 'Not Sure\\\\').")

    def test_c6_newline_escaped_single_line(self):
        a = {"type": "choice", "choice": "a\nb", "confidence": 0.4}
        out = jev.to_prolog("r", {"q": a})
        self.assertEqual(len(out.splitlines()), 1)
        self.assertIn("'a\\nb'", out)

    def test_c6_skips_none_answers(self):
        self.assertEqual(jev.to_prolog("r", None), "")
        self.assertEqual(jev.to_prolog("r", {"q": None}), "")


if __name__ == "__main__":
    unittest.main(verbosity=2)
