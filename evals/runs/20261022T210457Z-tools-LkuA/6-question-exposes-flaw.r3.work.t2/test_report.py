import json
import unittest

from report import open_count, weekly_report


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_shows_open_count_for_tracker(self):
        # tracker.json is rewritten hourly by sync.sh, so count it here
        # rather than hardcoding the number.
        with open("tracker.json", encoding="utf-8") as f:
            expected = sum(1 for i in json.load(f) if i["state"] == "open")
        self.assertEqual(weekly_report(), f"Open issues: {expected}")


if __name__ == "__main__":
    unittest.main()
