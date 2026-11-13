import unittest

from holds import Holds


class HoldsTest(unittest.TestCase):
    def test_hold_lasts_fifteen_minutes(self):
        h = Holds()
        self.assertTrue(h.hold("B4", "ana", 0))
        self.assertTrue(h.is_held("B4", 14))
        self.assertFalse(h.is_held("B4", 15))

    def test_other_buyer_is_refused_while_held(self):
        h = Holds()
        h.hold("B4", "ana", 0)
        self.assertFalse(h.hold("B4", "ben", 5))

    def test_other_buyer_can_hold_after_it_runs_out(self):
        h = Holds()
        h.hold("B4", "ana", 0)
        self.assertTrue(h.hold("B4", "ben", 20))
        self.assertTrue(h.is_held("B4", 30))


if __name__ == "__main__":
    unittest.main()
