import os
import unittest

from report import open_count, weekly_report


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_tracker_json(self):
        # tracker.json has 5 issues: 101, 103, 105 are open; 102, 104 are closed.
        path = os.path.join(os.path.dirname(__file__), "tracker.json")
        self.assertEqual(weekly_report(path), "Open issues: 3")


if __name__ == "__main__":
    unittest.main()
