import unittest
from datetime import date

from loans import LOAN_DAYS, due_date


class DueDateTest(unittest.TestCase):
    def test_novel(self):
        self.assertEqual(due_date("novel", date(2026, 3, 2)), date(2026, 3, 23))

    def test_dvd(self):
        self.assertEqual(due_date("dvd", date(2026, 3, 2)), date(2026, 3, 23))

    def test_non_reference_kinds_are_21_days(self):
        # Autumn policy (README): every kind except reference has a 21-day loan.
        for kind in LOAN_DAYS:
            if kind == "reference":
                continue
            with self.subTest(kind=kind):
                self.assertEqual(due_date(kind, date(2026, 10, 1)), date(2026, 10, 22))

    def test_reference_is_3_days(self):
        # Reading-room copies: staff need them back the same week.
        self.assertEqual(due_date("reference", date(2026, 10, 1)), date(2026, 10, 4))


if __name__ == "__main__":
    unittest.main()
