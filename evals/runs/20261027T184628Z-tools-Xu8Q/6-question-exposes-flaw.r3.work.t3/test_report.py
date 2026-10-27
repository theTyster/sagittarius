import json
import os
import unittest

from report import open_count, weekly_report


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_counts_open_issues(self):
        path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "fixtures", "tracker_sample.json")
        self.assertEqual(weekly_report(path), "Open issues: 3")

    def test_live_tracker_json_matches_report(self):
        # The sync job rewrites this file, so the count is not hard-coded.
        path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tracker.json")
        with open(path, encoding="utf-8") as f:
            issues = json.load(f)
        for i in issues:
            self.assertIn(i["state"], ("open", "closed"))
        expected = sum(1 for i in issues if i["state"] == "open")
        self.assertEqual(weekly_report(path), f"Open issues: {expected}")


if __name__ == "__main__":
    unittest.main()
