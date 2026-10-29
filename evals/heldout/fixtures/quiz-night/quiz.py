"""Quiz night: add up each team's points from scores.csv and name the winner."""
import csv
import sys


def load(path):
    """The rows of a score sheet: (team, round, points)."""
    with open(path, newline="") as f:
        return [(r["team"], int(r["round"]), int(r["points"])) for r in csv.DictReader(f)]


def totals(rows):
    out = {}
    for team, _round, points in rows:
        out[team] = out.get(team, 0) + points
    return out


def winner(rows):
    t = totals(rows)
    best = max(t, key=t.get)
    return best, t[best]


if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else "scores.csv"
    team, points = winner(load(path))
    print(f"Winner: {team} with {points} points")
