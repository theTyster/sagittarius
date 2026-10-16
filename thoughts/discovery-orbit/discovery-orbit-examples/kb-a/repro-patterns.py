#!/usr/bin/env python3
"""Which columns must differ between the two facts for --forall=all to be wrong?

Two facts of arity M. The key column J (1-based) holds x in the matching fact
and z in the other fact. Every other column holds the same constant in both
facts (S) or a different constant (D). All 2^(M-1) patterns are run, with the
matching fact first and with it second.

    c :- a(_, ..., x, ..., _).     % x is in column J, M-1 anonymous variables
    l :- not c.

c is true, so the correct answer for the query `l` is "no models".
Each program is run as:
    timeout 30 scasp --unknown=error --forall=ALGO -s 0 --query=l FILE

Usage: python3 -I repro-patterns.py M J OUTDIR
Prints one TSV line per program:
    M  J  order  pattern  all  prev  sasp
pattern is one letter per non-key column, left to right: S same, D different.
order is "match-first" or "match-second".
"""
import itertools
import os
import subprocess
import sys


def verdict(path, algo):
    proc = subprocess.run(
        ["timeout", "30", "scasp", "--unknown=error", f"--forall={algo}",
         "-s", "0", "--query=l", path],
        capture_output=True, text=True)
    out = proc.stdout + proc.stderr
    if proc.returncode == 124:
        return "TIMEOUT"
    if "No models" in out:
        return "no_models"
    if "Answer 1" in out:
        return "MODEL"
    return "OTHER"


def main():
    m, j, outdir = int(sys.argv[1]), int(sys.argv[2]), sys.argv[3]
    os.makedirs(outdir, exist_ok=True)
    cols = [c for c in range(1, m + 1) if c != j]
    for pattern in itertools.product("SD", repeat=m - 1):
        match_row, other_row = [], []
        for c, letter in zip(cols, pattern):
            match_row.append((c, f"m{c}"))
            other_row.append((c, f"m{c}" if letter == "S" else f"o{c}"))
        match_row.append((j, "x"))
        other_row.append((j, "z"))
        fact_match = "a(" + ", ".join(v for _, v in sorted(match_row)) + ")."
        fact_other = "a(" + ", ".join(v for _, v in sorted(other_row)) + ")."
        body = ["_"] * m
        body[j - 1] = "x"
        rule = "c :- a(" + ", ".join(body) + ")."
        for order, facts in (("match-first", [fact_match, fact_other]),
                             ("match-second", [fact_other, fact_match])):
            name = f"pat-m{m}-j{j}-{''.join(pattern)}-{order}.pl"
            path = os.path.join(outdir, name)
            with open(path, "w") as f:
                f.write("\n".join(facts + [rule, "l :- not c."]) + "\n")
            res = [verdict(path, a) for a in ("all", "prev", "sasp")]
            print(f"{m}\t{j}\t{order}\t{''.join(pattern)}\t" + "\t".join(res), flush=True)


if __name__ == "__main__":
    main()
