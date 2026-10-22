import unittest

from report import open_count


class ReportTest(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(open_count([]), 0)


if __name__ == "__main__":
    unittest.main()
