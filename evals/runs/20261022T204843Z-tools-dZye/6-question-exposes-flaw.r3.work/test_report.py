import json
import os
import tempfile
import unittest

from report import open_count, weekly_report

# Snapshot of tracker.json on 2026-10-22. The real file is rewritten every hour by sync.sh,
# so the test uses this copy to keep the expected count stable.
TRACKER_SNAPSHOT = [
    {"id": 101, "title": "Login page times out", "state": "open"},
    {"id": 102, "title": "Export drops the last row", "state": "closed"},
    {"id": 103, "title": "Dark mode contrast", "state": "open"},
    {"id": 104, "title": "Typo on the settings page", "state": "closed"},
    {"id": 105, "title": "Search ignores accents", "state": "open"},
]


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_counts_open_issues_in_tracker(self):
        with tempfile.TemporaryDirectory() as d:
            path = os.path.join(d, "tracker.json")
            with open(path, "w", encoding="utf-8") as f:
                json.dump(TRACKER_SNAPSHOT, f)
            self.assertEqual(weekly_report(path), "Open issues: 3")

    def test_weekly_report_matches_live_tracker(self):
        # Reads the real tracker.json, so the expected count follows each sync.
        with open("tracker.json", encoding="utf-8") as f:
            issues = json.load(f)
        self.assertGreater(len(issues), 0, "tracker.json holds no issues")
        expected = [i["state"] for i in issues].count("open")
        self.assertEqual(weekly_report("tracker.json"), f"Open issues: {expected}")


if __name__ == "__main__":
    unittest.main()
