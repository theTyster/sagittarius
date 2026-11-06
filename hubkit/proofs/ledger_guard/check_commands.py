#!/usr/bin/env python3
"""Compare hubflow.py's COMMANDS table with the command lists in LedgerGuard.lean.

usage: python3 -I check_commands.py [HUBFLOW_PY]

Every key of hubflow.py's `COMMANDS = {...}` must be in exactly one of `modelledCommands` or
`excludedCommands` (with a reason) in LedgerGuard.lean, and every listed name must be a real
command. Exit 0 when they agree, 1 when not (each difference is printed), 2 on a parse error.
Reads both files as text; runs and imports nothing.
"""
import ast
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT = os.path.join(HERE, "..", "..", "hub", ".claude", "scripts", "hubflow.py")
LEAN = os.path.join(HERE, "LedgerGuard.lean")


def hubflow_commands(path):
    tree = ast.parse(open(path, encoding="utf-8").read(), path)
    for node in tree.body:
        if isinstance(node, ast.Assign) and any(isinstance(t, ast.Name) and t.id == "COMMANDS" for t in node.targets):
            if not isinstance(node.value, ast.Dict):
                break
            return [k.value for k in node.value.keys if isinstance(k, ast.Constant)]
    print(f"check_commands: no COMMANDS dict in {path}", file=sys.stderr)
    sys.exit(2)


def lean_list(text, name):
    m = re.search(r"def " + name + r" : List \(String × String\) := \[(.*?)\n\]", text, re.S)
    if not m:
        print(f"check_commands: no {name} in {LEAN}", file=sys.stderr)
        sys.exit(2)
    pairs = re.findall(r'\(\s*"([^"]+)"\s*,\s*"([^"]*)"\s*\)', m.group(1))
    return pairs


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT
    real = hubflow_commands(path)
    text = open(LEAN, encoding="utf-8").read()
    modelled = lean_list(text, "modelledCommands")
    excluded = lean_list(text, "excludedCommands")
    problems = []
    names = [n for n, _ in modelled] + [n for n, _ in excluded]
    for n in sorted(set(names)):
        if names.count(n) > 1:
            problems.append(f"{n}: listed more than once")
    for n, why in excluded:
        if not why.strip():
            problems.append(f"{n}: excluded with no reason")
    for n in real:
        if n not in names:
            problems.append(f"{n}: a hubflow command that the model neither models nor excludes")
    for n in names:
        if n not in real:
            problems.append(f"{n}: listed in the model but not a hubflow command")
    for p in problems:
        print("FAIL " + p)
    print(f"{len(real)} hubflow commands; {len(modelled)} modelled, {len(excluded)} excluded; "
          f"{len(problems)} problem(s)")
    sys.exit(1 if problems else 0)


if __name__ == "__main__":
    main()
