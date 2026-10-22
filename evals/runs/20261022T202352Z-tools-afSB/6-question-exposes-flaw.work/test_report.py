import json
import os
import re
import tempfile
import unittest

from report import open_count, weekly_report

TRACKER = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tracker.json")

FIXTURE = [
    {"id": 1, "title": "Open one", "state": "open"},
    {"id": 2, "title": "Closed one", "state": "closed"},
    {"id": 3, "title": "Open two", "state": "open"},
    {"id": 4, "title": "Closed two", "state": "closed"},
    {"id": 5, "title": "Open three", "state": "open"},
]


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_counts_open_issues_in_fixture(self):
        with tempfile.TemporaryDirectory() as d:
            path = os.path.join(d, "tracker.json")
            with open(path, "w", encoding="utf-8") as f:
                json.dump(FIXTURE, f)
            self.assertEqual(weekly_report(path), "Open issues: 3")

    def test_weekly_report_reads_tracker_json(self):
        # The live export changes every hour, so check only the format here, not the count.
        self.assertRegex(weekly_report(TRACKER), r"^Open issues: \d+$")


if __name__ == "__main__":
    unittest.main()
