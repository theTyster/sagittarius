from datetime import date, timedelta

# Days a patron may keep each kind of item. Autumn policy: 21 days for all kinds.
LOAN_DAYS = {
    "novel": 21,
    "magazine": 21,
    "dvd": 21,
    "tool": 21,
    "reference": 21,
}


def due_date(kind: str, checked_out: date) -> date:
    """The date an item of this kind must come back."""
    return checked_out + timedelta(days=LOAN_DAYS[kind])
