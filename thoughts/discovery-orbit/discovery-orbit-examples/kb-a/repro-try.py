#!/usr/bin/env python3
"""Run several small s(CASP) programs under all, prev and sasp.

Usage: python3 -I repro-try.py VARIANTS.txt [QUERY]

VARIANTS.txt holds programs separated by header lines "%% NAME". Each program is
written to repro/tmp-try.pl and run as
    timeout 30 scasp --unknown=error --forall=ALGO -s 0 --query=QUERY repro/tmp-try.pl
QUERY defaults to `l`. Prints one line per program:
    NAME  all=VERDICT  prev=VERDICT  sasp=VERDICT  [FAIL]
Verdicts: no_models, MODEL (a model was found), TIMEOUT, OTHER.
FAIL marks the pattern all=MODEL with prev=no_models and sasp=no_models.
"""
import subprocess
import sys
import time

TMP = "repro/tmp-try.pl"


def run(algo, query):
    t0 = time.time()
    proc = subprocess.run(
        ["timeout", "30", "scasp", "--unknown=error", f"--forall={algo}",
         "-s", "0", f"--query={query}", TMP],
        capture_output=True, text=True)
    wall = time.time() - t0
    out = proc.stdout + proc.stderr
    if proc.returncode == 124:
        v = "TIMEOUT"
    elif "No models" in out:
        v = "no_models"
    elif "Answer 1" in out:
        v = "MODEL"
    else:
        v = "OTHER"
    return v, wall


def main():
    path = sys.argv[1]
    query = sys.argv[2] if len(sys.argv) > 2 else "l"
    programs = []
    with open(path) as f:
        for line in f:
            if line.startswith("%% "):
                programs.append([line[3:].strip(), []])
            elif programs and line.strip():
                programs[-1][1].append(line.rstrip("\n"))
    for name, lines in programs:
        with open(TMP, "w") as f:
            f.write("\n".join(lines) + "\n")
        res = [run(a, query) for a in ("all", "prev", "sasp")]
        flag = "  FAIL" if [r[0] for r in res] == ["MODEL", "no_models", "no_models"] else ""
        cells = "  ".join(f"{a}={r[0]}({r[1]:.2f}s)" for a, r in zip(("all", "prev", "sasp"), res))
        print(f"{name:34s} {cells}{flag}", flush=True)


if __name__ == "__main__":
    main()
