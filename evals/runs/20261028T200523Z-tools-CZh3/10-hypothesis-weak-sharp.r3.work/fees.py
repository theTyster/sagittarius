"""Shipping fees for parcels."""
from datetime import date

# Each rate table applies from its date. A fee is the zone's base plus a price per kilogram.
RATE_TABLES = [
    (date(2026, 1, 1), {"base": {1: 4.00, 2: 5.50, 3: 7.00}, "per_kg": 1.20}),
    (date(2026, 10, 1), {"base": {1: 4.60, 2: 6.30, 3: 8.10}, "per_kg": 1.35}),
]

# Postal code prefix -> zone.
ZONES = {"1": 1, "2": 1, "3": 2, "4": 2, "5": 2, "59": 3, "6": 3, "7": 3}


def zone_for(postal_code):
    for length in (1, 2):
        prefix = postal_code[:length]
        if prefix in ZONES:
            return ZONES[prefix]
    raise ValueError(f"no zone for {postal_code}")


def _rates():
    today = date.today()
    return [t for start, t in RATE_TABLES if start <= today][-1]


def shipping_fee(weight_kg, postal_code, ship_date):
    rates = _rates()
    return round(rates["base"][zone_for(postal_code)] + rates["per_kg"] * weight_kg, 2)
