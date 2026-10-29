import unittest
from datetime import date

from greenhouse import due, next_watering


class WateringTest(unittest.TestCase):
    def test_tomato_every_two_days(self):
        self.assertEqual(next_watering("tomato", date(2026, 6, 1)), date(2026, 6, 3))

    def test_missed_tray_stays_due(self):
        log = {"lettuce": date(2026, 6, 1)}
        self.assertEqual(due(log, date(2026, 6, 9)), ["lettuce"])


if __name__ == "__main__":
    unittest.main()
