#!/usr/bin/env python3
"""Compare the time, turns, and cost of eval runs. Usage: speed.py RUN_DIR [RUN_DIR ...]

For each run directory, prints one row per case: the median wall time, agent turns, and cost
over its runs (all turns of a session summed). Use it to measure what a prompt change costs:
run the same cases at the base and with the change, then pass both directories.
"""
import glob
import json
import os
import re
import statistics
import sys


def session_totals(path_glob):
    """Sum duration_ms, num_turns, and total_cost_usd over the result events of one run."""
    ms = turns = cost = 0
    for path in glob.glob(path_glob):
        for line in open(path):
            try:
                ev = json.loads(line)
            except ValueError:
                continue
            if ev.get("type") == "result":
                ms += ev.get("duration_ms") or 0
                turns += ev.get("num_turns") or 0
                cost += ev.get("total_cost_usd") or 0
    return ms, turns, cost


def main(dirs):
    for d in dirs:
        meta = json.load(open(os.path.join(d, "summary.json")))["meta"]
        print(f"{os.path.basename(d.rstrip('/'))}  model={meta['model']}  prompt={os.path.basename(meta['prompt'])}")
        cases = {}
        for f in glob.glob(os.path.join(d, "*.r[0-9].jsonl")):
            m = re.match(r"(\d+)-.*\.r(\d+)\.jsonl$", os.path.basename(f))
            if m:
                cases.setdefault(int(m.group(1)), []).append(f)
        for case in sorted(cases):
            rows = []
            for f in cases[case]:
                stem = f[: -len(".jsonl")]
                turn_files = glob.glob(stem + ".t*.jsonl")
                rows.append(session_totals(stem + ".t*.jsonl") if turn_files else session_totals(f))
            ms, turns, cost = (statistics.median(x) for x in zip(*rows))
            print(f"  case {case:>3}  runs={len(rows)}  time={ms / 1000:6.1f}s  turns={turns:5.1f}  cost=${cost:.3f}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    main(sys.argv[1:])
