"""s1watch prints each call of the System 1 log with the model's answers unchanged, whatever the questions."""
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

    def fan_lines(self, parts=9):
        """The two log lines of one fan-out call of `parts` parts, as s1/hook.py writes them."""
        names = ("doubts", "faults", "changes", "asks", "undecided", "reverses")
        raw = {"h_divergence": {"type": "noul", "noul": 0.5}, "h_work": {"type": "choice", "choice": "build", "confidence": 0.9}}
        for k in range(parts):
            raw[f"react@{k}"] = {"type": "choice", "choice": "doubts" if k == 1 else "accepts", "confidence": 0.9,
                                 "probabilities": {"doubts": 0.5, "accepts": 0.5}}
            for n in names:
                raw[f"{n}@{k}"] = {"type": "noul", "noul": 0.93 if (k == 1 and n == "doubts") else 0.04}
        texts = [f"Part number {k} of the message." for k in range(parts)]
        call = {"time": "2026-11-14T08:00:00+00:00", "session_id": "s-1", "routing": "workbench", "stage": 1, "latency": 0.24,
                "state": {"message": " ".join(texts), "recent": [], "sentences": texts}, "answers": raw}
        comb = {"time": "2026-11-14T08:00:00.300+00:00", "session_id": "s-1", "routing": "workbench", "combined": True, "parts": parts,
                "part_text": texts, "replaced": ["h_divergence"],
                "answers": dict(raw, h_divergence={"type": "noul", "noul": 0.93}, h_divergence_plain={"type": "noul", "noul": 0.5},
                                h_reversal={"type": "noul", "noul": 0.03})}
        return [call, comb]

    def test_a_fan_out_call_is_one_short_block(self):
        """PR 11 review: a 9-part prompt printed about 820 lines. Now: the call's header and message,
        then one block with the whole-message answers and one line for each part."""
        out_blocks = self.run_on(self.fan_lines(9))
        self.assertEqual(len(out_blocks), 2)
        call, comb = out_blocks
        self.assertEqual(len(call.splitlines()), 3)  # header, message, and the note
        self.assertIn("63 answers about the parts", call)
        lines = comb.splitlines()
        self.assertLess(len(lines), 45)
        self.assertNotIn("@", comb)  # no part answer is dumped
        part = [l for l in lines if l.startswith("  [")]
        self.assertEqual(len(part), 9)
        self.assertIn("react=doubts", part[1])
        self.assertIn("doubts 0.93", part[1])
        self.assertIn("“Part number 1 of the message.”", part[1])
        self.assertNotIn("faults", part[1])  # only what stands out
        whole = json.loads("\n".join(l for l in lines[1:] if not l.startswith("  [")))
        self.assertEqual(whole["h_divergence"]["noul"], 0.93)
        self.assertEqual(whole["h_divergence_plain"]["noul"], 0.5)

    def test_raw_prints_every_answer(self):
        d = tempfile.mkdtemp(); self.addCleanup(shutil.rmtree, d)
        log = os.path.join(d, "s1.jsonl")
        open(log, "w").write("".join(json.dumps(l) + "\n" for l in self.fan_lines(2)))
        r = subprocess.run([TOOL, "--once", "--raw"], capture_output=True, text=True, timeout=20,
                           env=dict(os.environ, S1_LOG=log, S1_SESSIONS=d, TZ="UTC"))
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(r.stdout.count('"react@1"'), 2)  # on the call line and on the combined line

    def test_names_no_question(self):
        src = open(TOOL).read()
        for w in ("noul", "choice", "score", "h_work"):
            self.assertIsNone(re.search(r"\b%s\b" % w, src), w)


if __name__ == "__main__":
    unittest.main()
