import os
import unittest

from report import open_count, weekly_report


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    # Frozen copy of a tracker.json export: the live file is rewritten by the hourly sync.
    def test_weekly_report_tracker_json(self):
        path = os.path.join(os.path.dirname(__file__), "fixtures", "tracker_sample.json")
        self.assertEqual(weekly_report(path), "Open issues: 3")


if __name__ == "__main__":
    unittest.main()
