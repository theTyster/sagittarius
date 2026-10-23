import csv


def monthly_totals(rows):
    totals = {}
    for r in rows:
        month = r["date"][:7]
        totals[month] = totals.get(month, 0.0) + float(r["mm"])
    return totals


def wettest_month(rows):
    totals = monthly_totals(rows)
    return max(totals, key=totals.get)


def summary(path="rainfall.csv"):
    with open(path, newline="", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))
    month = wettest_month(rows)
    return f"Wettest month: {month} ({monthly_totals(rows)[month]:.1f} mm)"
