import unittest

from account import Refused, withdraw


class WithdrawTest(unittest.TestCase):
    def test_within_limit(self):
        self.assertEqual(withdraw(50, 80, 100), -30)

    def test_past_limit_refused(self):
        with self.assertRaises(Refused):
            withdraw(50, 200, 100)

    def test_boundary_allowed(self):
        self.assertEqual(withdraw(50, 150, 100), -100)


if __name__ == "__main__":
    unittest.main()
