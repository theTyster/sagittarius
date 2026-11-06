#!/usr/bin/env python3
"""Check that the status of each store on slide 35 of site/index.html agrees with git (T18 c1).

A ticket TNN has landed when HEAD has a merge commit whose subject is a merge of its branch:
  - `Merge branch 'rd/tNN'` (the exact branch name; `rd/t06f` is not `rd/t06`), or
  - `Merge branch 'rd/tNN<suffix>'` (such as rd/t12b or rd/t05-proof) when the subject tags the
    ticket itself as `(TNN)` or `(TNN, ...)`.
A merge `... into rd/...` merged into another ticket branch, not into this line, and does not
count. A mention of a ticket elsewhere in a subject ("c8 waits for T06") does not count.
The existence of a branch rd/tNN is not used: a new branch that points at HEAD is an ancestor of
HEAD and would look landed.

For each store tile (and each other paragraph of the slide with "Status:") whose status names a
ticket: a landed ticket is named as "landed ... (TNN ...)" and the status never says "not built
yet", "not merged yet", or "a design"; a ticket that has not landed is "not merged yet". The intro
paragraph says "not merged yet" when a ticket has not landed, and never "not built yet", "not
merged yet", or "still a design" when every named ticket has landed.

T29 c5 (d_triage_per_item): slide 34 (the hub kit) says that items never lapse by themselves: its
text says "never lapse(s) by itself/themselves" (or "nothing lapses by itself"), and it never says
that items lapse when nobody renews them (or lapse on a timer, after a time, or by themselves).

Usage: python3 docs/check_deck_status.py      Exit 0: pass. 1: fail. 2: cannot run.
"""
import html
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SLIDE = "s35"
NOT_YET = ("not built yet", "not merged yet", "a design")
INTRO_NOT_YET = ("not built yet", "not merged yet", "still a design")


def merged_ticket(subject):
    """The ticket id (such as 'T06') that this merge subject lands, or None."""
    m = re.match(r"Merge branch 'rd/t(\d\d)([^']*)'(.*)$", subject)
    if not m:
        return None
    num, suffix, rest = m.groups()
    if re.match(r"\s+into\s+rd/", rest):
        return None
    tid = "T" + num
    if suffix == "":
        return tid
    if re.search(r"\(%s[,)]" % tid, rest):
        return tid
    return None


def self_test():
    cases = [
        ("Merge branch 'rd/t06': the project KB (T06, CONTRACT D23)", "T06"),
        ("Merge branch 'rd/t06f': T06 follow-up: hubkit names the project KB (T17 c8), CHANGELOG", None),
        ("Merge branch 'rd/t17': branch consistency fixes, text only (T17; c8 waits for T06)", "T17"),
        ("Merge branch 'rd/t12b': C4 repo map kb/bin/repo-map (T12)", "T12"),
        ("Merge branch 'rd/t05-proof': the flow ledger (T05) and the Lean proof of its guard (c8)", "T05"),
        ("Merge branch 'rd/t05' into rd/t10", None),
        ("merge: redesign (T03) into rd/t06", None),
        ("docs: merge redesign (T06 follow-up)", None),
    ]
    bad = []
    for subject, want in cases:
        got = merged_ticket(subject)
        if got != want:
            bad.append("self-test: %r gives %r, want %r" % (subject, got, want))
    # "waits for T06" alone must not land T06
    landed = {merged_ticket(s) for s, _ in cases[1:3]}
    if "T06" in landed:
        bad.append("self-test: a mention of T06 counts as its merge")
    return bad


def landed_tickets():
    r = subprocess.run(["git", "-C", ROOT, "log", "--merges", "--format=%s", "HEAD"],
                       capture_output=True, text=True, stdin=subprocess.DEVNULL)
    if r.returncode != 0:
        print("cannot read git log: %s" % r.stderr.strip())
        sys.exit(2)
    return {t for t in (merged_ticket(s) for s in r.stdout.splitlines()) if t}


def text_of(fragment):
    return re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", " ", fragment))).strip()


