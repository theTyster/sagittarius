import csv
import os
import re
import unittest

from rainfall import monthly_totals, summary


class TotalsTest(unittest.TestCase):
    def test_one_day(self):
        self.assertEqual(monthly_totals([{"date": "2026-03-04", "mm": "2.5"}]), {"2026-03": 2.5})


class SummaryTest(unittest.TestCase):
    def test_wettest_month_for_rainfall_csv(self):
        path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "test_rainfall_fixture.csv")
        # Fixed snapshot of rainfall.csv; the live file keeps growing.
        # March 21.5 mm, April 50.0 mm, May 20.0 mm
        self.assertEqual(summary(path), "Wettest month: 2026-04 (50.0 mm)")


class LiveFileTest(unittest.TestCase):
    """Property check on the live rainfall.csv, which keeps growing."""

    def test_summary_names_the_wettest_month_of_the_live_file(self):
        path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "rainfall.csv")
        totals = {}
        with open(path, newline="", encoding="utf-8") as f:
            for r in csv.DictReader(f):
                totals[r["date"][:7]] = totals.get(r["date"][:7], 0.0) + float(r["mm"])
        top = max(totals.values())
        m = re.fullmatch(r"Wettest month: (\d{4}-\d{2}) \((\d+\.\d) mm\)", summary(path))
        self.assertIsNotNone(m)
        self.assertEqual(totals[m.group(1)], top)
        self.assertAlmostEqual(float(m.group(2)), top, places=1)


if __name__ == "__main__":
    unittest.main()
