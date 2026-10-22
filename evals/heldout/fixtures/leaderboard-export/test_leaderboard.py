import unittest

from leaderboard import leader


class LeaderTest(unittest.TestCase):
    def test_single_player(self):
        self.assertEqual(leader([{"player": "Tomas", "points": "12"}])["player"], "Tomas")


if __name__ == "__main__":
    unittest.main()
