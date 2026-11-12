#!/usr/bin/env python3
"""T17 consistency checks: one check per claim (c1-c7, c9). Each is a grep-level test that
the named files agree. c8 (hubkit names the project KB) waits for ticket T06 and has no check.

Usage: python3 docs/check_consistency.py [c1 ... c9]
(0.3.0: a missing heading is a FAIL of its claim, never a stop; the later claims still run.)
Exit 0: pass. Exit 1: fail.
"""
import json
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


def c1():
    prompt = read("prompt/SAGITTARIUS.md")
    signals = block(prompt, "\n## Signals\n", "\n## One response\n")
    bullets = re.findall(r"^- \*\*([^*]+)\*\*", signals, re.M)
    if len(bullets) != 6:
        return "the list under Signals has %d signals, not 6" % len(bullets)
    if "effort" not in bullets[-1].lower():
        return "the last signal under Signals is not Effort"
    trig = flat(block(prompt, "Signals:     <", "Claims:"))
    for word in ["questions", "divergence", "someone else built", "burns", "handoff", "effort"]:
        if word not in trig:
            return "the Signals line of the delivery block lacks %r" % word
    phil = read("docs/PHILOSOPHY.md")
    para = flat(block(phil, "Most work needs little process", "\n\n"))
    if "effort" not in para:
        return "PHILOSOPHY principle 7 does not list effort with the other signals"
    return None


def c2():
    prompt = flat(read("prompt/SAGITTARIUS.md"))
    if "no party grades its own work" not in prompt:
        return "SAGITTARIUS.md lost the no-self-grading rule"
    panes = read("prompt/PANES.md")
    disc = read("prompt/panes/discovery.md")
    mj = flat(block(panes, "- Each handoff is a make/judge split", "- Stay in your role"))
    ph = flat(block(disc, "- **Phases:**", "- **Receives:**"))
    for name, text in (("PANES.md", mj), ("panes/discovery.md", ph)):
        if "specify judges" in text:
            return "%s says specify judges research (one pane would judge itself)" % name
        if "human vote" not in text or "formal artifacts" not in text:
            return "%s does not say that the human vote and the formal artifacts judge research" % name
    return None


def c3():
    disc = read("prompt/panes/discovery.md")
    gives = flat(block(disc, "- **Gives:**", "Rules:"))
    for word in ["orbit-kb help discovery", "gate", "subject", "ticket", "approval"]:
        if word not in gives:
            return "the GO handoff in panes/discovery.md lacks %r" % word
    return None


def c4():
    prompt = read("prompt/SAGITTARIUS.md")
    # 0.3.0: the prompt holds no panes (a workspace names its own routing). The prompt sends a
    # report to discovery; PANES.md (the hub's text) holds the route through review and intake.
    scope = flat(block(prompt, "\n## Scope\n", "\nClarity decides"))
    rep = re.search(r"- a report.*?(?=\n- |\Z)", scope, re.S)
    if not rep:
        return "the report bullet in Scope is missing"
    if "discovery" not in rep.group(0):
        return "the report bullet in Scope does not send a report to discovery"
    panes = flat(read("prompt/PANES.md"))
    for word in ["review", "intake", "discovery", "report"]:
        if word not in panes:
            return "PANES.md (the route of a report) lacks %r" % word
    return None


def c5():
    seed = json.loads(read("hubkit/hub/flow/seed.json"))
    has_review = any(s.get("role") == "review" for s in seed["sessions"])
    ins = flat(read("hubkit/INSTRUCTIONS.md"))
    says_example = re.search(r"not the (sagittarius )?pane set", ins)
    if not (has_review or says_example):
        return "seed.json roles lack review and INSTRUCTIONS.md does not say they are not the pane set"
    ex = flat(block(read("hubkit/INSTRUCTIONS.md"), "5. **A few named", "## The kit"))
    if "review" not in ex and "not the" not in ex:
        return "INSTRUCTIONS.md principle 5 example roles omit review and do not say they are not the pane set"
    return None


def c6():
    phil = read("docs/PHILOSOPHY.md")
    if "evals/refining.md" in phil.lower().replace("docs/refining.md", ""):
        return "PHILOSOPHY.md cites evals/REFINING.md (the file is docs/REFINING.md)"
    if not os.path.exists(os.path.join(ROOT, "docs/REFINING.md")):
        return "docs/REFINING.md is missing"
    core = read("kb/share/orbit-kb/core.pl")
    if "depends/2" in core:
        return "core.pl still mentions depends/2"
    prompt = read("prompt/SAGITTARIUS.md")
    m = re.search(r"docs/PHILOSOPHY\.md`? *\(([^)]*)\)", prompt)
    if m:
        heads = re.findall(r"^#+ (.*)$", phil, re.M)
        if not any(m.group(1).strip().lower() in h.lower() for h in heads):
            return "the parenthesis after docs/PHILOSOPHY.md in SAGITTARIUS.md (%r) names no section" % m.group(1)
    return None


def c7():
    readme = read("README.md")
    layout = block(readme, "## Layout", "## History")
    rows = {}
    for d in ["s1", "hubkit", "docs"]:
        m = re.search(r"^\| `%s/` \|(.*)$" % d, layout, re.M)
        if not m:
            return "README.md Layout table has no row for %s/" % d
        rows[d] = flat(m.group(1))
    if "manual" not in rows["s1"] or "approved" not in rows["s1"]:
        return "the s1/ row does not say manual install and off until the question set is approved"
    s1 = read("s1/README.md")
    if "/home/" in s1:
        return "s1/README.md has a hard-coded /home/ path"
    if "/path/to/sagittarius" not in s1:
        return "s1/README.md has no path placeholder"
    return None


def c8():
    text = flat(read("hubkit/INSTRUCTIONS.md") + " " + read("hubkit/README.md"))
    for need in ["project-kb/", "orbit-kb init project-kb --request", "orbit-kb help project"]:
        if need not in text:
            return "hubkit/INSTRUCTIONS.md and README.md do not name the project KB: missing %r" % need
    return None


def c9():
    hk = read("hubkit/README.md")
    words = {"two": 2, "three": 3, "four": 4, "five": 5}
    m = re.search(r"It has (\w+) ideas:\n\n((?:- .*\n(?:  .*\n)*)+)", hk)
    if not m:
        return "hubkit/README.md lost its ideas list"
    n = len(re.findall(r"^- ", m.group(2), re.M))
    if words.get(m.group(1)) != n:
        return "hubkit/README.md says %s ideas but lists %d" % (m.group(1), n)
    win = flat(block(read("prompt/SAGITTARIUS.md"), "\n## The vote\n", "Seal your vote"))
    if "more than 0.5, so the human and at least one other" not in win:
        return "the win rule in SAGITTARIUS.md lacks 'more than 0.5, so the human and at least one other'"
    return None


CHECKS = {"c1": c1, "c2": c2, "c3": c3, "c4": c4, "c5": c5, "c6": c6, "c7": c7, "c8": c8, "c9": c9}

if __name__ == "__main__":
    only = [a for a in sys.argv[1:] if a in CHECKS] or list(CHECKS)
    bad = 0
    for k in only:
        try:
            err = CHECKS[k]()
        except Exception as e:  # a missing anchor is a failure of that claim; the next claim still runs
            err = "%s: %s (an anchor of the check is gone from the files)" % (type(e).__name__, e)
        print("%s %s%s" % (k, "PASS" if err is None else "FAIL", "" if err is None else ": " + err))
        bad += err is not None
    sys.exit(1 if bad else 0)
