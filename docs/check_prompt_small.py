#!/usr/bin/env python3
"""T08 c1 and c3: the prompt is small, states what it must, and keeps the honesty and delivery rules.

c1: PROMPT has at most MAX_LINES lines (230, c6; was 200), and one key phrase for each required item (the purpose, the
    roles, the phase tree, when to shift up, the honesty rules, the delivery block, where the
    procedure is). It names nothing that T03 removes from orbit-kb (depends/2, declare-attest).
c3: every rule of the old prompt's "## Honesty rules" and "## Delivery", and rules 1 to 6 of
    "### Honesty rules for discovery", is in PROMPT after whitespace is collapsed. A rule is a
    paragraph, a numbered item, or a code block. A rule that is reworded must be listed in
    docs/PROMPT-MOVES.md between the c3-rewordings markers, as OLD:, NEW:, WHY: lines; then
    NEW must be in PROMPT, and WHY must not be empty.

Usage: python3 docs/check_prompt_small.py [PROMPT] [--old FILE] [--only c1|c3]
PROMPT defaults to prompt/SAGITTARIUS.md. --old defaults to `git show 7da5320:prompt/SAGITTARIUS.md`.
Exit 0: pass. Exit 1: fail.
"""
import argparse
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE = "7da5320"
# c6 supersedes c1@200: restoring the 9 rules that review found lost took the prompt to 209
# lines, so the limit is 230 (T08 c6). The phrase checks of c1 and c3 do not change.
MAX_LINES = 230

# (item, phrases): each phrase must be in the prompt (whitespace collapsed, case kept).
REQUIRED = [
    ("purpose", ["**Clear:**", "**Accurate:**", "**Honest:**", "**Fast:**"]),
    ("roles", ["## Roles"]),
    ("phase tree", ["## The phase tree", "research, specify", "build, verify"]),
    ("when to shift up", ["## When to shift up", "System 1", "effort or verbosity"]),
    ("honesty rules", ["## Honesty rules"]),
    ("delivery block", ["## Delivery", "Delivered:", "Not checked:"]),
    ("where the procedure is", ["orbit-kb help core", "orbit-kb help build",
                                "orbit-kb help discovery", "orbit-kb help codes",
                                "orbit-kb help answers"]),
]
FORBIDDEN = ["declare-attest", "depends/2", "depends("]


def norm(s):
    return " ".join(s.split())


def section(text, heading):
    lines = text.splitlines()
    level = len(heading) - len(heading.lstrip("#"))
    out, inside, fence = [], False, False
    for line in lines:
        if line.lstrip().startswith("```"):
            fence = not fence
        if not fence and re.match(r"^#{1,6} ", line):
            lv = len(line) - len(line.lstrip("#"))
            if inside and lv <= level:
                break
            if line.rstrip() == heading:
                inside = True
                continue
        if inside:
            out.append(line)
    return out


def rules(lines):
    """Paragraphs, numbered items, and code blocks of a section, each normalized."""
    out, cur, fence = [], [], False

    def flush():
        if cur:
            t = norm("\n".join(cur))
            t = re.sub(r"^\d+\. ", "", t)
            if t:
                out.append(t)
            cur.clear()

    for line in lines:
        if line.lstrip().startswith("```"):
            if not fence:
                flush()
                fence = True
                cur.append(line)
            else:
                cur.append(line)
                fence = False
                flush()
            continue
        if fence:
            cur.append(line)
        elif not line.strip():
            flush()
        elif re.match(r"^\d+\. ", line):
            flush()
            cur.append(line)
        else:
            cur.append(line)
    flush()
    return out


def rewordings():
    path = os.path.join(ROOT, "docs/PROMPT-MOVES.md")
    if not os.path.exists(path):
        return {}
    t = open(path, encoding="utf-8").read()
    m = re.search(r"<!-- c3-rewordings: begin -->(.*?)<!-- c3-rewordings: end -->", t, re.S)
    out = {}
    if not m:
        return out
    cur = {}
    for line in m.group(1).splitlines():
        for key in ("OLD", "NEW", "WHY"):
            if line.startswith(key + ":"):
                cur[key] = norm(line[len(key) + 1:])
        if all(k in cur for k in ("OLD", "NEW", "WHY")):
            out[cur["OLD"]] = (cur["NEW"], cur["WHY"])
            cur = {}
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("prompt", nargs="?", default=os.path.join(ROOT, "prompt/SAGITTARIUS.md"))
    ap.add_argument("--old")
    ap.add_argument("--only", choices=["c1", "c3"])
    a = ap.parse_args()
    text = open(a.prompt, encoding="utf-8").read()
    flat = norm(text)
    ok = True

    if a.only in (None, "c1"):
        bad = []
        n = len(text.splitlines())
        if n > MAX_LINES:
            bad.append(f"{n} lines; the limit is {MAX_LINES}")
        for item, phrases in REQUIRED:
            for p in phrases:
                if norm(p) not in flat:
                    bad.append(f"{item}: missing {p!r}")
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
        if a.old:
            old = open(a.old, encoding="utf-8").read()
        else:
            old = subprocess.run(["git", "-C", ROOT, "show", BASE + ":prompt/SAGITTARIUS.md"],
                                 capture_output=True, text=True, check=True).stdout
        want = rules(section(old, "## Honesty rules")) + rules(section(old, "## Delivery"))
        disc = rules(section(old, "### Honesty rules for discovery"))
        # Rule 7 names lint codes; it moves to orbit-kb help discovery (docs/PROMPT-MOVES.md).
        want += [r for r in disc if not r.startswith("What blocks `discovery_ready` blocks GO")]
        rw = rewordings()
        bad, reworded = [], 0
        for r in want:
            if r in flat:
                continue
            if r in rw:
                new, why = rw[r]
                if new in flat and why:
                    reworded += 1
                    continue
                bad.append(f"reworded, but NEW is not in the prompt or WHY is empty: {r[:70]}...")
                continue
            bad.append(f"missing or reworded with no entry: {r[:90]}...")
        if bad:
            ok = False
            print(f"c3 FAIL: {len(bad)} of {len(want)} rules")
            for b in bad:
                print("  " + b)
        else:
            print(f"c3 PASS: {len(want)} rules kept ({reworded} reworded, listed in docs/PROMPT-MOVES.md)")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
