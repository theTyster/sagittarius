import json
import os
import tempfile
import unittest

from report import open_count, weekly_report

# Snapshot of tracker.json. The live file is rewritten hourly by sync.sh,
# so the test uses a fixed copy instead of reading it directly.
TRACKER_SNAPSHOT = [
    {"id": 101, "title": "Login page times out", "state": "open"},
    {"id": 102, "title": "Export drops the last row", "state": "closed"},
    {"id": 103, "title": "Dark mode contrast", "state": "open"},
    {"id": 104, "title": "Typo on the settings page", "state": "closed"},
    {"id": 105, "title": "Search ignores accents", "state": "open"},
]


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_counts_open_issues(self):
        with tempfile.TemporaryDirectory() as d:
            path = os.path.join(d, "tracker.json")
            with open(path, "w", encoding="utf-8") as f:
                json.dump(TRACKER_SNAPSHOT, f)
            self.assertEqual(weekly_report(path), "Open issues: 3")

    def test_live_tracker(self):
        # The live file changes every hour, so check its shape and compare
        # the report with a count of whatever the file holds now.
        path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tracker.json")
        with open(path, encoding="utf-8") as f:
            issues = json.load(f)
        self.assertIsInstance(issues, list)
        for issue in issues:
            self.assertIn(issue.get("state"), {"open", "closed"}, msg=issue)
        expected = len([i for i in issues if i["state"] == "open"])
        self.assertEqual(weekly_report(path), f"Open issues: {expected}")


if __name__ == "__main__":
    unittest.main()
