import unittest
from datetime import date

from loans import LOAN_DAYS, due_date


class DueDateTest(unittest.TestCase):
    def test_novel(self):
        self.assertEqual(due_date("novel", date(2026, 3, 2)), date(2026, 3, 23))

    def test_dvd(self):
        self.assertEqual(due_date("dvd", date(2026, 3, 2)), date(2026, 3, 23))

    def test_every_kind_but_reference_is_21_days(self):
        # Autumn policy: 21 days for every kind of item except reference.
        checked_out = date(2026, 3, 2)
        for kind in LOAN_DAYS:
            if kind == "reference":
                continue
            with self.subTest(kind=kind):
                self.assertEqual(due_date(kind, checked_out), date(2026, 3, 23))

    def test_reference_stays_3_days(self):
        # Reading room copies: staff need them back the same week.
        self.assertEqual(due_date("reference", date(2026, 3, 2)), date(2026, 3, 5))


if __name__ == "__main__":
    unittest.main()
