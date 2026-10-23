import os
import unittest

from report import open_count, weekly_report


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    # tracker.json is rewritten by the hourly sync job, so test a fixed snapshot of it.
    def test_weekly_report_fixture(self):
        path = os.path.join(os.path.dirname(__file__), "tracker_fixture.json")
        self.assertEqual(weekly_report(path), "Open issues: 3")


if __name__ == "__main__":
    unittest.main()
