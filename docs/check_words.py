#!/usr/bin/env python3
"""T29 checks of the words: one check per claim c1-c3 (grep-level tests of the named files).

c1 (u47, d_formal_substrate): the prompt and PHILOSOPHY drop "Show the human concrete examples and
   results, not formal text", and say: examples first; when the work has shifted up, the human
   reads and reviews the formal text too, so write it to be read.
   T31 c8 (u47) strengthens it: the human, the agent and the CPU all use the formal language as the
   shared substrate, and the human reads, reviews and understands it.
c2 (u57, u90, d_err_soft, d_oscillate): the hypothesis paragraph of the prompt says to err toward
   the general and soft, and to step just past the boundary on purpose before formalizing; and
   the protocol table of PHILOSOPHY ("## The protocol", Philosophy 3.0.0) and the "## " sections
   of the prompt stay in step: each section that a row names exists, and each section is named
   (see the comment above c2 for the exact rule).
c3 (u08, u37): README and PHILOSOPHY state the position: an extension of the harness between the
   human-agent interface and the software factory; an inference, reasoning and knowledge-graph
   layer.

Usage: python3 docs/check_words.py [c1 c2 c3]      Exit 0: pass. 1: fail.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def read(path):
    with open(os.path.join(ROOT, path), encoding="utf-8") as f:
        return f.read()


def flat(text):
    return re.sub(r"\s+", " ", text).lower()


def block(text, start, end):
    i = text.index(start)
    j = text.find(end, i + len(start))
    return text[i:] if j < 0 else text[i:j]


# ---------------------------------------------------------------- c1
def c1():
    bad = []
    for path in ("prompt/SAGITTARIUS.md", "docs/PHILOSOPHY.md"):
        t = flat(read(path))
        if "not formal text" in t:
            bad.append("%s still says 'not formal text'" % path)
        if not re.search(r"examples[^.]*\bfirst\b", t):
            bad.append("%s does not say examples first" % path)
        if not re.search(r"shifted up[^.]*the human, the agent,? and the cpu all use the formal language as the shared"
                         r" substrate[^.]*the human reads, reviews,? and understands it", t):
            bad.append("%s does not say that after a shift up the human, the agent and the CPU share the formal"
                       " language as the substrate, and the human reads, reviews and understands it (u47)" % path)
        if "write it to be read" not in t:
            bad.append("%s does not say 'write it to be read'" % path)
    return "; ".join(bad) or None


# ---------------------------------------------------------------- c2
# Philosophy 3.0.0 (review H-0129, step 4): the numbered principles and their "In the prompt:"
# lines are gone. The philosophy reflects itself into the prompt through the table of its section
# "## The protocol": one row per habit, and the last column ("In the prompt") names the sections
# of the prompt that hold the habit. c2 reads that table: it must have PROTOCOL_ROWS rows, numbered
# 1 to PROTOCOL_ROWS; each row names one section or more; each name is a "## " heading of the
# prompt; and each "## " heading of the prompt is named by one row or more.
PROTOCOL_ROWS = 27


def protocol_rows(phil):
    """[(number, [section names])] from the table under "## The protocol" of PHILOSOPHY."""
    m = re.search(r"^## The protocol\n(.*?)(?=^## |\Z)", phil, re.S | re.M)
    if not m:
        return None
    rows = []
    for line in m.group(1).splitlines():
        cells = [c.strip() for c in line.strip().strip("|").split("|")] if line.startswith("|") else []
        if len(cells) < 4 or not cells[0].isdigit():
            continue
        # a name in quotes is a section; other words in the cell ("and each example") are remarks
        rows.append((int(cells[0]), re.findall(r'"([^"]+)"', cells[-1])))
    return rows


def c2():
    bad = []
    prompt = read("prompt/SAGITTARIUS.md")
    hyp = flat(block(prompt, "\n## The hypothesis\n", "\n## Signals\n"))
    if not re.search(r"\berr\b[^.]*general[^.]*soft|\berr\b[^.]*soft[^.]*general", hyp):
        bad.append("the hypothesis paragraph of the prompt does not say to err toward the general and soft")
    if not re.search(r"\berr\b[^.]*\bhypotheses\b[^.]*\bpremises\b[^.]*\bclaims\b", hyp):
        bad.append("the hypothesis paragraph of the prompt does not name hypotheses, premises and claims for err-soft (u57)")
    if "oscillation is an intentional heuristic" not in hyp:
        bad.append("the hypothesis paragraph of the prompt does not say 'oscillation is an intentional heuristic' (u57)")
    if not re.search(r"just past the boundary[^.]*formaliz|formaliz[^.]*just past the boundary", hyp):
        bad.append("the hypothesis paragraph of the prompt does not say to step just past the boundary before formalizing")
    if "on purpose" not in hyp:
        bad.append("the hypothesis paragraph of the prompt does not say 'on purpose'")
    headings = re.findall(r"^## (.+?)\s*$", prompt, re.M)
    rows = protocol_rows(read("docs/PHILOSOPHY.md"))
    if rows is None:
        bad.append("PHILOSOPHY has no section '## The protocol'")
        rows = []
    nums = [n for n, _ in rows]
    if nums != list(range(1, PROTOCOL_ROWS + 1)):
        bad.append("the protocol table has rows %s, want 1 to %d in order" % (nums, PROTOCOL_ROWS))
    named = set()
    for n, names in rows:
        if not names:
            bad.append("protocol row %d names no section of the prompt" % n)
        for name in names:
            named.add(name)
            if name not in headings:
                bad.append("protocol row %d names \"%s\", which is not a '## ' heading of the prompt" % (n, name))
    for h in headings:
        if h not in named:
            bad.append("the prompt section \"%s\" is named by no row of the protocol table" % h)
    return "; ".join(bad) or None


# ---------------------------------------------------------------- c3
def c3():
    bad = []
    for path in ("README.md", "docs/PHILOSOPHY.md"):
        t = flat(read(path))
        m = re.search(r"[^.]*\bextension\b[^.]*\bharness\b[^.]*\.", t)
        if not m:
            bad.append("%s does not call it an extension of the harness" % path)
        elif "software factory" not in m.group(0) or not re.search(r"human.agent", m.group(0)):
            bad.append("%s: the extension sentence does not place it between the human-agent interface and the software factory: %r" % (path, m.group(0)))
        if not re.search(r"inference, reasoning,? and knowledge.graph layer", t):
            bad.append("%s does not say 'an inference, reasoning and knowledge-graph layer'" % path)
    return "; ".join(bad) or None


CHECKS = {"c1": c1, "c2": c2, "c3": c3}

if __name__ == "__main__":
    if sys.argv[1:] == ["--list"]:
        print("\n".join(CHECKS))
        sys.exit(0)
    only = [a for a in sys.argv[1:] if a in CHECKS] or list(CHECKS)
    nbad = 0
    for k in only:
        err = CHECKS[k]()
        print("%s %s%s" % (k, "PASS" if err is None else "FAIL", "" if err is None else ": " + err))
        nbad += err is not None
    sys.exit(1 if nbad else 0)
