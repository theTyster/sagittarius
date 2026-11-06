#!/usr/bin/env python3
"""T08 c2 and c4: every heading of the old prompt has a home, and each moved recipe is in its help topic.

c2: each heading (# to ######, outside code fences) of the old prompt has at least one row in
    docs/PROMPT-MOVES.md. A row is a table line whose first cell is the heading in backticks.
    The home is one of: prompt | help TOPIC | hook | PHILOSOPHY.md §N | dropped, because ...
c4: each row with home "help TOPIC" names a key phrase (third cell, in backticks). The phrase
    must be in HELP_DIR/TOPIC.txt. TOPIC "general" means the general help text in the CLI
    (--cli). A "hook" row with a phrase must be in s1/questions.json or s1/hook.py. A
    "PHILOSOPHY.md §N" row needs a "### N." heading in docs/PHILOSOPHY.md.
    Phrases match after whitespace is collapsed, without regard to case.

Usage: python3 docs/check_prompt_moves.py [--old FILE] [--map FILE] [--help-dir DIR] [--cli FILE]
       [--only c2|c4]
Default --old: the prompt before the redesign, `git show 7da5320:prompt/SAGITTARIUS.md`.
Exit 0: all checks pass. Exit 1: a check fails. Exit 2: a usage or input error.
"""
import argparse
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE = "7da5320"
HOME_RE = re.compile(r"^(prompt|help [a-z]+|hook|PHILOSOPHY\.md §\d+|dropped, because .+)$")


def norm(s):
    return " ".join(s.split()).lower()


def headings(text):
    out, fence = [], False
    for line in text.splitlines():
        if line.lstrip().startswith("```"):
            fence = not fence
            continue
        if not fence and re.match(r"^#{1,6} \S", line):
            out.append(line.rstrip())
    return out


def rows(map_text):
    out = []
    for n, line in enumerate(map_text.splitlines(), 1):
        if not line.startswith("| `#"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 3:
            out.append((n, cells[0].strip("`"), "", ""))
            continue
        out.append((n, cells[0].strip("`"), cells[1], cells[2].strip("`")))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--old")
    ap.add_argument("--map", default=os.path.join(ROOT, "docs/PROMPT-MOVES.md"))
    ap.add_argument("--help-dir", default=os.path.join(ROOT, "kb/share/orbit-kb/help"))
    ap.add_argument("--cli", default=os.path.join(ROOT, "kb/bin/orbit-kb"))
    ap.add_argument("--only", choices=["c2", "c4"])
    a = ap.parse_args()

    if a.old:
        old = open(a.old, encoding="utf-8").read()
    else:
        old = subprocess.run(["git", "-C", ROOT, "show", BASE + ":prompt/SAGITTARIUS.md"],
                             capture_output=True, text=True, check=True).stdout
    try:
        mp = open(a.map, encoding="utf-8").read()
    except OSError as e:
        print(f"c2 FAIL: no map: {e}")
        return 1
    hs = headings(old)
    rs = rows(mp)
    ok = True

    if a.only in (None, "c2"):
        bad = []
        mapped = {}
        for n, h, home, _ in rs:
            if not HOME_RE.match(home):
                bad.append(f"map line {n}: {h}: home {home!r} is not prompt, help TOPIC, hook, "
                           "PHILOSOPHY.md §N, or 'dropped, because ...'")
            mapped.setdefault(h, []).append(home)
        missing = [h for h in hs if h not in mapped]
        extra = sorted(set(mapped) - set(hs))
        for h in missing:
            bad.append(f"unmapped heading: {h}")
        for h in extra:
            bad.append(f"map names a heading that the old prompt does not have: {h}")
        if bad:
            ok = False
            print(f"c2 FAIL ({len(hs)} headings, {len(missing)} unmapped)")
            for b in bad:
                print("  " + b)
        else:
            print(f"c2 PASS: {len(hs)} headings, each mapped")

    if a.only in (None, "c4"):
        phil = open(os.path.join(ROOT, "docs/PHILOSOPHY.md"), encoding="utf-8").read()
        s1 = ""
        for f in ("s1/questions.json", "s1/hook.py"):
            p = os.path.join(ROOT, f)
            if os.path.exists(p):
                s1 += open(p, encoding="utf-8").read()
        cache = {}
        missing, present = [], []
        for n, h, home, phrase in rs:
            if home.startswith("help "):
                topic = home.split()[1]
                path = a.cli if topic == "general" else os.path.join(a.help_dir, topic + ".txt")
                if path not in cache:
                    cache[path] = norm(open(path, encoding="utf-8").read()) if os.path.exists(path) else None
                where = f"orbit-kb help {topic}"
                if not phrase:
                    missing.append(f"{h} -> {where}: no key phrase in the map (line {n})")
                elif cache[path] is None:
                    missing.append(f"{h} -> {where}: no file {path}")
                elif norm(phrase) not in cache[path]:
                    missing.append(f"{h} -> {where}: missing {phrase!r}")
                else:
                    present.append(f"{h} -> {where}: {phrase!r}")
            elif home == "hook" and phrase:
                (present if norm(phrase) in norm(s1) else missing).append(f"{h} -> hook: {phrase!r}")
            elif home.startswith("PHILOSOPHY.md §"):
                num = home.split("§")[1]
                tgt = present if re.search(rf"^### {num}\. ", phil, re.M) else missing
                tgt.append(f"{h} -> {home}")
        if missing:
            ok = False
            print(f"c4 FAIL: {len(missing)} missing, {len(present)} present")
        else:
            print(f"c4 PASS: {len(present)} present")
        for m in missing:
            print("  missing: " + m)
        for p in present:
            print("  present: " + p)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
