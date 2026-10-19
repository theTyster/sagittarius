#!/usr/bin/env python3
"""R8 review checks: the discovery draft agrees with the module.

Usage: python3 -I harness/check_draft.py [DRAFT [MODULE]]
Exit 0 when every check passes.

Part 1 is the text from "# Part 1" up to "# Part 2". The checks:
  1. Part 1 has fewer than 3,000 words.
  2. Each row of the Facts table names a fact that the module declares, with the same arity.
  3. Every fact that the module declares has a row in the Facts table.
  4. Each query in the query table is a rule that the module or the core declares, with
     the same arity. The table holds discovery_ready and discovery_decide.
  5. Each attestation predicate that Part 1 shows in backticks (result, confirms, verdict,
     calibration, mutation, no_go, hold) has the arity that the module declares.
  6. Part 1 names every lint code of the module, and no other WD or ED code.
"""
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
DRAFT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "../../../discovery-orbit-draft.md")
MODULE = sys.argv[2] if len(sys.argv) > 2 else os.path.join(HERE, "../modules/discovery.pl")
CORE = os.path.expanduser("~/.local/share/orbit-kb/core.pl")

# Print each decl as "kind name arity", and each attest_type alternative as "attest name arity".
DUMP = r"""
:- op(900, fy, not).
main :- forall(member(F, [%s]), (
    open(F, read, S),
    repeat, read_term(S, T, []),
    ( T == end_of_file -> !, close(S)
    ; ( T = decl(K, H, _, _) -> functor(H, N, A), format("~w ~w ~w~n", [K, N, A])
      ; T = attest_type(_, Shape, _, _) -> forall(alt_member(Shape, P), ( functor(P, N, A), format("attest ~w ~w~n", [N, A]) ))
      ; true ), fail ) )).
alt_member(alt(L), P) :- !, member(X, L), alt_member(X, P).
alt_member(P, P).
"""


def dump(files):
    prog = DUMP % ", ".join("'%s'" % f for f in files)
    with tempfile.NamedTemporaryFile("w", suffix=".pl", delete=False) as fh:
        fh.write(prog)
    try:
        r = subprocess.run(["swipl", "-q", "-g", "main", "-t", "halt", fh.name],
                           capture_output=True, text=True)
    finally:
        os.unlink(fh.name)
    if r.returncode != 0:
        sys.exit("swipl failed: " + r.stderr)
    out = {"fact": {}, "rule": {}, "attest": {}}
    for line in r.stdout.split("\n"):
        if line:
            k, n, a = line.split()
            out[k][n] = int(a)
    return out


def arity(term):
    """Arity of a term written as name(args) in the draft."""
    m = re.match(r"([a-z_][a-z0-9_]*)(?:\((.*)\))?$", term.strip())
    if not m:
        return None, None
    args = m.group(2)
    if args is None:
        return m.group(1), 0
    depth, n = 0, 1
    for ch in args:
        depth += ch in "([" and 1 or 0
        depth -= ch in ")]" and 1 or 0
        n += ch == "," and depth == 0
    return m.group(1), n


text = open(DRAFT, encoding="utf-8").read()
part1 = text[text.index("# Part 1"):text.index("# Part 2")]
mod = dump([MODULE])
core = dump([CORE])
fails = 0


def report(ok, msg):
    global fails
    print(("ok    " if ok else "FAIL  ") + msg)
    fails += not ok


words = len(part1.split())
report(words < 3000, f"1 Part 1 has {words} words (limit: fewer than 3,000)")


def table_after(heading):
    i = part1.find(heading)
    if i < 0:
        return []
    rows = []
    for line in part1[i:].split("\n")[1:]:
        if line.startswith("|"):
            cells = [c.strip() for c in line.strip("|").split("|")]
            m = re.match(r"`([^`]+)`", cells[0])
            if m:
                rows.append(m.group(1))
        elif rows:
            break
    return rows


facts = table_after("Facts:")
bad = []
for f in facts:
    n, a = arity(f)
    if mod["fact"].get(n) != a:
        bad.append(f"{f} (module: {n}/{mod['fact'].get(n)})")
report(facts and not bad, f"2 Facts table rows match module facts: {bad or 'all ' + str(len(facts))}")
named = {arity(f)[0] for f in facts}
missing = sorted(set(mod["fact"]) - named)
report(not missing, f"3 every module fact has a row: missing {missing}")

queries = table_after("| Query |")
bad = []
for q in queries:
    n, a = arity(q)
    if mod["rule"].get(n, core["rule"].get(n)) != a:
        bad.append(q)
gate = {"discovery_ready", "discovery_decide"} - {arity(q)[0] for q in queries}
report(queries and not bad and not gate,
       f"4 query table: unknown or wrong arity {bad}; gate rules missing {sorted(gate)}")

bad = []
for name, a in mod["attest"].items():
    for m in re.finditer(r"`(" + name + r"\([^`]*\))`", part1):
        if arity(m.group(1))[1] != a:
            bad.append(m.group(1))
report(not bad, f"5 attestation predicates have the module's arity: wrong {bad}")

mod_codes = set(re.findall(r"lint_issue\('([A-Z]+[0-9]+)'", open(MODULE).read()))
draft_codes = set(re.findall(r"\b([WE]D[0-9]+)\b", part1))
report(mod_codes == draft_codes,
       f"6 lint codes: not in draft {sorted(mod_codes - draft_codes)}; not in module {sorted(draft_codes - mod_codes)}")

sys.exit(1 if fails else 0)
