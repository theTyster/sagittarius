#!/usr/bin/env python3
"""k7: the scorer says what it counts; unsure and failed are never met.

Usage: k7_scorer_counts.py SAGITTARIUS_DIR [--scorer FILE]
On recorded answers (no model call) it checks that the scorer (default
evals/conformance/score.py) counts an answer under the floor as unsure and a missing answer as
failed, never as met; that a criterion with only unsure answers has no score; that the case of
q3 (5 met, 3 not met, 1 does not apply, 1 unsure) scores 5/8; and that report.md has the line of
each criterion before the one number of the run.
Exit 0: pass. Exit 1: one finding or more, each on its own line.
"""
import argparse
import importlib.util
import os
import sys
import tempfile


def ch(label, p):
    probs = {k: (p if k == label else (1 - p) / 2) for k in ("met", "not_met", "does_not_apply")}
    return {"type": "choice", "choice": label, "confidence": p, "probabilities": probs}


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument("root")
    ap.add_argument("--scorer", default=None)
    a = ap.parse_args(argv)
    conf = os.path.join(a.root, "evals", "conformance")
    path = a.scorer or os.path.join(conf, "score.py")
    if not os.path.exists(path):
        print(f"no scorer at {path}")
        return 1
    sys.path.insert(0, conf)
    spec = importlib.util.spec_from_file_location("score_under_test", path)
    s = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(s)
    floor = s.FLOOR
    lo, hi = floor / 2, min(0.99, floor + (1 - floor) / 2)
    crits = [{"id": "a", "row": 1, "source": {}}, {"id": "b", "row": 2, "source": {}},
             {"id": "q3", "row": 18, "source": {}}]
    results = {}
    for i in range(10):
        results[f"r{i}"] = {"a": ch("met", lo) if i < 3 else None,       # 3 unsure, 7 failed
                            "b": ch("met", lo)}                           # only unsure
    q3 = [ch("met", hi)] * 5 + [ch("not_met", hi)] * 3 + [ch("does_not_apply", hi), ch("met", lo)]
    for i, ans in enumerate(q3):
        results[f"r{i}"]["q3"] = ans
    bad = []
    if s.classify(ch("met", lo), floor) != "unsure":
        bad.append(f"an answer of met with probability {lo} (floor {floor}) is not counted unsure")
    if s.classify(None, floor) != "failed":
        bad.append("a missing answer is not counted failed")
    t = s.tally(results, crits, floor)
    ca = t["a"]["counts"]
    if (ca["met"], ca["unsure"], ca["failed"]) != (0, 3, 7):
        bad.append(f"criterion a: met {ca['met']}, unsure {ca['unsure']}, failed {ca['failed']}; "
                   "want 0, 3, 7")
    if t["b"]["score"] is not None:
        bad.append(f"a criterion with only unsure answers has the score {t['b']['score']}, not no score")
    cq = t["q3"]["counts"]
    if (cq["met"], cq["not_met"], cq["does_not_apply"], cq["unsure"]) != (5, 3, 1, 1) \
            or t["q3"]["score"] is None or abs(t["q3"]["score"] - 5 / 8) > 1e-9:
        bad.append(f"the case of q3 gives {cq} and score {t['q3']['score']}; want 5, 3, 1, 1 and 0.625")
    tmp = tempfile.TemporaryDirectory(prefix="k7-")
    out = tmp.name
    reqs = {r: {"state": {"request": "", "transcript": "", "delivery": ""}} for r in results}
    s.write_report(out, crits, t, results, reqs, None, floor)
    lines = open(os.path.join(out, "report.md"), encoding="utf-8").read().splitlines()
    one = [i for i, line in enumerate(lines) if line.startswith("One number")]
    rows = {c["id"]: [i for i, line in enumerate(lines) if line.startswith(f"| {c['id']} |")]
            for c in crits}
    if len(one) != 1:
        bad.append(f"the report has {len(one)} lines with the one number, not 1")
    else:
        for cid, idx in rows.items():
            if not idx or idx[0] > one[0]:
                bad.append(f"the line of criterion {cid} is not before the one number")
    for b in bad:
        print(b)
    if not bad:
        print("unsure and failed are counted apart and never as met; only unsure: no score; "
              "5 met 3 not met: 0.625; the criteria lines come before the one number")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
