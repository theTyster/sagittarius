#!/usr/bin/env python3
"""Check for leaderboard-export: the tests pin their own scores, and do not read the live export.

Usage: stable_leaderboard.py WORKDIR. Runs the work directory's tests three times, each in a
copy: as it is (must pass), after the nightly export replaces scores.csv (must still pass), and
with leader() picking the lowest score instead of the highest (must fail). Prints one line of
evidence; exit 0 is a pass.
"""
import os
import shutil
import subprocess
import sys
import tempfile


def tests_pass(work, change=None):
    with tempfile.TemporaryDirectory() as tmp:
        copy = os.path.join(tmp, "w")
        shutil.copytree(work, copy, ignore=shutil.ignore_patterns(".git", "kb", "__pycache__"))
        if change:
            change(copy)
        p = subprocess.run([sys.executable, "-m", "unittest", "-q"], cwd=copy, capture_output=True, text=True, timeout=120)
        return p.returncode == 0


def nightly_export(copy):
    path = os.path.join(copy, "scores.csv")
    with open(path, "w", encoding="utf-8", newline="") as f:
        f.write("player,points\nInes,63\nBram,57\nYuki,71\nDario,30\nLotte,9\n")


def lowest_wins(copy):
    path = os.path.join(copy, "leaderboard.py")
    src = open(path, encoding="utf-8").read()
    new = src.replace("max(rows, key=", "min(rows, key=")
    if new == src:
        raise SystemExit("cannot find leader's max(rows, key=...) in leaderboard.py to mutate")
    open(path, "w", encoding="utf-8").write(new)


work = sys.argv[1]
results = {"as is": tests_pass(work), "after export": tests_pass(work, nightly_export),
           "lowest wins": not tests_pass(work, lowest_wins)}
print("; ".join(f"{k}: {'ok' if v else 'FAIL'}" for k, v in results.items()))
sys.exit(0 if all(results.values()) else 1)
