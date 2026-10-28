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

    def test_receipt_counts_from_submit_date(self):
        # Purchased ~2 months before submitting; approver opens it the next day.
        c = Claims()
        c.submit("EX-3", date(2026, 8, 20), b"scan-3", date(2026, 10, 21))
        self.assertEqual(c.receipt("EX-3", date(2026, 10, 28)), b"scan-3")

    def test_receipt_window_is_60_days_after_submit(self):
        c = Claims()
        c.submit("EX-4", date(2026, 8, 20), b"scan-4", date(2026, 10, 21))
        self.assertEqual(c.receipt("EX-4", date(2026, 12, 20)), b"scan-4")
        self.assertIsNone(c.receipt("EX-4", date(2026, 12, 21)))


if __name__ == "__main__":
    unittest.main()
