import json
import os
import tempfile
import unittest

from report import open_count, weekly_report


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_counts_open_issues(self):
        # tracker.json is rewritten by a sync job, so use fixed data in the same shape.
        issues = [
            {"id": 1, "title": "a", "state": "open"},
            {"id": 2, "title": "b", "state": "closed"},
            {"id": 3, "title": "c", "state": "open"},
        ]
        with tempfile.TemporaryDirectory() as d:
            path = os.path.join(d, "tracker.json")
            with open(path, "w", encoding="utf-8") as f:
                json.dump(issues, f)
            self.assertEqual(weekly_report(path), "Open issues: 2")

    def test_tracker_export_shape(self):
        # The sync job rewrites tracker.json; fail if its format changes in a way open_count ignores.
        path = os.path.join(os.path.dirname(__file__), "tracker.json")
        with open(path, encoding="utf-8") as f:
            issues = json.load(f)
        for issue in issues:
            self.assertIn(issue.get("state"), {"open", "closed"}, issue)


if __name__ == "__main__":
    unittest.main()
