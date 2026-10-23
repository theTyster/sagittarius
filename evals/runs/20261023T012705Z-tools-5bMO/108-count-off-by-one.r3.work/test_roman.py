import unittest

from roman import to_roman


class RomanTest(unittest.TestCase):
    def test_one(self):
        self.assertEqual(to_roman(1), "I")

    def test_four(self):
        self.assertEqual(to_roman(4), "IV")

    def test_nineteen(self):
        self.assertEqual(to_roman(19), "XIX")

    def test_thirty_eight(self):
        self.assertEqual(to_roman(38), "XXXVIII")

    def test_fifty(self):
        self.assertEqual(to_roman(50), "L")


if __name__ == "__main__":
    unittest.main()
