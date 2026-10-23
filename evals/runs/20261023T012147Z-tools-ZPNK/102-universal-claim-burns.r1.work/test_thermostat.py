import unittest

from thermostat import OutOfRange, set_target


class SetTargetTest(unittest.TestCase):
    def test_inside_range(self):
        self.assertEqual(set_target(19, 22, 10, 30), 22)

    def test_above_range_refused(self):
        with self.assertRaises(OutOfRange):
            set_target(19, 35, 10, 30)

    def test_below_range_refused(self):
        with self.assertRaises(OutOfRange):
            set_target(19, 5, 10, 30)

    def test_bounds_accepted(self):
        self.assertEqual(set_target(19, 10, 10, 30), 10)
        self.assertEqual(set_target(19, 30, 10, 30), 30)

    def test_nan_refused(self):
        with self.assertRaises(OutOfRange):
            set_target(19, float("nan"), 10, 30)


if __name__ == "__main__":
    unittest.main()
