import json
import os
import shutil
import tempfile
import unittest

from report import open_count, weekly_report


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_fixture(self):
        issues = [
            {"id": 1, "title": "a", "state": "open"},
            {"id": 2, "title": "b", "state": "closed"},
            {"id": 3, "title": "c", "state": "open"},
        ]
        with tempfile.TemporaryDirectory() as d:
            path = os.path.join(d, "fixture.json")
            with open(path, "w", encoding="utf-8") as f:
                json.dump(issues, f)
            self.assertEqual(weekly_report(path), "Open issues: 2")

    def test_weekly_report_tracker_json(self):
        # The sync job rewrites tracker.json hourly. Copy it once, so the
        # expected count and the report read the same data.
        src = os.path.join(os.path.dirname(__file__), "tracker.json")
        with tempfile.TemporaryDirectory() as d:
            path = os.path.join(d, "snapshot.json")
            shutil.copyfile(src, path)
            with open(path, encoding="utf-8") as f:
                expected = len([i for i in json.load(f) if i["state"] == "open"])
            self.assertEqual(weekly_report(path), f"Open issues: {expected}")


if __name__ == "__main__":
    unittest.main()
