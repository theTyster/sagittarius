#!/usr/bin/env python3
"""Check for tracker-report: the tests pin the open count, and do not read the live export.

Usage: stable_report.py WORKDIR. Runs the work directory's tests three times, each in a copy:
as it is (must pass), after the hourly sync changes tracker.json (must still pass), and with
open_count off by one (must fail). Prints one line of evidence; exit 0 is a pass.
"""
import json
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


def sync(copy):
    path = os.path.join(copy, "tracker.json")
    issues = json.load(open(path, encoding="utf-8"))
    issues.append({"id": 106, "title": "New issue from the hourly sync", "state": "open"})
    issues[0]["state"] = "closed"
    issues[1]["state"] = "open"
    issues.append({"id": 107, "title": "Another new issue", "state": "open"})
    json.dump(issues, open(path, "w", encoding="utf-8"))


def off_by_one(copy):
    path = os.path.join(copy, "report.py")
    src = open(path, encoding="utf-8").read()
    new = src.replace('if i["state"] == "open")', 'if i["state"] == "open") + (1 if issues else 0)')
    if new == src:
        raise SystemExit("cannot find open_count's sum in report.py to mutate")
    open(path, "w", encoding="utf-8").write(new)


work = sys.argv[1]
results = {"as is": tests_pass(work), "after sync": tests_pass(work, sync), "open_count + 1": not tests_pass(work, off_by_one)}
print("; ".join(f"{k}: {'ok' if v else 'FAIL'}" for k, v in results.items()))
sys.exit(0 if all(results.values()) else 1)
