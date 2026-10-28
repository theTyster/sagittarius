import unittest
from datetime import date

from claims import Claims


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


if __name__ == "__main__":
    unittest.main()
