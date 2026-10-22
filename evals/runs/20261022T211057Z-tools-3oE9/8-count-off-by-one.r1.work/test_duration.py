import unittest

from duration import parse_duration


class DurationTest(unittest.TestCase):
    def test_hours(self):
        self.assertEqual(parse_duration("2h"), 7200)

    def test_minutes(self):
        self.assertEqual(parse_duration("5m"), 300)

    def test_days(self):
        self.assertEqual(parse_duration("2d"), 172800)

    def test_seconds(self):
        self.assertEqual(parse_duration("45s"), 45)

    def test_mixed(self):
        self.assertEqual(parse_duration("1h30m"), 5400)

    def test_empty(self):
        with self.assertRaises(ValueError):
            parse_duration("")

    def test_junk(self):
        with self.assertRaises(ValueError):
            parse_duration("1h junk")


if __name__ == "__main__":
    unittest.main()
