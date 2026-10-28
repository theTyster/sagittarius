import unittest
from datetime import date

from vault import Vault


class VaultTest(unittest.TestCase):
    def test_put_and_get(self):
        v = Vault()
        doc = v.put(b"contract", date(2026, 5, 1))
        self.assertEqual(v.get(doc, date(2026, 5, 2)), b"contract")


if __name__ == "__main__":
    unittest.main()
