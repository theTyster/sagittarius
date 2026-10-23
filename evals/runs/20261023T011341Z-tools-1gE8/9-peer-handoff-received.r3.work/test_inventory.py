import unittest

from inventory import Inventory


class InventoryTest(unittest.TestCase):
    def test_reserve(self):
        inv = Inventory({"apple": 5})
        self.assertEqual(inv.reserve("apple", 2), 2)

    def test_reserve_over_stock(self):
        inv = Inventory({"apple": 5})
        inv.reserve("apple", 4)
        with self.assertRaises(ValueError):
            inv.reserve("apple", 2)

    def test_reserve_exact_stock(self):
        inv = Inventory({"apple": 5})
        self.assertEqual(inv.reserve("apple", 5), 5)

    def test_refused_reserve_keeps_state(self):
        inv = Inventory({"apple": 5})
        inv.reserve("apple", 4)
        with self.assertRaises(ValueError):
            inv.reserve("apple", 2)
        self.assertEqual(inv.reserved["apple"], 4)


if __name__ == "__main__":
    unittest.main()
