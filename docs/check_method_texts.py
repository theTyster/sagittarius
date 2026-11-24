#!/usr/bin/env python3
"""scientific-method-overhaul: the phrase tests of the texts (they outlive the ticket).

Each id is one claim of the ticket. A phrase is matched after whitespace is collapsed.

  c7   the prompt names the three verdicts, and says what an unresolved verdict does
  c9   locate first: a conflict is located (build, measurement, premise, hypothesis) before anything is
       reopened; build keeps a conflict in the build; a location outside the build needs a party that
       did not build; the control needs no location; the old rule "the hypothesis is the law" is gone
  c10  two levels of judgment: verdicts on claims, the human on the goal; a case judged not wanted
       while every claim meets defeats the hypothesis, not the build; a ticket with a KB closes only
       on the judgment of the human, which never turns a verdict into meets
  c11  no shipped text holds the old definition (closest statement of the intent, law of its ticket)
  c13  formal language: the three moments, the one rule, no signal needed, one example can be enough,
       each formal statement records its claim and the decision that its precision could change;
       the prompt no longer says "and not before"
  c14  the opening rule: the human's goal and first hypothesis, sharpened or challenged at once; for a
       plain request the agent drafts both as its own and builds; it asks only when a wrong avenue is costly
  c15  the pane prompts: review records results and judgments; a defeated hypothesis goes to
       discovery, which re-evaluates and tempers a new one; build fixes a conflict located in the
       build; no text tells build to restate a hypothesis
  c16  Sound Basis in the words of Ty (2026-11-23), and what follows for a change that no claim names
  c45  the light path keeps at most 7 numbered Build steps and 4 Discovery steps, needs no KB, and
       asks for no adoption and no judgment

Usage: python3 docs/check_method_texts.py [--list] [ID ...]      Exit 0: pass. 1: fail. 2: usage.
"""
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROMPT = "prompt/SAGITTARIUS.md"
PANE_FILES = ["prompt/PANES.md", "prompt/panes/build.md", "prompt/panes/discovery.md", "prompt/panes/review.md"]
OLD = ["closest statement of the intent", "law of its ticket"]
SOUND_BASIS = ("Existing behavior is presumed to be preserved. A claim in the specification can identify "
               "behavior to change. A demonstrated conflict opens the affected behavior for review.")
RULE = "formalize the smallest claim whose precision could change what the human or the agent does next"


def read(rel):
    with open(os.path.join(ROOT, rel), encoding="utf-8") as f:
        return f.read()


def flat(rel):
    return " ".join(read(rel).split())


def need(rel, phrases):
    t = flat(rel)
    return [f"{rel}: missing {p!r}" for p in phrases if " ".join(p.split()) not in t]


def lack(rel, phrases):
    t = flat(rel).lower()
    return [f"{rel}: still says {p!r}" for p in phrases if p.lower() in t]


def c7():
    return need(PROMPT, ["**Meets:**", "**Conflicts:**", "**Unresolved:**", "it gives exactly one verdict",
                         "Say what could not be decided",
                         "An unresolved verdict fulfils nothing, defeats nothing, and keeps its claim open"])


def c9():
    return need(PROMPT, ["**Locate first.**", "Before you reopen anything, locate the conflict",
                         "In the build:", "In the measurement:", "In a premise or in the hypothesis:",
                         "The party that builds keeps a conflict in the build",
                         "A location outside the build counts only when a party that did not build confirms it",
                         "a fresh-eyes subagent", "The control needs no location"]) \
        + lack(PROMPT, ["the hypothesis is the law"])


def c10():
    return need(PROMPT, ["There are two levels of judgment", "Experiments give verdicts on claims",
                         "Verdicts are about claims. Only the human judges the goal",
                         "the case defeats the hypothesis that allowed it, not the build",
                         "closes only when nothing holds it up and the human judged that the goal is satisfied",
                         "That judgment never turns a conflicting, an unresolved, or a stale verdict into meets",
                         "A verdict counts only for the state that its experiment observed"])


def shipped():
    out = []
    for pat in ("prompt/**/*.md", "kb/share/**/*", "kb/bin/*", "kb/CONTRACT.md", "hubkit/**/*", "docs/PHILOSOPHY.md",
                "README.md", "s1/*.py", "s1/*.json", "s1/*.md"):
        out += [p for p in glob.glob(os.path.join(ROOT, pat), recursive=True)
                if os.path.isfile(p) and "/.lake/" not in p and "__pycache__" not in p]
    return sorted(set(out))


def c11():
    bad, n = [], 0
    for p in shipped():
        try:
            with open(p, encoding="utf-8") as f:
                lines = f.read().splitlines()
        except (UnicodeDecodeError, OSError):
            continue
        n += 1
        for i, ln in enumerate(lines, 1):
            for o in OLD:
                if o in ln:
                    bad.append(f"{os.path.relpath(p, ROOT)}:{i}: the old definition ({o!r})")
    if n < 20:
        bad.append(f"only {n} shipped texts were read: the check cannot hold the claim")
    return bad


