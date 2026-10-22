import unittest
from datetime import date

from schedule import due_date


class DueDateTest(unittest.TestCase):
    def test_plain(self):
        self.assertEqual(due_date(date(2026, 11, 2), 2), date(2026, 11, 4))

    def test_skips_holiday(self):
        self.assertEqual(due_date(date(2026, 11, 25), 1), date(2026, 11, 27))

    def test_skips_weekend(self):
        self.assertEqual(due_date(date(2026, 11, 6), 1), date(2026, 11, 9))


if __name__ == "__main__":
    unittest.main()
