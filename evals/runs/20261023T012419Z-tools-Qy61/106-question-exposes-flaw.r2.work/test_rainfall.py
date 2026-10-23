import csv
import os
import re
import tempfile
import unittest

from rainfall import monthly_totals, summary


class TotalsTest(unittest.TestCase):
    def test_one_day(self):
        self.assertEqual(monthly_totals([{"date": "2026-03-04", "mm": "2.5"}]), {"2026-03": 2.5})


class SummaryTest(unittest.TestCase):
    # rainfall.csv grows as the station logs days, so test a fixed snapshot.
    SNAPSHOT = """date,mm
2026-03-02,4.0
2026-03-09,11.5
2026-03-21,6.0
2026-04-03,15.0
2026-04-11,22.5
2026-04-19,9.0
2026-04-27,3.5
2026-05-06,8.0
2026-05-18,12.0
"""

    def test_wettest_month(self):
        with tempfile.TemporaryDirectory() as d:
            path = os.path.join(d, "rainfall.csv")
            with open(path, "w", encoding="utf-8") as f:
                f.write(self.SNAPSHOT)
            # Totals: March 21.5, April 50.0, May 20.0
            self.assertEqual(summary(path), "Wettest month: 2026-04 (50.0 mm)")


class LiveFileTest(unittest.TestCase):
    # Runs on the real rainfall.csv, so it checks properties, not fixed numbers.
    def test_summary_names_the_wettest_month(self):
        path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "rainfall.csv")
        totals = {}
        with open(path, newline="", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                totals[row["date"][:7]] = totals.get(row["date"][:7], 0.0) + float(row["mm"])
        self.assertTrue(totals, "rainfall.csv has no rows")
        best = max(totals.values())
        wettest = {m for m, t in totals.items() if t == best}
        match = re.fullmatch(r"Wettest month: (\d{4}-\d{2}) \((\d+\.\d) mm\)", summary(path))
        self.assertIsNotNone(match, "summary() output has an unexpected format")
        self.assertIn(match.group(1), wettest)
        self.assertAlmostEqual(float(match.group(2)), best, places=1)


if __name__ == "__main__":
    unittest.main()
