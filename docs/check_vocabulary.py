#!/usr/bin/env python3
"""scientific-method-overhaul c12 (k12): the eight words have the same sentence in every shipped text.

The source is docs/vocabulary.json: goal, hypothesis, premise, claim, specification, experiment,
verdict, tempered. Each id below is one copy. It fails when the copy differs from the source, when
its block is missing, or when it holds more than the eight sentences.

  philosophy   docs/PHILOSOPHY.md
  prompt       prompt/SAGITTARIUS.md
  panes        prompt/PANES.md (one block; each pane prompt is read with PANES.md)
  principles   hubkit/hub/PRINCIPLES.md
  hubcore      hubkit/hub/HUB-CORE.md
  help         kb/share/orbit-kb/help/core.txt (`orbit help core`)
  desk         kb/share/orbit-kb/vocabulary.json (the Desk reads its labels from it)
  temper       s1/temper.py: TEMPERED_DEFINITION, and the words that the tool gives a proposer for a
               statement that no single case can show false ("not tempered", with the sentence)
  one-home     outside its block, no text of the list defines one of the eight words in another
               sentence that starts as the definition does ("A goal is ...", "A verdict is ...")

Usage: python3 docs/check_vocabulary.py [--list] [ID ...]      Exit 0: pass. 1: fail. 2: usage.
"""
import os
import re
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import vocabulary as V  # noqa: E402

ID_OF = {"docs/PHILOSOPHY.md": "philosophy", "prompt/SAGITTARIUS.md": "prompt", "prompt/PANES.md": "panes",
         "hubkit/hub/PRINCIPLES.md": "principles", "hubkit/hub/HUB-CORE.md": "hubcore",
         "kb/share/orbit-kb/help/core.txt": "help", "kb/share/orbit-kb/vocabulary.json": "desk",
         "s1/temper.py": "temper"}
IDS = list(ID_OF.values()) + ["one-home"]
# The texts of the pane prompts are read with PANES.md, so a second definition there is a copy too.
ONE_HOME = ["docs/PHILOSOPHY.md", "prompt/SAGITTARIUS.md", "prompt/PANES.md", "prompt/panes/build.md",
            "prompt/panes/discovery.md", "prompt/panes/review.md", "hubkit/hub/PRINCIPLES.md"]


def read(rel):
    with open(os.path.join(V.ROOT, rel), encoding="utf-8") as f:
        return f.read()


def temper_words(voc):
    """The tool calls a statement that no single case can show false "not tempered", with the sentence."""
    text = read("s1/temper.py")
    bad = []
    m = re.search(r'"collapsed":\s*(.+?),?\s*$', text[text.find("WHY_WORDS"):], re.M)
    if not m:
        return ["s1/temper.py: WHY_WORDS has no entry for 'collapsed' (the statement that no single case can show false)"]
    if "not tempered" not in m.group(1) or "TEMPERED_DEFINITION" not in m.group(1):
        bad.append("s1/temper.py: WHY_WORDS['collapsed'] does not call the statement \"not tempered\" with "
                   "TEMPERED_DEFINITION beside it")
    return bad


def one_home(voc):
    bad = []
    for rel in ONE_HOME:
        try:
            text = read(rel)
        except OSError:
            continue
        span = V.find_block(text, V.MD_BEGIN, V.MD_END)
        if span:
            text = text[:span[0]] + "\n" * text[span[0]:span[1]].count("\n") + text[span[1]:]
        flat_lines = text.splitlines()
        for w, s in voc:
            start = " ".join(s.split()[:4 if w != "tempered" else 5])  # "A goal is what", "A hypothesis is tempered when"
            for n, line in enumerate(flat_lines, 1):
                if start in line and not line.lstrip().startswith(">"):
                    bad.append(f"{rel}:{n}: a second definition of {w!r} outside the vocabulary block ({start!r} ...)")
    return bad


def main(argv):
    if argv == ["--list"]:
        print("\n".join(IDS))
        return 0
    unknown = [a for a in argv if a not in IDS]
    if unknown:
        print(f"usage: python3 docs/check_vocabulary.py [--list] [{' '.join(IDS)}]  (unknown: {' '.join(unknown)})")
        return 2
    ids = argv or IDS
    try:
        voc = V.vocabulary()
    except (OSError, ValueError) as e:
        print(f"FAIL source {e}")
        return 1
    by_id = {}
    for line in V.check():
        rel = line.split(":", 1)[0]
        by_id.setdefault(ID_OF.get(rel, "source"), []).append(line)
    if "temper" in ids:
        by_id.setdefault("temper", []).extend(temper_words(voc))
    if "one-home" in ids:
        by_id["one-home"] = one_home(voc)
    nbad = 0
    for i in ids:
        bad = by_id.get(i, [])
        print(f"{i}: {'FAIL' if bad else 'ok'}")
        for b in bad:
            print("  " + b)
        nbad += len(bad)
    if nbad:
        print(f"check_vocabulary: {nbad} failure(s)")
        return 1
    print(f"check_vocabulary PASS: {len(voc)} sentences, {len(ids)} checks")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
