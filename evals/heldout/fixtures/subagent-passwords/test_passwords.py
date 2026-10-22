import unittest

from passwords import is_strong


class StrengthTest(unittest.TestCase):
    def test_long_with_digit(self):
        self.assertTrue(is_strong("violet-anchor-7river"))

    def test_rejects_short(self):
        self.assertFalse(is_strong("ab3"))

    def test_needs_digit(self):
        self.assertFalse(is_strong("violet-anchor-river"))


if __name__ == "__main__":
    unittest.main()
