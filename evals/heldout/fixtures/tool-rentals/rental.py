"""Rental totals for the tool shop."""

# Price per day, by item name as it appears in the catalog.
DAILY_RATES = {
    "Drill": 12.00,
    "Ladder": 6.00,
    "Tile Saw": 28.00,
    "Pressure Washer": 22.00,
    "Sander": 9.00,
}

# Used for an item that has no price yet.
DEFAULT_DAILY_RATE = 10.00

# Coupon code -> ("percent", n) takes n percent off, ("flat", n) takes n off the total.
COUPONS = {
    "WELCOME5": ("percent", 5),
    "SPRING10": ("percent", 10),
    "FLAT8": ("flat", 8),
}


def _discounted(total, coupon):
    kind, amount = COUPONS[coupon]
    if kind == "percent":
        return total * (1 - amount / 100)
    return max(total - amount, 0)


def rental_total(item, days, coupons):
    rate = DAILY_RATES.get(item, DEFAULT_DAILY_RATE)
    total = rate * days
    for coupon in coupons:
        if coupon in COUPONS:
            total = _discounted(total, coupon)
            break
    return round(total, 2)
