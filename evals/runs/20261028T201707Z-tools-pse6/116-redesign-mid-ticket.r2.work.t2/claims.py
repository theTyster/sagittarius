"""Expense claims and their scanned receipts."""
from datetime import timedelta

from vault import Vault

SUBMIT_WINDOW_DAYS = 90
RECEIPT_DAYS = 60


class Claims:
    def __init__(self, vault=None):
        self._claims = {}
        self._vault = vault if vault is not None else Vault()

    def submit(self, claim_id, purchased, receipt, today):
        """Record a claim for a purchase made on the date purchased."""
        if today > purchased + timedelta(days=SUBMIT_WINDOW_DAYS):
            raise ValueError("claims must be submitted within 90 days of the purchase")
        # The vault purges on the day keep_days after storage, so the receipt
        # stays readable through day RECEIPT_DAYS and is gone on the next day.
        receipt_ref = self._vault.put(receipt, today, keep_days=RECEIPT_DAYS + 1)
        self._claims[claim_id] = {
            "purchased": purchased,
            "submitted": today,
            "receipt_ref": receipt_ref,
        }

    def receipt(self, claim_id, today):
        """The scanned receipt for an approver, or None when it is no longer available."""
        claim = self._claims[claim_id]
        return self._vault.get(claim["receipt_ref"], today)
