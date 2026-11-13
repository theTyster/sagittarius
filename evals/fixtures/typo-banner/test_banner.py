import unittest

from banner import banner


class BannerTest(unittest.TestCase):
    def test_banner(self):
        self.assertEqual(banner("Ana"), "Welcom back, Ana!")


if __name__ == "__main__":
    unittest.main()
