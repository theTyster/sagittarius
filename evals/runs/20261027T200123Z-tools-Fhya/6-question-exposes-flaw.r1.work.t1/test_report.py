import unittest

import os

from report import open_count, weekly_report


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_counts_open_issues_in_tracker(self):
        path = os.path.join(os.path.dirname(__file__), "tracker.json")
        self.assertEqual(weekly_report(path), "Open issues: 3")


if __name__ == "__main__":
    unittest.main()
