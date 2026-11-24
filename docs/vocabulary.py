#!/usr/bin/env python3
"""The vocabulary of Sagittarius has one source: docs/vocabulary.json (scientific-method-overhaul c12).

Eight words (goal, hypothesis, premise, claim, specification, experiment, verdict, tempered), one
sentence each. This script copies the sentences into a marked block of each text that ships them,
and checks that each copy still equals the source. A hand edit of one copy makes --check fail.

The copies (TARGETS below):
  Markdown   the lines between `<!-- vocabulary:begin -->` and `<!-- vocabulary:end -->`:
             docs/PHILOSOPHY.md, prompt/SAGITTARIUS.md, prompt/PANES.md (one block for the three
             pane prompts), hubkit/hub/PRINCIPLES.md, hubkit/hub/HUB-CORE.md.
  help       kb/share/orbit-kb/help/core.txt: the lines between
             `Vocabulary (generated; docs/vocabulary.py)` and `End of vocabulary`.
  json       kb/share/orbit-kb/vocabulary.json: a copy of the source file (the Desk reads it).
  constant   s1/temper.py: the line `TEMPERED_DEFINITION = "..."` holds the sentence of "tempered".

--write puts the sentences into each block. It does not make a block: put the two marker lines
into a new text by hand, then run --write.

Usage: python3 docs/vocabulary.py --check | --write | --list
Exit 0: every copy equals the source (--check), or was written (--write). Exit 1: a copy differs,
or a block or a file is missing. Exit 2: usage, or the source is not the eight sentences.
"""
import json
import os
import re
import sys
import textwrap

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE = "docs/vocabulary.json"
WORDS = ["goal", "hypothesis", "premise", "claim", "specification", "experiment", "verdict", "tempered"]
MD_BEGIN, MD_END = "<!-- vocabulary:begin -->", "<!-- vocabulary:end -->"
TXT_BEGIN, TXT_END = "Vocabulary (generated; docs/vocabulary.py)", "End of vocabulary"
WIDTH = 96
TARGETS = [
    ("docs/PHILOSOPHY.md", "markdown"),
    ("prompt/SAGITTARIUS.md", "markdown"),
    ("prompt/PANES.md", "markdown"),
    ("hubkit/hub/PRINCIPLES.md", "markdown"),
    ("hubkit/hub/HUB-CORE.md", "markdown"),
    ("kb/share/orbit-kb/help/core.txt", "help"),
    ("kb/share/orbit-kb/vocabulary.json", "json"),
    ("s1/temper.py", "constant"),
]
CONSTANT = re.compile(r'^TEMPERED_DEFINITION = (".*")[ \t]*$', re.M)


def path(rel, root=None):
    return os.path.join(root or ROOT, rel)


def source_text(root=None):
    with open(path(SOURCE, root), encoding="utf-8") as f:
        return f.read()


def vocabulary(root=None):
    """The eight sentences, in order: [(word, sentence)]. Raises ValueError when the source is not them."""
    data = json.loads(source_text(root))
    if list(data) != WORDS:
        raise ValueError(f"{SOURCE} must hold exactly these keys, in this order: {', '.join(WORDS)}")
    for w, s in data.items():
        if not isinstance(s, str) or not s.strip() or "\n" in s:
            raise ValueError(f"{SOURCE}: the sentence of {w!r} must be one line of text")
    return list(data.items())


def markdown_block(voc):
    lines = []
    for _, s in voc:
        lines += textwrap.wrap(s, WIDTH, initial_indent="- ", subsequent_indent="  ", break_long_words=False,
                               break_on_hyphens=False)
    return "\n".join(lines)


def help_block(voc):
    lines = []
    for _, s in voc:
        lines += textwrap.wrap(s, WIDTH, initial_indent="  ", subsequent_indent="    ", break_long_words=False,
                               break_on_hyphens=False)
    return "\n".join(lines)


def find_block(text, begin, end):
    """(start, stop) of the text between the line BEGIN and the line END, or None. One block only."""
    pat = re.compile(r"^%s[ \t]*\n(.*?)^%s[ \t]*$" % (re.escape(begin), re.escape(end)), re.M | re.S)
    found = list(pat.finditer(text))
    if len(found) != 1:
        return None
    return found[0].start(1), found[0].end(1)


