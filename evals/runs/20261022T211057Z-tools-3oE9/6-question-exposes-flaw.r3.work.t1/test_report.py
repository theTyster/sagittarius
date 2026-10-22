import json
import os
import unittest

from report import open_count, weekly_report

TRACKER = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tracker.json")


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_shows_open_count_for_tracker(self):
        # Count the open issues directly from the file, not via open_count,
        # so the expected value does not depend on the code under test.
        with open(TRACKER, encoding="utf-8") as f:
            expected = sum(1 for i in json.load(f) if i["state"] == "open")
        self.assertEqual(weekly_report(TRACKER), f"Open issues: {expected}")


if __name__ == "__main__":
    unittest.main()
