"""LANDING fuzz: random KBs over the CURRENT discovery vocabulary (model_run, digests,
discovery_evidence, reason/3, calibration cases, budgets, decisions, supersession chains).

Adapted from scratch/review/fuzz/gen_fuzz.py (small random KBs) and gen_fuzz3.py
(perturbations of the real fixture), whose vocabulary predates the IGNITION module.

Usage: python3 -I gen_fuzz_l.py small OUT_DIR SEED COUNT
       python3 -I gen_fuzz_l.py pert  OUT_DIR SEED COUNT   (OUT_DIR holds a fixture copy)
Writes OUT_DIR/expected.pl (and kb.pl for small). Expectations use a dummy answer; the
point is the harness ENGINE DISAGREEMENT check (SWI against s(CASP) --forall=prev).
"""
import os
import random
import sys

mode, out_dir, seed, count = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
rng = random.Random(seed)
D1 = "'sha256:" + "1" * 64 + "'"
D2 = "'sha256:" + "2" * 64 + "'"
D3 = "'sha256:" + "3" * 64 + "'"
T = "'2026-10-15T09:00:00Z'"
QUERIES = ["discovery_ready", "no_falsifier(C)", "model_trusted(M)", "lint_issue(Code, Id, _)",
           "model_unfiled_break(C)", "discovery_unratified(C)", "discovery_decide"]
RESULTS = ["sat", "sat", "unsat", "unsat", "unknown", "reached", "violated", "holds"]


