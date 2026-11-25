#!/usr/bin/env python3
"""Score a run of the conformance evals from recorded System 1 answers, and write its report.

Usage: score.py RUN_DIR [--criteria FILE] [--answers FILE] [--floor P] [--out DIR]

RUN_DIR holds record.json (see runner.py), transcripts/<run>.jsonl, and answers.json: the
recorded answers of System 1, {"<run>": {"<criterion id>": <choice answer>}}. The System 1 call
is a stub that returns these recorded answers (stub_judge); this file makes no model call.
For each transcript it builds the request of questions.py, asks the stub, and decides the
criteria with instrument script with script.py.

The counts of each criterion: met, not met, does not apply, unsure (the probability of the
chosen label is under the floor) and failed (no answer). score = met / (met + not met); unsure
and failed never count as met; with no met and no not met the criterion has no score.
The report (DIR/report.md, default RUN_DIR/report) gives the line of each criterion first and
one number last: the mean of the criterion scores, each with the same weight (default of q3).
Each score under 1 links to DIR/targets/<id>.md: the criterion id and its source sentences, and
for each run with not met the answer with its probability and the transcript text.
Python 3 standard library only.
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import questions as qmod  # noqa: E402
import script as smod  # noqa: E402

# The probability floor: an answer whose chosen label has a lower probability is unsure.
# A guess of build (2026-11-25), not a decision of Ty: no question of the KB names a floor.
FLOOR = 0.6
LABELS = ("met", "not_met", "does_not_apply")
KINDS = LABELS + ("unsure", "failed")


def stub_judge(request, recorded):
    """The System 1 call, replaced by recorded answers: one answer per question id or None."""
    return {qid: recorded.get(qid) for qid in request["questions"]}


def probability(ans):
    probs = ans.get("probabilities") or {}
    p = probs.get(ans.get("choice"))
    return float(p if p is not None else ans.get("confidence", 0.0))


def classify(ans, floor=FLOOR):
    """met, not_met, does_not_apply, unsure or failed."""
    if not isinstance(ans, dict) or ans.get("choice") not in LABELS:
        return "failed"
    if probability(ans) < floor:
        return "unsure"
    return ans["choice"]


def tally(results, criteria, floor=FLOOR):
    """results: {run: {cid: answer or None}}. Returns {cid: {"counts", "score", "runs"}}."""
    out = {}
    for c in criteria:
        cid = c["id"]
        counts = {k: 0 for k in KINDS}
        per_run = {}
        for run, answers in results.items():
            kind = classify(answers.get(cid), floor)
            counts[kind] += 1
            per_run[run] = kind
        n = counts["met"] + counts["not_met"]
        out[cid] = {"counts": counts, "score": (counts["met"] / n) if n else None, "runs": per_run}
    return out


def overall(table):
    scores = [v["score"] for v in table.values() if v["score"] is not None]
    return sum(scores) / len(scores) if scores else None


def judge_run(run_dir, criteria, recorded):
    """Ask the stub and the script judges for every transcript. Returns (results, requests)."""
    tdir = os.path.join(run_dir, "transcripts")
    results, requests = {}, {}
    for name in sorted(os.listdir(tdir)):
        if not name.endswith(".jsonl"):
            continue
        run = name[:-len(".jsonl")]
        path = os.path.join(tdir, name)
        req = qmod.build_request(path, criteria)
        requests[run] = req
        answers = stub_judge(req, recorded.get(run) or {})
        events = qmod.read_transcript(path)
        for c in criteria:
            if c.get("instrument") == "script":
                j = smod.JUDGES.get(c["id"])
                answers[c["id"]] = j(events) if j else None
        results[run] = answers
    return results, requests


def fmt(x):
    return "no score" if x is None else f"{x:.2f}"


def write_report(out, criteria, table, results, requests, record, floor=FLOOR):
    os.makedirs(os.path.join(out, "targets"), exist_ok=True)
    by_id = {c["id"]: c for c in criteria}
    lines = ["# Conformance report", ""]
    if record:
        lines += [f"Agent model: {record.get('agent_model')}. Prompt: {record.get('prompt_file')} "
                  f"(sha256 {record.get('prompt_sha256')}). Commit: {record.get('commit')}. "
                  f"System 1 hooks: {record.get('s1_hooks')}.", ""]
    lines += [f"Probability floor: {floor}. score = met / (met + not met); unsure and failed never "
              "count as met.", "",
              "| Criterion | Row | Met | Not met | Does not apply | Unsure | Failed | Score |",
              "|---|---|---|---|---|---|---|---|"]
    for cid, v in table.items():
        k = v["counts"]
        s = fmt(v["score"])
        if v["score"] is not None and v["score"] < 1:
            s = f"[{s}](targets/{cid}.md)"
            write_target(os.path.join(out, "targets", f"{cid}.md"), by_id[cid], v, results, requests,
                         floor)
        lines.append(f"| {cid} | {by_id[cid].get('row')} | {k['met']} | {k['not_met']} | "
                     f"{k['does_not_apply']} | {k['unsure']} | {k['failed']} | {s} |")
    lines += ["", f"One number for the run (the mean of the criterion scores, equal weight; "
              f"criteria with no score left out): {fmt(overall(table))}", ""]
    with open(os.path.join(out, "report.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


def write_target(path, c, v, results, requests, floor):
    src = c.get("source") or {}
    lines = [f"# {c['id']}", "",
             f"Row {c.get('row')} of The protocol: {src.get('philosophy')}", "",
             f"Prompt: {src.get('prompt')}", "",
             f"Score: {fmt(v['score'])}. Instrument: {c.get('instrument')}.", ""]
    for run, kind in v["runs"].items():
        if kind != "not_met":
            continue
        ans = results[run][c["id"]]
        lines += [f"## {run}", "",
                  f"Answer: not_met, probability {probability(ans):.2f} (floor {floor}).",
                  "", "Answer as returned:", "", "```json", json.dumps(ans, ensure_ascii=False),
                  "```", "", "Transcript:", "", "```text",
                  requests[run]["state"]["transcript"], "```", "",
                  "Delivery:", "", "```text", requests[run]["state"]["delivery"], "```", ""]
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


def main(argv):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("run_dir")
    ap.add_argument("--criteria", default=qmod.DEFAULT_CRITERIA)
    ap.add_argument("--answers", default=None)
    ap.add_argument("--floor", type=float, default=FLOOR)
    ap.add_argument("--out", default=None)
    a = ap.parse_args(argv)
    criteria = qmod.load_criteria(a.criteria)
    with open(a.answers or os.path.join(a.run_dir, "answers.json"), encoding="utf-8") as f:
        recorded = json.load(f)
    rec_path = os.path.join(a.run_dir, "record.json")
    record = json.load(open(rec_path, encoding="utf-8")) if os.path.exists(rec_path) else None
    results, requests = judge_run(a.run_dir, criteria, recorded)
    table = tally(results, criteria, a.floor)
    out = a.out or os.path.join(a.run_dir, "report")
    write_report(out, criteria, table, results, requests, record, a.floor)
    print(open(os.path.join(out, "report.md"), encoding="utf-8").read())
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
