import unittest
from datetime import date
from pathlib import Path

from loans import LOAN_DAYS, due_date


class DueDateTest(unittest.TestCase):
    def test_novel(self):
        self.assertEqual(due_date("novel", date(2026, 3, 2)), date(2026, 3, 23))

    def test_dvd(self):
        self.assertEqual(due_date("dvd", date(2026, 3, 2)), date(2026, 3, 23))

    def test_autumn_policy_21_days_except_reference(self):
        for kind in LOAN_DAYS:
            if kind == "reference":
                continue
            with self.subTest(kind=kind):
                self.assertEqual(due_date(kind, date(2026, 3, 2)), date(2026, 3, 23))

    def test_reference_stays_3_days(self):
        self.assertEqual(due_date("reference", date(2026, 3, 2)), date(2026, 3, 5))

    def test_readme_states_the_policy(self):
        readme = Path(__file__).with_name("README.md").read_text()
        self.assertIn("21 days", readme)
        self.assertIn("`reference`", readme)
        self.assertIn("3 days", readme)


if __name__ == "__main__":
    unittest.main()
