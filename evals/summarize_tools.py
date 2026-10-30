#!/usr/bin/env python3
"""Summarize one run_tools.sh output directory: summary.json, and a table on stderr.

Usage: summarize_tools.py OUTDIR SPEC
A run passes the checks when every check passes. An eval passes the checks when at least 2 of 3
of its runs do (for N runs: at least ceil(2N/3)); that is "passed" in summary.json.
When a rubric ran (grade_rubric.py), a run passes the rubric when every assertion passes, and
passes combined when it passes both. "passed_combined" applies the same 2-of-3 bar to those runs.
A run whose rubric is missing, empty or an error counts in "rubric_errors" and fails the rubric.
The PASS/FAIL line on stderr leads with the combined verdict when a rubric ran.
"""
import glob
import json
import math
import os
import re
import sys

out, spec = sys.argv[1], sys.argv[2]
evals = json.load(open(spec))["evals"]
summary = {"meta": json.load(open(os.path.join(out, "meta.json"))), "evals": []}
for e in evals:
    grades = sorted(g for g in glob.glob(os.path.join(out, f"{e['id']}-{e['name']}*.grade.json"))
                    if re.search(r"(\.r\d+)?\.grade\.json$", g))
    if not grades:
        continue
    runs, checks, rubric, rstat = [], {}, {}, []
    for g in grades:
        d = json.load(open(g))
        runs.append(all(c["passed"] for c in d["checks"]))
        for c in d["checks"]:
            checks.setdefault(c["text"], []).append(c["passed"])
        rb = g[:-len(".grade.json")] + ".rubric.json"
        rstat.append(None)  # None: missing or failed
        if os.path.exists(rb):
            try:
                asr = json.load(open(rb))["assertions"]
                if asr:
                    for a in asr:
                        rubric.setdefault(a["assertion"], []).append(bool(a["passed"]))
                    rstat[-1] = all(a["passed"] for a in asr)
            except (json.JSONDecodeError, KeyError, TypeError):
                pass
    n, k = len(runs), sum(runs)
    bar = math.ceil(2 * n / 3)
    used = bool(glob.glob(os.path.join(out, "*.rubric.json")))
    both = sum(c and r is True for c, r in zip(runs, rstat))
    summary["evals"].append({
        "id": e["id"], "name": e["name"], "runs": n, "passed_runs": k,
        "passed": k >= bar,
        **({"rubric_passed_runs": sum(r is True for r in rstat), "combined_passed_runs": both,
            "rubric_errors": rstat.count(None), "passed_combined": both >= bar} if used else {}),
        "checks": {t: f"{sum(v)}/{len(v)}" for t, v in checks.items()},
        "rubric": {t: f"{sum(v)}/{len(v)}" for t, v in rubric.items()},
    })
json.dump(summary, open(os.path.join(out, "summary.json"), "w"), indent=2)
m = summary["meta"]
print(f"model {m['model']}, prompt {m['prompt']}, {m['runs']} run(s) each, commit {m['commit']}{' (dirty)' if m['dirty'] else ''}", file=sys.stderr)
for s in summary["evals"]:
    weak = [f"{t[:40]} {v}" for t, v in s["checks"].items() if not v.startswith(str(s["runs"]) + "/")]
    n = s["runs"]
    if "passed_combined" in s:
        rb = f"rubric ERROR {s['rubric_errors']}/{n}" if s["rubric_errors"] else f"rubric {s['rubric_passed_runs']}/{n}"
        line = (f"{'PASS' if s['passed_combined'] else 'FAIL'} {s['id']:>3} {s['name']:<32} combined {s['combined_passed_runs']}/{n}"
                f"   checks {'PASS' if s['passed'] else 'FAIL'} {s['passed_runs']}/{n}   {rb}")
    else:
        line = f"{'PASS' if s['passed'] else 'FAIL'} {s['id']:>3} {s['name']:<32} checks {s['passed_runs']}/{n}"
    print(f"  {line}" + (f"   short: {'; '.join(weak)}" if weak else ""), file=sys.stderr)
ev = summary["evals"]
print(f"  {sum(s['passed'] for s in ev)}/{len(ev)} evals pass the checks", file=sys.stderr)
if any("passed_combined" in s for s in ev):
    print(f"  {sum(s.get('passed_combined', s['passed']) for s in ev)}/{len(ev)} evals pass combined", file=sys.stderr)
    bad = sum(s.get("rubric_errors", 0) for s in ev)
    if bad:
        print(f"  !! {bad} run(s) have a missing or failed rubric", file=sys.stderr)
