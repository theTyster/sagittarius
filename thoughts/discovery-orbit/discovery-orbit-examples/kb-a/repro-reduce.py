#!/usr/bin/env python3
"""Greedy 1-minimal reducer for a failing s(CASP) program.

A program "fails" when, for the given query:
    --forall=all  answers with a model   (wrong: the right answer is "No models"), and
    --forall=prev and --forall=sasp both answer "No models" (right).

Usage: python3 -I repro-reduce.py PROGRAM.pl NKEEP [QUERY]
  PROGRAM.pl : one clause per line.
  NKEEP      : the last NKEEP lines are never removed.
  QUERY      : defaults to `l`.
Tries to delete each of the other lines in turn and keeps the deletion when
the program still fails. Prints the reduced program to stdout and each
removal to stderr. Uses repro/tmp-reduce.pl as scratch.
"""
import subprocess
import sys

TMP = "repro/tmp-reduce.pl"
QUERY = "l"


def run(algo, path):
    proc = subprocess.run(
        ["timeout", "30", "scasp", "--unknown=error", f"--forall={algo}",
         "-s", "0", f"--query={QUERY}", path],
        capture_output=True, text=True)
    out = proc.stdout + proc.stderr
    if proc.returncode == 124:
        return "TIMEOUT"
    if "No models" in out:
        return "no_models"
    if "Answer 1" in out:
        return "MODEL"
    return "OTHER"


def verdicts(lines):
    with open(TMP, "w") as f:
        f.write("\n".join(lines) + "\n")
    return tuple(run(a, TMP) for a in ("all", "prev", "sasp"))


def failing(lines):
    return verdicts(lines) == ("MODEL", "no_models", "no_models")


def main():
    global QUERY
    path, nkeep = sys.argv[1], int(sys.argv[2])
    if len(sys.argv) > 3:
        QUERY = sys.argv[3]
    with open(path) as f:
        lines = [ln.rstrip("\n") for ln in f if ln.strip()]
    if not failing(lines):
        print("start program does not fail:", verdicts(lines), file=sys.stderr)
        sys.exit(1)
    changed = True
    while changed:
        changed = False
        i = 0
        while i < len(lines) - nkeep:
            trial = lines[:i] + lines[i + 1:]
            if failing(trial):
                print("removed:", lines[i], file=sys.stderr)
                lines = trial
                changed = True
            else:
                i += 1
    print("\n".join(lines))


if __name__ == "__main__":
    main()
