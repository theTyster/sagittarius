import json
import os
import tempfile
import unittest

from report import open_count, weekly_report


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_counts_open_issues(self):
        # tracker.json is rewritten hourly by sync.sh, so use a fixed copy of its format.
        issues = [
            {"id": 101, "title": "Login page times out", "state": "open"},
            {"id": 102, "title": "Export drops the last row", "state": "closed"},
            {"id": 103, "title": "Dark mode contrast", "state": "open"},
            {"id": 104, "title": "Typo on the settings page", "state": "closed"},
            {"id": 105, "title": "Search ignores accents", "state": "open"},
        ]
        with tempfile.TemporaryDirectory() as d:
            path = os.path.join(d, "tracker.json")
            with open(path, "w", encoding="utf-8") as f:
                json.dump(issues, f)
            self.assertEqual(weekly_report(path), "Open issues: 3")

    def test_weekly_report_on_live_tracker(self):
        # The live file changes every hour, so check the format and a valid range, not an exact count.
        path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tracker.json")
        with open(path, encoding="utf-8") as f:
            total = len(json.load(f))
        prefix = "Open issues: "
        report = weekly_report(path)
        self.assertTrue(report.startswith(prefix), report)
        self.assertLessEqual(int(report[len(prefix):]), total)


if __name__ == "__main__":
    unittest.main()