def c13():
    return need(PROMPT, ["A formal statement needs no signal", "A formal language can enter at three moments",
                         "while forming the hypothesis", "while exploring interpretations",
                         "while verifying the chosen claim", RULE,
                         "the example is enough: write no formal statement",
                         "record the claim that it states and the decision that its precision could change"]) \
        + lack(PROMPT, ["and not before", "add rigor only on a signal"])


def c14():
    return need(PROMPT, ["A ticket opens with its goal and a first hypothesis",
                         "The human gives them: they are the human's",
                         "Keep the human's words, and sharpen or challenge them at once",
                         "Name the case that would defeat the hypothesis, or say that you find none",
                         "draft both from the request, say that they are yours",
                         '"Goal (mine): ... Hypothesis (mine): ..."',
                         "Ask for the human's own only when a wrong avenue is costly",
                         "You may explore other hypotheses inside the goal",
                         "Bring the human only the ones worth adopting, and each material tradeoff",
                         "A hypothesis that you wrote and that the human has not adopted is a guess",
                         '"(agent-written, not adopted)"']) \
        + lack(PROMPT, ["In build, you state it yourself, from the request"])


def c15():
    bad = []
    for rel in ("prompt/PANES.md", "prompt/panes/review.md"):
        if not re.search(r"records? each experiment result and each judgment of the human on the ticket", flat(rel), re.I):
            bad.append(f"{rel}: does not say that review records each experiment result and each judgment of the human")
    bad += need("prompt/panes/review.md", ["defeats the hypothesis, not the build", "hand the ticket to **discovery**"])
    bad += need("prompt/panes/discovery.md", ["Re-evaluate the goal, the premises and the measurement, and temper a new hypothesis",
                                             "The case stays on the old hypothesis"])
    bad += need("prompt/panes/build.md", ["Fix a conflict that is located in the build",
                                         "A hypothesis that a located conflict or a judged case defeats goes to **discovery**",
                                         "record the new goal in the words of the human"])
    bad += need("prompt/PANES.md", ["A hypothesis that a located conflict or a judged case defeats goes to discovery",
                                   "the pane that hears it records the new goal in the words of the human, and carries over what still counts"])
    for rel in PANE_FILES:
        if re.search(r"\b[Rr]estates?\b", flat(rel)):  # RESTATE is a move of discovery, not this
            bad.append(f"{rel}: tells a pane to restate (no text tells build to restate a hypothesis)")
    return bad


def c16():
    return need(PROMPT, ["**Sound Basis.**", SOUND_BASIS, "change only the behavior that a claim names",
                         "do not edit the test, and do not make the change silently",
                         "Report the conflict: it opens that behavior for review"])


def c45():
    text = read(PROMPT)
    m = re.search(r"^## The light path\n(.*?)(?=^## )", text, re.S | re.M)
    if not m:
        return [f"{PROMPT}: no section The light path"]
    sec = m.group(1)
    b = re.search(r"^\*\*Build\.\*\*(.*?)^\*\*Discovery\.\*\*", sec, re.S | re.M)
    d = re.search(r"^\*\*Discovery\.\*\*(.*?)^\*\*Asking\.\*\*", sec, re.S | re.M)
    if not b or not d:
        return [f"{PROMPT}: the light path lost its Build, Discovery or Asking block"]
    nb, nd = (len(re.findall(r"^\d+\. ", x.group(1), re.M)) for x in (b, d))
    bad = []
    if not 1 <= nb <= 7:
        bad.append(f"{PROMPT}: the light path has {nb} numbered Build steps (at most 7, as at 0.7.2)")
    if not 1 <= nd <= 4:
        bad.append(f"{PROMPT}: the light path has {nd} numbered Discovery steps (at most 4, as at 0.7.2)")
    return bad + need(PROMPT, ["State the goal and the hypothesis of the ticket in one statement",
                               "nobody adopts or judges anything first",
                               "Start with no KB and no models, unless a signal is there already",
                               "On the light path nothing is recorded: the human judges the delivery"])


CHECKS = {"c7": c7, "c9": c9, "c10": c10, "c11": c11, "c13": c13, "c14": c14, "c15": c15, "c16": c16, "c45": c45}


def main(argv):
    if argv == ["--list"]:
        print("\n".join(CHECKS))
        return 0
    unknown = [a for a in argv if a not in CHECKS]
    if unknown:
        print(f"usage: python3 docs/check_method_texts.py [--list] [{' '.join(CHECKS)}]  (unknown: {' '.join(unknown)})")
        return 2
    nbad = 0
    for cid in argv or list(CHECKS):
        try:
            bad = CHECKS[cid]()
        except OSError as e:
            bad = [f"cannot read a text: {e}"]
        print(f"{cid}: {'FAIL' if bad else 'ok'}")
        for b in bad:
            print("  " + b)
        nbad += len(bad)
    if nbad:
        print(f"check_method_texts: {nbad} failure(s)")
        return 1
    print("check_method_texts PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
