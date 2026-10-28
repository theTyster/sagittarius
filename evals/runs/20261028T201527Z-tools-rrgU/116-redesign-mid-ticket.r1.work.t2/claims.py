"""Expense claims and their scanned receipts."""
from datetime import timedelta

SUBMIT_WINDOW_DAYS = 90
RECEIPT_DAYS = 60


class Claims:
    def __init__(self, vault):
        self._vault = vault
        self._claims = {}

    def submit(self, claim_id, purchased, receipt, today):
        """Record a claim for a purchase made on the date purchased."""
        if today > purchased + timedelta(days=SUBMIT_WINDOW_DAYS):
            raise ValueError("claims must be submitted within 90 days of the purchase")
        # The vault purges on the keep day itself, so keep one day past the last
        # day an approver may open the receipt.
        doc_id = self._vault.put(receipt, today, keep_days=RECEIPT_DAYS + 1)
        self._claims[claim_id] = {
            "purchased": purchased,
            "submitted": today,
            "receipt_doc": doc_id,
        }

    def receipt(self, claim_id, today):
        """The scanned receipt for an approver, or None when it is no longer available."""
        claim = self._claims[claim_id]
        if today > claim["submitted"] + timedelta(days=RECEIPT_DAYS):
            return None
        return self._vault.get(claim["receipt_doc"], today)
