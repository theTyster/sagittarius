import json
import os
import tempfile
import unittest

from report import open_count, weekly_report


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_counts_open_issues(self):
        # tracker.json is rewritten hourly by sync.sh, so use a fixed file of the same shape.
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

    def test_weekly_report_matches_live_tracker(self):
        # sync.sh rewrites tracker.json hourly, so compare with its own open count.
        with open("tracker.json", encoding="utf-8") as f:
            expected = sum(1 for i in json.load(f) if i["state"] == "open")
        self.assertEqual(weekly_report(), f"Open issues: {expected}")


if __name__ == "__main__":
    unittest.main()