def want(kind, voc, root=None):
    if kind == "markdown":
        return markdown_block(voc) + "\n"
    if kind == "help":
        return help_block(voc) + "\n"
    if kind == "json":
        return source_text(root)
    return json.dumps(dict(voc)["tempered"], ensure_ascii=False)


def have(rel, kind, root=None):
    """(the copy as the file holds it, or None; why it is None)."""
    try:
        with open(path(rel, root), encoding="utf-8") as f:
            text = f.read()
    except OSError as e:
        return None, f"cannot read it ({e.strerror})"
    if kind == "json":
        return text, ""
    if kind == "constant":
        m = CONSTANT.findall(text)
        if len(m) != 1:
            return None, f"it must hold exactly one line TEMPERED_DEFINITION = \"...\" (found {len(m)})"
        return m[0], ""
    begin, end = (MD_BEGIN, MD_END) if kind == "markdown" else (TXT_BEGIN, TXT_END)
    span = find_block(text, begin, end)
    if span is None:
        return None, f"it must hold exactly one block between the lines {begin!r} and {end!r}"
    return text[span[0]:span[1]], ""


def check(root=None):
    """The failures, one line each. Empty when every copy equals the source."""
    voc = vocabulary(root)
    bad = []
    for rel, kind in TARGETS:
        got, why = have(rel, kind, root)
        if got is None:
            bad.append(f"{rel}: {why}")
            continue
        exp = want(kind, voc, root)
        if got == exp:
            continue
        if kind in ("markdown", "help"):
            flat = " ".join(got.split())
            missing = [w for w, s in voc if s not in flat]
            what = ("the sentence of " + ", ".join(missing) + " differs from the source") if missing \
                else "the block holds more than the eight sentences, or another layout"
        elif kind == "json":
            what = "the copy differs from " + SOURCE
        else:
            what = "TEMPERED_DEFINITION is not the sentence of 'tempered'"
        bad.append(f"{rel}: {what} (run: python3 docs/vocabulary.py --write)")
    return bad


def write(root=None):
    voc = vocabulary(root)
    bad, changed = [], []
    for rel, kind in TARGETS:
        exp = want(kind, voc, root)
        if kind == "json":
            got, _ = have(rel, kind, root)
            if got != exp:
                with open(path(rel, root), "w", encoding="utf-8") as f:
                    f.write(exp)
                changed.append(rel)
            continue
        got, why = have(rel, kind, root)
        if got is None:
            bad.append(f"{rel}: {why}")
            continue
        if got == exp:
            continue
        with open(path(rel, root), encoding="utf-8") as f:
            text = f.read()
        if kind == "constant":
            text = CONSTANT.sub(lambda m: "TEMPERED_DEFINITION = " + exp, text, count=1)
        else:
            begin, end = (MD_BEGIN, MD_END) if kind == "markdown" else (TXT_BEGIN, TXT_END)
            a, b = find_block(text, begin, end)
            text = text[:a] + exp + text[b:]
        with open(path(rel, root), "w", encoding="utf-8") as f:
            f.write(text)
        changed.append(rel)
    return bad, changed


def main(argv):
    if argv not in (["--check"], ["--write"], ["--list"]):
        print("usage: python3 docs/vocabulary.py --check | --write | --list")
        return 2
    try:
        voc = vocabulary()
    except (OSError, ValueError) as e:
        print(f"vocabulary: {e}")
        return 2
    if argv == ["--list"]:
        for w, s in voc:
            print(f"{w}: {s}")
        return 0
    if argv == ["--write"]:
        bad, changed = write()
        for rel in changed:
            print(f"wrote {rel}")
        for b in bad:
            print("FAIL " + b)
        if not bad:
            print(f"vocabulary: {len(TARGETS)} copies hold the {len(voc)} sentences")
        return 1 if bad else 0
    bad = check()
    for b in bad:
        print("FAIL " + b)
    if not bad:
        print(f"vocabulary PASS: {len(TARGETS)} copies equal {SOURCE} ({len(voc)} sentences)")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
