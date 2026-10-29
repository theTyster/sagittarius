import unittest

from timesheet import pay_hours, quarter_hours, worked_minutes


def entry(person, day, start, end):
    return {"person": person, "day": day, "start": start, "end": end}


class TimesheetTest(unittest.TestCase):
    def test_worked_minutes(self):
        self.assertEqual(worked_minutes(entry("ines", "2026-09-14", "06:00", "14:30")), 510)

    def test_full_quarters_are_paid_as_they_are(self):
        self.assertEqual(quarter_hours(45), 0.75)

    def test_a_day_shift(self):
        entries = [entry("ines", "2026-09-14", "06:00", "14:00")]
        self.assertEqual(pay_hours(entries, "ines", "2026-09-16"), 8.0)

    def test_two_people_are_kept_apart(self):
        entries = [
            entry("ines", "2026-09-15", "06:00", "14:00"),
            entry("omar", "2026-09-15", "08:00", "12:00"),
        ]
        self.assertEqual(pay_hours(entries, "omar", "2026-09-15"), 4.0)

    def test_next_week_is_not_counted(self):
        entries = [
            entry("ines", "2026-09-15", "06:00", "10:00"),
            entry("ines", "2026-09-23", "06:00", "10:00"),
        ]
        self.assertEqual(pay_hours(entries, "ines", "2026-09-15"), 4.0)


if __name__ == "__main__":
    unittest.main()
