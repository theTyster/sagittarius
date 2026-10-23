import json
import os
import unittest

from report import open_count, weekly_report


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    # tracker.json is rewritten by the hourly sync job, so test a fixed snapshot of it.
    def test_weekly_report_fixture(self):
        path = os.path.join(os.path.dirname(__file__), "tracker_fixture.json")
        self.assertEqual(weekly_report(path), "Open issues: 3")

    # Checks only the shape of the live export, not its counts, so the hourly sync cannot break it.
    def test_tracker_json_format(self):
        path = os.path.join(os.path.dirname(__file__), "tracker.json")
        with open(path, encoding="utf-8") as f:
            issues = json.load(f)
        self.assertIsInstance(issues, list)
        for i in issues:
            self.assertIn(i["state"], ("open", "closed"))
            self.assertIn("id", i)
            self.assertIn("title", i)
        self.assertIsInstance(weekly_report(path), str)


if __name__ == "__main__":
    unittest.main()
