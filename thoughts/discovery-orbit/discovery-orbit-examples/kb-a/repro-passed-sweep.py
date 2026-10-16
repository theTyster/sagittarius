#!/usr/bin/env python3
"""Differential test of the shared core's passed/1 rules: s(CASP) against plain SWI-Prolog.

For every pass/fail sequence of length 1..NMAX (run numbers 1, 2, ...), the
facts are written in run order and in reverse order. The rules are those of
repro/passed-a.pl. Each program is checked with four queries:
    passed(k1)   was_red(k1)   not passed(k1)   not was_red(k1)
under s(CASP) --forall=all, prev, sasp (as `timeout 30 scasp --unknown=error
--forall=ALGO -s 0 --query=Q FILE`) and, as the reference, under plain
SWI-Prolog with `not` replaced by `\\+`
(`timeout 30 swipl -g "(GOAL -> writeln(yes) ; writeln(no)), halt" FILE`).

Usage: python3 -I repro-passed-sweep.py NMAX OUTDIR
Prints one TSV line per program and query:
    sequence  order  query  swipl  all  prev  sasp  mismatching-algorithms
sequence uses P (pass) and F (fail), one letter per run, in run-number order.
Answers: yes/no for swipl, model/none for s(CASP).
"""
import itertools
import os
import subprocess
import sys

RULES = """check(k1, c1).
passed(K) :- attest(_, test_result, _, result(K, R, pass), _, _), not failed_after(K, R).
failed_after(K, R) :- attest(_, test_result, _, result(K, R2, fail), _, _), R2 > R.
was_red(K) :- attest(_, test_result, _, result(K, R1, fail), _, _), attest(_, test_result, _, result(K, R2, pass), _, _), R1 < R2.
"""

QUERIES = [
    ("passed(k1)", "passed(k1)"),
    ("was_red(k1)", "was_red(k1)"),
    ("not passed(k1)", "\\+ passed(k1)"),
    ("not was_red(k1)", "\\+ was_red(k1)"),
]


def facts(seq, reverse):
    lines = []
    for i, r in enumerate(seq, start=1):
        word = "pass" if r == "P" else "fail"
        lines.append(f"attest(a{i}, test_result, k1, result(k1, {i}, {word}), script, '2026-10-15T10:00:00Z').")
    if reverse:
        lines.reverse()
    return "\n".join(lines) + "\n"


def scasp(algo, query, path):
    proc = subprocess.run(
        ["timeout", "30", "scasp", "--unknown=error", f"--forall={algo}",
         "-s", "0", f"--query={query}", path],
        capture_output=True, text=True)
    out = proc.stdout + proc.stderr
    if proc.returncode == 124:
        return "TIMEOUT"
    if "No models" in out:
        return "none"
    if "Answer 1" in out:
        return "model"
    return "OTHER"


def swipl(goal, path):
    proc = subprocess.run(
        ["timeout", "30", "swipl", "-g", f"({goal} -> writeln(yes) ; writeln(no)), halt", path],
        capture_output=True, text=True)
    out = proc.stdout.strip().splitlines()
    return out[-1] if out else "ERR"


def main():
    nmax, outdir = int(sys.argv[1]), sys.argv[2]
    os.makedirs(outdir, exist_ok=True)
    for n in range(1, nmax + 1):
        for seq in itertools.product("PF", repeat=n):
            seq = "".join(seq)
            for reverse in (False, True):
                order = "reverse" if reverse else "run-order"
                base = f"seq-{seq}-{order}"
                path = os.path.join(outdir, base + ".pl")
                plain = os.path.join(outdir, base + "-plain.pl")
                text = RULES + facts(seq, reverse)
                with open(path, "w") as f:
                    f.write(text)
                with open(plain, "w") as f:
                    f.write(text.replace(", not failed_after", ", \\+ failed_after"))
                for label, plain_goal in QUERIES:
                    ref = swipl(plain_goal, plain)
                    want = "model" if ref == "yes" else "none"
                    res = {a: scasp(a, label, path) for a in ("all", "prev", "sasp")}
                    bad = ",".join(a for a in ("all", "prev", "sasp") if res[a] != want)
                    print(f"{seq}\t{order}\t{label}\t{ref}\t{res['all']}\t{res['prev']}\t{res['sasp']}\t{bad or '-'}", flush=True)


if __name__ == "__main__":
    main()
