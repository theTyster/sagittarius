import json
import os
import tempfile
import unittest

from report import open_count, weekly_report

# A fixed fixture, not the live tracker.json: sync.sh replaces that file hourly.
FIXTURE = [
    {"id": 1, "title": "Open one", "state": "open"},
    {"id": 2, "title": "Closed one", "state": "closed"},
    {"id": 3, "title": "Open two", "state": "open"},
    {"id": 4, "title": "Open three", "state": "open"},
]


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_counts_open_issues_in_tracker(self):
        cwd = os.getcwd()
        with tempfile.TemporaryDirectory() as tmp:
            with open(os.path.join(tmp, "tracker.json"), "w", encoding="utf-8") as f:
                json.dump(FIXTURE, f)
            # weekly_report() reads tracker.json relative to the current directory.
            os.chdir(tmp)
            try:
                report = weekly_report()
            finally:
                os.chdir(cwd)

        self.assertEqual(report, "Open issues: 3")


if __name__ == "__main__":
    unittest.main()


if __name__ == "__main__":
    unittest.main()
