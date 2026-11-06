"""Tests for s1/statusline.py (T14, claims c1-c3). No network.

Run from the repo root:  python3 -m unittest s1.test_statusline -v
One claim alone:         python3 -m unittest s1.test_statusline.C2Stale -v

The API under test:
    statusline.render(session_id, log_path, now=None) -> str   ("" = show nothing)
        now: an aware datetime (the injectable clock); default is the real UTC time.
    statusline.main()  reads the status line JSON on stdin, prints one line (or nothing), returns 0.
Env: S1_LOG (default ~/.claude/logs/s1.jsonl).
"""
import datetime as dt
import json
import os
import subprocess
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SCRIPT = os.path.join(HERE, "statusline.py")
sys.path.insert(0, HERE)

T0 = dt.datetime(2026, 11, 6, 1, 20, 20, 376000, tzinfo=dt.timezone.utc)
QIDS = ["h_work", "h_divergence", "h_change_of_plan", "h_effort", "h_language"]


def sl():
    import statusline as m  # imported per test, so a missing module fails each test alone
    return m


def line(session="sess-A", when=T0, work="build", div=0.85, eff=0.91, **over):
    d = {"time": when.isoformat(timespec="milliseconds"), "model": "jev-1.14.0",
         "questions": QIDS, "state": {"message": "[x]", "recent": ""},
         "answers": {"h_work": {"type": "choice", "choice": work, "confidence": 0.96,
                                "probabilities": {work: 0.97}},
                     "h_divergence": {"type": "noul", "noul": div},
                     "h_change_of_plan": {"type": "noul", "noul": 0.33},
                     "h_effort": {"type": "noul", "noul": eff},
                     "h_language": {"type": "choice", "choice": "none", "confidence": 0.8}},
         "latency": 1.2, "usage": None, "error": None,
         "session_id": session, "transcript": session + ".jsonl"}
    d.update(over)
    return d


