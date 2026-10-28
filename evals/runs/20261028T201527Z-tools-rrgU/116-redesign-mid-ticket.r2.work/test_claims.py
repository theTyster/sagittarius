import unittest
from datetime import date

from claims import Claims
from vault import Vault


class ClaimsTest(unittest.TestCase):
    def test_receipt_on_submit_day(self):
        c = Claims()
        c.submit("EX-1", date(2026, 3, 2), b"scan-1", date(2026, 3, 4))
        self.assertEqual(c.receipt("EX-1", date(2026, 3, 4)), b"scan-1")

    def test_window_is_day_60_from_submission(self):
        c = Claims()
        c.submit("EX-3", date(2026, 8, 28), b"scan-3", date(2026, 10, 21))
        self.assertEqual(c.receipt("EX-3", date(2026, 10, 28)), b"scan-3")
        self.assertEqual(c.receipt("EX-3", date(2026, 12, 20)), b"scan-3")  # day 60
        self.assertIsNone(c.receipt("EX-3", date(2026, 12, 21)))  # day 61

    def test_late_claim_refused(self):
        c = Claims()
        with self.assertRaises(ValueError):
            c.submit("EX-2", date(2026, 1, 5), b"scan-2", date(2026, 4, 20))

    def test_late_claim_stores_nothing_in_vault(self):
        v = Vault()
        c = Claims(v)
        with self.assertRaises(ValueError):
            c.submit("EX-2", date(2026, 1, 5), b"scan-2", date(2026, 4, 20))
        self.assertEqual(v._docs, {})

    def test_receipt_lives_in_vault_not_in_claim(self):
        v = Vault()
        c = Claims(v)
        c.submit("EX-1", date(2026, 3, 2), b"scan-1", date(2026, 3, 4))
        self.assertNotIn(b"scan-1", c._claims["EX-1"].values())
        self.assertEqual([d for d, _ in v._docs.values()], [b"scan-1"])
        self.assertEqual(c.receipt("EX-1", date(2026, 3, 4)), b"scan-1")


if __name__ == "__main__":
    unittest.main()
