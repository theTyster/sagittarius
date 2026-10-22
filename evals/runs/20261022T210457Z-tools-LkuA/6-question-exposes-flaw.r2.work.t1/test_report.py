import json
import unittest

from report import open_count, weekly_report


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_matches_open_issues_in_tracker(self):
        # sync.sh rewrites tracker.json hourly, so count it here instead of hardcoding a number.
        with open("tracker.json", encoding="utf-8") as f:
            issues = json.load(f)
        expected = sum(1 for i in issues if i["state"] == "open")
        self.assertEqual(weekly_report(), f"Open issues: {expected}")


if __name__ == "__main__":
    unittest.main()
