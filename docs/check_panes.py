#!/usr/bin/env python3
"""T09 c1, c2, c3 and the review-rule check for the pane prompts.

c1: each pane prompt names its phases (discovery: research, specify; build: build; review: verify,
    intake), a line that starts "Receives:" and one that starts "Gives:" (after list marker and
    bold marks), and the make/judge split (the words "make" and "judge"). No pane cites the
    removed "Discovery orbit" section.
c2: PANES.md states the path "research -> specify -> build -> verify".
c3: each pane prompt (PANES.md and panes/*.md) has fewer than 60 lines.
rules: every rule of the old review.md is still in the new one: one key phrase per rule, matched
    after whitespace is collapsed and case is ignored. A rule that is shortened must be listed
    by the person who shortens it in the report; the phrase here stays.

Usage: python3 docs/check_panes.py [--only c1|c2|c3|rules]
Exit 0: pass. Exit 1: fail.
"""
import argparse
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAX_LINES = 60
PANES = {"discovery": ["research", "specify"], "build": ["build"], "review": ["verify", "intake"]}

REVIEW_RULES = [
    "regression", "behavior worked before", "gap", "never existed",
    "reproduce the report", "last worked", "do not guess",
    "orbit-kb init dir --request-file f --uses discovery", "word for word",
    "`world` facts", "send the kb path to **discovery**",
    "do not write the hypothesis or the ticket", "do not plan the fix",
    "fresh eyes", "do not fix the work",
    "judge against the request", "the time in uat",
    "date when the implementation reached uat", "ask the human",
    "long use in uat with no report", "short time in uat is little evidence",
    "passing checks are not time in use", "not in uat yet has no time in use",
    "give the date, the length of time, and where you found the date",
    "read only the request, the kb, and the diff",
    "do not take another pane's reasoning", "do not ask build how it reasoned",
    "run every check again yourself with `orbit-kb run`",
    "contradicts a report is a divergence", "record it on the claim",
    "`under(c)`, `over(x)`, and `to_ask(q)`", "no claim covers",
    "run disprove on each claim", "other inputs, boundaries, orders of steps, and old data",
    "one verdict for each claim", "not there yet",
    "evals cost much", "only when the human asks", "cases that the human names",
    "docs/refining.md", "tell the human in one line", "what you did not check",
    # review of 0.3.0 (finding 11; claim c_m_f_2): the evidence that does not decide is still given,
    # and the return to build is a handoff that releases the KB
    "give what you found", "return the work to build as a handoff", "run `orbit-kb release`",
]


def read(rel):
    with open(os.path.join(ROOT, rel), encoding="utf-8") as f:
        return f.read()


def norm(s):
    return " ".join(s.lower().split())


def has_label(text, label):
    pat = re.compile(r"^\s*(?:[-*]\s+)?(?:\*\*)?" + label + r":(?:\*\*)?", re.M | re.I)
    return bool(pat.search(text))


def c1():
    bad = []
    for pane, phases in PANES.items():
        t = read(f"prompt/panes/{pane}.md")
        n = norm(t)
        for p in phases:
            if not re.search(r"\b" + p + r"\b", n):
                bad.append(f"{pane}: phase '{p}' not named")
        for label in ("Receives", "Gives"):
            if not has_label(t, label):
                bad.append(f"{pane}: no '{label}:' line")
        for w in ("make", "judge"):
            if not re.search(r"\b" + w + r"\b", n):
                bad.append(f"{pane}: make/judge split missing ('{w}')")
        if "discovery orbit\"" in n or "\"discovery orbit" in n:
            bad.append(f"{pane}: cites the removed 'Discovery orbit' section")
    return bad


def c2():
    n = norm(read("prompt/PANES.md"))
    return [] if "research -> specify -> build -> verify" in n else [
        "PANES.md lacks 'research -> specify -> build -> verify'"]


def c3():
    files = ["prompt/PANES.md"] + [f"prompt/panes/{p}.md" for p in PANES]
    out = []
    for f in files:
        k = len(read(f).splitlines())
        if k >= MAX_LINES:
            out.append(f"{f}: {k} lines (limit: under {MAX_LINES})")
    return out


def rules():
    n = norm(read("prompt/panes/review.md"))
    return [f"review.md lost rule phrase: {r!r}" for r in REVIEW_RULES if norm(r) not in n]


CHECKS = {"c1": c1, "c2": c2, "c3": c3, "rules": rules}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", choices=CHECKS)
    a = ap.parse_args()
    fail = False
    for name, fn in CHECKS.items():
        if a.only and a.only != name:
            continue
        bad = fn()
        print(f"{name}: {'FAIL' if bad else 'ok'}")
        for b in bad:
            print("  " + b)
        fail = fail or bool(bad)
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main())
