import unittest

import os

from report import open_count, weekly_report


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_counts_open_issues(self):
        # A fixed copy of an export. The live tracker.json is rewritten by the sync job.
        path = os.path.join(os.path.dirname(__file__), "fixtures", "tracker_sample.json")
        self.assertEqual(weekly_report(path), "Open issues: 3")


if __name__ == "__main__":
    unittest.main()