def small():
    facts = []
    aid = [0]

    def att(typ, subj, pred, by="agent"):
        aid[0] += 1
        facts.append(f"attest(a{aid[0]}, {typ}, {subj}, {pred}, {by}, {T})")

    claims = rng.sample(["c1", "c2", "c3"], rng.randint(0, 3))
    for c in claims:
        facts.append(f"claim({c}, {rng.choice(['preserve', 'retire', 'introduce'])}, 'x')")
        facts.append(f"cites({c}, 'x')")
    for _ in range(rng.randint(0, 2)):
        if len(claims) >= 2:
            a, b = rng.sample(claims, 2)
            facts.append(f"supersedes({a}, {b})")
    if claims and rng.random() < 0.4:
        c = rng.choice(claims)
        facts.append(f"check(k1, {c})")
        facts.append(f"discovery_evidence(k1, {rng.choice(['system', 'system', 'model'])})")
    hyps = rng.sample(["h1", "h2"], rng.randint(0, 2))
    for h in hyps:
        facts.append(f"hypothesis({h}, {rng.choice(['defect', 'feature', 'risk'])}, 'x')")
    logs = rng.sample(["l1", "l2"], rng.randint(0, 2))
    for lg in logs:
        facts.append(f"subject({lg}, 'p', {D3})")
        if rng.random() < 0.8:
            facts.append(f"discovery_evidence({lg}, {rng.choice(['system', 'system', 'model'])})")
    models = rng.sample(["m1", "m2"], rng.randint(0, 2))
    digest = {"m1": D1, "m2": D2}
    runs = []
    for m in models:
        if rng.random() < 0.9:
            facts.append(f"subject({m}, 'p', {digest[m]})")
        facts.append(f"model({m}, {rng.choice(['smt', 'smt', 'tla'])})")
        for i in range(rng.randint(0, 2)):
            r = f"r{m[1]}{i}"
            runs.append((r, m))
            facts.append(f"subject({r}, 'p', {D3})")
            d = digest[m] if rng.random() < 0.8 else rng.choice([D1, D2, D3])
            facts.append(f"model_run({r}, {m}, {d})")
            if rng.random() < 0.3:   # F2: the same log reused at another digest
                facts.append(f"model_run({r}, {m}, {rng.choice([D1, D2, D3])})")
    if models:
        for _ in range(rng.randint(0, 2)):
            facts.append(f"derived_from({rng.choice(models)}, {rng.choice(models)})")
        for _ in range(rng.randint(0, 3)):
            if claims:
                facts.append(f"encodes({rng.choice(models)}, {rng.choice(claims)})")
    subjects = [r for r, _ in runs] + logs + models
    if models and subjects:
        kinds = ["sanity", "sanity", "bad_case", "root_cause(x)", "explore(w)"]
        if claims:
            kinds += [f"preserve({c})" for c in claims] + [f"applies({c})" for c in claims]
        for _ in range(rng.randint(0, 6)):
            att("model_result", rng.choice(subjects),
                f"verdict({rng.choice(models)}, {rng.choice(kinds)}, {rng.choice(RESULTS)})")
        for _ in range(rng.randint(0, 2)):
            case = f"example({rng.choice(claims)})" if claims and rng.random() < 0.5 else "case('t')"
            att("model_result", rng.choice(subjects),
                f"calibration({rng.choice(models)}, {case}, {rng.choice(['matches', 'matches', 'differs'])})")
        for _ in range(rng.randint(0, 2)):
            att("model_result", rng.choice(subjects),
                f"mutation({rng.choice(models)}, {rng.choice(['ra', 'rb'])}, {rng.choice(['killed', 'survived'])})")
        if rng.random() < 0.3:
            facts.append(f"reason({rng.choice(models)}, {rng.choice(['ra', 'rb'])}, 't')")
        if rng.random() < 0.3:
            att("divergence", rng.choice(subjects), f"model({rng.choice(models)})")
    finds = rng.sample(["f1", "f2"], rng.randint(0, 2))
    fk = ["root_cause(x)", "conflict([x, y])", "surprise(x)", "trace(x)", "scope(x)"]
    for f in finds:
        facts.append(f"finding({f}, {rng.choice(fk)}, {rng.choice(['model', 'system'])})")
    all_subj = subjects + (["k1"] if any(x.startswith("check(") for x in facts) else [])
    if all_subj:
        for f in finds:
            if rng.random() < 0.5:
                att("reproduction", rng.choice(all_subj), f"confirms({f})")
        for h in hyps:
            if rng.random() < 0.8:
                att("reproduction", rng.choice(all_subj),
                    f"result({h}, {rng.choice(['reproduced', 'reproduced', 'not_reproduced'])})")
    if claims:
        for _ in range(rng.randint(0, 2)):
            att(rng.choice(["divergence", "disproof"]), rng.choice(all_subj or ["zz"]),
                rng.choice([f"claim({rng.choice(claims)})",
                            f"verdict({rng.choice(claims)}, {rng.choice(['refuted', 'inconclusive', 'abstained'])})"]))
        for i in range(rng.randint(0, 2)):
            q = f"q{i + 1}"
            facts.append(f"question({q}, {rng.choice(claims)}, 'x')")
            facts.append(f"assumed({q}, yes)")
            src = finds + hyps + claims
            if src and rng.random() < 0.6:
                facts.append(f"raised_by({q}, {rng.choice(src)})")
            if rng.random() < 0.5:
                facts.append(f"answer({q}, {rng.choice(['yes', 'no'])}, {rng.choice(['human', 'agent'])})")
    if rng.random() < 0.6:
        b = rng.randint(1, 3)
        facts.append(f"budget(laps, {b})")
        if rng.random() < 0.3:
            facts.append(f"budget(laps, {b + 1})")
        for l in range(1, rng.randint(0, 4) + 1):
            facts.append(f"lap_done({l})")
    rng.shuffle(facts)
    return [f"add({x})" for x in facts]


