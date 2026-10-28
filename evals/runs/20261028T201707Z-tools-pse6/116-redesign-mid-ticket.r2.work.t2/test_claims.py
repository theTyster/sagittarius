import unittest
from datetime import date

from claims import Claims
from vault import Vault


class ClaimsTest(unittest.TestCase):
    def test_receipt_on_submit_day(self):
        c = Claims()
        c.submit("EX-1", date(2026, 3, 2), b"scan-1", date(2026, 3, 4))
        self.assertEqual(c.receipt("EX-1", date(2026, 3, 4)), b"scan-1")

    def test_late_claim_refused(self):
        c = Claims()
        with self.assertRaises(ValueError):
            c.submit("EX-2", date(2026, 1, 5), b"scan-2", date(2026, 4, 20))

    def test_receipt_counts_from_submission_not_purchase(self):
        c = Claims()
        c.submit("EX-3", date(2026, 8, 20), b"scan-3", date(2026, 10, 21))
        self.assertEqual(c.receipt("EX-3", date(2026, 10, 28)), b"scan-3")
        self.assertEqual(c.receipt("EX-3", date(2026, 12, 20)), b"scan-3")
        self.assertIsNone(c.receipt("EX-3", date(2026, 12, 21)))

    def test_receipt_is_kept_in_vault_not_in_claim(self):
        v = Vault()
        c = Claims(v)
        c.submit("EX-4", date(2026, 3, 2), b"scan-4", date(2026, 3, 4))
        self.assertNotIn(b"scan-4", [x for x in c._claims["EX-4"].values()])
        ref = c._claims["EX-4"]["receipt_ref"]
        self.assertEqual(v.get(ref, date(2026, 3, 5)), b"scan-4")

    def test_vault_keeps_receipt_through_day_60_only(self):
        v = Vault()
        c = Claims(v)
        c.submit("EX-5", date(2026, 3, 2), b"scan-5", date(2026, 3, 4))
        self.assertEqual(c.receipt("EX-5", date(2026, 5, 3)), b"scan-5")
        self.assertIsNone(c.receipt("EX-5", date(2026, 5, 4)))

    def test_refused_claim_stores_nothing_in_vault(self):
        v = Vault()
        c = Claims(v)
        with self.assertRaises(ValueError):
            c.submit("EX-6", date(2026, 1, 5), b"scan-6", date(2026, 4, 20))
        self.assertIsNone(v.get("doc-1", date(2026, 4, 20)))


if __name__ == "__main__":
    unittest.main()
