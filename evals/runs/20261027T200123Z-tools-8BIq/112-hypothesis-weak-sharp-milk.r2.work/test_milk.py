import unittest

from milk import month_of, monthly_statement, pickup_payment, pickups


class MilkTest(unittest.TestCase):
    def test_litre_pickup(self):
        row = {"amount": "100", "unit": "L"}
        self.assertEqual(pickup_payment(row), 42.00)

    def test_month_of_midday(self):
        self.assertEqual(month_of("2026-09-17T14:50Z"), "2026-09")

    def test_statement_mid_month(self):
        self.assertEqual(monthly_statement("F-03", "2026-09"), 266.70)

    def test_all_pickups_read(self):
        self.assertEqual(len(pickups()), 9)


if __name__ == "__main__":
    unittest.main()
