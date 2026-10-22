import unittest

from rainfall import monthly_totals


class TotalsTest(unittest.TestCase):
    def test_one_day(self):
        self.assertEqual(monthly_totals([{"date": "2026-03-04", "mm": "2.5"}]), {"2026-03": 2.5})


if __name__ == "__main__":
    unittest.main()
