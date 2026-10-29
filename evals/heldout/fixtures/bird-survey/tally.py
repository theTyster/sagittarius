"""Garden bird survey: total the birds of each species from survey.csv.

Each row is one observer's count of one species at one post during one
ten-minute window on one survey date.
Usage: python3 tally.py [survey.csv]
"""
import csv
import sys


def load(path):
    with open(path, newline="") as f:
        return [dict(r, count=int(r["count"])) for r in csv.DictReader(f)]


def count_species(rows):
    totals = {}
    for r in rows:
        totals[r["species"]] = totals.get(r["species"], 0) + r["count"]
    return totals


def report(totals):
    return "\n".join(f"{species}: {n}" for species, n in sorted(totals.items()))


if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else "survey.csv"
    print(report(count_species(load(path))))
