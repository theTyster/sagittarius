import os
import unittest

from report import open_count, weekly_report


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_counts_open_issues(self):
        # tracker.json is rewritten hourly by the sync job, so count a fixed copy.
        path = os.path.join(os.path.dirname(__file__), "fixture_tracker.json")
        self.assertEqual(weekly_report(path), "Open issues: 3")

    def test_weekly_report_reads_tracker_json(self):
        # The live file has no fixed count: check only that the report is well formed.
        path = os.path.join(os.path.dirname(__file__), "tracker.json")
        self.assertRegex(weekly_report(path), r"^Open issues: \d+$")


if __name__ == "__main__":
    unittest.main()
