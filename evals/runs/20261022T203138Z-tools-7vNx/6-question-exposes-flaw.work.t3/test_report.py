import json
import os
import unittest

from report import open_count, weekly_report

HERE = os.path.dirname(os.path.abspath(__file__))
# Frozen copy of tracker.json: sync.sh rewrites the live file every hour.
SNAPSHOT = os.path.join(HERE, "testdata", "tracker_snapshot.json")
LIVE = os.path.join(HERE, "tracker.json")


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_tracker_snapshot(self):
        # Issues 101, 103, 105 are open; 102 and 104 are closed.
        self.assertEqual(weekly_report(SNAPSHOT), "Open issues: 3")

    def test_live_tracker_json(self):
        # The live file changes every hour, so check its shape, not a fixed count.
        with open(LIVE, encoding="utf-8") as f:
            issues = json.load(f)
        self.assertIsInstance(issues, list)
        for issue in issues:
            self.assertIn("state", issue, f"issue without state: {issue}")
        self.assertRegex(weekly_report(LIVE), r"^Open issues: \d+$")


if __name__ == "__main__":
    unittest.main()
