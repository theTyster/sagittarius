import os
import unittest

from report import open_count, weekly_report

# Frozen copy of tracker.json: sync.sh rewrites the live file every hour.
SNAPSHOT = os.path.join(os.path.dirname(__file__), "testdata", "tracker_snapshot.json")


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_tracker_snapshot(self):
        # Issues 101, 103, 105 are open; 102 and 104 are closed.
        self.assertEqual(weekly_report(SNAPSHOT), "Open issues: 3")


if __name__ == "__main__":
    unittest.main()
