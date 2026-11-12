#!/usr/bin/env python3
"""T29 checks of the words: one check per claim c1-c3 (grep-level tests of the named files).

c1 (u47, d_formal_substrate): the prompt and PHILOSOPHY drop "Show the human concrete examples and
   results, not formal text", and say: examples first; when the work has shifted up, the human
   reads and reviews the formal text too, so write it to be read.
   T31 c8 (u47) strengthens it: the human, the agent and the CPU all use the formal language as the
   shared substrate, and the human reads, reviews and understands it.
c2 (u57, u90, d_err_soft, d_oscillate): the hypothesis paragraph of the prompt says to err toward
   the general and soft, and to step just past the boundary on purpose before formalizing; and
   every "Applied in" line of PHILOSOPHY is true: each target it names exists, and grepping the
   target finds the principle (the table APPLIED below). A target that the table does not know,
   or a table row that no line names, is a failure too, so the table and the lines stay in step.
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
# APPLIED[principle][target] = the regexes (case-insensitive, over flattened text) that the
# target must match for the "In the prompt:" line of the principle to be true. Target keys:
#   prompt:SECTION   the text of "## SECTION" in prompt/SAGITTARIUS.md, up to the next "## "
#   help:TOPIC       kb/share/orbit-kb/help/TOPIC.txt
#   file:PATH        the file at PATH
# Sagittarius 0.3.0 / Philosophy 2.0.0: principles are "#### N." headings, and each ends with a
# line "In the prompt: ..." (or "In the repository: ..." for principle 14). The check also holds
# that every section the line names exists in the prompt.
APPLIED = {
    1: {"prompt:The orbit": [r"human's judgment"],
        "prompt:Who judges what": [r"human\*\* owns the intent"],
        "prompt:The vote": [r"the human 0\.49"]},
    2: {"prompt:The light path": [r"must fail before the change"],
        "prompt:The hypothesis": [r"closest statement of the intent"]},
    3: {"prompt:Signals": [r"a handoff"],
        "prompt:One response": [r"third step of the orbit"],
        "prompt:When the human says that it is wrong": [r"kept"],
        "prompt:Delivery": [r"each \"yes\" and what fired it|what fired it"],
        "prompt:The tool": [r"do not rely on what you remember"]},
    4: {"prompt:Who judges what": [r"no party grades its own work"],
        "prompt:One response": [r"system 1"]},
    5: {"prompt:The idea": [r"orbit it"],
        "prompt:The orbit": [r"write it from the source"],
        "prompt:The light path": [r"\bexample\b"]},
    6: {"prompt:Who judges what": [r"the human reads it|the human judges meaning"],
        "prompt:Delivery": [r"formal:"]},
    7: {"prompt:Honesty": [r"none stops cheating"],
        "prompt:The tool": [r"never type a digest"]},
    8: {"prompt:The idea": [r"quiet failure", r"divergence"],
        "prompt:Signals": [r"a divergence"],
        "prompt:The light path": [r"must fail before the change"]},
    9: {"prompt:Honesty": [r"match your words to your evidence", r"in discovery"]},
    10: {"prompt:The light path": [r"add rigor only on a signal"],
         "prompt:Signals": [r"effort"],
         "prompt:One response": [r"every signal gets the same response"]},
    11: {"prompt:Signals": [r"a claim that burns"],
         "prompt:One response": [r"one lens at a time"]},
    12: {"prompt:The orbit": [r"speed never comes from hiding"],
         "prompt:Delivery": [r"waiver"]},
    13: {"prompt:When the human says that it is wrong": [r"examples of the meaning, not phrases to match"],
         "prompt:The hypothesis": [r"example"]},
    14: {"file:docs/REFINING.md": [r"held-out"]},
}


def applied_lines(phil):
    """{principle number: the text of its "In the prompt:" / "In the repository:" paragraph}."""
    out = {}
    for m in re.finditer(r"^#### (\d+)\. .*?(?=^#### |^### |^## |\Z)", phil, re.S | re.M):
        n = int(m.group(1))
        a = re.search(r"^In the (?:prompt|repository):(.*?)(?:\n\n|\Z)", m.group(0), re.S | re.M)
        if a:
            out[n] = ("prompt:" if "In the prompt:" in a.group(0) else "repository:") + re.sub(r"\s+", " ", a.group(1)).strip()
    return out


def targets(line):
    """The target keys that one "In the prompt:" paragraph names."""
    keys = []
    kind, _, line = line.partition(":")
    if kind == "prompt":
        # a name in quotes is a section; a parenthesis after it is a remark, not a name
        for name in re.findall(r'"([^"]+)"', line):
            keys.append("prompt:" + name)
    for topic in re.findall(r"`orbit-kb help (\w+)`", line):
        keys.append("help:" + topic)
    for path in re.findall(r"`([\w./-]+\.(?:py|md|sh|html))`", line):
        keys.append("file:" + path)
    return keys


def target_text(key):
    kind, name = key.split(":", 1)
    if kind == "prompt":
        prompt = read("prompt/SAGITTARIUS.md")
        m = re.search(r"^## %s\n(.*?)(?=^## |\Z)" % re.escape(name), prompt, re.S | re.M)
        return m.group(1) if m else None
    if kind == "help":
        p = os.path.join(ROOT, "kb/share/orbit-kb/help", name + ".txt")
        return read(os.path.relpath(p, ROOT)) if os.path.exists(p) else None
    if kind == "file":
        return read(name) if os.path.exists(os.path.join(ROOT, name)) else None
    return None


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
    lines = applied_lines(read("docs/PHILOSOPHY.md"))
    if len(lines) < 14:
        bad.append("PHILOSOPHY has %d In-the-prompt lines, the check reads too few (want 14)" % len(lines))
    for n, line in sorted(lines.items()):
        keys = targets(line)
        if not keys:
            bad.append("principle %d: no target read from %r" % (n, line))
        want = APPLIED.get(n, {})
        for key in keys:
            if key not in want:
                bad.append("principle %d: the target %s is not in the table of check_words.py" % (n, key))
                continue
            text = target_text(key)
            if text is None:
                bad.append("principle %d: the target %s does not exist" % (n, key))
                continue
            for rx in want[key]:
                if not re.search(rx, flat(text)):
                    bad.append("principle %d: the target %s lacks /%s/" % (n, key, rx))
        for key in want:
            if key not in keys:
                bad.append("principle %d: the table names %s, but the In the prompt line does not" % (n, key))
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
