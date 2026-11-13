"""Tests for s1/s1inspect.py, the System 1 inspection tool. No network. Every log line, projects dir
and question here is invented.

Run from the repo root:  python3 -m unittest s1.test_s1inspect -v
"""
import importlib.util
import io
import json
import os
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stdout

HERE = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location("s1_inspect_tool", os.path.join(HERE, "s1inspect.py"))
ins = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(ins)
hook, jev = ins.hook, ins.jev

QUESTIONS = {
    "h_work": {"type": "choice", "instructions": "What work?",
               "criteria": {"build": "Change code", "question": "Answer only"}},
    "h_divergence": {"type": "noul", "instructions": "Is the result wrong?"},
    "h_change_of_plan": {"type": "noul", "instructions": "Did the plan change?"},
    "h_effort": {"type": "noul", "instructions": "Is the effort big?"},
    "h_language": {"type": "choice", "instructions": "Which tool?",
                   "criteria": {"lean": "Lean", "none": "No tool"}},
}


def answers(div=0.9, eff=0.1, work=("build", 0.8), lang=("none", 0.6)):
    return {
        "h_work": {"type": "choice", "choice": work[0], "confidence": work[1],
                   "probabilities": {work[0]: work[1], "question": round(1 - work[1], 2)}},
        "h_divergence": {"type": "noul", "noul": div},
        "h_change_of_plan": {"type": "noul", "noul": 0.5},
        "h_effort": {"type": "noul", "noul": eff},
        "h_language": {"type": "choice", "choice": lang[0], "confidence": lang[1],
                       "probabilities": {lang[0]: lang[1], "lean": round(1 - lang[1], 2)}},
    }


def call(sid="aaaaaaaa-1111", time="2026-11-10T10:00:00.000+00:00", message="fix it", ans=None,
         error=None, version=None, **extra):
    rec = {"time": time, "model": "jev-1.14.0", "questions": list(QUESTIONS),
           "state": {"message": message, "recent": [{"role": "you", "text": "before"},
                                                    {"role": "agent", "text": "done"}]},
           "answers": ans if ans is not None or error else answers(), "latency": 1.5,
           "usage": {"input_tokens": 10, "output_tokens": 2}, "error": error, "session_id": sid,
           "transcript": sid + ".jsonl", "sagittarius": version or jev.sagittarius_version()}
    rec.update(extra)
    return rec


