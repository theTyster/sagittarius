import json
import os
import tempfile
import unittest

from report import open_count, weekly_report

HERE = os.path.dirname(os.path.abspath(__file__))

# A fixed snapshot of the tracker.json format. tracker.json itself is
# rewritten every hour by the server sync job, so its content can change.
FIXTURE = [
    {"id": 101, "title": "Login page times out", "state": "open"},
    {"id": 102, "title": "Export drops the last row", "state": "closed"},
    {"id": 103, "title": "Dark mode contrast", "state": "open"},
    {"id": 104, "title": "Typo on the settings page", "state": "closed"},
    {"id": 105, "title": "Search ignores accents", "state": "open"},
]


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_counts_open_issues(self):
        with tempfile.TemporaryDirectory() as d:
            path = os.path.join(d, "tracker.json")
            with open(path, "w", encoding="utf-8") as f:
                json.dump(FIXTURE, f)
            self.assertEqual(weekly_report(path), "Open issues: 3")

    def test_weekly_report_matches_live_tracker_json(self):
        # Content-independent: the number may change with each sync.
        path = os.path.join(HERE, "tracker.json")
        with open(path, encoding="utf-8") as f:
            expected = len([i for i in json.load(f) if i["state"] == "open"])
        self.assertEqual(weekly_report(path), f"Open issues: {expected}")


if __name__ == "__main__":
    unittest.main()
