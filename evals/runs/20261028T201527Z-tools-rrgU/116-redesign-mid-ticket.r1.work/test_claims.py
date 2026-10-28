import unittest
from datetime import date, timedelta

from claims import Claims
from vault import Vault


class ClaimsTest(unittest.TestCase):
    def test_receipt_on_submit_day(self):
        c = Claims(Vault())
        c.submit("EX-1", date(2026, 3, 2), b"scan-1", date(2026, 3, 4))
        self.assertEqual(c.receipt("EX-1", date(2026, 3, 4)), b"scan-1")

    def test_late_claim_refused(self):
        c = Claims(Vault())
        with self.assertRaises(ValueError):
            c.submit("EX-2", date(2026, 1, 5), b"scan-2", date(2026, 4, 20))

    def test_receipt_counted_from_submit_day(self):
        c = Claims(Vault())
        c.submit("EX-3", date(2026, 1, 5), b"scan-3", date(2026, 3, 30))
        self.assertEqual(c.receipt("EX-3", date(2026, 3, 30) + timedelta(days=60)), b"scan-3")
        self.assertIsNone(c.receipt("EX-3", date(2026, 3, 30) + timedelta(days=61)))

    def test_receipt_not_in_claims_store(self):
        c = Claims(Vault())
        c.submit("EX-4", date(2026, 3, 2), b"scan-4", date(2026, 3, 4))
        self.assertNotIn(b"scan-4", c._claims["EX-4"].values())

    def test_receipt_kept_in_vault_by_reference(self):
        v = Vault()
        c = Claims(v)
        c.submit("EX-5", date(2026, 3, 2), b"scan-5", date(2026, 3, 4))
        doc_id = c._claims["EX-5"]["receipt_doc"]
        self.assertEqual(v.get(doc_id, date(2026, 3, 5)), b"scan-5")
        self.assertEqual(c.receipt("EX-5", date(2026, 3, 5)), b"scan-5")


if __name__ == "__main__":
    unittest.main()
