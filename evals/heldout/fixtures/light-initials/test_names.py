import unittest

from names import initials


class InitialsTest(unittest.TestCase):
    def test_two_names(self):
        self.assertEqual(initials("Mira Okafor"), "MO")


if __name__ == "__main__":
    unittest.main()
