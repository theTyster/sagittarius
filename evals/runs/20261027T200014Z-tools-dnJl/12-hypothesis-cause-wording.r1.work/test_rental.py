import unittest

from rental import rental_total


class RentalTest(unittest.TestCase):
    def test_plain_rental(self):
        self.assertEqual(rental_total("Drill", 1, []), 12.00)

    def test_flat_coupon(self):
        self.assertEqual(rental_total("Sander", 2, ["FLAT8"]), 10.00)

    def test_total_is_not_negative(self):
        self.assertGreaterEqual(rental_total("Ladder", 1, ["FLAT8"]), 0)


if __name__ == "__main__":
    unittest.main()
