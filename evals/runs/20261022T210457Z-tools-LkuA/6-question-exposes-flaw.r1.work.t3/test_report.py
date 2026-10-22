import json
import os
import tempfile
import unittest

from report import open_count, weekly_report

HERE = os.path.dirname(os.path.abspath(__file__))

# Fixed fixture with a known answer: independent of the live tracker.json.
FIXTURE = [
    {"id": 1, "title": "a", "state": "open"},
    {"id": 2, "title": "b", "state": "closed"},
    {"id": 3, "title": "c", "state": "open"},
    {"id": 4, "title": "d", "state": "closed"},
    {"id": 5, "title": "e", "state": "open"},
]


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_counts_known_fixture(self):
        with tempfile.TemporaryDirectory() as d:
            path = os.path.join(d, "tracker.json")
            with open(path, "w", encoding="utf-8") as f:
                json.dump(FIXTURE, f)
            self.assertEqual(weekly_report(path), "Open issues: 3")

    def test_weekly_report_open_count_matches_tracker_json(self):
        # tracker.json is rewritten hourly by sync.sh, so count it here
        # rather than hardcoding the number.
        with open(os.path.join(HERE, "tracker.json"), encoding="utf-8") as f:
            expected = sum(1 for i in json.load(f) if i["state"] == "open")

        # weekly_report() reads "tracker.json" relative to the working directory.
        cwd = os.getcwd()
        self.addCleanup(os.chdir, cwd)
        os.chdir(HERE)

        self.assertEqual(weekly_report(), f"Open issues: {expected}")


if __name__ == "__main__":
    unittest.main()
