"""Time s(CASP) queries on one assembled program.

Usage: python3 -I fuzz/time_queries.py PROGRAM FORALL QUERY...
Each run is: timeout 30 scasp --unknown=error FORALL -s 0 --json=- --query=Q PROGRAM
Prints the wall time, the exit code, and the number of answers.
"""
import json
import subprocess
import sys
import time

prog, flag, queries = sys.argv[1], sys.argv[2], sys.argv[3:]
nsol = "0"
if queries and queries[0].startswith("-s"):
    nsol, queries = queries[0][2:], queries[1:]
for q in queries:
    t0 = time.monotonic()
    p = subprocess.run(["timeout", "30", "scasp", "--unknown=error", flag, "-s", nsol,
                        "--json=-", "--width=0", f"--query={q}", prog],
                       capture_output=True, text=True)
    dt = time.monotonic() - t0
    n = "-"
    if p.returncode == 0:
        try:
            n = len(json.loads(p.stdout)["answers"])
        except Exception:
            n = "?"
    print(f"{dt:6.1f}s exit={p.returncode:<3} answers={n:<3} {q}")
