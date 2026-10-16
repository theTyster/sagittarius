"""Generate a fuzz fixture: random small KBs over the discovery vocabulary.

Usage: python3 -I fuzz/gen_fuzz.py OUT_DIR SEED COUNT
Writes OUT_DIR/kb.pl (only uses/1) and OUT_DIR/expected.pl with COUNT variants. Each
variant adds a random set of facts. Expectations use a dummy answer; the point is the
harness ENGINE DISAGREEMENT check, which compares SWI with s(CASP).
"""
import os
import random
import sys

out_dir, seed, count = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
rng = random.Random(seed)
DIG = "'sha256:" + "0" * 64 + "'"
T = "'2026-10-15T09:00:00Z'"
QUERIES = ["no_falsifier(C)", "model_trusted(M)", "finding_lead(F)", "discovery_ready",
           "lint_issue(Code, Id, _)", "weak_rule(R)", "question_waits(Q)"]


def pick(xs, lo, hi):
    return rng.sample(xs, rng.randint(lo, min(hi, len(xs))))


def kb():
    facts = []
    aid = [0]

    def att(typ, subj, pred, by="agent"):
        aid[0] += 1
        facts.append(f"attest(a{aid[0]}, {typ}, {subj}, {pred}, {by}, {T})")

    claims = pick(["c1", "c2", "c3"], 1, 3)
    models = pick(["m1", "m2", "m3"], 0, 3)
    logs = pick(["l1", "l2"], 0, 2)
    finds = pick(["f1", "f2", "f3"], 0, 3)
    for c in claims:
        facts.append(f"claim({c}, {rng.choice(['preserve', 'retire', 'introduce'])}, 'x')")
    for _ in range(rng.randint(0, 2)):
        a, b = rng.choice(claims), rng.choice(claims)
        if a != b:
            facts.append(f"supersedes({a}, {b})")
    for i in range(rng.randint(0, 2)):
        facts.append(f"check(k{i + 1}, {rng.choice(claims)})")
    for s in models + logs:
        if rng.random() < 0.8:
            facts.append(f"subject({s}, 'p', {DIG})")
    for m in models:
        facts.append(f"model({m}, {rng.choice(['smt', 'tla'])})")
    subjects = models + logs + ["zz"]
    if models:
        for _ in range(rng.randint(0, 2)):
            facts.append(f"derived_from({rng.choice(models)}, {rng.choice(models)})")
        for _ in range(rng.randint(0, 4)):
            facts.append(f"encodes({rng.choice(models)}, {rng.choice(claims)})")
        for _ in range(rng.randint(0, 4)):
            att("model_result", rng.choice(subjects),
                f"verdict({rng.choice(models)}, {rng.choice(['sanity', 'sanity', 'bad_case'])}, "
                f"{rng.choice(['sat', 'sat', 'unsat', 'reached'])})")
        for _ in range(rng.randint(0, 3)):
            att("model_result", rng.choice(subjects),
                f"calibration({rng.choice(models)}, k{rng.randint(1, 2)}case, "
                f"{rng.choice(['matches', 'matches', 'differs'])})")
        for _ in range(rng.randint(0, 2)):
            att("model_result", rng.choice(subjects),
                f"mutation({rng.choice(models)}, r{rng.randint(1, 2)}, "
                f"{rng.choice(['killed', 'survived'])})")
    kinds = ["root_cause(x)", "conflict([x, y])", "surprise(x)", "trace(x)", "scope(x)"]
    for f in finds:
        facts.append(f"finding({f}, {rng.choice(kinds)}, {rng.choice(['model', 'model', 'system'])})")
    if finds:
        for _ in range(rng.randint(0, 3)):
            att("reproduction", rng.choice(subjects), f"confirms({rng.choice(finds)})")
    if rng.random() < 0.5:
        facts.append("hypothesis(h1, defect, 'x')")
        att("reproduction", rng.choice(subjects), "result(h1, reproduced)")
    for _ in range(rng.randint(0, 2)):
        att(rng.choice(["divergence", "disproof"]), rng.choice(subjects),
            rng.choice([f"claim({rng.choice(claims)})", f"verdict({rng.choice(claims)}, refuted)"]))
    qs = []
    for i in range(rng.randint(0, 2)):
        q = f"q{i + 1}"
        qs.append(q)
        facts.append(f"question({q}, {rng.choice(claims)}, 'x')")
        if finds and rng.random() < 0.7:
            facts.append(f"raised_by({q}, {rng.choice(finds)})")
        if rng.random() < 0.5:
            facts.append(f"answer({q}, yes, {rng.choice(['human', 'agent'])})")
    if rng.random() < 0.4:
        facts.append("reason(r1, 'x')")
    if rng.random() < 0.3:
        att("test_result", "k1", "result(k1, 1, fail)", by="script")
    rng.shuffle(facts)
    return facts


os.makedirs(out_dir, exist_ok=True)
with open(os.path.join(out_dir, "kb.pl"), "w") as f:
    f.write("uses([discovery]).\n")
with open(os.path.join(out_dir, "expected.pl"), "w") as f:
    for i in range(count):
        name = f"z{seed}x{i}"
        facts = kb()
        f.write(f"variant({name}, [\n    " + ",\n    ".join(f"add({x})" for x in facts) + "]).\n")
        for q in QUERIES:
            f.write(f"expect({name}, '{q}', none).\n")
