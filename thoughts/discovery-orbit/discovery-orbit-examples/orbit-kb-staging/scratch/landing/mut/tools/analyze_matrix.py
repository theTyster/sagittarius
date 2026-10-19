"""Summarize a variant-kill matrix (LANDING review).

Usage: python3 -I analyze_matrix.py MATRIX_JSON MUT_DIR [MUT_DIR ...]
Prints: totals; duplicates across mutant sets (same file content); for each variant the
number of mutants it kills and the mutants that only it kills; the survivors.
"""
import collections
import hashlib
import json
import os
import sys

m = json.load(open(sys.argv[1]))
dirs = sys.argv[2:]
content = {}
for d in dirs:
    for f in os.listdir(d):
        if f.endswith(".pl"):
            content[f[:-3]] = hashlib.sha256(open(os.path.join(d, f), "rb").read()).hexdigest()
groups = collections.defaultdict(list)
for k in m:
    groups[content.get(k, k)].append(k)
dups = [sorted(v) for v in groups.values() if len(v) > 1]
uniq = {sorted(v)[0] for v in groups.values()}
killed = {k for k, v in m.items() if v["killed_by"]}
print(f"mutants: {len(m)}; killed: {len(killed)} ({100.0 * len(killed) / len(m):.1f}%)")
print(f"distinct mutants (by content): {len(uniq)}; killed: {len(uniq & killed)} "
      f"({100.0 * len(uniq & killed) / len(uniq):.1f}%)")
print("duplicates across sets:", dups)
by_variant = collections.defaultdict(set)
for k, v in m.items():
    for var in v["killed_by"]:
        by_variant[var].add(k)
print("\nper variant: kills / unique kills")
for var in sorted(by_variant, key=lambda x: (-len(by_variant[x]), x)):
    only = sorted(k for k in by_variant[var] if m[k]["killed_by"] == [var])
    print(f"  {var}: {len(by_variant[var])} / {len(only)} {only}")
print("\nsurvivors:")
for k in sorted(set(m) - killed):
    print(f"  {k}\t{m[k]['op']}\t{m[k]['clause'][:100]}\t{m[k]['detail']}")
