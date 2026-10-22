import unittest

from duration import parse_duration


class FormatTest(unittest.TestCase):
    def test_no_spaces(self):
        with self.assertRaises(ValueError):
            parse_duration("1h 30m")


if __name__ == "__main__":
    unittest.main()
