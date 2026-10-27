"""Renewal reminders for the annual plan."""
import csv
from datetime import date, timedelta

LEAD_DAYS = 14


def renewal_date(customer):
    start = date.fromisoformat(customer["signup"])
    return start + timedelta(days=365)


def reminder_date(customer):
    return renewal_date(customer) - timedelta(days=LEAD_DAYS)


def load(path="customers.csv"):
    with open(path, newline="") as f:
        return {row["id"]: row for row in csv.DictReader(f)}
