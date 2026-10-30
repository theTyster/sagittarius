import unittest
from datetime import date
from pathlib import Path

from loans import LOAN_DAYS, due_date


class DueDateTest(unittest.TestCase):
    def test_novel(self):
        self.assertEqual(due_date("novel", date(2026, 3, 2)), date(2026, 3, 23))

    def test_dvd(self):
        self.assertEqual(due_date("dvd", date(2026, 3, 2)), date(2026, 3, 23))

    def test_autumn_policy_every_kind_is_21_days(self):
        for kind in LOAN_DAYS:
            with self.subTest(kind=kind):
                self.assertEqual(due_date(kind, date(2026, 3, 2)), date(2026, 3, 23))

    def test_readme_states_the_policy(self):
        readme = Path(__file__).with_name("README.md").read_text()
        self.assertIn("every kind of item is 21 days", readme)


if __name__ == "__main__":
    unittest.main()
