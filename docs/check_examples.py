#!/usr/bin/env python3
"""0.3.0 c_sg4b (suggestion 4): the worked examples of the prompt have one verdict wherever they appear.

The prompt (section "The hypothesis") gives each sentence of its worked examples a verdict: "members
got the wrong loyalty points" (Too strong, Collapsed, Fit) and "add a dark mode" (Too narrow, Names a
fix, Fit). The prompt of this checkout is the source. Wherever a sentence of an example appears, it
must have the same verdict, and its quote must hold the sentence alone: the finding "some purchases
get a different number" is kept apart from the hypothesis.

  c1  Hypothesis.lean (docs/**/Hypothesis.lean): the label of the doc comment that quotes the sentence,
      and the theorem about the definition under it. Fit is `ProperlyWritten _ fitHyp`
      (fit_properly_written); Too strong is `¬ ProperlyWritten _ causeHyp` (cause_not_properly_written);
      Collapsed is `Collapsed vagueHyp.req` (vague_collapsed).
  c2  `orbit-kb help discovery` (kb/share/orbit-kb/help/discovery.txt): the label before the quote.
  c3  the philosophy (docs/PHILOSOPHY.md): the verdict cell after the quote in its table.
  c4  the recording of s1/temper.py (s1/fixtures/loopcal_trio.json): a step whose statement is the
      sentence. Fit is "collapsed: false", faithful, and no added cause (the System 1 answer
      j_adds is "nothing"); Too strong or Names a fix is "collapsed: false" with an added cause or mechanism; Collapsed is
      "collapsed: true". A step whose statement holds the sentence and more (the finding inside it)
      must not be accepted as a hypothesis.

Each place must hold at least one sentence of the examples: a place where none is found fails, so a
change of format cannot make the check pass quietly. The verdict words: Fit = Properly written;
Too strong = Names a fix (it adds a cause or a mechanism); Collapsed; Too narrow.

Usage: python3 docs/check_examples.py [--list] [c1 c2 c3 c4]      Exit 0: pass. 1: fail. 2: usage.
"""
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROMPT = "prompt/SAGITTARIUS.md"
HELP = "kb/share/orbit-kb/help/discovery.txt"
PHIL = "docs/PHILOSOPHY.md"
RECORDING = "s1/fixtures/loopcal_trio.json"
IDS = ["c1", "c2", "c3", "c4"]

# a verdict word -> its class
VERDICT = {"fit": "fit", "properly written": "fit",
           "too strong": "adds", "names a fix": "adds", "names a cause": "adds",
           "collapsed": "collapsed", "too narrow": "narrow"}
SAY = {"fit": "Fit", "adds": "Too strong (it adds a cause or a fix)", "collapsed": "Collapsed",
       "narrow": "Too narrow", "unfaithful": "not faithful to the request"}

fails = []


def fail(cid, msg):
    fails.append(f"FAIL {cid} {msg}")


def read(rel):
    with open(os.path.join(ROOT, rel), encoding="utf-8") as f:
        return f.read()


def flat(s):
    return " ".join(s.split())


def lineno(text, i):
    return text.count("\n", 0, i) + 1


def examples():
    """{sentence: class} from the worked examples of the prompt of this checkout."""
    text = read(PROMPT)
    out = {}
    for m in re.finditer(r'^- ([A-Z][A-Za-z ]*?): "([^"]+)"', text, re.M):
        label = m.group(1).lower()
        if label in VERDICT:
            out[flat(m.group(2))] = VERDICT[label]
    return out


def pattern(sentence):
    return re.compile(r"\s+".join(re.escape(w) for w in sentence.split()))


def label_at(text, start, end):
    """The verdict word for the quote text[start:end] (with its quotes): a label before it
    ("- Fit: ", "/-- Fit: ") or a table cell after it ("| Too strong |"). None if there is none."""
    head = text[text.rfind("\n", 0, start) + 1:start]
    m = re.search(r'(?:^|[-*]\s+|/--\s*)([A-Z][A-Za-z ]*?):\s*$', head)
    if m:
        return m.group(1)
    m = re.match(r'\s*\|\s*([A-Za-z][A-Za-z ]*?)\s*\|', text[end:end + 80])
    return m.group(1) if m else None


def quotes(cid, rel, text, ex):
    """Each place in text where a sentence of the examples appears: (sentence, line, label, start, end).
    A sentence with more inside its quote fails here."""
    found = []
    for s in ex:
        for m in pattern(s).finditer(text):
            a, b = m.start(), m.end()
            n = lineno(text, a)
            if text[a - 1:a] != '"' or text[b:b + 1] != '"':
                fail(cid, f'{rel}:{n}: the quote holds more than the sentence "{s}" (keep the finding apart from the hypothesis)')
                continue
            found.append((s, n, label_at(text, a - 1, b + 1), a - 1, b + 1))
    return found


def compare(cid, rel, s, n, word, want):
    if word is None:
        fail(cid, f'{rel}:{n}: no verdict word for "{s}" (the prompt says {SAY[want]})')
        return None
    got = VERDICT.get(word.lower())
    if got is None:
        fail(cid, f'{rel}:{n}: the verdict "{word}" of "{s}" is not a verdict word of the prompt')
    elif got != want:
        fail(cid, f'{rel}:{n}: "{s}" is {SAY[want]} in the prompt and "{word}" here')
    return got