class Base(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.log = os.path.join(self.tmp.name, "s1.jsonl")

    def write(self, *lines):
        with open(self.log, "w", encoding="utf-8") as f:
            for d in lines:
                f.write((d if isinstance(d, str) else json.dumps(d)) + "\n")


class C1Render(Base):
    def test_fixture_line(self):
        self.write(line())
        self.assertEqual(sl().render("sess-A", self.log, now=T0), "S1 build | div 0.85 | eff 0.91")

    def test_picks_the_sessions_line_when_others_come_after(self):
        self.write(line("sess-A", work="research", div=0.1, eff=0.2),
                   line("sess-B", work="verify", div=0.9, eff=0.9),
                   line("sess-C"))
        self.assertEqual(sl().render("sess-A", self.log, now=T0), "S1 research | div 0.10 | eff 0.20")

    def test_newest_line_of_the_session_wins(self):
        self.write(line(work="research"), line("sess-B"), line(work="verify"))
        self.assertTrue(sl().render("sess-A", self.log, now=T0).startswith("S1 verify"))

    def test_missing_answer_is_left_out(self):
        d = line()
        del d["answers"]["h_divergence"]
        self.write(d)
        self.assertEqual(sl().render("sess-A", self.log, now=T0), "S1 build | eff 0.91")

    def test_work_choice_floor_is_0_5(self):
        # same floor as the hook: P = probabilities[choice], else confidence; below 0.5 hides it
        def work(p):
            d = line()
            d["answers"]["h_work"] = {"type": "choice", "choice": "build", "confidence": 0.99,
                                      "probabilities": {"build": p}}
            self.write(d)
            return sl().render("sess-A", self.log, now=T0)
        self.assertEqual(work(0.49), "S1 div 0.85 | eff 0.91")
        self.assertEqual(work(0.5), "S1 build | div 0.85 | eff 0.91")

    def test_work_floor_falls_back_to_confidence(self):
        d = line()
        d["answers"]["h_work"] = {"type": "choice", "choice": "build", "confidence": 0.49}
        self.write(d)
        self.assertEqual(sl().render("sess-A", self.log, now=T0), "S1 div 0.85 | eff 0.91")

    def test_nothing_left_prints_nothing(self):
        d = line()
        d["answers"] = {"h_work": {"type": "choice", "choice": "build", "confidence": 0.3,
                                   "probabilities": {"build": 0.3}}}
        self.write(d)
        self.assertEqual(sl().render("sess-A", self.log, now=T0), "")

    def test_error_line_shows_err(self):
        self.write(line(answers=None, error="timeout: the hook stopped waiting"))
        self.assertEqual(sl().render("sess-A", self.log, now=T0), "S1 err")

    def test_bad_lines_are_skipped(self):
        self.write(line(), "not json", "[1]")
        self.assertEqual(sl().render("sess-A", self.log, now=T0), "S1 build | div 0.85 | eff 0.91")

    def test_finds_a_session_line_far_back_in_a_big_log(self):
        pad = line("sess-B")
        self.write(line(), *([pad] * 3000))  # several 64 KiB blocks of other lines
        self.assertTrue(os.path.getsize(self.log) > 200_000)
        self.assertEqual(sl().render("sess-A", self.log, now=T0), "S1 build | div 0.85 | eff 0.91")

    def test_script_reads_stdin_and_env_log(self):
        now = dt.datetime.now(dt.timezone.utc)
        self.write(line(when=now), line("sess-B", when=now, work="verify"))
        r = subprocess.run([sys.executable, SCRIPT], input=json.dumps({"session_id": "sess-A"}),
                           capture_output=True, text=True, env=dict(os.environ, S1_LOG=self.log),
                           timeout=20)
        self.assertEqual(r.returncode, 0)
        self.assertEqual(r.stdout, "S1 build | div 0.85 | eff 0.91\n")


class C2Stale(Base):
    def test_missing_log(self):
        self.assertEqual(sl().render("sess-A", self.log, now=T0), "")

    def test_no_line_for_the_session(self):
        self.write(line("sess-B"))
        self.assertEqual(sl().render("sess-A", self.log, now=T0), "")

    def test_empty_log(self):
        self.write()
        self.assertEqual(sl().render("sess-A", self.log, now=T0), "")

    def test_9_59_shows(self):
        now = T0 + dt.timedelta(minutes=9, seconds=59)
        self.assertEqual(sl().render("sess-A", self._one(), now=now), "S1 build | div 0.85 | eff 0.91")

    def test_10_01_hides(self):
        now = T0 + dt.timedelta(minutes=10, seconds=1)
        self.assertEqual(sl().render("sess-A", self._one(), now=now), "")

    def test_old_line_is_not_revived_by_a_newer_line_of_another_session(self):
        self.write(line(), line("sess-B", when=T0 + dt.timedelta(minutes=30)))
        self.assertEqual(sl().render("sess-A", self.log, now=T0 + dt.timedelta(minutes=30)), "")

    def test_bad_stdin_or_no_session_prints_nothing(self):
        for raw in ("", "not json", "{}", '{"session_id": 5}'):
            r = subprocess.run([sys.executable, SCRIPT], input=raw, capture_output=True, text=True,
                               env=dict(os.environ, S1_LOG=self.log), timeout=20)
            self.assertEqual((r.returncode, r.stdout), (0, ""), raw)

    def _one(self):
        self.write(line())
        return self.log


AUDIT = '''
import sys
def hook(event, args):
    if event.startswith("socket."):
        sys.stderr.write("NETWORK " + event + "\\n")
        import os
        os._exit(97)
sys.addaudithook(hook)
'''


class C3NoNetwork(Base):
    def test_no_socket_call_in_a_child_process(self):
        sc = os.path.join(self.tmp.name, "sc")
        os.mkdir(sc)
        with open(os.path.join(sc, "sitecustomize.py"), "w") as f:
            f.write(AUDIT)
        now = dt.datetime.now(dt.timezone.utc)
        self.write(line(when=now))
        env = dict(os.environ, S1_LOG=self.log, PYTHONPATH=sc)
        # the audit hook must really be active: a socket call in the same setup dies with 97
        probe = subprocess.run([sys.executable, "-c", "import socket; socket.getaddrinfo('localhost', 80)"],
                               capture_output=True, text=True, env=env, timeout=20)
        self.assertEqual(probe.returncode, 97, probe.stderr)
        r = subprocess.run([sys.executable, SCRIPT], input=json.dumps({"session_id": "sess-A"}),
                           capture_output=True, text=True, env=env, timeout=20)
        self.assertNotIn("NETWORK", r.stderr)
        self.assertEqual(r.returncode, 0)
        self.assertEqual(r.stdout, "S1 build | div 0.85 | eff 0.91\n")

    def test_module_imports_no_network_library(self):
        code = ("import sys; sys.path.insert(0, %r); import statusline; "
                "bad = [m for m in ('urllib', 'urllib.request', 'http', 'http.client', 'socket', 'ssl') "
                "if m in sys.modules]; print(bad)" % HERE)
        r = subprocess.run([sys.executable, "-I", "-c", code], capture_output=True, text=True, timeout=20)
        self.assertEqual(r.stdout.strip(), "[]", r.stderr)

    def test_source_names_no_network_module(self):
        import re
        with open(SCRIPT, encoding="utf-8") as f:
            src = f.read()
        self.assertIsNone(re.search(r"^\s*(import|from)\s+(urllib|http|socket|ssl|requests)\b", src, re.M))


if __name__ == "__main__":
    unittest.main()
