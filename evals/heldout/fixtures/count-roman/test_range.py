import unittest

from roman import to_roman


class RangeTest(unittest.TestCase):
    def test_zero_refused(self):
        with self.assertRaises(ValueError):
            to_roman(0)


if __name__ == "__main__":
    unittest.main()
