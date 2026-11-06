#!/usr/bin/env python3
"""Build s1/fixtures/loopcal_trio.json from review's runs.jsonl (step "loopcal", last run).

    python3 s1/fixtures/build_loopcal_fixture.py PATH/TO/runs.jsonl > s1/fixtures/loopcal_trio.json

Per item (c11, c12, c13) the last loopcal run is kept, in call order. Each step holds the
statement and falsifier as they went to Jev, Jev's exact answers, and the Sonnet judge's logged
booleans (collapsed, faithful). The proposer (haiku) outputs are the statements and falsifiers of
the later steps: the loop used haiku's text as it came. Raw Sonnet text and raw haiku stdout were
not logged. Only the generic loyalty example is in this step; it is checked for client names.
"""
import json
import re
import sys

rows = [json.loads(l) for l in open(sys.argv[1]) if '"loopcal"' in l]
items = {}
for r in rows:
    it = items.setdefault(r["item"], [])
    if "judge" in r:
        it[-1]["sonnet"] = {"collapsed": r["collapsed"], "faithful": r["faithful"]}
    else:
        it.append({"statement": r["state"]["statement"], "falsifier": r["state"]["falsifier"],
                   "source": r["state"]["source"], "jev": r["answers"], "at": r["at"]})
out = {}
for k, steps in items.items():
    # last run: it begins at the last occurrence of the first statement
    first = steps[0]["statement"]
    starts = [i for i, s in enumerate(steps) if s["statement"] == first]
    steps = steps[starts[-1]:]
    out[k] = {"source": steps[0]["source"], "steps": [{x: s[x] for x in ("statement", "falsifier", "jev", "sonnet")} for s in steps]}
text = json.dumps(out, indent=1, sort_keys=True)
if re.search("(?i)" + "|".join(["del" + "ta", "den" + "tal", "co" + "bra", "mind" + "hub", "ho" + "gg"]), text):
    sys.exit("client material in the fixture")
print(text)
