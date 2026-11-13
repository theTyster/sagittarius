#!/usr/bin/env python3
"""Build s1/fixtures/loopcal_trio.json from one live run of s1/temper.py (0.3.0 S-B).

    python3 s1/fixtures/build_loopcal_fixture.py RUN_DIR [ITEM ...] > s1/fixtures/loopcal_trio.json

RUN_DIR holds one folder per item (default c12 c13 c14). Each folder holds the two logs of one
`python3 s1/temper.py STATEMENT --source SOURCE --item ITEM --falsifier F` run: temper.jsonl
($TEMPER_LOG) and s1.jsonl ($S1_LOG). Per item, each judged statement is one step, in call order:
the statement and falsifier as they were judged, the System 1 model's exact answers, and the
judge's booleans (collapsed, faithful) from the verdict record. The key of those booleans is
"sonnet", the name that the spec check and docs/check_examples.py read. Since 0.3.0 S-B round 3 the
System 1 model is the only judge, so in a new run the key holds its booleans, not a sonnet reply. The proposer's outputs are the statements and falsifiers of the later steps.
Only the generic loyalty example is in the run; it is checked for client names.
"""
import json
import os
import re
import sys


def rows(path):
    with open(path, encoding="utf-8") as f:
        return [json.loads(line) for line in f if line.strip()]


def item(d):
    t = rows(os.path.join(d, "temper.jsonl"))
    s1 = [r for r in rows(os.path.join(d, "s1.jsonl")) if r.get("answers")]
    verdicts = [r for r in t if r.get("event") == "verdict"]
    if len(verdicts) != len(s1):
        sys.exit(f"{d}: {len(verdicts)} judged statements and {len(s1)} System 1 answers")
    steps, source = [], None
    for v, a in zip(verdicts, s1):
        st = a["state"]
        if st["statement"] != v["statement"] or st["falsifier"] != v["falsifier"]:
            sys.exit(f"{d}: step {v['step']}: the logs disagree on the statement or falsifier")
        source = source or st["source"]
        steps.append({"statement": v["statement"], "falsifier": v["falsifier"], "jev": a["answers"],
                      "sonnet": {"collapsed": v["collapsed"], "faithful": v["faithful"]}})
    return {"source": source, "steps": steps}


def main(argv):
    run, items = argv[0], argv[1:] or ["c12", "c13", "c14"]
    out = {k: item(os.path.join(run, k)) for k in items}
    text = json.dumps(out, indent=1, sort_keys=True)
    if re.search("(?i)" + "|".join(["del" + "ta", "den" + "tal", "co" + "bra", "mind" + "hub", "ho" + "gg"]), text):
        sys.exit("client material in the fixture")
    print(text)


if __name__ == "__main__":
    main(sys.argv[1:])
