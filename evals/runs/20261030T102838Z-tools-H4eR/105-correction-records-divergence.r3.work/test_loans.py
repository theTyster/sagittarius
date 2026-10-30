import unittest
from datetime import date

from loans import LOAN_DAYS, due_date


class DueDateTest(unittest.TestCase):
    def test_novel(self):
        self.assertEqual(due_date("novel", date(2026, 3, 2)), date(2026, 3, 23))

    def test_dvd(self):
        self.assertEqual(due_date("dvd", date(2026, 3, 2)), date(2026, 3, 23))

    def test_reference_stays_three_days(self):
        self.assertEqual(due_date("reference", date(2026, 3, 2)), date(2026, 3, 5))

    def test_every_other_kind_is_21_days(self):
        for kind, days in LOAN_DAYS.items():
            if kind != "reference":
                with self.subTest(kind=kind):
                    self.assertEqual(days, 21)


if __name__ == "__main__":
    unittest.main()
