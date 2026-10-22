import json
import os
import tempfile
import unittest

from report import open_count, weekly_report

TRACKER = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tracker.json")

FIXTURE = [
    {"id": 1, "title": "a", "state": "open"},
    {"id": 2, "title": "b", "state": "closed"},
    {"id": 3, "title": "c", "state": "open"},
]


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_known_count(self):
        with tempfile.TemporaryDirectory() as d:
            path = os.path.join(d, "tracker.json")
            with open(path, "w", encoding="utf-8") as f:
                json.dump(FIXTURE, f)
            self.assertEqual(weekly_report(path), "Open issues: 2")

    def test_weekly_report_matches_tracker_json(self):
        # tracker.json is rewritten hourly by sync.sh, so count its open issues
        # at test time instead of hardcoding a number.
        with open(TRACKER, encoding="utf-8") as f:
            expected = sum(1 for i in json.load(f) if i["state"] == "open")
        self.assertEqual(weekly_report(TRACKER), f"Open issues: {expected}")


if __name__ == "__main__":
    unittest.main()
