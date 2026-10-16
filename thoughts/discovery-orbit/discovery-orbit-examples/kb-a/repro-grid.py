#!/usr/bin/env python3
"""Grid of tiny programs: where does s(CASP) --forall=all give a wrong answer?

Program family. b = body-only variables BEFORE the head variable in the body
atom, e = body-only variables AFTER it, n = number of facts, p = which fact
(counted from 1) is the one that matches. The arity of a/N is b + 1 + e.

    a(r1c1, ..., x, ..., r1c5).     % row 1; the key column holds x if it matches, else z
    a(r2c1, ..., z, ..., r2c5).
    c(X) :- a(_, ..., X, ..., _).   % b anonymous variables, X, e anonymous variables
    l :- not c(x).

c(x) is true, so the correct answer for the query `l` is "no models".
Each program is run as:
    timeout 30 scasp --unknown=error --forall=ALGO -s 0 --query=l FILE
for ALGO in all, prev, sasp.

Usage: python3 -I repro-grid.py BMAX EMAX NMAX OUTDIR [shared]
  "shared" gives every row the same filler constants (s1, s2, ...) instead of
  row-specific ones (r1c1, ...).
Writes one FILE per program into OUTDIR and prints one TSV line per run:
    b  e  n  p  algo  verdict  wall_seconds
verdict is no_models (correct), MODEL (wrong), TIMEOUT or OTHER.
"""
import os
import subprocess
import sys
import time

ALGOS = ["all", "prev", "sasp"]


def program(b, e, n, p, shared):
    arity = b + 1 + e
    lines = []
    for i in range(1, n + 1):
        args = []
        for c in range(1, arity + 1):
            if c == b + 1:
                args.append("x" if i == p else "z")
            else:
                args.append(f"s{c}" if shared else f"r{i}c{c}")
        lines.append("a(" + ", ".join(args) + ").")
    body = ["_"] * arity
    body[b] = "X"
    lines.append("c(X) :- a(" + ", ".join(body) + ").")
    lines.append("l :- not c(x).")
    return "\n".join(lines) + "\n"


def verdict(proc):
    out = proc.stdout + proc.stderr
    if proc.returncode == 124:
        return "TIMEOUT"
    if "No models" in out:
        return "no_models"
    if "Answer 1" in out:
        return "MODEL"
    return "OTHER"


def main():
    bmax, emax, nmax, outdir = int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
    shared = len(sys.argv) > 5 and sys.argv[5] == "shared"
    os.makedirs(outdir, exist_ok=True)
    for b in range(0, bmax + 1):
        for e in range(0, emax + 1):
            for n in range(1, nmax + 1):
                for p in range(1, n + 1):
                    path = os.path.join(outdir, f"g-b{b}-e{e}-n{n}-p{p}.pl")
                    with open(path, "w") as f:
                        f.write(program(b, e, n, p, shared))
                    for algo in ALGOS:
                        t0 = time.time()
                        proc = subprocess.run(
                            ["timeout", "30", "scasp", "--unknown=error", f"--forall={algo}",
                             "-s", "0", "--query=l", path],
                            capture_output=True, text=True)
                        wall = time.time() - t0
                        print(f"{b}\t{e}\t{n}\t{p}\t{algo}\t{verdict(proc)}\t{wall:.2f}", flush=True)


if __name__ == "__main__":
    main()
