"""s1watch prints each call of the System 1 log with Jev's answers unchanged, whatever the questions."""
import json, os, re, shutil, subprocess, tempfile, unittest

TOOL = os.path.join(os.path.dirname(os.path.abspath(__file__)), "s1watch")


@unittest.skipUnless(shutil.which("jq"), "needs jq")
class S1Watch(unittest.TestCase):
    def run_on(self, lines, sessions=()):
        d = tempfile.mkdtemp(); self.addCleanup(shutil.rmtree, d)
        log = os.path.join(d, "s1.jsonl")
        open(log, "w").write("".join((l if isinstance(l, str) else json.dumps(l)) + "\n" for l in lines))
        sess = os.path.join(d, "sessions"); os.mkdir(sess)
        for i, (sid, name) in enumerate(sessions):
            json.dump({"sessionId": sid, "name": name}, open(os.path.join(sess, f"{i}.json"), "w"))
        r = subprocess.run([TOOL, "--once", "-n", "50"], capture_output=True, text=True, timeout=20,
                           env=dict(os.environ, S1_LOG=log, S1_SESSIONS=sess, TZ="UTC"))
        self.assertEqual(r.returncode, 0, r.stderr)
        return [b for b in re.split(r"^── ", r.stdout, flags=re.M) if b.strip()]

    def test_new_question_type_comes_out_unchanged(self):
        ans = {"anything": {"type": "never-seen", "x": [1, 2], "p": {"a": 0.5}}}
        b, = self.run_on([{"time": "2026-11-14T08:00:00+00:00", "session_id": "s-1", "routing": "workbench",
                           "latency": 2.04, "state": {"message": "hi\x1b[2Jthere"}, "answers": ans}],
                         [("s-1", "named")])
        head, msg, *rest = b.splitlines()
        self.assertIn("08:00:00  named  workbench  2.0s", head)
        self.assertEqual(msg, "> hithere")
        self.assertEqual(json.loads("\n".join(rest)), ans)

    def test_skips_bad_lines_and_shows_skipped_calls(self):
        blocks = self.run_on(["{broken", {"time": "2026-11-14T08:00:00+00:00", "session_id": "abcdefgh-9",
                                          "skipped": "no key"}])
        self.assertEqual(len(blocks), 1)
        self.assertIn("abcdefgh", blocks[0]); self.assertIn("skipped: no key", blocks[0])

    def test_names_no_question(self):
        src = open(TOOL).read()
        for w in ("noul", "choice", "score", "h_work"):
            self.assertIsNone(re.search(r"\b%s\b" % w, src), w)


if __name__ == "__main__":
    unittest.main()
