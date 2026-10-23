import os
import unittest

from rainfall import monthly_totals, summary


class TotalsTest(unittest.TestCase):
    def test_one_day(self):
        self.assertEqual(monthly_totals([{"date": "2026-03-04", "mm": "2.5"}]), {"2026-03": 2.5})


class SummaryTest(unittest.TestCase):
    def test_wettest_month_for_rainfall_csv(self):
        path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "rainfall.csv")
        # March 21.5 mm, April 50.0 mm, May 20.0 mm
        self.assertEqual(summary(path), "Wettest month: 2026-04 (50.0 mm)")


if __name__ == "__main__":
    unittest.main()
