import unittest
from datetime import date

from loans import LOAN_DAYS, due_date


class DueDateTest(unittest.TestCase):
    def test_novel(self):
        self.assertEqual(due_date("novel", date(2026, 3, 2)), date(2026, 3, 23))

    def test_dvd(self):
        self.assertEqual(due_date("dvd", date(2026, 3, 2)), date(2026, 3, 23))

    def test_autumn_policy_is_21_days_for_every_kind(self):
        start = date(2026, 3, 2)
        for kind in LOAN_DAYS:
            with self.subTest(kind=kind):
                self.assertEqual(due_date(kind, start), date(2026, 3, 23))

    def test_readme_states_21_days(self):
        with open("README.md") as f:
            self.assertIn("is 21 days", f.read())


if __name__ == "__main__":
    unittest.main()
