"""make-live.sh and take-live.sh keep a copy of the files they overwrite (review H-0026, a105)."""
import glob, os, shutil, subprocess, tempfile, unittest

HERE = os.path.dirname(os.path.abspath(__file__))


class Copy(unittest.TestCase):
    def setUp(self):
        self.wb = os.path.join(tempfile.mkdtemp(), "workbench")
        self.addCleanup(shutil.rmtree, os.path.dirname(self.wb))
        os.makedirs(os.path.join(self.wb, "bench"))
        for s in ("make-live.sh", "take-live.sh"):
            shutil.copy(os.path.join(HERE, "workbench", "bench", s), os.path.join(self.wb, "bench", s))
        for d, tag in ((self.wb, "live"), (os.path.join(self.wb, "bench"), "bench")):
            for f in ("questions.json", "pipeline.py"):
                open(os.path.join(d, f), "w").write(f"{tag} {f}\n")

    def run_script(self, name):
        r = subprocess.run(["sh", os.path.join(self.wb, "bench", name)], capture_output=True, text=True, timeout=10)
        self.assertEqual(r.returncode, 0, r.stderr)
        return r.stdout

    def test_make_live_keeps_the_live_files(self):
        out = self.run_script("make-live.sh")
        self.assertEqual(open(os.path.join(self.wb, "questions.json")).read(), "bench questions.json\n")
        kept = glob.glob(os.path.join(self.wb, "bench", "backups", "*", "live-questions.json"))
        self.assertEqual(len(kept), 1, out)
        self.assertEqual(open(kept[0]).read(), "live questions.json\n")
        self.assertIn(os.path.dirname(kept[0]), out)

    def test_take_live_keeps_the_bench_files(self):
        out = self.run_script("take-live.sh")
        self.assertEqual(open(os.path.join(self.wb, "bench", "pipeline.py")).read(), "live pipeline.py\n")
        kept = glob.glob(os.path.join(self.wb, "bench", "backups", "*", "bench-pipeline.py"))
        self.assertEqual(len(kept), 1, out)
        self.assertEqual(open(kept[0]).read(), "bench pipeline.py\n")


if __name__ == "__main__":
    unittest.main()
