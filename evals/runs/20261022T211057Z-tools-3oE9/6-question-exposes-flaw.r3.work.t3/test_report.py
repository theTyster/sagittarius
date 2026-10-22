import os
import unittest

from report import open_count, weekly_report

# A fixed copy of the tracker export. The live tracker.json is rewritten hourly by sync.sh,
# so the test must not read it.
FIXTURE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "fixtures", "tracker.json")


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_shows_open_count_for_tracker(self):
        # The fixture has 3 open issues (IDs 101, 103, 105).
        self.assertEqual(weekly_report(FIXTURE), "Open issues: 3")


if __name__ == "__main__":
    unittest.main()
