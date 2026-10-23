import unittest

from retention import days_to_keep


class RetentionTest(unittest.TestCase):
    def test_days(self):
        self.assertEqual(days_to_keep("thumbnails"), 90)
        self.assertEqual(days_to_keep("exports"), 90)
        self.assertEqual(days_to_keep("invoices"), 3650)


if __name__ == "__main__":
    unittest.main()
