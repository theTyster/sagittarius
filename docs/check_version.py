#!/usr/bin/env python3
"""V-A c_v_a_1: Sagittarius has one source for its version, the file VERSION.

The last line of prompt/SAGITTARIUS.md ("This is Sagittarius X.Y.Z (DATE).") and a heading of
CHANGELOG.md ("## ... X.Y.Z ...") must agree with it. The prompt is Ty's text: this check only
compares it with the file, and no script writes the prompt.

Usage: python3 docs/check_version.py
Exit 0: the three agree. Exit 1: they do not (each difference is printed).
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SEMVER = re.compile(r"\d+\.\d+\.\d+")


def read(rel):
    try:
        with open(os.path.join(ROOT, rel), encoding="utf-8") as f:
            return f.read()
    except OSError:
        return None


def main():
    bad = []
    v = (read("VERSION") or "").strip()
    if not SEMVER.fullmatch(v):
        bad.append(f"VERSION does not hold one number X.Y.Z: {v!r}")
    prompt = read("prompt/SAGITTARIUS.md") or ""
    last = (prompt.strip().splitlines() or [""])[-1]
    m = re.fullmatch(r"This is Sagittarius (\d+\.\d+\.\d+) \(\d{4}-\d{2}-\d{2}\)\.", last)
    if not m:
        bad.append(f"the last line of the prompt is not 'This is Sagittarius X.Y.Z (DATE).': {last!r}")
    elif m.group(1) != v:
        bad.append(f"VERSION says {v}, and the last line of the prompt says {m.group(1)}")
    cl = read("CHANGELOG.md") or ""
    if not any(re.match(r"## ", ln) and re.search(r"(?<![\d.])" + re.escape(v) + r"(?![\d.])", ln) for ln in cl.splitlines()):
        bad.append(f"CHANGELOG.md has no heading ('## ...') for {v}")
    for b in bad:
        print("FAIL " + b)
    if not bad:
        print(f"version PASS: VERSION, the prompt, and CHANGELOG.md agree on {v}")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
