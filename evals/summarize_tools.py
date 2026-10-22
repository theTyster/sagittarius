#!/usr/bin/env python3
"""Summarize one run_tools.sh output directory: summary.json, and a table on stderr.

Usage: summarize_tools.py OUTDIR SPEC
A run passes when every check passes. An eval passes when at least 2 of 3 of its runs pass
(for N runs: at least ceil(2N/3)). Rubric results (grade_rubric.py) are counted beside the
checks and do not decide the verdict.
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
    runs, checks, rubric = [], {}, {}
    for g in grades:
        d = json.load(open(g))
        runs.append(all(c["passed"] for c in d["checks"]))
        for c in d["checks"]:
            checks.setdefault(c["text"], []).append(c["passed"])
        rb = g[:-len(".grade.json")] + ".rubric.json"
        if os.path.exists(rb):
            try:
                for a in json.load(open(rb)).get("assertions", []):
                    rubric.setdefault(a["assertion"], []).append(bool(a.get("passed")))
            except (json.JSONDecodeError, KeyError):
                pass
    n, k = len(runs), sum(runs)
    summary["evals"].append({
        "id": e["id"], "name": e["name"], "runs": n, "passed_runs": k,
        "passed": k >= math.ceil(2 * n / 3),
        "checks": {t: f"{sum(v)}/{len(v)}" for t, v in checks.items()},
        "rubric": {t: f"{sum(v)}/{len(v)}" for t, v in rubric.items()},
    })
json.dump(summary, open(os.path.join(out, "summary.json"), "w"), indent=2)
m = summary["meta"]
print(f"model {m['model']}, prompt {m['prompt']}, {m['runs']} run(s) each, commit {m['commit']}{' (dirty)' if m['dirty'] else ''}", file=sys.stderr)
for s in summary["evals"]:
    weak = [f"{t[:40]} {v}" for t, v in s["checks"].items() if not v.startswith(str(s["runs"]) + "/")]
    print(f"  {'PASS' if s['passed'] else 'FAIL'} {s['id']:>3} {s['name']:<32} {s['passed_runs']}/{s['runs']}"
          + (f"   short: {'; '.join(weak)}" if weak else ""), file=sys.stderr)
print(f"  {sum(s['passed'] for s in summary['evals'])}/{len(summary['evals'])} evals pass", file=sys.stderr)