def pert():
    edits = []
    n = [18]

    def att(typ, subj, pred, by="agent"):
        n[0] += 1
        edits.append(f"add(attest(a{n[0]}, {typ}, {subj}, {pred}, {by}, '2026-10-15T11:00:00Z'))")

    claims = ["c1", "c2", "c2b"]
    for k in rng.sample(range(14), rng.randint(1, 4)):
        if k == 0:
            att("disproof", "m_target", f"verdict({rng.choice(claims)}, {rng.choice(['refuted', 'inconclusive', 'abstained'])})")
        elif k == 1:
            att("divergence", rng.choice(["run_now", "run_target", "m_now", "log4417"]),
                f"model({rng.choice(['m_now', 'm_target'])})")
        elif k == 2:
            att("model_result", rng.choice(["run_now", "run_target"]),
                f"verdict({rng.choice(['m_now', 'm_target'])}, {rng.choice(['sanity', 'bad_case', 'preserve(c2b)', 'applies(c1)', 'root_cause(x)'])}, {rng.choice(RESULTS)})")
        elif k == 3:
            att("model_result", rng.choice(["run_now", "run_target"]),
                f"calibration({rng.choice(['m_now', 'm_target'])}, case('t'), {rng.choice(['matches', 'differs'])})")
        elif k == 4:
            edits += ["add(claim(c3, preserve, 'x'))", "add(cites(c3, 'x'))",
                      f"add(supersedes(c3, {rng.choice(claims)}))"]
            if rng.random() < 0.6:
                edits.append(f"add(encodes({rng.choice(['m_now', 'm_target'])}, c3))")
                att("model_result", "run_target", f"verdict(m_target, preserve(c3), {rng.choice(RESULTS)})")
        elif k == 5:
            att("reproduction", rng.choice(["run_target", "log4417", "t1", "m_now"]),
                f"{rng.choice(['confirms(f1)', 'result(h1, not_reproduced)', 'result(h1, reproduced)'])}")
        elif k == 6:
            edits.append(f"add(finding(f7, {rng.choice(['surprise(x)', 'trace(x)', 'scope(x)', 'root_cause(x)'])}, {rng.choice(['model', 'system'])}))")
            if rng.random() < 0.5:
                edits.append("add(question(q7, c1, 'x'))")
                edits.append(f"add(raised_by(q7, {rng.choice(['f7', 'h1', 'c1'])}))")
                if rng.random() < 0.5:
                    edits.append("add(answer(q7, yes, human))")
        elif k == 7:
            edits.append(f"add(derived_from({rng.choice(['m_now', 'm_target'])}, {rng.choice(['m_now', 'm_target'])}))")
        elif k == 8:
            att("model_result", rng.choice(["run_now", "run_target"]),
                f"mutation({rng.choice(['m_now', 'm_target'])}, {rng.choice(['clamp', 'floor'])}, {rng.choice(['survived', 'killed'])})")
            if rng.random() < 0.5:
                edits.append(f"add(reason({rng.choice(['m_now', 'm_target'])}, {rng.choice(['clamp', 'floor'])}, 'x'))")
        elif k == 9:
            if rng.random() < 0.5:
                edits.append("add(model_run(run_now, m_now, 'sha256:" + "4" * 64 + "'))")
            edits.append("replace(subject(m_now, 'models/discount-now.smt2', 'sha256:25847de81516893a8ab780844edf1c3c4eb3eb97b459d06f353f40d9e39b72db'), "
                         "subject(m_now, 'models/discount-now.smt2', 'sha256:" + "4" * 64 + "'))")
        elif k == 10:
            edits.append(f"add(discovery_evidence({rng.choice(['log4417', 'run_now', 'm_target'])}, {rng.choice(['system', 'model'])}))")
        elif k == 11:
            edits.append(f"add(budget(laps, {rng.choice([1, 2, 5])}))")
            edits.append(f"add(lap_done({rng.choice([2, 3])}))")
        elif k == 12:
            edits.append("add(hypothesis(h2, risk, 'x'))")
            if rng.random() < 0.6:
                att("reproduction", "log4417", f"result(h2, {rng.choice(['reproduced', 'not_reproduced'])})")
        elif k == 13:
            att("divergence", "run_target", f"claim({rng.choice(claims)})")
            if rng.random() < 0.5:
                edits.append(f"add(question(q8, {rng.choice(claims)}, 'x'))")
    return edits


os.makedirs(out_dir, exist_ok=True)
if mode == "small":
    with open(os.path.join(out_dir, "kb.pl"), "w") as f:
        f.write("uses([discovery]).\n")
prefix = "s" if mode == "small" else "p"
with open(os.path.join(out_dir, "expected.pl"), "w") as f:
    for i in range(count):
        name = f"{prefix}{seed}x{i}"
        edits = small() if mode == "small" else pert()
        f.write(f"variant({name}, [\n    " + ",\n    ".join(edits) + "]).\n")
        for q in QUERIES:
            f.write(f"expect({name}, '{q}', none).\n")
