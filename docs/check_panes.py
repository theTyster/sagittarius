#!/usr/bin/env python3
"""T09 c1, c2, c3 and the review-rule check for the pane prompts.

c1: each pane prompt names its phases (discovery: research, specify; build: build; review: verify,
    intake), a line that starts "Receives:" and one that starts "Gives:" (after list marker and
    bold marks), and the make/judge split (the words "make" and "judge"). No pane cites the
    removed "Discovery orbit" section.
c2: PANES.md states the path "research -> specify -> build -> verify".
c3: each pane prompt (PANES.md and panes/*.md) has fewer than 66 lines, not counting the generated
    vocabulary block of PANES.md (60 before 0.8.0; scientific-method-overhaul c12 and c15 add text).
c4: (0.3.0 M-E; 0.8.0 c14) for a change request the build pane opens the ticket with the goal and a
    hypothesis: the human's own word for word, or its own, marked "(mine)": what the human wants, wide,
    with its premises, and goes on. A hub has a light path: the build pane delivers a
    clear change with no signal with its check, no KB and no review; a signal brings the KB and the
    review pane; review also comes in when the human asks. Both HUB-CORE.md files name the light
    path. The old sentences ("You do not decide what the problem is", "Do not tell the human that
    the work is done until review has reported") are gone.
c5: (0.8.0, scientific-method-overhaul c15; it replaces the 0.3.0 rule M-A, under which build restated the
    hypothesis) review records each experiment result and each judgment of the human; build fixes a
    conflict that is located in the build; a defeated hypothesis goes to discovery, which re-evaluates
    the goal, the premises and the measurement, and tempers a new one; the pane that hears a corrected
    goal records it in the words of the human; no pane text tells build to restate a hypothesis.
rules: every rule of the old review.md is still in the new one: one key phrase per rule, matched
    after whitespace is collapsed and case is ignored. A rule that is shortened must be listed
    by the person who shortens it in the report; the phrase here stays.

Usage: python3 docs/check_panes.py [--only c1|c2|c3|c4|c5|rules]
Exit 0: pass. Exit 1: fail.
"""
import argparse
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAX_LINES = 66  # 60 before 0.8.0; c15 adds rules to review.md (65 lines). The generated vocabulary block is not counted.
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
        k = len(re.sub(r"<!-- vocabulary:begin -->.*?<!-- vocabulary:end -->\n", "", read(f), flags=re.S).splitlines())
        if k >= MAX_LINES:
            out.append(f"{f}: {k} lines (limit: under {MAX_LINES})")
    return out


HUB_CORES = ("hubkit/hub/HUB-CORE.md", "hubkit/editions/informal/HUB-CORE.md")


def bullet(text, rx):
    """The rule bullets (collapsed, lower case) of TEXT that match RX."""
    items = re.split(r"\n(?=- )", text)
    return [norm(i) for i in items if re.search(rx, norm(i))]


def c4():
    b = read("prompt/panes/build.md")
    n = norm(b)
    out = []
    # 0.8.0 (scientific-method-overhaul c14): the rule opens the ticket with the goal and a hypothesis; the
    # human's own are recorded as the human's, and a plain request gets both from build, marked "(mine)".
    hyp = bullet(b, r"change request.*state the goal and one hypothesis yourself")
    if not hyp:
        out.append("build.md: no rule that states the goal and a hypothesis of a change request")
    else:
        for w in ("what the human wants", "wide", "premises", "go on", "word for word as the human's",
                  "goal (mine)", "hypothesis (mine)", "case that would defeat"):
            if w not in hyp[0]:
                out.append(f"build.md: the hypothesis rule lacks {w!r}")
    lp = bullet(b, r"light path")
    if not lp:
        out.append("build.md: no light path rule")
    else:
        for w in ("no signal", "check", "no kb", "no review", "a signal", "review pane", "the human asks"):
            if w not in lp[0]:
                out.append(f"build.md: the light path rule lacks {w!r}")
    for old in ("you do not decide what the problem is", "do not tell the human that the work is done until review has reported"):
        if old in n:
            out.append(f"build.md still says {old!r}")
    for f in HUB_CORES:
        t = norm(read(f))
        if "light path" not in t:
            out.append(f"{f}: does not name the light path")
        elif re.search(r"light path[^.]*(is not|not used|does not apply)", t):
            out.append(f"{f}: says that the light path does not apply")
    return out


def c5():
    """0.8.0 (scientific-method-overhaul c15, q12): build fixes a conflict that is located in the build; a defeated
    hypothesis goes to discovery, which re-evaluates and tempers a new one; review records results and judgments;
    the pane that hears a corrected goal records it. No text tells build to restate a hypothesis (the 0.3.0 rule
    M-A, which this check held before, is retired by c15)."""
    b, d, r, p = (read("prompt/panes/build.md"), read("prompt/panes/discovery.md"),
                  read("prompt/panes/review.md"), read("prompt/PANES.md"))
    nb, nd, nr, np_ = norm(b), norm(d), norm(r), norm(p)
    out = []
    fs = bullet(b, r"review's findings")
    if not fs or "fix a conflict that is located in the build" not in fs[0] or "hypothesis stays current" not in fs[0]:
        out.append("build.md: the rule on review's findings does not say that build fixes a conflict located in the build, and that the hypothesis stays current")
    elif "by your own word" not in fs[0]:
        out.append("build.md: the rule does not say that build cannot move a conflict out of the build by its own word")
    if not re.search(r"hypothesis that a located conflict or a judged case defeats goes to \*\*discovery\*\*", nb):
        out.append("build.md does not send a defeated hypothesis to **discovery**")
    gl = bullet(b, r"human corrects the goal")
    if not gl:
        out.append("build.md: no rule for a goal that the human corrects")
    else:
        for w in ("says what it changes to", "in the words of the human", "supersedes", "carry over", "go on", "cannot say", "**discovery**"):
            if w not in gl[0]:
                out.append(f"build.md: the goal rule lacks {w!r}")
    for f, t in (("PANES.md", np_), ("panes/build.md", nb), ("panes/discovery.md", nd), ("panes/review.md", nr)):
        if re.search(r"restates? (it|the hypothesis)|build restates", t):
            out.append(f"{f} tells a pane to restate a hypothesis (c15: a defeated hypothesis goes to discovery)")
    if not re.search(r"re-evaluate the goal, the premises and the measurement, and temper a new hypothesis", nd):
        out.append("discovery.md does not say: re-evaluate the goal, the premises and the measurement, and temper a new hypothesis")
    if "the case stays on the old hypothesis" not in nd:
        out.append("discovery.md does not keep the defeating case on the old hypothesis")
    for f, t in (("PANES.md", np_), ("panes/review.md", nr)):
        if not re.search(r"records? each experiment result and each judgment of the human on the ticket", t):
            out.append(f"{f} does not say that review records each experiment result and each judgment of the human")
    if not re.search(r"defeats the hypothesis, not the build.*hand the ticket to \*\*discovery\*\*", nr):
        out.append("review.md does not hand a defeated hypothesis to **discovery**")
    for w in ("locate first", "counts only when a pane that did not build confirms it", "fresh-eyes subagent",
              "the pane that hears it records the new goal in the words of the human, and carries over what still counts"):
        if w not in np_:
            out.append(f"PANES.md lacks {w!r}")
    return out


def rules():
    n = norm(read("prompt/panes/review.md"))
    return [f"review.md lost rule phrase: {r!r}" for r in REVIEW_RULES if norm(r) not in n]


CHECKS = {"c1": c1, "c2": c2, "c3": c3, "c4": c4, "c5": c5, "rules": rules}


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
