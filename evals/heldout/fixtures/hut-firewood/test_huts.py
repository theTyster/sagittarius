import unittest
from huts import bundles_needed, stage_plan


class HutTests(unittest.TestCase):
    def test_even(self):
        self.assertEqual(bundles_needed(4, 2), 4)

    def test_large(self):
        self.assertEqual(bundles_needed(10, 3), 15)

    def test_plan(self):
        self.assertEqual(stage_plan([("Ridge", 4, 2), ("Ridge", 2, 2), ("Lake", 6, 2)]), {"Ridge": 6, "Lake": 6})


if __name__ == "__main__":
    unittest.main()
