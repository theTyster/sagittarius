import unittest

from thermostat import OutOfRange, set_target


class SetTargetTest(unittest.TestCase):
    def test_inside_range(self):
        self.assertEqual(set_target(19, 22, 10, 30), 22)

    def test_above_range_refused(self):
        with self.assertRaises(OutOfRange):
            set_target(19, 35, 10, 30)


if __name__ == "__main__":
    unittest.main()
