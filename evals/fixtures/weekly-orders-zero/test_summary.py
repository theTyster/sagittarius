import unittest
from datetime import date
from summary import week_start, partition_key, weekly_summary


class WeekStart(unittest.TestCase):
    def test_monday_is_its_own_start(self):
        self.assertEqual(week_start(date(2026, 10, 5)), date(2026, 10, 5))

    def test_sunday_maps_to_monday(self):
        self.assertEqual(week_start(date(2026, 10, 11)), date(2026, 10, 5))


class Partition(unittest.TestCase):
    def test_key(self):
        self.assertEqual(partition_key(date(2026, 9, 3)), "2026-09")


class Weekly(unittest.TestCase):
    def test_first_full_week_of_october(self):
        self.assertEqual(weekly_summary(date(2026, 10, 7))["orders"], 2)

    def test_mid_october_week(self):
        self.assertEqual(weekly_summary(date(2026, 10, 14))["orders"], 1)

    def test_week_inside_november(self):
        self.assertEqual(weekly_summary(date(2026, 11, 4))["orders"], 2)

    def test_week_with_one_order(self):
        self.assertEqual(weekly_summary(date(2026, 10, 22))["orders"], 1)

    def test_bounds_reported(self):
        s = weekly_summary(date(2026, 10, 7))
        self.assertEqual((s["week_start"], s["week_end"]), ("2026-10-05", "2026-10-11"))


if __name__ == "__main__":
    unittest.main()
