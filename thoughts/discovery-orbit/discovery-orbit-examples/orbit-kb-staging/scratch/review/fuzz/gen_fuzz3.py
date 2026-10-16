"""Targeted fuzz: random small perturbations of the real fixture (which is ready).

Usage: python3 -I fuzz/gen_fuzz3.py OUT_DIR SEED COUNT
OUT_DIR must already hold a copy of the fixture (kb.pl, logs, models, runs).
It stresses the negated helpers of discovery_ready: refuted/1 (5 body-only variables),
defeated/1 (A \\= B under negation, through to_ask/1), and model trust.
"""
import os
import random
import sys

out_dir, seed, count = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
rng = random.Random(seed)
T = "'2026-10-15T11:00:00Z'"
QUERIES = ["discovery_ready", "some_current_refuted", "to_ask(Q)", "no_falsifier(C)",
           "model_trusted(M)", "lint_issue(Code, Id, _)", "finding_lead(F)"]


def variant():
    edits = []
    n = [18]

    def att(typ, subj, pred, by="agent"):
        n[0] += 1
        edits.append(f"add(attest(a{n[0]}, {typ}, {subj}, {pred}, {by}, {T}))")

    claims = ["c1", "c2", "c2b"]
    menu = list(range(12))
    for k in rng.sample(menu, rng.randint(1, 5)):
        if k == 0:
            att("disproof", "m_target", f"verdict({rng.choice(claims)}, "
                f"{rng.choice(['refuted', 'inconclusive', 'abstained'])})")
        elif k == 1:
            att(rng.choice(["divergence", "decision", "model_result"]), rng.choice(["run_now", "zz"]),
                f"verdict({rng.choice(claims + ['c9'])}, refuted)")
        elif k == 2:
            att("model_result", rng.choice(["run_now", "run_target"]),
                f"verdict({rng.choice(['m_now', 'm_target'])}, sanity, {rng.choice(['unsat', 'unknown', 'sat'])})")
        elif k == 3:
            q1, q2 = "q5", "q6"
            c = rng.choice(["c2b", "c2", "c1"])
            edits += [f"add(question({q1}, {c}, 'x'))", f"add(question({q2}, {rng.choice(['c2b', 'c2'])}, 'x'))",
                      f"add(assumed({q1}, yes))", f"add(depends({q2}, {q1}))"]
            for _ in range(rng.randint(1, 3)):
                edits.append(f"add(answer({q1}, {rng.choice(['yes', 'no'])}, {rng.choice(['human', 'agent'])}))")
            if rng.random() < 0.3:
                edits.append(f"add(assumed({q1}, {rng.choice(['no', 'maybe'])}))")
            if rng.random() < 0.3:
                edits.append(f"add(answer({q2}, yes, {rng.choice(['human', 'agent'])}))")
        elif k == 4:
            edits += ["add(claim(c3, preserve, 'x'))", "add(cites(c3, 'x'))",
                      f"add(supersedes(c3, {rng.choice(claims)}))"]
            if rng.random() < 0.6:
                edits.append(f"add(encodes({rng.choice(['m_now', 'm_target'])}, c3))")
        elif k == 5:
            att("reproduction", rng.choice(["run_target", "zz", "log4417"]),
                f"confirms({rng.choice(['f1', 'f2', 'f9'])})")
        elif k == 6:
            edits.append(f"add(finding(f7, {rng.choice(['surprise(x)', 'trace(x)', 'root_cause(x)'])}, "
                         f"{rng.choice(['model', 'system'])}))")
            if rng.random() < 0.5:
                att("reproduction", "log4417", "confirms(f7)")
        elif k == 7:
            edits.append(f"add(derived_from({rng.choice(['m_now', 'm_target'])}, {rng.choice(['m_now', 'm_target'])}))")
        elif k == 8:
            att("model_result", "run_target",
                f"mutation({rng.choice(['m_now', 'm_target'])}, {rng.choice(['clamp', 'floor'])}, "
                f"{rng.choice(['survived', 'killed'])})")
            if rng.random() < 0.5:
                edits.append(f"add(reason({rng.choice(['clamp', 'floor'])}, 'x'))")
        elif k == 9:
            att("model_result", "run_now",
                f"calibration({rng.choice(['m_now', 'm_target'])}, k{rng.randint(1, 3)}, "
                f"{rng.choice(['matches', 'differs'])})")
        elif k == 10:
            att("divergence", "run_target", f"claim({rng.choice(claims)})")
        elif k == 11:
            edits.append(f"add(check(t{rng.randint(2, 3)}, {rng.choice(claims)}))")
    return edits


with open(os.path.join(out_dir, "expected.pl"), "w") as f:
    for i in range(count):
        name = f"y{seed}x{i}"
        edits = variant()
        f.write(f"variant({name}, [\n    " + ",\n    ".join(edits) + "]).\n")
        for q in QUERIES:
            f.write(f"expect({name}, '{q}', none).\n")
