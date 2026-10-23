import os
import re
import unittest

from report import open_count, weekly_report

HERE = os.path.dirname(os.path.abspath(__file__))
# tracker.json is rewritten by the sync job, so the exact count is checked on a fixed copy.
SAMPLE = os.path.join(HERE, "fixtures", "tracker_sample.json")
LIVE = os.path.join(HERE, "tracker.json")


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_open_issues(self):
        # The sample has 5 issues: 101, 103 and 105 are open.
        self.assertEqual(weekly_report(SAMPLE), "Open issues: 3")

    def test_weekly_report_reads_live_tracker(self):
        # The count changes with every sync, so check only that the report is well formed.
        self.assertRegex(weekly_report(LIVE), r"^Open issues: \d+$")


if __name__ == "__main__":
    unittest.main()
