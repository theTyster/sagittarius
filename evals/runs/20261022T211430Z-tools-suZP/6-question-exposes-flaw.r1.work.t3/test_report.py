import json
import os
import shutil
import tempfile
import unittest

from report import open_count, weekly_report

TRACKER = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tracker.json")


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)

    def test_weekly_report_counts_open_issues_in_tracker(self):
        # sync.sh replaces tracker.json hourly, so count its open issues here
        # instead of pinning a number that the next export would break.
        # Copy the file once so the expected count and weekly_report() read
        # the same snapshot, even if sync.sh replaces tracker.json mid-test.
        with tempfile.TemporaryDirectory() as tmp:
            snapshot = os.path.join(tmp, "tracker.json")
            shutil.copyfile(TRACKER, snapshot)
            with open(snapshot, encoding="utf-8") as f:
                expected = sum(1 for i in json.load(f) if i["state"] == "open")
            self.assertEqual(weekly_report(snapshot), f"Open issues: {expected}")

    def test_tracker_states_are_open_or_closed(self):
        # open_count() only matches "open", so a renamed state such as "Open"
        # would silently drop out of the count. Fail loudly instead.
        with tempfile.TemporaryDirectory() as tmp:
            snapshot = os.path.join(tmp, "tracker.json")
            shutil.copyfile(TRACKER, snapshot)
            with open(snapshot, encoding="utf-8") as f:
                states = {i["state"] for i in json.load(f)}
            self.assertLessEqual(states, {"open", "closed"})


if __name__ == "__main__":
    unittest.main()
