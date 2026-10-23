import os
import unittest

from report import open_count, weekly_report

TRACKER = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tracker.json")


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_open_issues(self):
        # tracker.json has 5 issues: 101, 103 and 105 are open.
        self.assertEqual(weekly_report(TRACKER), "Open issues: 3")


if __name__ == "__main__":
    unittest.main()
