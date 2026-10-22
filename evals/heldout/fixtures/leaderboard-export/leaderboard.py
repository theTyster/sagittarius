import csv


def leader(rows):
    return max(rows, key=lambda r: int(r["points"]))


def banner(path="scores.csv"):
    with open(path, newline="", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))
    top = leader(rows)
    return f"Leader: {top['player']} ({top['points']} pts)"
