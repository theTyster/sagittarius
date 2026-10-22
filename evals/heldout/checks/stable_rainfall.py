#!/usr/bin/env python3
"""Check for rain-wettest: the tests pin their own readings, and do not read the live rainfall.csv.

Usage: stable_rainfall.py WORKDIR. Runs the work directory's tests three times, each in a copy:
as it is (must pass), after rainfall.csv gains new readings (must still pass), and with the
wettest_month picking the driest month (must fail). Prints one line of evidence; exit 0 is a pass.
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


def new_readings(copy):
    path = os.path.join(copy, "rainfall.csv")
    with open(path, "a", encoding="utf-8", newline="") as f:
        f.write("2026-05-22,40.0\n2026-05-29,35.5\n2026-06-02,5.0\n")


def wettest_broken(copy):
    path = os.path.join(copy, "rainfall.py")
    src = open(path, encoding="utf-8").read()
    new = src.replace("return max(totals, key=totals.get)", "return min(totals, key=totals.get)")
    if new == src:
        raise SystemExit("cannot find wettest_month's max in rainfall.py to mutate")
    open(path, "w", encoding="utf-8").write(new)


work = sys.argv[1]
results = {"as is": tests_pass(work), "after new readings": tests_pass(work, new_readings),
           "wettest broken": not tests_pass(work, wettest_broken)}
print("; ".join(f"{k}: {'ok' if v else 'FAIL'}" for k, v in results.items()))
sys.exit(0 if all(results.values()) else 1)
