#!/usr/bin/env python3
"""k6: each score under 1 in the report links to a target that shows what gave it.

Usage: k6_report_links.py SAGITTARIUS_DIR [--report DIR]
With no --report it scores the fixture run evals/conformance/fixtures/run-sample (recorded
answers, no model call) into a temp dir and checks that report. It passes only when, for each
criterion line of report.md with a score under 1, the score links to a target file, the target
exists, and it holds the criterion id, its source sentences (Philosophy and prompt), and for
each run with not met: the run name, the answer with its probability, the question that the
judge got with its three cases, the request of the human, and the transcript text. The report
also lists each unsure or failed run, and its header says that the answers are stubs, that no
number is a conformance score before c2 and c3, that Ty has not judged the criteria, and that
the floor is a guess of build.
Exit 0: pass. Exit 1: one finding or more, each on its own line.
"""
import argparse
import json
import os
import re
import subprocess
import sys
import tempfile


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument("root")
    ap.add_argument("--report", default=None)
    a = ap.parse_args(argv)
    conf = os.path.join(a.root, "evals", "conformance")
    fixture = os.path.join(conf, "fixtures", "run-sample")
    if not os.path.exists(os.path.join(conf, "score.py")):
        print(f"no scorer at {conf}/score.py")
        return 1
    out = a.report
    if out is None:
        tmp = tempfile.TemporaryDirectory(prefix="k6-")
        out = tmp.name
        r = subprocess.run([sys.executable, os.path.join(conf, "score.py"), fixture, "--out", out],
                           capture_output=True, text=True)
        if r.returncode:
            print(f"score.py failed: {r.stderr.strip()}")
            return 1
    sys.path.insert(0, conf)
    import questions as qmod
    import score as smod
    crits = {c["id"]: c for c in qmod.load_criteria(os.path.join(conf, "criteria.json"))}
    recorded = json.load(open(os.path.join(fixture, "answers.json"), encoding="utf-8"))
    results, requests = smod.judge_run(fixture, list(crits.values()), recorded)
    bad, low = [], 0
    try:
        report = open(os.path.join(out, "report.md"), encoding="utf-8").read()
    except OSError as e:
        print(f"no report: {e}")
        return 1
    for line in report.splitlines():
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 8 or cells[0] not in crits:
            continue
        cid, cell = cells[0], cells[-1]
        m = re.search(r"\d+\.\d+", cell)
        if not m or float(m.group(0)) >= 1:
            continue
        low += 1
        link = re.fullmatch(r"\[\d+\.\d+\]\(([^)]+)\)", cell)
        if not link:
            bad.append(f"{cid}: the score {m.group(0)} has no link")
            continue
        target = os.path.join(out, link.group(1))
        if not os.path.isfile(target):
            bad.append(f"{cid}: the target {link.group(1)} does not exist")
            continue
        text = open(target, encoding="utf-8").read()
        src = crits[cid]["source"]
        q = crits[cid]["question"]
        for what, s in (("the id", cid), ("the habit of the Philosophy", src["philosophy"]),
                        ("the prompt sentence", src["prompt"]),
                        ("the question that the judge got", q["instructions"]),
                        *((f"the {k} case", t) for k, t in q["criteria"].items())):
            if s not in text:
                bad.append(f"{cid}: the target does not hold {what}")
        for run, answers in results.items():
            if smod.classify(answers.get(cid)) != "not_met":
                continue
            p = f"{smod.probability(answers[cid]):.2f}"
            if f"## {run}" not in text:
                bad.append(f"{cid}: the target has no entry for the not met run {run}")
            elif not re.search(rf"not_met, probability {re.escape(p)}", text):
                bad.append(f"{cid}: the entry of {run} does not show the answer with its probability {p}")
            if requests[run]["state"]["request"] not in text:
                bad.append(f"{cid}: the entry of {run} does not hold the request of the human")
            if requests[run]["state"]["transcript"] not in text:
                bad.append(f"{cid}: the entry of {run} does not hold the transcript text")
    for cid in crits:
        for run, answers in results.items():
            kind = smod.classify(answers.get(cid))
            if kind in ("unsure", "failed") and not re.search(
                    rf"^- {re.escape(cid)}(, {re.escape(run)}: {kind}|: failed in all .*\b{re.escape(run)}\b)",
                    report, re.M):
                bad.append(f"the report does not list {cid}, {run} as {kind}")
    for need in ("Not a conformance score", "hand-written", "c2", "c3", "not judged",
                 "is a guess of build"):
        if need not in report:
            bad.append(f"the header of the report does not say {need!r}")
    if low == 0:
        bad.append("the report has no score under 1: the check shows nothing on it")
    for b in bad:
        print(b)
    if not bad:
        print(f"{low} scores under 1, each linked to a target with the criterion, its sources, "
              "the answer with its probability and the transcript of each not met run")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
