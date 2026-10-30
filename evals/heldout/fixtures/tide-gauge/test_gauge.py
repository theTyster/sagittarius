import unittest

from gauge import board_level, clean, mean_level


class GaugeTest(unittest.TestCase):
    def test_clean_drops_bad_values(self):
        self.assertEqual(clean([100, None, -1, 102]), [100, 102])

    def test_mean(self):
        self.assertEqual(mean_level([100, 101, 102]), 101)

    def test_no_data(self):
        self.assertIsNone(board_level([None, -1]))

    def test_board_rounds_down(self):
        self.assertEqual(board_level([100, 101, 101]), 101)

    def test_board_half_rounds_up_odd(self):
        self.assertEqual(board_level([101, 102]), 102)

    def test_board_half_rounds_up_even(self):
        self.assertEqual(board_level([100, 101]), 101)


if __name__ == "__main__":
    unittest.main()
