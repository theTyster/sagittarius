#!/usr/bin/env python3
"""0.3.0 c_sg5b (suggestion 5): each term has one meaning in the texts that an agent reads.

The philosophy (principle 13): "Give each term one meaning." The audits of 2026-11-11 (findings K13,
K17, M14, M19, S-c10, D14) found old terms that now clash with a new meaning, or that name a thing
that is gone. This check fails when a text that an agent reads uses one of them. For each use it
prints the file, the line, the retired term, and the term to use:

    FAIL prompt/PANES.md:25: "trigger" is retired (the prompt calls it a signal); write "signal".

The texts (texts() below): the prompt prompt/SAGITTARIUS.md, the pane prompts prompt/PANES.md and
prompt/panes/*.md, the help topics kb/share/orbit-kb/help/*.txt, and the hub's text under hubkit/
(*.md, *.txt and *.json; not hubkit/proofs/, whose Lean files a hub agent does not read).

A line that names a rename or a retired term is history, and the check skips it: the line holds
"renamed from", "was <TERM>", or the word "retired".

Not retired, on purpose: "hub kit" (M-G changes only titles and first sentences); the word "scope"
(the prompt has a section "Scope", and "the scope" of a request is a guess to show); the word
"model" alone (System 1 is a model; a solver has a model); the directory kb/tests/burn_model.

Usage: python3 docs/check_terms.py      Exit 0: no retired term. Exit 1: a retired term, or no text found.
"""
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# (the retired term as printed, its pattern, why, the term to use)
TERMS = [
    ("trigger", re.compile(r"\btrigger(s|ed|ing)?\b", re.I),
     "the prompt calls it a signal", '"signal"'),
    ("Lean model", re.compile(r"\bLean\s+(burn\s+)?models?\b|\bmodels?\s*\(Lean\b", re.I),
     "Lean is not a modeling language: a Lean file holds definitions, and theorems about them",
     '"Lean definitions" (and theorems)'),
    ("The phase tree", re.compile(r"\bphase\s+tree\b", re.I),
     "the prompt has no phase tree; the phases are in its section \"Scope\"", 'the section "Scope" of the prompt'),
    ("scoped", re.compile(r"\bscoped\b|\bin\s+the\s+scope\s+of\s+the\s+report\b", re.I),
     "a hypothesis is written wide: the default is the widest reading", '"wide"'),
    ("SIGNAL", re.compile(r"\bSIGNAL\b"),
     "the move SIGNAL is RESTATE; \"signal\" means one of the six signals", '"RESTATE"'),
]

HISTORY = re.compile(r"renamed from|\bretired\b|\bwas\s+(the\s+)?(move\s+)?(SIGNAL|trigger|scoped|Lean model)", re.I)


def texts():
    """(group, [relative paths]) for each group of texts that an agent reads."""
    def g(*patterns):
        out = []
        for p in patterns:
            out += glob.glob(os.path.join(ROOT, p), recursive=True)
        return sorted({os.path.relpath(p, ROOT) for p in out if os.path.isfile(p)})

    hub = [p for p in g("hubkit/**/*.md", "hubkit/**/*.txt", "hubkit/**/*.json")
           if not p.startswith("hubkit/proofs/") and "/.lake/" not in p]
    return [
        ("the prompt", g("prompt/SAGITTARIUS.md")),
        ("the pane prompts", g("prompt/PANES.md", "prompt/panes/*.md")),
        ("the help topics", g("kb/share/orbit-kb/help/*.txt")),
        ("the hub's text", hub),
    ]


def scan(rel):
    """Each use of a retired term in one file: (line number, term, why, right term)."""
    hits = []
    with open(os.path.join(ROOT, rel), encoding="utf-8") as f:
        for n, line in enumerate(f, 1):
            if HISTORY.search(line):
                continue
            for term, pat, why, right in TERMS:
                if pat.search(line):
                    hits.append((n, term, why, right))
    return hits


def main(argv):
    if argv:
        print(__doc__.strip().splitlines()[-1].replace("Usage: ", "usage: "))
        return 2
    bad = 0
    nfiles = 0
    for group, files in texts():
        if not files:
            print(f"FAIL no file of {group} was found: the check cannot read it")
            bad += 1
            continue
        nfiles += len(files)
        for rel in files:
            for n, term, why, right in scan(rel):
                print(f'FAIL {rel}:{n}: "{term}" is retired ({why}); write {right}.')
                bad += 1
    if bad:
        print(f"check_terms: {bad} failure(s) in {nfiles} files")
        return 1
    print(f"check_terms PASS: {nfiles} files, {len(TERMS)} retired terms, none used")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
