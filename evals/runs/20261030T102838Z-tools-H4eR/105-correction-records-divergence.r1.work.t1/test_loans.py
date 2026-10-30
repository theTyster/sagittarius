import unittest
from datetime import date

from loans import LOAN_DAYS, due_date


class DueDateTest(unittest.TestCase):
    def test_novel(self):
        self.assertEqual(due_date("novel", date(2026, 3, 2)), date(2026, 3, 23))

    def test_dvd(self):
        self.assertEqual(due_date("dvd", date(2026, 3, 2)), date(2026, 3, 23))

    def test_every_kind_is_21_days(self):
        # Autumn policy (README): every kind of item has a 21-day loan period.
        for kind in LOAN_DAYS:
            with self.subTest(kind=kind):
                self.assertEqual(due_date(kind, date(2026, 10, 1)), date(2026, 10, 22))


if __name__ == "__main__":
    unittest.main()
