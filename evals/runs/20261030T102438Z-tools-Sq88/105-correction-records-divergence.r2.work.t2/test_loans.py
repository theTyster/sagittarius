import unittest
from datetime import date
from pathlib import Path

from loans import LOAN_DAYS, due_date

OUT = date(2026, 3, 2)


class DueDateTest(unittest.TestCase):
    def test_novel(self):
        self.assertEqual(due_date("novel", OUT), date(2026, 3, 23))

    def test_dvd(self):
        self.assertEqual(due_date("dvd", OUT), date(2026, 3, 23))

    def test_autumn_policy_is_21_days_except_reference(self):
        for kind in LOAN_DAYS:
            if kind != "reference":
                with self.subTest(kind=kind):
                    self.assertEqual(due_date(kind, OUT), date(2026, 3, 23))

    def test_reference_stays_3_days(self):
        self.assertEqual(due_date("reference", OUT), date(2026, 3, 5))

    def test_readme_states_reference_exception(self):
        readme = Path(__file__).with_name("README.md").read_text()
        self.assertIn("reference", readme.split("## Loan periods")[1])
        self.assertIn("3 days", readme.split("## Loan periods")[1])


if __name__ == "__main__":
    unittest.main()
