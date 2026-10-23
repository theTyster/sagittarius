import os
import unittest

from report import open_count, weekly_report


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_fixture(self):
        # The sync job rewrites tracker.json every hour, so the test uses a fixed copy.
        # The fixture has 6 issues: 4 open, 2 closed.
        path = os.path.join(os.path.dirname(__file__), "tests", "fixtures", "tracker.json")
        self.assertEqual(weekly_report(path), "Open issues: 4")


if __name__ == "__main__":
    unittest.main()
