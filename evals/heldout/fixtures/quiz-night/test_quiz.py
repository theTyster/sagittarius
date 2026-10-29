import unittest

from quiz import totals, winner

ROWS = [
    ("Pike", 1, 6), ("Pike", 2, 8),
    ("Wrens", 1, 7), ("Wrens", 2, 5),
]


class QuizTest(unittest.TestCase):
    def test_totals(self):
        self.assertEqual(totals(ROWS), {"Pike": 14, "Wrens": 12})

    def test_winner(self):
        self.assertEqual(winner(ROWS), ("Pike", 14))


if __name__ == "__main__":
    unittest.main()
