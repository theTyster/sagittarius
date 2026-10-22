import json
import os
import shutil
import tempfile
import unittest

from report import open_count, weekly_report

TRACKER = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tracker.json")


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_matches_open_issues_in_tracker(self):
        # tracker.json is rewritten hourly by sync.sh, so count its open issues here
        # instead of hard-coding the number. Work on a copy, so a sync that runs
        # mid-test cannot change the file between the count and the report.
        with tempfile.TemporaryDirectory() as tmp:
            path = os.path.join(tmp, "tracker.json")
            shutil.copy(TRACKER, path)
            with open(path, encoding="utf-8") as f:
                expected = sum(1 for i in json.load(f) if i["state"] == "open")
            self.assertEqual(weekly_report(path), f"Open issues: {expected}")


if __name__ == "__main__":
    unittest.main()
