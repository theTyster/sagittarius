#!/usr/bin/env python3
"""Judge the tracked calibration cases (s1/fixtures/calibration.json) with the live System 1 model.

Run by a person, never by a test (0.3.0 S-C): a call per case, one call for all the questions of a
case. Needs $TYPESAFE_API_KEY. It calls the System 1 model only.

    python3 s1/calibrate.py [--questions s1/questions.json] [--case ID ...] [--out FILE]

Prints each miss and, for each question, how many labels agree. --out writes the rows as JSON.
"""
import argparse
import json
import os
import sys
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import jev  # noqa: E402

CHOICE_MIN = 0.5  # the floor of hook.py


def score(answer, want):
    """(got, p, agrees) for one answer and the expected label. A yes/no answer is read in the bands of
    jev.band; a choice counts when P(choice) >= CHOICE_MIN, else it is "unsure"."""
    if answer.get("type") == "noul":
        p = float(answer["noul"])
        got = jev.band(p)
    else:
        ch = answer.get("choice")
        probs = answer.get("probabilities") or {}
        p = float(probs.get(ch, answer.get("confidence", 0)))
        got = ch if p >= CHOICE_MIN else "unsure"
    return got, p, got == want


def judge_case(case, questions, timeout=30):
    state = {"message": case["message"], "recent": case["recent"]}
    ans = jev.judge(state, questions, timeout=timeout, log_extra={"cal": "s1", "case": case["id"]})
    rows = []
    for qid, want in case["expect"].items():
        if not ans or qid not in ans:
            rows.append({"case": case["id"], "q": qid, "want": want, "got": "error", "p": 0.0, "ok": False})
            continue
        got, p, ok = score(ans[qid], want)
        rows.append({"case": case["id"], "q": qid, "want": want, "got": got, "p": round(p, 2), "ok": ok})
    return rows


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("--questions", default=os.path.join(HERE, "questions.json"))
    ap.add_argument("--cases", default=os.path.join(HERE, "fixtures", "calibration.json"))
    ap.add_argument("--case", action="append", default=[])
    ap.add_argument("--out")
    a = ap.parse_args(argv)
    with open(a.questions, encoding="utf-8") as f:
        questions = json.load(f)
    with open(a.cases, encoding="utf-8") as f:
        cases = [c for c in json.load(f)["cases"] if not a.case or c["id"] in a.case]
    with ThreadPoolExecutor(4) as ex:
        rows = [r for part in ex.map(lambda c: judge_case(c, questions), cases) for r in part]
    per = {}
    for r in rows:
        n = per.setdefault(r["q"], [0, 0])
        n[0] += r["ok"]
        n[1] += 1
        if not r["ok"]:
            print("miss:", r["case"], r["q"], "want", r["want"], "got", r["got"], r["p"])
    for q, (ok, n) in sorted(per.items()):
        print(f"{q}: {ok} of {n}")
    print(f"all: {sum(v[0] for v in per.values())} of {sum(v[1] for v in per.values())}")
    if a.out:
        with open(a.out, "w", encoding="utf-8") as f:
            json.dump(rows, f, indent=1)
    return 0


if __name__ == "__main__":
    sys.exit(main())
