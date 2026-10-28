"""Expense claims and their scanned receipts."""
from datetime import timedelta

from vault import Vault

SUBMIT_WINDOW_DAYS = 90
RECEIPT_DAYS = 60


class Claims:
    def __init__(self, vault=None):
        self._vault = vault if vault is not None else Vault()
        self._claims = {}

    def submit(self, claim_id, purchased, receipt, today):
        """Record a claim for a purchase made on the date purchased."""
        if today > purchased + timedelta(days=SUBMIT_WINDOW_DAYS):
            raise ValueError("claims must be submitted within 90 days of the purchase")
        # The vault purges on the keep_days-th day, so keep one day more than the
        # last day on which an approver may open the receipt.
        receipt_ref = self._vault.put(receipt, today, keep_days=RECEIPT_DAYS + 1)
        self._claims[claim_id] = {
            "purchased": purchased,
            "submitted": today,
            "receipt_ref": receipt_ref,
        }

    def receipt(self, claim_id, today):
        """The scanned receipt for an approver, or None when it is no longer available."""
        return self._vault.get(self._claims[claim_id]["receipt_ref"], today)
