#!/usr/bin/env python3
"""T29 c4: the short deck (site/essentials.html) covers the redesign, for its audience.

Fails when a redesign term is missing from the visible text of essentials.html:
  - System 1 (the hook, the status line, Jev),
  - each of the seven stores by name (Spec KB, Project KB, Ledger, Memory, Weeks, Bespoke tools,
    Tracker),
  - the phase tree (its two orbits and four phases: research, specify, build, verify),
  - the hub (and the hub kit),
  - the question server (orbit-kb serve questions),
  - the audience: people who work with formal methods and AI (u46).
It also fails when essentials.html is not what site/build_essentials.py makes from index.html now
(the short deck is generated; a hand edit or a missed rebuild is a failure).

Usage: python3 site/check_essentials.py      Exit 0: pass. 1: fail.
"""
import html
import os
import re
import subprocess
import sys
import tempfile
import shutil

SITE = os.path.dirname(os.path.abspath(__file__))

TERMS = [
    ("System 1", r"\bsystem 1\b"),
    ("the System 1 hook", r"\bhook\b"),
    ("the status line", r"status line"),
    ("Jev", r"\bjev\b"),
    ("store: Spec KB", r"\bspec kb\b"),
    ("store: Project KB", r"\bproject kb\b"),
    ("store: Ledger", r"\bledger\b"),
    ("store: Memory", r"\bmemory\b"),
    ("store: Weeks", r"\bweeks\b"),
    ("store: Bespoke tools", r"\bbespoke tools\b"),
    ("store: Tracker", r"\btracker\b"),
    ("seven stores", r"\bseven stores\b"),
    ("the phase tree", r"\bphase tree\b"),
    ("phase: research", r"\bresearch\b"),
    ("phase: specify", r"\bspecify\b"),
    ("phase: verify", r"\bverify\b"),
    ("orbit: discovery", r"\bdiscovery\b"),
    ("the hub", r"\bhub\b"),
    ("the hub kit", r"\bhub kit\b"),
    ("the question server", r"\bquestion server\b"),
    ("serve questions", r"orbit-kb serve questions"),
    ("the audience", r"formal methods and ai"),
]


def visible(page):
    page = re.sub(r"<(script|style)\b.*?</\1>", " ", page, flags=re.S)
    page = re.sub(r"<!--.*?-->", " ", page, flags=re.S)
    return re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", " ", page))).lower()


def main():
    bad = []
    with open(os.path.join(SITE, "essentials.html"), encoding="utf-8") as f:
        page = f.read()
    text = visible(page)
    for name, rx in TERMS:
        if not re.search(rx, text):
            bad.append("essentials.html lacks %s (/%s/)" % (name, rx))
    # generated: rebuild into a temp copy and compare
    tmp = tempfile.mkdtemp()
    try:
        for n in ("index.html", "build_essentials.py"):
            shutil.copy(os.path.join(SITE, n), os.path.join(tmp, n))
        r = subprocess.run([sys.executable, os.path.join(tmp, "build_essentials.py")],
                           capture_output=True, text=True)
        if r.returncode != 0:
            bad.append("build_essentials.py failed: %s" % r.stderr.strip()[-300:])
        else:
            with open(os.path.join(tmp, "essentials.html"), encoding="utf-8") as f:
                if f.read() != page:
                    bad.append("essentials.html is not what build_essentials.py makes now: rerun it")
    finally:
        shutil.rmtree(tmp)
    for b in bad:
        print("FAIL " + b)
    if not bad:
        print("PASS essentials.html has all %d redesign terms and is up to date" % len(TERMS))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