def none_found(cid, rel, what):
    fail(cid, f"{rel}: no sentence of the worked examples of the prompt is {what}: the check cannot hold it")


def c1(ex):
    files = sorted(p for p in glob.glob(os.path.join(ROOT, "docs", "**", "Hypothesis.lean"), recursive=True)
                   if "/.lake/" not in p)
    if not files:
        fail("c1", "no Hypothesis.lean under docs/: the check cannot read the Lean file")
        return
    for path in files:
        rel = os.path.relpath(path, ROOT)
        text = read(rel)
        found = quotes("c1", rel, text, ex)
        if not found:
            none_found("c1", rel, "quoted in a doc comment")
        for s, n, word, _, end in found:
            compare("c1", rel, s, n, word, ex[s])
            close = text.find("-/", end)
            m = re.match(r"\s*(?:def|abbrev)\s+(\w+)", text[close + 2:]) if close >= 0 else None
            if not m:
                fail("c1", f'{rel}:{n}: no definition follows the doc comment that quotes "{s}"')
                continue
            name = m.group(1)
            stmts = [flat(t) for t in re.findall(r"^theorem\s+\w+\s*(.*?)(?::=|\bwhere\b)", text, re.M | re.S)]
            coll = any(re.search(rf"^:\s*Collapsed\s+{name}\.req\b", st) for st in stmts)
            neg = any(re.search(rf"^:\s*¬\s*ProperlyWritten\s+\w+\s+{name}\b", st) for st in stmts)
            pos = any(re.search(rf"^:\s*ProperlyWritten\s+\w+\s+{name}\b", st) for st in stmts)
            if coll:
                lean = {"collapsed"}
            elif neg and not pos:
                lean = {"adds", "narrow"}
            elif pos and not neg:
                lean = {"fit"}
            else:
                fail("c1", f'{rel}:{n}: no theorem of the file gives {name} ("{s}") a verdict')
                continue
            if ex[s] not in lean:
                fail("c1", f'{rel}:{n}: "{s}" is {SAY[ex[s]]} in the prompt, and the theorems about {name} say '
                           + " or ".join(SAY[v] for v in sorted(lean)))


def text_place(cid, rel, what):
    def run(ex):
        try:
            text = read(rel)
        except OSError as e:
            fail(cid, f"{rel}: cannot read it ({e})")
            return
        found = quotes(cid, rel, text, ex)
        if not found:
            none_found(cid, rel, what)
        for s, n, word, _, _ in found:
            compare(cid, rel, s, n, word, ex[s])
    return run


c2 = text_place("c2", HELP, "in `orbit-kb help discovery`")
c3 = text_place("c3", PHIL, "in the philosophy")


def judged(step):
    """The class that the recording gives one step."""
    sonnet = step.get("sonnet") or {}
    adds = (((step.get("jev") or {}).get("j_adds") or {}).get("choice"))
    if sonnet.get("collapsed") is True:
        return "collapsed"
    if sonnet.get("faithful") is False:
        return "unfaithful"
    if sonnet.get("collapsed") is False and adds == "nothing":
        return "fit"
    if sonnet.get("collapsed") is False and adds:
        return "adds"
    return None


def c4(ex):
    where = f"{RECORDING} (the recording of s1/temper.py)"
    try:
        data = json.loads(read(RECORDING))
    except (OSError, ValueError) as e:
        fail("c4", f"{where}: cannot read it ({e})")
        return
    seen = 0
    for item, body in sorted(data.items()):
        if not isinstance(body, dict):
            continue
        for i, st in enumerate(body.get("steps", [])):
            statement = flat(st.get("statement", ""))
            at = f"{RECORDING} {item} step {i}"
            for s, want in ex.items():
                if s not in statement:
                    continue
                seen += 1
                got = judged(st)
                if statement != s:
                    if got == "fit":
                        fail("c4", f'{at}: temper.py accepts "{statement}" as a hypothesis; it holds the sentence '
                                   f'"{s}" with more inside it (the finding is kept apart from the hypothesis)')
                elif got != want:
                    fail("c4", f'{at}: "{s}" is {SAY[want]} in the prompt, and temper.py judged it '
                               + (SAY[got] if got else "with no verdict that the check can read"))
    if not seen:
        none_found("c4", where, "in a recorded step")


CHECKS = {"c1": c1, "c2": c2, "c3": c3, "c4": c4}


def main(argv):
    if argv == ["--list"]:
        print("\n".join(IDS))
        return 0
    bad = [a for a in argv if a not in CHECKS]
    if bad:
        print(f"usage: python3 docs/check_examples.py [--list] [{' '.join(IDS)}]  (unknown: {' '.join(bad)})")
        return 2
    ex = examples()
    ids = argv or IDS
    if not ex:
        fails.append(f"FAIL {PROMPT}: no worked example (a line '- Fit: \"...\"') in the prompt: the check cannot hold one")
    else:
        for cid in ids:
            CHECKS[cid](ex)
    for f in fails:
        print(f)
    if fails:
        print(f"check_examples: {len(fails)} failure(s) ({' '.join(ids)})")
        return 1
    print(f"check_examples PASS: {len(ex)} sentences of the worked examples, one verdict each ({' '.join(ids)})")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
