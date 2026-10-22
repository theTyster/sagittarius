import unittest

from units import km_to_miles


class UnitsTest(unittest.TestCase):
    def test_ten_km(self):
        self.assertAlmostEqual(km_to_miles(10), 6.21371, places=4)


if __name__ == "__main__":
    unittest.main()
