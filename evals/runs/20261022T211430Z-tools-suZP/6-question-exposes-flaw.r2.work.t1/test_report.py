import json
import os
import unittest

from report import open_count, weekly_report

TRACKER = os.path.join(os.path.dirname(__file__), "tracker.json")


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_matches_open_issues_in_tracker(self):
        # Count open issues straight from the file, not through open_count,
        # so the test checks the whole path: file read, count, and output text.
        with open(TRACKER, encoding="utf-8") as f:
            issues = json.load(f)
        expected = sum(1 for i in issues if i["state"] == "open")
        self.assertEqual(weekly_report(TRACKER), f"Open issues: {expected}")


if __name__ == "__main__":
    unittest.main()
