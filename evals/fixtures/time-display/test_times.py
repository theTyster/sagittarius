import unittest

from export import csv_row
from reminder import reminder_text
from screen import class_line


class TimesTest(unittest.TestCase):
    def test_screen(self):
        self.assertEqual(class_line("Wheel basics", 15, 5), "Wheel basics at 3:05 PM")

    def test_reminder(self):
        self.assertEqual(reminder_text("Wheel basics", 15, 5), "Reminder: Wheel basics starts at 3:05 PM.")

    def test_export(self):
        self.assertEqual(csv_row("Wheel basics", 15, 5), "Wheel basics,3:05 PM")


if __name__ == "__main__":
    unittest.main()
