"""SCHEMA.md names every field that the code writes in a log line (no field goes undocumented)."""
import json, os, re, sys, tempfile, unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import test_hook as th  # noqa: E402


def documented():
    text = open(os.path.join(HERE, "SCHEMA.md"), encoding="utf-8").read()
    part = text.split("## The log line", 1)[1]
    return set(re.findall(r"^\| `([a-z_]+)` \|", part, re.M))


def extra_keys(path):
    """The keys of the log_extra dict literals in a script (bench.py, calibrate.py)."""
    src = open(os.path.join(HERE, path), encoding="utf-8").read()
    out = set()
    for m in re.finditer(r"log_extra=\{([^}]*)\}", src):
        out |= set(re.findall(r"\"([a-z_]+)\"\s*:", m.group(1)))
    return out


class Schema(th.Base):
    def keys_of_runs(self):
        keys = set()
        self.run_hook(th.Fake())                                    # a normal call
        env = dict(self.env, TYPESAFE_API_KEY="")
        self.run_hook(None, env=env)                                # no key: a skip line
        self.run_hook(None, raw="not json")                         # bad input: a skip line
        wb = tempfile.mkdtemp()
        open(os.path.join(wb, "pipeline.py"), "w").write(
            "def run(state, ask, questions):\n    return ask(questions)\n")
        json.dump(json.load(open(os.path.join(HERE, "questions.json"))),
                  open(os.path.join(wb, "questions.json"), "w"))
        self.run_hook(th.Fake(), env=dict(self.env, S1_WORKBENCH=wb))  # a workbench routing call
        for line in self.log_lines():
            keys |= set(line)
        return keys

    def test_every_written_field_is_documented(self):
        doc = documented()
        self.assertTrue(doc, "no field table in SCHEMA.md")
        written = self.keys_of_runs() | extra_keys("bench.py") | extra_keys("calibrate.py")
        self.assertIn("routing", written)  # the workbench run did route
        self.assertEqual(sorted(written - doc), [], "fields written but not in SCHEMA.md")

    def test_answer_types_that_the_hook_reads_are_documented(self):
        text = open(os.path.join(HERE, "SCHEMA.md"), encoding="utf-8").read()
        for t in ("noul", "choice", "score"):
            self.assertRegex(text, r"\| `%s` \|" % t)


if __name__ == "__main__":
    unittest.main()
