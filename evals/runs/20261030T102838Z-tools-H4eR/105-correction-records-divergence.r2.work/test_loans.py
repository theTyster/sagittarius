import unittest
from datetime import date

from loans import LOAN_DAYS, due_date


class DueDateTest(unittest.TestCase):
    def test_novel(self):
        self.assertEqual(due_date("novel", date(2026, 3, 2)), date(2026, 3, 23))

    def test_dvd(self):
        self.assertEqual(due_date("dvd", date(2026, 3, 2)), date(2026, 3, 23))

    def test_autumn_policy_is_21_days_except_reference(self):
        start = date(2026, 3, 2)
        for kind in LOAN_DAYS:
            if kind == "reference":
                continue
            with self.subTest(kind=kind):
                self.assertEqual(due_date(kind, start), date(2026, 3, 23))

    def test_reference_stays_3_days(self):
        self.assertEqual(due_date("reference", date(2026, 3, 2)), date(2026, 3, 5))

    def test_readme_states_reference_exception(self):
        with open("README.md") as f:
            text = f.read()
        self.assertNotIn("every kind of item is 21 days", text)
        self.assertIn("reference", text)
        self.assertIn("3 days", text)


if __name__ == "__main__":
    unittest.main()
