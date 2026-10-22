import json
import os
import unittest

from report import open_count, weekly_report

PROJECT_DIR = os.path.dirname(os.path.abspath(__file__))


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_counts_open_issues_in_tracker(self):
        # weekly_report() reads tracker.json relative to the current directory.
        cwd = os.getcwd()
        os.chdir(PROJECT_DIR)
        try:
            report = weekly_report()
        finally:
            os.chdir(cwd)

        # Count from the file itself, not a constant: sync.sh replaces tracker.json hourly.
        with open(os.path.join(PROJECT_DIR, "tracker.json"), encoding="utf-8") as f:
            expected = sum(1 for i in json.load(f) if i["state"] == "open")

        self.assertEqual(report, f"Open issues: {expected}")


if __name__ == "__main__":
    unittest.main()
