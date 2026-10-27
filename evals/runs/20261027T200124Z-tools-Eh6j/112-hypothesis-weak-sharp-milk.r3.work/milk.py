"""Payments for milk collected from member farms."""
import csv

RATE_PER_LITRE = 0.42


def _read(path):
    with open(path, newline="") as f:
        return list(csv.DictReader(f))


def pickups(path="pickups.csv"):
    return _read(path)


def month_of(taken_at):
    """The month a pickup belongs to, as YYYY-MM."""
    return taken_at[:7]


def pickup_payment(row):
    return round(float(row["amount"]) * RATE_PER_LITRE, 2)


def monthly_statement(farm, month):
    return round(sum(pickup_payment(r) for r in pickups()
                     if r["farm"] == farm and month_of(r["taken_at"]) == month), 2)
