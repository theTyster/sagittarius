#!/usr/bin/env python3
"""Count the body-only variables of every rule in the given s(CASP) files.

A body-only variable occurs in the body of a rule but not in its head. Each
anonymous variable `_` counts as one variable. A named variable counts once,
however often it occurs in the body. Facts and rules with a body that has no
body-only variable are not listed.

Usage: python3 -I repro-bodyvars.py FILE... [--min N]
Prints "COUNT  FILE  RULE" for every rule with at least N body-only variables
(default 2), then a summary line per file.
"""
import re
import sys


def clauses(path):
    with open(path) as f:
        lines = [ln for ln in f if not ln.lstrip().startswith("%")]
    text = "".join(lines)
    text = re.sub(r"'[^']*'", "q", text)  # drop quoted atoms
    for part in re.split(r"\.\s*(?:\n|$)", text):
        part = " ".join(part.split())
        if part:
            yield part


def variables(text):
    return re.findall(r"\b[A-Z_][A-Za-z0-9_]*\b", text)


def body_only(rule):
    if ":-" not in rule:
        return 0
    head, body = rule.split(":-", 1)
    head_vars = {v for v in variables(head) if v != "_"}
    count = 0
    seen = set()
    for v in variables(body):
        if v == "_":
            count += 1
        elif v not in head_vars and v not in seen:
            seen.add(v)
            count += 1
    return count


def main():
    args = sys.argv[1:]
    minimum = 2
    if "--min" in args:
        i = args.index("--min")
        minimum = int(args[i + 1])
        del args[i:i + 2]
    for path in args:
        worst = 0
        listed = 0
        for rule in clauses(path):
            n = body_only(rule)
            worst = max(worst, n)
            if n >= minimum:
                listed += 1
                print(f"{n}  {path}  {rule}")
        print(f"-- {path}: {listed} rule(s) with >= {minimum} body-only variables; maximum {worst}")


if __name__ == "__main__":
    main()
