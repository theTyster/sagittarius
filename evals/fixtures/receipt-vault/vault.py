"""The company document vault: compliance-approved storage for scanned documents.

The vault keeps a document for keep_days days after the day it is stored, and then
purges it. get() returns None for a purged or unknown document.
"""
from datetime import timedelta

DEFAULT_KEEP_DAYS = 30


class Vault:
    def __init__(self):
        self._docs = {}
        self._next = 1

    def put(self, data, today, keep_days=DEFAULT_KEEP_DAYS):
        """Store data on the date today. Returns the document id."""
        doc_id = f"doc-{self._next}"
        self._next += 1
        self._docs[doc_id] = (data, today + timedelta(days=keep_days))
        return doc_id

    def get(self, doc_id, today):
        """The stored data, or None when the document is purged or unknown."""
        entry = self._docs.get(doc_id)
        if entry is None:
            return None
        data, purge_on = entry
        if today >= purge_on:
            del self._docs[doc_id]
            return None
        return data
