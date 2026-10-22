import json
import os
import tempfile
import unittest

from report import open_count, weekly_report

# Snapshot of tracker.json. The real file is rewritten every hour by sync.sh,
# so the test must not depend on its live contents.
SNAPSHOT = [
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
                json.dump(SNAPSHOT, f)
            self.assertEqual(weekly_report(path), "Open issues: 3")

    def test_live_tracker_has_expected_shape(self):
        # Reads the real tracker.json, which sync.sh rewrites every hour.
        # Checks the format, not the count, so it stays valid after a sync.
        with open("tracker.json", encoding="utf-8") as f:
            issues = json.load(f)
        for issue in issues:
            self.assertIn("id", issue)
            self.assertIn("title", issue)
            self.assertIn(issue["state"], ("open", "closed"))

    def test_weekly_report_runs_on_live_tracker(self):
        with open("tracker.json", encoding="utf-8") as f:
            issues = json.load(f)
        self.assertRegex(weekly_report(), r"^Open issues: \d+$")
        self.assertLessEqual(open_count(issues), len(issues))


if __name__ == "__main__":
    unittest.main()
