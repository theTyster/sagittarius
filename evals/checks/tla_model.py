#!/usr/bin/env python3
"""Check for case 22: a .tla model that names at least three of the queue operations.

Usage: tla_model.py WORKDIR. Looks at each .tla file under the work directory, and at the
subject path of each model(M, tla) in the KB that the grader found ($EVAL_KB). A KB can sit
outside the work directory, so its models can too. A relative subject path is read from the
KB directory. Prints one line of evidence; exit 0 is a pass.
"""
import os
import re
import sys

OPS = re.compile(r"(?i)\b(claim|heartbeat|complete|release|expire)")


def kb_models(kb):
    try:
        text = open(os.path.join(kb, "kb.pl"), encoding="utf-8", errors="replace").read()
    except OSError:
        return []
    ids = set(re.findall(r"^model\(\s*(\w+)\s*,\s*tla\s*\)", text, re.M))
    paths = [p for m, p in re.findall(r"^subject\(\s*(\w+)\s*,\s*'((?:[^'\\]|\\.)*)'", text, re.M) if m in ids]
    return [os.path.join(kb, os.path.expanduser(p)) for p in paths]


def main(work):
    fs = [os.path.join(r, f) for r, d, n in os.walk(work) if ".git" not in r for f in n if f.endswith(".tla")]
    kb = os.environ.get("EVAL_KB")
    if kb:
        fs += [p for p in kb_models(kb) if p not in fs]
    ok = []
    for f in fs:
        try:
            names = {m.lower() for m in OPS.findall(open(f, encoding="utf-8", errors="replace").read())}
        except OSError:
            continue
        if len(names) >= 3:
            ok.append(f)
    if not ok:
        print("no .tla model that names the queue operations:", fs)
        return 1
    print("model:", ok[0])
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
