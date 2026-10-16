#!/usr/bin/env python3
"""Which body-literal shapes make --forall=all wrong? Two facts, any mix of columns.

The rule body is one literal a/M. Each column is F (an anonymous body-only
variable) or K (the constant k1, k2, ... that the first fact holds in that
column). Fact 1 holds exactly the K constants, so the body matches it. Fact 2
holds the same K constants except in the "mismatch" columns, which hold a
different constant. In the F columns the two facts hold different constants
(unless "sameF" is given, then the same).

    a(f1, k2, k3, f4).       % fact 1, shape F K K F
    a(g1, k2, m3, g4).       % fact 2, mismatch in column 3
    c :- a(_, k2, k3, _).
    l :- not c.

c is true, so the correct answer for the query `l` is "no models".
Each program is run as:
    timeout 30 scasp --unknown=error --forall=ALGO -s 0 --query=l FILE

Usage: python3 -I repro-types.py M OUTDIR [sameF]
Prints one TSV line per program:
    shape  mismatch_columns  all  prev  sasp
shape is one letter per column. mismatch_columns is a comma list of 1-based columns.
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
    m, outdir = int(sys.argv[1]), sys.argv[2]
    same_f = len(sys.argv) > 3 and sys.argv[3] == "sameF"
    os.makedirs(outdir, exist_ok=True)
    for shape in itertools.product("FK", repeat=m):
        kcols = [i + 1 for i, s in enumerate(shape) if s == "K"]
        if not kcols or len(kcols) == m:
            continue
        for r in range(1, len(kcols) + 1):
            for mism in itertools.combinations(kcols, r):
                f1, f2, body = [], [], []
                for c in range(1, m + 1):
                    if shape[c - 1] == "F":
                        f1.append(f"f{c}")
                        f2.append(f"f{c}" if same_f else f"g{c}")
                        body.append("_")
                    else:
                        f1.append(f"k{c}")
                        f2.append(f"m{c}" if c in mism else f"k{c}")
                        body.append(f"k{c}")
                text = "\n".join([
                    "a(" + ", ".join(f1) + ").",
                    "a(" + ", ".join(f2) + ").",
                    "c :- a(" + ", ".join(body) + ").",
                    "l :- not c.",
                ]) + "\n"
                name = f"ty-{''.join(shape)}-m{'_'.join(map(str, mism))}{'-sameF' if same_f else ''}.pl"
                path = os.path.join(outdir, name)
                with open(path, "w") as f:
                    f.write(text)
                res = [verdict(path, a) for a in ("all", "prev", "sasp")]
                print(f"{''.join(shape)}\t{','.join(map(str, mism))}\t" + "\t".join(res), flush=True)


if __name__ == "__main__":
    main()
