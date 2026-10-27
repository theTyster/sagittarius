import unittest
from datetime import date

from fees import shipping_fee, zone_for


class FeesTest(unittest.TestCase):
    def test_zone_one(self):
        self.assertEqual(zone_for("12001"), 1)

    def test_fee_is_positive(self):
        self.assertGreater(shipping_fee(2.0, "30110", date(2026, 10, 20)), 0)


if __name__ == "__main__":
    unittest.main()
