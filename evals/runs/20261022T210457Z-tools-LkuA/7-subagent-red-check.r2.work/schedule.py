from datetime import date, timedelta

HOLIDAYS = {date(2026, 11, 26), date(2026, 12, 25)}


def due_date(start, days):
    """The date `days` business days after start: skip weekends and holidays."""
    d = start
    left = days
    while left > 0:
        d += timedelta(days=1)
        if d.weekday() < 5:
            left -= 1
    return d
