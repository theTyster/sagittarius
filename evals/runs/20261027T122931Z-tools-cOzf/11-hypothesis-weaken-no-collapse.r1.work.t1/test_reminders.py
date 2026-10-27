import unittest

from reminders import load, reminder_date


class RemindersTest(unittest.TestCase):
    def test_two_weeks_before(self):
        c = load()["C-340"]
        self.assertEqual(str(reminder_date(c)), "2026-01-06")


if __name__ == "__main__":
    unittest.main()
