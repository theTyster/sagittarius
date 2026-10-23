import os
import unittest

from rainfall import monthly_totals, summary


class TotalsTest(unittest.TestCase):
    def test_one_day(self):
        self.assertEqual(monthly_totals([{"date": "2026-03-04", "mm": "2.5"}]), {"2026-03": 2.5})


class SummaryTest(unittest.TestCase):
    def test_wettest_month_of_rainfall_csv(self):
        path = os.path.join(os.path.dirname(__file__), "rainfall.csv")
        # Totals: March 21.5, April 50.0, May 20.0
        self.assertEqual(summary(path), "Wettest month: 2026-04 (50.0 mm)")


if __name__ == "__main__":
    unittest.main()
