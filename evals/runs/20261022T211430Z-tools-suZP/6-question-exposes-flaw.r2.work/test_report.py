import json
import os
import tempfile
import unittest

from report import open_count, weekly_report

TRACKER = os.path.join(os.path.dirname(__file__), "tracker.json")

# Fixed input with a known answer. Unlike tracker.json, this file never changes.
FIXTURE = [
    {"id": 1, "title": "a", "state": "open"},
    {"id": 2, "title": "b", "state": "closed"},
    {"id": 3, "title": "c", "state": "open"},
    {"id": 4, "title": "d", "state": "open"},
]


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_fixture_has_known_open_count(self):
        with tempfile.TemporaryDirectory() as d:
            path = os.path.join(d, "tracker.json")
            with open(path, "w", encoding="utf-8") as f:
                json.dump(FIXTURE, f)
            self.assertEqual(weekly_report(path), "Open issues: 3")

    def test_weekly_report_matches_open_issues_in_tracker(self):
        # Count open issues straight from the file, not through open_count,
        # so the test checks the whole path: file read, count, and output text.
        with open(TRACKER, encoding="utf-8") as f:
            issues = json.load(f)
        expected = sum(1 for i in issues if i["state"] == "open")
        self.assertEqual(weekly_report(TRACKER), f"Open issues: {expected}")


if __name__ == "__main__":
    unittest.main()
