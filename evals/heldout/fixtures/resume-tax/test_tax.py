import unittest

from tax import sales_tax


class SalesTaxTest(unittest.TestCase):
    def test_two_hundred(self):
        self.assertAlmostEqual(sales_tax(200), 14.50, places=2)


if __name__ == "__main__":
    unittest.main()
