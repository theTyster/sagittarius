"""Scaled fixtures: N claims, each with its own target model derived from m_now.

Usage: python3 -I fuzz/gen_scale.py OUT_DIR N1 N2 ...
OUT_DIR must already hold a copy of the fixture. Writes OUT_DIR/expected.pl with one
variant per N. Each variant adds, per claim i: claim, cites, a target model with a
subject and a log, derived_from, encodes, 5 model verdicts, a finding confirmed by the
order-4417 log, a question raised by a conflict finding and answered by the human.
The intended answer for every variant is the same as for the base: ready, lint clean.
"""
import sys

out_dir, sizes = sys.argv[1], [int(x) for x in sys.argv[2:]]
D = "'sha256:" + "0" * 64 + "'"
T = "'2026-10-15T11:00:00Z'"
with open(f"{out_dir}/expected.pl", "w") as f:
    for n in sizes:
        e = []
        a = 100
        for i in range(n):
            c, m, r, fr, fc, q = f"cs{i}x", f"mt{i}x", f"rt{i}x", f"fr{i}x", f"fc{i}x", f"qs{i}x"
            e += [f"claim({c}, preserve, 'x')", f"cites({c}, 'x')",
                  f"subject({m}, 'models/discount-target.smt2', {D})", f"model({m}, smt)",
                  f"subject({r}, 'logs/discount-target.log', {D})",
                  f"derived_from({m}, m_now)", f"encodes({m}, {c})"]
            for chk, res in [("sanity", "sat"), ("bad_case", "unsat"), (f"preserve({c})", "unsat"),
                             (f"applies({c})", "sat"), ("together", "sat")]:
                a += 1
                e.append(f"attest(a{a}, model_result, {r}, verdict({m}, {chk}, {res}), agent, {T})")
            a += 1
            e.append(f"attest(a{a}, model_result, {r}, mutation({m}, clamp, killed), agent, {T})")
            e += [f"finding({fr}, root_cause(x), model)", f"finding({fc}, conflict([x]), model)"]
            a += 1
            e.append(f"attest(a{a}, reproduction, log4417, confirms({fr}), agent, {T})")
            e += [f"question({q}, {c}, 'x')", f"assumed({q}, yes)", f"raised_by({q}, {fc})",
                  f"answer({q}, yes, human)"]
        name = f"s{n}x"
        f.write(f"variant({name}, [\n    " + ",\n    ".join(f"add({x})" for x in e) + "]).\n")
        f.write(f"expect({name}, 'discovery_ready', true).\n")
        f.write(f"expect({name}, 'lint_issue(Code, Id, _)', none).\n")
        f.write(f"expect({name}, 'no_falsifier(C)', none).\n")
