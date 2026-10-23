import os
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


if __name__ == "__main__":
    unittest.main()
