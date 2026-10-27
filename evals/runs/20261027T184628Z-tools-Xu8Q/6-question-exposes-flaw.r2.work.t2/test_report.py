import json
import os
import tempfile
import unittest

from report import open_count, weekly_report


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_counts_open_issues(self):
        # Own fixture, not the live tracker.json: the hourly sync rewrites that file.
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


if __name__ == "__main__":
    unittest.main()
