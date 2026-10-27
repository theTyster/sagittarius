import unittest

from account import Refused, withdraw  # noqa: E402


class BoundaryTest(unittest.TestCase):
    def test_ends_exactly_at_limit_is_allowed(self):
        self.assertEqual(withdraw(0, 100, 100), -100)

    def test_one_below_limit_is_refused(self):
        with self.assertRaises(Refused):
            withdraw(0, 101, 100)


if __name__ == "__main__":
    unittest.main()