class Base(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.dir = self.tmp.name
        self.projects = os.path.join(self.dir, "projects")
        os.makedirs(self.projects)
        self.qpath = os.path.join(self.dir, "questions.json")
        with open(self.qpath, "w") as f:
            json.dump(QUESTIONS, f)

    @staticmethod
    def read(path):
        with open(path, encoding="utf-8") as f:
            return f.read()

    def write_log(self, recs):
        p = os.path.join(self.dir, "s1.jsonl")
        with open(p, "w") as f:
            for r in recs:
                f.write((r if isinstance(r, str) else json.dumps(r)) + "\n")
        return p

    def project(self, hub, sids):
        d = os.path.join(self.projects, ins.project_dirname(hub))
        os.makedirs(d, exist_ok=True)
        for s in sids:
            open(os.path.join(d, s + ".jsonl"), "w").close()

    def run_main(self, *argv):
        out = io.StringIO()
        with redirect_stdout(out):
            code = ins.main(list(argv))
        return code, out.getvalue()

    def common(self, log):
        return ["--log", log, "--questions", self.qpath, "--projects", self.projects]


class Selection(Base):
    def test_project_dir_rule(self):
        self.assertEqual(ins.project_dirname("/home/ty/Projects/mine/sagittarius"),
                         "-home-ty-Projects-mine-sagittarius")
        self.assertEqual(ins.project_dirname("/home/ty/.dotfiles"), "-home-ty--dotfiles")

    def test_hub_filter(self):
        hub = os.path.join(self.dir, "hub.one")
        other = os.path.join(self.dir, "other")
        self.project(hub, ["sess-hub-1"])
        self.project(other, ["sess-other-1"])
        log = self.write_log([call("sess-hub-1", message="in hub"), call("sess-other-1", message="elsewhere"),
                              call("sess-nowhere", message="nowhere")])
        code, out = self.run_main(*self.common(log), "--hub", hub, "--json")
        self.assertEqual(code, 0)
        rows = [json.loads(x) for x in out.splitlines()]
        self.assertEqual([r["saw"]["message"]["text"] for r in rows], ["in hub"])

    def test_hub_without_projects_dir_gives_nothing(self):
        log = self.write_log([call("s1")])
        code, out = self.run_main(*self.common(log), "--hub", os.path.join(self.dir, "none"), "--json")
        self.assertEqual(out.strip(), "")

    def test_session_prefix_since_last_newest_first(self):
        log = self.write_log([call("abcd1111", time="2026-11-01T00:00:00+00:00", message="m1"),
                              call("abcd2222", time="2026-11-03T00:00:00+00:00", message="m3"),
                              call("zzzz", time="2026-11-02T00:00:00+00:00", message="m2")])
        _, out = self.run_main(*self.common(log), "--json")
        self.assertEqual([json.loads(x)["saw"]["message"]["text"] for x in out.splitlines()], ["m3", "m2", "m1"])
        _, out = self.run_main(*self.common(log), "--json", "--session", "abcd")
        self.assertEqual(len(out.splitlines()), 2)
        _, out = self.run_main(*self.common(log), "--json", "--since", "2026-11-02T00:00:00Z")
        self.assertEqual(len(out.splitlines()), 2)
        _, out = self.run_main(*self.common(log), "--json", "--last", "1")
        self.assertEqual(json.loads(out)["saw"]["message"]["text"], "m3")

    def test_bad_lines_are_skipped(self):
        log = self.write_log(["not json", "[1]", "", call("s1")])
        _, out = self.run_main(*self.common(log), "--json")
        self.assertEqual(len(out.splitlines()), 1)


class FailedAndSkip(Base):
    def test_failed_call_and_skip_line(self):
        failed = call("s1", error="timeout: handshake", ans=None, time="2026-11-10T10:00:00+00:00")
        failed["answers"] = None
        failed["usage"] = None
        skip = {"time": "2026-11-10T10:00:04+00:00", "skipped": "no answers (the call's line has the error)",
                "session_id": "s1", "transcript": "s1.jsonl", "sagittarius": "0.4.0"}
        good = call("s1", time="2026-11-10T09:00:00+00:00")
        log = self.write_log([good, failed, skip])
        _, out = self.run_main(*self.common(log), "--json", "--errors")
        rows = [json.loads(x) for x in out.splitlines()]
        self.assertEqual([r["kind"] for r in rows], ["skip", "call"])
        self.assertTrue(all(r["failed"] for r in rows))
        self.assertEqual(rows[0]["answered"]["hint"], "System 1: no view (no answer)")
        self.assertEqual(rows[1]["answered"]["error"], "timeout: handshake")
        self.assertEqual(rows[1]["answered"]["hint"], "System 1: no view (no answer)")
        _, text = self.run_main(*self.common(log))
        self.assertIn("HOOK SKIP", text)
        self.assertIn("error: timeout: handshake", text)
        s = ins.summarize([json.loads(x) for x in self.run_main(*self.common(log), "--json")[1].splitlines()])
        self.assertEqual((s["calls"], s["skip_lines"], s["failed_calls"]), (2, 1, 1))
        self.assertEqual(s["error_rate"], 0.5)

    def test_skip_reasons_map_to_hook_wording(self):
        self.assertEqual(ins.skip_hint("no API key"), hook.no_view("no API key"))
        self.assertEqual(ins.skip_hint("timeout: the hook stopped"), hook.no_view("timeout"))
        self.assertEqual(ins.skip_hint("stdin: not JSON"), hook.no_view("bad input"))
        self.assertEqual(ins.skip_hint("weird"), hook.no_view("error"))


class Mismatch(Base):
    def test_ids_missing_from_file_and_version(self):
        rec = call("s1", version="0.0.1")
        rec["questions"] = list(QUESTIONS) + ["h_gone"]
        rec["answers"]["h_gone"] = {"type": "noul", "noul": 0.1}
        log = self.write_log([rec])
        _, out = self.run_main(*self.common(log), "--json")
        a = json.loads(out)["asked"]
        self.assertEqual(a["missing_from_file"], ["h_gone"])
        self.assertIsNone(a["questions"]["h_gone"])
        joined = " ".join(a["notes"])
        self.assertIn("h_gone", joined)
        self.assertIn("0.0.1", joined)
        self.assertEqual(a["match"], "unknown")
        self.assertNotIn("Authorization", json.dumps(a["request_body"]))

    def test_extra_in_file(self):
        rec = call("s1")
        rec["questions"] = ["h_work"]
        log = self.write_log([rec])
        a = json.loads(self.run_main(*self.common(log), "--json")[1])["asked"]
        self.assertTrue(any("did not send" in n for n in a["notes"]))

    def test_sha_decides_when_logged(self):
        if not hasattr(jev, "questions_sha"):
            self.skipTest("jev has no questions_sha")
        same = call("s1", questions_sha=jev.questions_sha(QUESTIONS))
        diff = call("s2", questions_sha="0" * 12)
        log = self.write_log([same, diff])
        rows = {json.loads(x)["session_id"]: json.loads(x) for x in self.run_main(*self.common(log), "--json")[1].splitlines()}
        self.assertEqual(rows["s1"]["asked"]["match"], "same")
        self.assertEqual(rows["s2"]["asked"]["match"], "differs")
        self.assertTrue(any("NOT what was sent" in n for n in rows["s2"]["asked"]["notes"]))

    def test_questions_file_unreadable(self):
        log = self.write_log([call("s1")])
        _, out = self.run_main("--log", log, "--questions", os.path.join(self.dir, "nope.json"),
                               "--projects", self.projects, "--json")
        j = json.loads(out)
        self.assertTrue(any("could not be read" in n for n in j["asked"]["notes"]))
        self.assertIn("Not recomputed", j["answered"]["hint_note"])


class HintAgreement(Base):
    def test_format_answers_agreement(self):
        cases = [answers(), answers(div=0.5, eff=0.5, work=("build", 0.3), lang=("none", 0.3)),
                 answers(div=0.5, eff=0.5, work=("build", 0.3), lang=("none", 0.9)),
                 answers(div=0.1, eff=0.9, lang=("lean", 0.9))]
        log = self.write_log([call(f"s{i}", ans=a, time=f"2026-11-10T10:00:0{i}+00:00") for i, a in enumerate(cases)])
        rows = [json.loads(x) for x in self.run_main(*self.common(log), "--json")[1].splitlines()][::-1]
        for r, a in zip(rows, cases):
            self.assertEqual(r["answered"]["hint"], hook.format_answers(a, QUESTIONS))
        # the cases reach both special lines
        hints = [r["answered"]["hint"] for r in rows]
        self.assertIn(hook.UNSURE, hints)
        self.assertIn(hook.NO_SIGNAL, hints)

    def test_bands_and_choice_floor(self):
        log = self.write_log([call("s1", ans=answers(div=0.7, eff=0.3, work=("build", 0.49)))])
        r = json.loads(self.run_main(*self.common(log), "--json")[1])
        a = r["answered"]["answers"]
        self.assertEqual(a["h_divergence"]["band"], "yes")
        self.assertEqual(a["h_effort"]["band"], "no")
        self.assertEqual(a["h_change_of_plan"]["band"], "unsure")
        self.assertEqual(a["h_work"]["band"], "unsure")
        self.assertEqual(a["h_work"]["probabilities"]["build"], 0.49)
        self.assertEqual(r["signals"], ["divergence"])

    def test_malformed_answer_does_not_crash(self):
        bad = answers()
        bad["h_divergence"] = {"type": "noul", "noul": "x"}
        log = self.write_log([call("s1", ans=bad)])
        r = json.loads(self.run_main(*self.common(log), "--json")[1])
        self.assertTrue(r["answered"]["answers"]["h_divergence"]["malformed"])
        self.assertIn("Not recomputed", r["answered"]["hint_note"])
        self.assertIsNone(r["answered"]["hint"])


class Summary(Base):
    def test_summary_counts(self):
        log = self.write_log([call("s1", ans=answers(div=0.9)), call("s2", ans=answers(div=0.1)),
                              call("s3", ans=answers(div=0.5, work=("build", 0.3)))])
        _, out = self.run_main(*self.common(log), "--summary", "--json")
        s = json.loads(out)
        self.assertEqual(s["questions"]["h_divergence"]["counts"], {"yes": 1, "no": 1, "unsure": 1})
        self.assertEqual(s["questions"]["h_work"]["counts"], {"build": 2, "unsure": 1})
        self.assertEqual(s["signals_fired"]["divergence"], 1)
        self.assertEqual(s["latency_median"], 1.5)
        _, text = self.run_main(*self.common(log), "--summary")
        self.assertIn("h_divergence", text)


class Html(Base):
    def test_escaping_and_self_contained(self):
        evil = '<script>alert("x")</script> & </pre><img src=x onerror=1>'
        rec = call("s1", message=evil)
        rec["state"]["recent"][0]["text"] = evil
        rec["error"] = "boom <b>"
        skip = {"time": "2026-11-10T10:00:05+00:00", "skipped": "<i>why</i>", "session_id": "s1"}
        log = self.write_log([rec, skip])
        out_file = os.path.join(self.dir, "r.html")
        code, _ = self.run_main(*self.common(log), "--html", out_file)
        self.assertEqual(code, 0)
        text = self.read(out_file)
        self.assertNotIn(evil, text)
        self.assertNotIn("<img src=x", text)
        self.assertIn("boom &lt;b&gt;", text)
        self.assertIn("&lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt;", text)
        self.assertIn("&lt;i&gt;why&lt;/i&gt;", text)
        self.assertEqual(text.count("<script>"), 1)  # only the tool's own script
        for ext in ("http://", "https://", "src=\"", "href=\""):
            self.assertNotIn(ext, text)
        for word in ("Saw", "Asked", "Answered"):
            self.assertIn(f"<summary>{word}</summary>", text)
        self.assertIn("prefers-color-scheme:dark", text)

    def test_html_has_summary_and_no_key(self):
        old = os.environ.get("TYPESAFE_API_KEY")
        os.environ["TYPESAFE_API_KEY"] = "sk-secret-test-key"
        self.addCleanup(lambda: os.environ.pop("TYPESAFE_API_KEY", None) if old is None
                        else os.environ.__setitem__("TYPESAFE_API_KEY", old))
        log = self.write_log([call("s1")])
        out_file = os.path.join(self.dir, "r.html")
        self.run_main(*self.common(log), "--html", out_file)
        text = self.read(out_file)
        self.assertNotIn("sk-secret-test-key", text)
        self.assertIn("median latency", text)
        self.assertIn("error rate", text)


class Script(Base):
    def test_runs_as_script_and_reads_only(self):
        log = self.write_log([call("s1")])
        before = os.listdir(self.dir)
        r = subprocess.run([sys.executable, os.path.join(HERE, "s1inspect.py"), *self.common(log), "--last", "1"],
                           capture_output=True, text=True, timeout=30)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("WHAT IT SAW", r.stdout)
        self.assertEqual(sorted(os.listdir(self.dir)), sorted(before))

    def test_bad_since(self):
        log = self.write_log([call("s1")])
        r = subprocess.run([sys.executable, os.path.join(HERE, "s1inspect.py"), *self.common(log), "--since", "nope"],
                           capture_output=True, text=True, timeout=30)
        self.assertEqual(r.returncode, 2)


if __name__ == "__main__":
    unittest.main()


class LiveServer(unittest.TestCase):
    """--serve: the page carries the live script, and /stamp changes when the log changes."""

    def test_page_and_stamp(self):
        import socket, threading, time, urllib.request
        from s1 import s1inspect
        d = tempfile.mkdtemp()
        log = os.path.join(d, "s1.jsonl")
        with open(log, "w") as f:
            f.write("")
        with socket.socket() as s:
            s.bind(("127.0.0.1", 0))
            port = s.getsockname()[1]
        args = s1inspect.parser().parse_args(["--log", log, "--serve", str(port), "--projects", d])
        t = threading.Thread(target=s1inspect.serve, args=(args,), daemon=True)
        t.start()
        url = f"http://127.0.0.1:{port}"
        for _ in range(50):
            try:
                page = urllib.request.urlopen(url + "/").read().decode()
                break
            except OSError:
                time.sleep(0.05)
        self.assertIn("/stamp", page)
        self.assertIn('id="live"', page)
        a = urllib.request.urlopen(url + "/stamp").read().decode()
        time.sleep(0.01)
        with open(log, "a") as f:
            f.write('{"time": "2026-11-13T00:00:00+00:00"}\n')
        b = urllib.request.urlopen(url + "/stamp").read().decode()
        self.assertNotEqual(a, b)
