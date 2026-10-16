#!/usr/bin/env python3
"""Compare the output of run-matrix.sh with the expected answers.

Usage: python3 -I check-matrix.py MATRIX.txt
Reads the summary lines of run-matrix.sh and prints
  - every run whose set of distinct answers differs from the expected set,
  - every run that is correct but printed the same answer more than once, and
  - a count of correct runs per algorithm.

The expected answers for kb.pl and kb-cf1 .. kb-cf5b follow the task:
  kb.pl      discovery_ready: model; every other query: no models.
  kb-cf1     question_waits -> Q = q1; discovery_ready -> no models.
  kb-cf2     no_falsifier -> C = c1 and C = c2b; discovery_ready -> no models.
  kb-cf3     finding_lead -> F = f1.
  kb-cf4     unasked_finding -> F = f2; discovery_ready -> no models.
  kb-cf5     weak_rule -> R = clamp; discovery_ready -> no models.
  kb-cf5b    weak_rule -> no models.
The task states those expectations only. For the remaining (KB, query) pairs
the expected answer is derived by hand from the rules:
  - question_waits, no_falsifier, finding_lead, unasked_finding, weak_rule and
    some_current_refuted stay "no models" unless the list above says otherwise;
  - discovery_ready stays a model in kb-cf3 and kb-cf5b, because finding_lead
    is not part of the readiness gate and the reason removes the weak rule.
"""
import re
import sys

MODEL = {"true (model, no bindings)"}

BASE = {
    "discovery_ready": MODEL,
    "question_waits(Q)": set(),
    "no_falsifier(C)": set(),
    "finding_lead(F)": set(),
    "unasked_finding(F)": set(),
    "weak_rule(R)": set(),
    "some_current_refuted": set(),
}


def expected(kb):
    e = dict(BASE)
    if kb == "kb-cf1.pl":
        e["question_waits(Q)"] = {"Q = q1"}
        e["discovery_ready"] = set()
    elif kb == "kb-cf2.pl":
        e["no_falsifier(C)"] = {"C = c1", "C = c2b"}
        e["discovery_ready"] = set()
    elif kb == "kb-cf3.pl":
        e["finding_lead(F)"] = {"F = f1"}
    elif kb == "kb-cf4.pl":
        e["unasked_finding(F)"] = {"F = f2"}
        e["discovery_ready"] = set()
    elif kb == "kb-cf5.pl":
        e["weak_rule(R)"] = {"R = clamp"}
        e["discovery_ready"] = set()
    return e


def parse(answers):
    """Return (set of distinct answers, number of answers printed)."""
    if answers == "no models":
        return set(), 0
    m = re.match(r"(\d+) answer\(s\): (.*)$", answers)
    if not m:
        return {answers}, -1
    items = [re.sub(r" \(x\d+\)$", "", s) for s in m.group(2).split(" / ")]
    return set(items), int(m.group(1))


def main():
    total, good, dups = {}, {}, {}
    with open(sys.argv[1]) as f:
        for line in f:
            parts = [p.strip() for p in line.rstrip("\n").split(" ;; ")]
            if len(parts) < 7:
                continue
            algo, query, answers, wall, internal, exit_code, files = parts[:7]
            kb = files.split()[-1]
            want = expected(kb)[query]
            got, n = parse(answers)
            total[algo] = total.get(algo, 0) + 1
            if got == want:
                good[algo] = good.get(algo, 0) + 1
                if n > len(got):
                    dups[algo] = dups.get(algo, 0) + 1
                    print(f"DUP   {algo:5s} {kb:11s} {query:22s} correct, but {n} answers printed for {len(got)} distinct")
            else:
                print(f"DIFF  {algo:5s} {kb:11s} {query:22s} got: {answers}   expected: {sorted(want) or 'no models'}")
    for algo in ("all", "prev", "sasp"):
        print(f"{algo}: {good.get(algo, 0)} of {total.get(algo, 0)} runs match the expected answers; "
              f"{dups.get(algo, 0)} of them repeat an answer")


if __name__ == "__main__":
    main()
