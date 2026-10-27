import unittest

from invoice import invoice_number


class InvoiceTest(unittest.TestCase):
    def test_format(self):
        self.assertEqual(invoice_number(2026, 7), "INV-2026-0007")

    def test_large_sequence(self):
        self.assertEqual(invoice_number(2026, 12345), "INV-2026-2345")


if __name__ == "__main__":
    unittest.main()
