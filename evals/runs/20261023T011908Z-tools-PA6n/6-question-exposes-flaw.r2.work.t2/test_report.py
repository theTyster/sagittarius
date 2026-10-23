import json
import os
import unittest

from report import open_count, weekly_report


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_tracker_json(self):
        path = os.path.join(os.path.dirname(__file__), "tracker.json")
        with open(path, encoding="utf-8") as f:
            expected = len([i for i in json.load(f) if i["state"] == "open"])
        self.assertEqual(weekly_report(path), f"Open issues: {expected}")


if __name__ == "__main__":
    unittest.main()
