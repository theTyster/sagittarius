#!/usr/bin/env python3
"""Make a copy of the prompt with one rule deleted (docs/REFINING.md, rule 5).

Usage: rule_copy.py OUT START END [START END ...]
Each pair names a span of prompt/SAGITTARIUS.md: from the first character of START through
the last character of END. Each anchor must occur once in the file (END is looked for after
START). The copy goes to OUT; run a case on it with `run.sh --prompt OUT ID` or
`run_tools.sh --prompt OUT ID`. Exit 2 when an anchor is missing or not unique.
"""
import os
import sys

SRC = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "prompt", "SAGITTARIUS.md")


def cut(text, start, end):
    if text.count(start) != 1:
        raise ValueError(f"start anchor occurs {text.count(start)} times: {start[:40]!r}")
    a = text.index(start)
    b = text.find(end, a)
    if b < 0 or text[a:].count(end) < 1:
        raise ValueError(f"end anchor not found after the start: {end[:40]!r}")
    return text[:a] + text[b + len(end):]


def main(argv):
    if len(argv) < 3 or len(argv) % 2 == 0:
        print(__doc__, file=sys.stderr)
        return 2
    text = open(SRC, encoding="utf-8").read()
    try:
        for start, end in zip(argv[1::2], argv[2::2]):
            text = cut(text, start.replace("\\n", "\n"), end.replace("\\n", "\n"))
    except ValueError as e:
        print(f"rule_copy: {e}", file=sys.stderr)
        return 2
    open(argv[0], "w", encoding="utf-8").write(text)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
