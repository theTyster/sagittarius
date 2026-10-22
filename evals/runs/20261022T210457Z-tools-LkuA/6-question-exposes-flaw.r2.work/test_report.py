import json
import os
import tempfile
import unittest

from report import open_count, weekly_report


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_counts_known_fixture(self):
        # Fixed data, so the expected count does not change when tracker.json is re-exported.
        issues = [
            {"id": 1, "title": "a", "state": "open"},
            {"id": 2, "title": "b", "state": "closed"},
            {"id": 3, "title": "c", "state": "open"},
            {"id": 4, "title": "d", "state": "open"},
        ]
        with tempfile.TemporaryDirectory() as tmp:
            path = os.path.join(tmp, "tracker.json")
            with open(path, "w", encoding="utf-8") as f:
                json.dump(issues, f)
            self.assertEqual(weekly_report(path), "Open issues: 3")

    def test_weekly_report_matches_open_issues_in_tracker(self):
        # sync.sh rewrites tracker.json hourly, so count it here instead of hardcoding a number.
        with open("tracker.json", encoding="utf-8") as f:
            issues = json.load(f)
        expected = sum(1 for i in issues if i["state"] == "open")
        self.assertEqual(weekly_report(), f"Open issues: {expected}")


if __name__ == "__main__":
    unittest.main()
