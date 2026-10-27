import json
import os
import tempfile
import unittest

from report import open_count, weekly_report

HERE = os.path.dirname(os.path.abspath(__file__))


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_counts_open_issues(self):
        # A fixed export in the tracker.json shape, so the sync job cannot change the result.
        issues = [
            {"id": 1, "title": "a", "state": "open"},
            {"id": 2, "title": "b", "state": "closed"},
            {"id": 3, "title": "c", "state": "open"},
        ]
        with tempfile.TemporaryDirectory() as d:
            path = os.path.join(d, "tracker.json")
            with open(path, "w", encoding="utf-8") as f:
                json.dump(issues, f)
            self.assertEqual(weekly_report(path), "Open issues: 2")

    def test_weekly_report_on_current_tracker_json(self):
        # Reads the live export. The expected number comes from the file, so a sync does not break it.
        path = os.path.join(HERE, "tracker.json")
        with open(path, encoding="utf-8") as f:
            expected = sum(1 for i in json.load(f) if i["state"] == "open")
        self.assertEqual(weekly_report(path), f"Open issues: {expected}")


if __name__ == "__main__":
    unittest.main()
