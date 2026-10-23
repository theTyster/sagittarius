import json
import os
import tempfile
import unittest

from report import open_count, weekly_report

# The sync job rewrites tracker.json every hour, so the test uses its own export.
ISSUES = [
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
                json.dump(ISSUES, f)
            self.assertEqual(weekly_report(path), "Open issues: 3")

    def test_real_tracker_export_is_well_formed(self):
        path = os.path.join(os.path.dirname(__file__), "tracker.json")
        with open(path, encoding="utf-8") as f:
            issues = json.load(f)
        self.assertIsInstance(issues, list)
        for issue in issues:
            self.assertIn(issue["state"], ("open", "closed"))
        self.assertEqual(
            weekly_report(path), f"Open issues: {open_count(issues)}"
        )


if __name__ == "__main__":
    unittest.main()
