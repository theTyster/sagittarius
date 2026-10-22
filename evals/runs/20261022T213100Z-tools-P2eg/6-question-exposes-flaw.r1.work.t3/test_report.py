import json
import os
import tempfile
import unittest

from report import open_count, weekly_report


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_counts_open_issues(self):
        # tracker.json is rewritten hourly by sync.sh, so use a fixed fixture.
        issues = [
            {"id": 1, "title": "a", "state": "open"},
            {"id": 2, "title": "b", "state": "closed"},
            {"id": 3, "title": "c", "state": "open"},
            {"id": 4, "title": "d", "state": "closed"},
            {"id": 5, "title": "e", "state": "open"},
        ]
        with tempfile.TemporaryDirectory() as d:
            path = os.path.join(d, "tracker.json")
            with open(path, "w", encoding="utf-8") as f:
                json.dump(issues, f)
            self.assertEqual(weekly_report(path), "Open issues: 3")

    def test_live_tracker_has_expected_shape(self):
        # Shape only: sync.sh changes the issues, so the count is not checked.
        path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tracker.json")
        with open(path, encoding="utf-8") as f:
            issues = json.load(f)
        self.assertIsInstance(issues, list)
        for issue in issues:
            self.assertIsInstance(issue, dict)
            self.assertIsInstance(issue.get("state"), str)
        self.assertRegex(weekly_report(path), r"^Open issues: \d+$")


if __name__ == "__main__":
    unittest.main()
