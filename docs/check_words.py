#!/usr/bin/env python3
"""T29 checks of the words: one check per claim c1-c3 (grep-level tests of the named files).

c1 (u47, d_formal_substrate): the prompt and PHILOSOPHY drop "Show the human concrete examples and
   results, not formal text", and say: examples first; when the work has shifted up, the human
   reads and reviews the formal text too, so write it to be read.
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
        if not re.search(r"shifted up[^.]*reads and reviews the formal text", t):
            bad.append("%s does not say that after a shift up the human reads and reviews the formal text" % path)
        if "write it to be read" not in t:
            bad.append("%s does not say 'write it to be read'" % path)
    return "; ".join(bad) or None


# ---------------------------------------------------------------- c2
# APPLIED[principle][target] = the regexes (case-insensitive, over flattened text) that the
# target must match for the "Applied in" line to be true. Target keys:
#   prompt:SECTION   the text of "## SECTION" in prompt/SAGITTARIUS.md, up to the next "## "
#   help:TOPIC       kb/share/orbit-kb/help/TOPIC.txt
#   file:PATH        the file at PATH
#   slide:N          slide sN of site/index.html
APPLIED = {
    1: {"prompt:Roles": [r"human owns the intent"],
        "prompt:The phase tree": [r"against the human's vote"],
        "help:discovery": [r"\bgate\b"]},
    2: {"prompt:Purpose": [r"the goal is alignment"]},
    3: {"prompt:The phase tree": [r"parallax"],
        "prompt:Roles": [r"no party grades its own work"],
        "prompt:Delivery": [r"how it was verified"]},
    4: {"prompt:The phase tree": [r"goes back to the source"],
        "help:discovery": [r"\bspectrum\b"]},
    5: {"prompt:The phase tree": [r"few assumptions", r"\bsoft\b", r"general", r"just past the boundary",
                                  r"formaliz"]},
    6: {"prompt:The phase tree": [r"quiet failures"],
        "prompt:Start light": [r"must fail before the change"]},
    7: {"prompt:Start light": [r"start light"],
        "prompt:When to shift up": [r"leaning back", r"effort"],
        "file:s1/hook.py": [r"effort"],
        "slide:12": [r"tiers"],
        "slide:30": [r"signal"]},
    8: {"prompt:Purpose": [r"speed never comes from hiding"],
        "prompt:Delivery": [r"waiver"]},
    9: {"prompt:Honesty rules": [r"match your words to your evidence", r"in discovery"]},
    10: {"prompt:Honesty rules": [r"none stops cheating"],
         "prompt:Where the procedure is": [r"never type a digest"],
         "help:core": [r"never type a digest"]},
    11: {"prompt:When to shift up": [r"a claim that burns"],
         "help:discovery": [r"\bspectrum\b"],
         "slide:14": [r"lean", r"prolog"]},
    12: {"prompt:Where the procedure is": [r"do not rely on what you remember"],
         "prompt:When to shift up": [r"a handoff"],
         "help:build": [r"supersedes a burning claim needs its own proof"]},
    13: {"prompt:When the human says that it is wrong": [r"examples of the meaning, not phrases to match"],
         "help:discovery": [r"\bsignal\b"]},
    14: {"file:docs/REFINING.md": [r"held-out"]},
}


def applied_lines(phil):
    """{principle number: the text of its "Applied in:" paragraph}."""
    out = {}
    for m in re.finditer(r"^### (\d+)\. .*?(?=^### |^## )", phil, re.S | re.M):
        n = int(m.group(1))
        a = re.search(r"^Applied in:(.*?)(?:\n\n|\Z)", m.group(0), re.S | re.M)
        if a:
            out[n] = re.sub(r"\s+", " ", a.group(1)).strip()
    return out


def targets(line):
    """The target keys that one "Applied in" paragraph names."""
    keys = []
    # cut the trailing remark (". The exact definition is open ...") off the list
    line = re.split(r"\.\s+[A-Z]", line)[0]
    for part in line.split(";"):
        part = part.strip()
        if part.startswith("prompt"):
            for name in re.findall(r'"([^"]+)"', part):
                keys.append("prompt:" + name)
        for topic in re.findall(r"`orbit-kb help (\w+)`", part):
            keys.append("help:" + topic)
        for path in re.findall(r"`([\w./-]+\.(?:py|md|sh|html))`", part):
            keys.append("file:" + path)
        if "slide" in part:
            for n in re.findall(r"\b(\d+)\b", part):
                keys.append("slide:" + n)
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
    if kind == "slide":
        page = read("site/index.html")
        m = re.search(r'<section class="slide" id="s%s"[^>]*>(.*?)</section>' % name, page, re.S)
        return re.sub(r"<[^>]+>", " ", m.group(1)) if m else None
    return None


def c2():
    bad = []
    prompt = read("prompt/SAGITTARIUS.md")
    hyp = flat(block(prompt, "**The hypothesis.**", "**The vote.**"))
    if not re.search(r"\berr\b[^.]*general[^.]*soft|\berr\b[^.]*soft[^.]*general", hyp):
        bad.append("the hypothesis paragraph of the prompt does not say to err toward the general and soft")
    if not re.search(r"just past the boundary[^.]*formaliz|formaliz[^.]*just past the boundary", hyp):
        bad.append("the hypothesis paragraph of the prompt does not say to step just past the boundary before formalizing")
    if "on purpose" not in hyp:
        bad.append("the hypothesis paragraph of the prompt does not say 'on purpose'")
    lines = applied_lines(read("docs/PHILOSOPHY.md"))
    if len(lines) < 14:
        bad.append("PHILOSOPHY has %d Applied in lines, the check reads too few (want 14)" % len(lines))
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
                bad.append("principle %d: the table names %s, but the Applied in line does not" % (n, key))
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
    only = [a for a in sys.argv[1:] if a in CHECKS] or list(CHECKS)
    nbad = 0
    for k in only:
        err = CHECKS[k]()
        print("%s %s%s" % (k, "PASS" if err is None else "FAIL", "" if err is None else ": " + err))
        nbad += err is not None
    sys.exit(1 if nbad else 0)
