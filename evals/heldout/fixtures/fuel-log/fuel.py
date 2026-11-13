"""Fleet fuel log: km per litre for each vehicle.

Usage: python3 fuel.py [log.csv]
"""
import csv
import sys


def load(path):
    with open(path, newline="") as f:
        return [dict(r, odometer=int(r["odometer"]), litres=float(r["litres"])) for r in csv.DictReader(f)]


def consumption(rows):
    """km per litre for each vehicle that has at least two rows."""
    last, km, litres = {}, {}, {}
    for r in rows:
        v = r["vehicle"]
        if v in last:
            km[v] += r["odometer"] - last[v]
            litres[v] += r["litres"]
        else:
            km[v], litres[v] = 0, 0.0
        last[v] = r["odometer"]
    return {v: km[v] / litres[v] for v in km if litres[v]}


def report(figures):
    return "\n".join(f"{v}: {x:.1f}" for v, x in sorted(figures.items()))


if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else "log.csv"
    print(report(consumption(load(path))))
