import os
import unittest

from report import open_count, weekly_report

# A frozen copy of tracker.json: sync.sh rewrites the real file every hour.
FIXTURE = os.path.join(os.path.dirname(__file__), "testdata", "tracker.json")


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_open_issues(self):
        self.assertEqual(weekly_report(FIXTURE), "Open issues: 3")


if __name__ == "__main__":
    unittest.main()
