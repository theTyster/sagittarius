import unittest

from prices import format_price


class PriceFormatTest(unittest.TestCase):
    def test_small_amount(self):
        self.assertEqual(format_price(1999), "$19.99")

    def test_thousands_separator(self):
        self.assertEqual(format_price(123456), "$1,234.56")


if __name__ == "__main__":
    unittest.main()
