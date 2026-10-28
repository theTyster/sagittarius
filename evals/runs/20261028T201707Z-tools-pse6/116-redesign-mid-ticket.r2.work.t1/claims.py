"""Expense claims and their scanned receipts."""
from datetime import timedelta

SUBMIT_WINDOW_DAYS = 90
RECEIPT_DAYS = 60


class Claims:
    def __init__(self):
        self._claims = {}

    def submit(self, claim_id, purchased, receipt, today):
        """Record a claim for a purchase made on the date purchased."""
        if today > purchased + timedelta(days=SUBMIT_WINDOW_DAYS):
            raise ValueError("claims must be submitted within 90 days of the purchase")
        self._claims[claim_id] = {
            "purchased": purchased,
            "submitted": today,
            "receipt": receipt,
        }

    def receipt(self, claim_id, today):
        """The scanned receipt for an approver, or None when it is no longer available."""
        claim = self._claims[claim_id]
        if today > claim["submitted"] + timedelta(days=RECEIPT_DAYS):
            return None
        return claim["receipt"]