def slide_units():
    with open(os.path.join(ROOT, "site", "index.html"), encoding="utf-8") as f:
        page = f.read()
    m = re.search(r'<section class="slide" id="%s"[^>]*>(.*?)</section>' % SLIDE, page, re.S)
    if not m:
        print("site/index.html has no slide %s" % SLIDE)
        sys.exit(2)
    body = m.group(1)
    tiles_at = body.find('<div class="tiles">')
    plain = [text_of(p) for p in re.findall(r"<p>(.*?)</p>", body[:tiles_at] if tiles_at >= 0 else body, re.S)]
    intro = plain[0] if plain else ""
    units = []
    for t in re.findall(r'<div class="tile[^"]*">(.*?)</div>', body, re.S):
        h = re.search(r"<h3>(.*?)</h3>", t, re.S)
        units.append((text_of(h.group(1)) if h else "?", text_of(t)))
    rest = re.sub(r'<div class="tile[^"]*">.*?</div>', "", body, flags=re.S)
    for p in re.findall(r"<p(?:\s[^>]*)?>(.*?)</p>", rest, re.S):
        s = text_of(p)
        if "Status:" in s:
            units.append((s.split(":")[0], s))
    return intro, units


LAPSE_SLIDE = "s34"


def lapse_check():
    """T29 c5: slide 34 says that items never lapse by themselves. A list of failures."""
    with open(os.path.join(ROOT, "site", "index.html"), encoding="utf-8") as f:
        page = f.read()
    m = re.search(r'<section class="slide" id="%s"[^>]*>(.*?)</section>' % LAPSE_SLIDE, page, re.S)
    if not m:
        return ["site/index.html has no slide %s" % LAPSE_SLIDE]
    text = text_of(m.group(1)).lower()
    bad = []
    if not re.search(r"\b(never|nothing|no item)\b[^.]*\blapses?\b[^.]*\bby (itself|themselves)\b", text):
        bad.append("slide %s does not say that items never lapse by themselves" % LAPSE_SLIDE)
    for sentence in re.split(r"(?<=[.!?])\s+", text):
        if re.search(r"\blapses?\b", sentence) and not re.search(r"\b(never|nothing|no item|not)\b", sentence):
            bad.append("slide %s says that items lapse: %r" % (LAPSE_SLIDE, sentence))
    return bad


def main():
    bad = self_test()
    bad += lapse_check()
    landed = landed_tickets()
    intro, units = slide_units()
    named = []
    for name, text in units:
        i = text.find("Status:")
        if i < 0:
            continue
        status = text[i + len("Status:"):]
        ids = sorted(set(re.findall(r"\bT\d\d\b", status)))
        for tid in ids:
            named.append(tid)
            said_landed = re.search(r"\blanded\b[^.()]*\([^)]*\b%s\b" % tid, status)
            if tid in landed:
                if not said_landed:
                    bad.append("%s: %s has landed, but the status does not say 'landed (%s)': %r" % (name, tid, tid, status))
                for w in NOT_YET:
                    if w in status.lower():
                        bad.append("%s: %s has landed, but the status says %r: %r" % (name, tid, w, status))
            else:
                if said_landed:
                    bad.append("%s: %s has not landed, but the status says landed: %r" % (name, tid, status))
                if "not merged yet" not in status.lower():
                    bad.append("%s: %s has not landed, but the status does not say 'not merged yet': %r" % (name, tid, status))
    if not named:
        bad.append("slide %s names no ticket in a status (the check reads nothing)" % SLIDE)
    open_ids = sorted(set(t for t in named if t not in landed))
    if open_ids:
        if "not merged yet" not in intro.lower():
            bad.append("intro: %s has not landed, but the intro does not say 'not merged yet': %r" % (", ".join(open_ids), intro))
    else:
        for w in INTRO_NOT_YET:
            if w in intro.lower():
                bad.append("intro: every named ticket has landed, but the intro says %r: %r" % (w, intro))
    for b in bad:
        print("FAIL " + b)
    if not bad:
        print("PASS slide %s: items never lapse by themselves" % LAPSE_SLIDE)
        print("PASS slide %s: %d statuses name tickets, and they agree with the merges (%s)" % (SLIDE, len(named), " ".join(sorted(set(named)))))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
