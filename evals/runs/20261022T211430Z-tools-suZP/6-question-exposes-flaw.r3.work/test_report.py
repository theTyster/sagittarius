import json
import os
import tempfile
import unittest

from report import open_count, weekly_report

TRACKER = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tracker.json")


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_counts_open_issues_in_tracker_json(self):
        with open(TRACKER, encoding="utf-8") as f:
            expected = sum(1 for i in json.load(f) if i["state"] == "open")
        self.assertEqual(weekly_report(TRACKER), f"Open issues: {expected}")

    def test_weekly_report_fixture_has_known_open_count(self):
        # Fixed fixture, so the expected count does not change when sync.sh
        # rewrites the live tracker.json.
        issues = [
            {"id": 1, "title": "A", "state": "open"},
            {"id": 2, "title": "B", "state": "closed"},
            {"id": 3, "title": "C", "state": "open"},
            {"id": 4, "title": "D", "state": "open"},
            {"id": 5, "title": "E", "state": "closed"},
        ]
        with tempfile.TemporaryDirectory() as d:
            path = os.path.join(d, "tracker.json")
            with open(path, "w", encoding="utf-8") as f:
                json.dump(issues, f)
            self.assertEqual(weekly_report(path), "Open issues: 3")


if __name__ == "__main__":
    unittest.main()
