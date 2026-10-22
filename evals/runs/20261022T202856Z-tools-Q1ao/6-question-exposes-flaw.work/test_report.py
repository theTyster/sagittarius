import os
import unittest

from report import open_count, weekly_report

FIXTURE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tracker_fixture.json")


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_shows_open_issue_count_for_tracker(self):
        # tracker_fixture.json is a fixed copy of the export, so the count does not
        # change when sync.sh rewrites tracker.json.
        self.assertEqual(weekly_report(FIXTURE), "Open issues: 3")


if __name__ == "__main__":
    unittest.main()
