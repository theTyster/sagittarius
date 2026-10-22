#!/usr/bin/env python3
"""Check a prompt diff for answer-key leaks: 4-word runs shared with an eval prompt.

Usage: check_leaks.py [GIT-DIFF-ARGS...]   (default: the uncommitted diff of the prompt)
Example: check_leaks.py HEAD~3 -- prompt/SAGITTARIUS.md
Reads every eval spec (tools.json, heldout/heldout.json). Exit 1 when an added line shares
a 4-word run with an eval prompt or turn. See REFINING.md, rule 2.
"""
import glob
import json
import os
import re
import subprocess
import sys

here = os.path.dirname(os.path.abspath(__file__))
args = sys.argv[1:] or ["--", "prompt/SAGITTARIUS.md"]
diff = subprocess.run(["git", "-C", os.path.dirname(here), "diff", "-U0", *args], capture_output=True, text=True).stdout
added = " ".join(l[1:] for l in diff.splitlines() if l.startswith("+") and not l.startswith("+++"))
words = lambda t: re.findall(r"[a-z0-9']+", t.lower())
text = " " + " ".join(words(added)) + " "
hits = []
for spec in [os.path.join(here, "tools.json")] + glob.glob(os.path.join(here, "heldout", "*.json")):
    for e in json.load(open(spec))["evals"]:
        for t in e.get("turns") or [e.get("prompt", "")]:
            w = words(t)
            hits += [(e["id"], " ".join(w[i:i + 4])) for i in range(len(w) - 3) if f" {' '.join(w[i:i + 4])} " in text]
for i, g in sorted(set(hits)):
    print(f"eval {i}: \"{g}\"")
print("no 4-word overlap with an eval prompt" if not hits else f"{len(set(hits))} overlap(s)", file=sys.stderr)
sys.exit(1 if hits else 0)
