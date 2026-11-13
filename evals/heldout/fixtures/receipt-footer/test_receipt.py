import unittest

from receipt import footer


class ReceiptTest(unittest.TestCase):
    def test_footer(self):
        self.assertEqual(footer("Omar"), "Thank you for shoping, Omar.")


if __name__ == "__main__":
    unittest.main()
