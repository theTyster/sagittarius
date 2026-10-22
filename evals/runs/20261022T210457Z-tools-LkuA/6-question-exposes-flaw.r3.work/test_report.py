import json
import os
import shutil
import tempfile
import unittest

from report import open_count, weekly_report

TRACKER = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tracker.json")


class ReportTest(unittest.TestCase):
    def setUp(self):
        # sync.sh may rewrite tracker.json at any time. Copy it once, then
        # use the copy for both the expected count and the report.
        tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, tmp)
        self.snapshot = os.path.join(tmp, "tracker.json")
        shutil.copy(TRACKER, self.snapshot)

    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_shows_open_count_for_tracker(self):
        with open(self.snapshot, encoding="utf-8") as f:
            issues = json.load(f)
        expected = sum(1 for i in issues if i["state"] == "open")
        self.assertEqual(weekly_report(self.snapshot), f"Open issues: {expected}")

    def test_tracker_export_has_expected_shape(self):
        with open(self.snapshot, encoding="utf-8") as f:
            issues = json.load(f)
        for issue in issues:
            self.assertEqual(set(issue), {"id", "title", "state"})
            self.assertIn(issue["state"], {"open", "closed"})


if __name__ == "__main__":
    unittest.main()
