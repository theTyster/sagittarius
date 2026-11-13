import unittest
from datetime import date

from board import shift_line
from export import csv_row
from notice import notice_text


class RotaTest(unittest.TestCase):
    def test_board(self):
        self.assertEqual(shift_line("Mo", date(2026, 11, 5)), "Mo works on 2026-11-05")

    def test_notice(self):
        self.assertEqual(notice_text("Mo", date(2026, 11, 5)), "Hello Mo, your shift is on 2026-11-05. Thank you!")

    def test_export(self):
        self.assertEqual(csv_row("Mo", date(2026, 11, 5)), "Mo,2026-11-05")


if __name__ == "__main__":
    unittest.main()
