#!/usr/bin/env python3
"""T08 c1 and c3, rewritten for Sagittarius 0.3.0 (0.3.0 package D-A).

c1: the prompt states what it must, each item by one key phrase: the purpose, the orbit, who
    judges what, the light path, the hypothesis, the signals, the response to a signal, the
    vote, the honesty rules, the delivery block (with Signals and Formal), the tool. It names
    nothing that T03 removed from orbit-kb (depends/2, declare-attest). No limit on the number
    of lines: Ty ruled that the prompt has none (0.3.0).
c3: each rule of "## Honesty" (with "In discovery") and of "## Delivery" is held by one key
    phrase. A key phrase is a few words that the rule cannot lose: the check fails when the
    rule is gone, and it does not fail when the rule is reworded around the phrase.

The map of the old prompt (see docs/) is a dated record of ticket T08: no check compares it with
this prompt.

Usage: python3 docs/check_prompt_small.py [PROMPT] [--only c1|c3]
PROMPT defaults to prompt/SAGITTARIUS.md.
Exit 0: pass. Exit 1: fail.
"""
import argparse
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# (item, phrases): each phrase must be in the prompt (whitespace collapsed, case kept).
REQUIRED = [
    ("purpose", ["**Clear:**", "**Accurate:**", "**Honest:**", "**Fast:**"]),
    ("the orbit", ["\n## The orbit\n"]),
    ("who judges what", ["\n## Who judges what\n", "No party grades its own work"]),
    ("scope", ["\n## Scope\n"]),
    ("the light path", ["\n## The light path\n"]),
    ("the hypothesis", ["\n## The hypothesis\n", "Err toward the general and soft"]),
    ("signals", ["\n## Signals\n", "A claim that burns"]),
    ("one response", ["\n## One response\n", "Every signal gets the same response"]),
    ("the vote", ["\n## The vote\n", "more than 0.5"]),
    ("honesty rules", ["\n## Honesty\n"]),
    ("delivery block", ["\n## Delivery\n", "Delivered:", "Signals: <questions", "Formal: <the formal statement", "Not checked:", "To land:"]),
    ("where the procedure is", ["\n## The tool\n", "orbit-kb help"]),
]
FORBIDDEN = ["declare-attest", "depends/2", "depends("]

# One key phrase for each rule of "## Honesty", "In discovery" and "## Delivery".
RULES = [
    ("honesty: a check that cannot fail", "A check that cannot fail is not evidence"),
    ("honesty 1: every default is a guess", "Every default is a guess"),
    ("honesty 2: disclose", "Hiding is a failure"),
    ("honesty 3: match words to evidence", "Match your words to your evidence"),
    ("honesty 3: proved in Lean", "\"Proved in Lean\" is about the Lean definitions, not the code"),
    ("honesty 4: own earlier work wrong", "say so first"),
    ("honesty 5: the artifacts trust you", "none stops cheating"),
    ("honesty 5: record as the human's", "record as the human's only what the human said"),
    ("discovery 1: label each finding", "A model-only finding is a lead"),
    ("discovery 2: solver results", "Report each solver result with its encoding, bounds, and assumptions"),
    ("discovery 3: a model matches the system", "only after it has matched the system"),
    ("discovery 4: a model that cannot fail", "A model that cannot fail is not evidence"),
    ("discovery 5: what each model omits", "Say what each model omits"),
    ("discovery 6: a wrong report", "A wrong report is a valid result"),
    ("discovery 7: what blocks readiness", "What blocks readiness blocks GO"),
    ("delivery: short plain sentences", "short, plain sentences"),
    ("delivery: the KB field", "The `KB:` field tells the human where the evidence lives"),
    ("delivery: the Signals field", "The `Signals:` field compares the work with"),
    ("delivery: none in an empty field", "Write \"none\" in an empty field"),
    ("delivery: Open", "Keep `Open:` in the delivery"),
    ("delivery: a home that outlives the ticket", "give it a home that outlives the ticket"),
    ("delivery: you propose, a human ratifies", "a human ratifies it"),
    ("delivery: land when safe", "Stop for the human first"),
    ("delivery: only the human may skip", "Only the human may skip work"),
    ("delivery: a waiver is not fulfilled", "It is not fulfilled either"),
    ("delivery: list every waiver", "List every waiver in the delivery"),
]


def norm(s):
    return " ".join(s.split())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("prompt", nargs="?", default=os.path.join(ROOT, "prompt/SAGITTARIUS.md"))
    ap.add_argument("--only", choices=["c1", "c3"])
    a = ap.parse_args()
    text = open(a.prompt, encoding="utf-8").read()
    flat = norm(text)
    padded = "\n" + text  # a heading on the first line still has its newline before it
    ok = True

    if a.only in (None, "c1"):
        bad = []
        n = len(text.splitlines())
        for item, phrases in REQUIRED:
            for p in phrases:
                if (p in padded) if p.startswith("\n") else (norm(p) in flat):
                    continue
                bad.append(f"{item}: missing {p.strip()!r}")
        for f in FORBIDDEN:
            if f in text:
                bad.append(f"names {f!r}, which T03 removes")
        if bad:
            ok = False
            print(f"c1 FAIL ({a.prompt}, {n} lines)")
            for b in bad:
                print("  " + b)
        else:
            print(f"c1 PASS: {n} lines, every required item stated")

    if a.only in (None, "c3"):
        bad = [f"{name}: missing {phrase!r}" for name, phrase in RULES if norm(phrase) not in flat]
        if bad:
            ok = False
            print(f"c3 FAIL: {len(bad)} of {len(RULES)} rules")
            for b in bad:
                print("  " + b)
        else:
            print(f"c3 PASS: {len(RULES)} rules held, one key phrase each")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
