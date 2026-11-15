import json, sys, collections
sys.path.insert(0, "."); import gen
TOP = int(sys.argv[1]) if len(sys.argv) > 1 else 9
LEN = {c["id"]: len(c["message"]) for c in gen.cases()}
rows = collections.defaultdict(list)
for l in open("res.jsonl"):
    d = json.loads(l); rows[d["arm"]].append(d)
n = lambda a, k: a[k]["noul"]
def ch(a, k, opts): return sum(a[k]["probabilities"].get(o, 0) for o in opts)
def lv(a, k, ls): return sum(a[k]["probabilities"][str(i)] for i in ls)
def mean(*ks): return lambda a, r: sum(n(a, k) for k in ks) / len(ks)
def mx(*ks): return lambda a, r: max(n(a, k) for k in ks)
def N(k): return lambda a, r: n(a, k)
def I(k): return lambda a, r: 1 - n(a, k)
has_agent = lambda r: r["kind"] not in ("first", "spec", "paste") and not r["kind"].startswith(("work_", "tool_")) if r["kind"] != "hand" else True
V = {
 "divergence": dict({k: N(k) for k in ("sh_divergence","d_crit","d_unhappy","d_pushback","d_stmt","d_redo","d_disputes","d_doubts","d_misread","d_criticize","d_complaint","d_disagree","d_surprise")},
    **{"1-d_accepts": I("d_accepts"), "1-d_trust": I("d_trust"), "d_score P(1,2)": lambda a, r: lv(a, "d_score", (1, 2)), "react corr+doubt": lambda a, r: ch(a, "react", ("corrects", "doubts")),
       "react2 corr+doubt": lambda a, r: ch(a, "react2", ("corrects", "doubts")), "max(disp,doubt)": mx("d_disputes", "d_doubts"), "mean(sh,crit,complaint)": mean("sh_divergence", "d_criticize", "d_complaint"),
       "mean(sh,d_crit)": mean("sh_divergence", "d_crit"), "mean(5)": mean("sh_divergence", "d_crit", "d_criticize", "d_complaint", "d_pushback"),
       "mean(sh,dscore)": lambda a, r: (n(a, "sh_divergence") + lv(a, "d_score", (1, 2))) / 2}),
 "change": dict({k: N(k) for k in ("sh_change_of_plan","c_cand","c_nocrit","c_differs","c_stmt","c_cancel","c_conflict","c_cand_ex")},
    **{"1-c_still_ok": I("c_still_ok"), "1-c_only_adds": I("c_only_adds"), "c_score P2": lambda a, r: lv(a, "c_score", (2,)), "react chg": lambda a, r: ch(a, "react", ("changes_request",)),
       "react2 chg": lambda a, r: ch(a, "react2", ("changes_request",)), "mean(cand,cancel,ex)": mean("c_cand", "c_cancel", "c_cand_ex"), "mean(cand,ex)": mean("c_cand", "c_cand_ex")}),
 "questions": dict({k: N(k) for k in ("sh_questions","q_terse","q_undecided","q_asks_back","q_lacks","q_stmt")},
    **{"1-q_fully": I("q_fully"), "1-q_can_start": I("q_can_start"), "q_score P(1,2)": lambda a, r: lv(a, "q_score", (1, 2)), "react asks_back": lambda a, r: ch(a, "react", ("asks_back",)),
       "react2 asks_back": lambda a, r: ch(a, "react2", ("asks_back",)), "max(undec,back)": mx("q_undecided", "q_asks_back"), "mean(sh,terse)": mean("sh_questions", "q_terse"),
       "sh*agent_asked": lambda a, r: n(a, "sh_questions") * (n(a, "q_agent_asked") >= .5), "mean(sh,terse,lacks)": mean("sh_questions", "q_terse", "q_lacks")}),
 "proof": dict({k: N(k) for k in ("sh_proof","p_terse","p_asks","p_every","p_stmt","p_bare","p_universal")},
    **{"1-p_tests_enough": I("p_tests_enough"), "max(asks,every)": mx("p_asks", "p_every"), "mean(sh,terse,bare)": mean("sh_proof", "p_terse", "p_bare")}),
 "effort": dict({k: N(k) for k in ("sh_effort","e_terse","e_minutes","e_decisions","e_own_words","e_stmt")},
    **{"e_score P2": lambda a, r: lv(a, "e_score", (2,)), "e_score/2": lambda a, r: a["e_score"]["score"] / 2, "code len>=300": lambda a, r: float(LEN.get(r["id"], 0) >= 300),
       "len>=300 & !pasted": lambda a, r: float(LEN.get(r["id"], 0) >= 300) * (1 - n(a, "e_pasted")), "sh*(1-pasted)": lambda a, r: n(a, "sh_effort") * (1 - n(a, "e_pasted")), "mean(sh,terse,stmt)": mean("sh_effort", "e_terse", "e_stmt")}),
}
def auc(ys, ns):
    if not ys or not ns: return float("nan")
    al = sorted([(p, 1) for p in ys] + [(p, 0) for p in ns]); rk = {}; i = 0
    s = 0.0
    while i < len(al):
        j = i
        while j < len(al) and al[j][0] == al[i][0]: j += 1
        for k in range(i, j):
            if al[k][1]: s += (i + j + 1) / 2
        i = j
    return (s - len(ys) * (len(ys) + 1) / 2) / (len(ys) * len(ns))
def stats(rs, sig, f):
    ys = []; ns = []; bad = collections.Counter(); tot = collections.Counter()
    for r in rs:
        e = r["expect"].get(sig)
        if e is None: continue
        p = f(r["a"], r); (ys if e == "yes" else ns).append(p); tot[r["kind"]] += 1
        g = "yes" if p >= .7 else "no" if p <= .3 else "unsure"
        if g != e: bad[(r["kind"], g != "unsure")] += 1
    agree = 1 - sum(bad.values()) / max(len(ys) + len(ns), 1); wrong = sum(v for (k, w), v in bad.items() if w) / max(len(ys) + len(ns), 1)
    return auc(ys, ns), agree, wrong, bad, tot, len(ys), len(ns)
ARMS = [a for a in ("plain", "long", "tail", "lower", "inject") if a in rows]
print("rows per arm:", {a: len(rows[a]) for a in ARMS})
for part, sel in (("GENERATED", lambda r: r["kind"] != "hand"), ("HAND (104 cases)", lambda r: r["kind"] == "hand")):
    print("\n########", part)
    for sig, vs in V.items():
        res = {name: {a: stats([r for r in rows[a] if sel(r)], sig, f) for a in ARMS} for name, f in vs.items()}
        order = sorted(res, key=lambda k: -(res[k]["plain"][1] - res[k]["plain"][2]))
        s0 = res[order[0]]["plain"]
        print(f"\n== {sig}  (yes {s0[5]}, no {s0[6]})   columns per arm: AUC agree% wrong%   [arms: {' '.join(ARMS)}]")
        shown = order[:TOP] + [k for k in order[TOP:] if k.startswith("sh_")]
        for k in shown:
            line = f"{k:24}" + " | ".join(f"{res[k][a][0]:.3f} {100*res[k][a][1]:5.1f} {100*res[k][a][2]:4.1f}" for a in ARMS)
            b = res[k]["plain"][3]; t = res[k]["plain"][4]
            kinds = collections.Counter(); 
            for (kd, w), v in b.items(): kinds[kd] += v
            line += "  miss: " + " ".join(f"{kd}:{v}/{t[kd]}" for kd, v in kinds.most_common(3)) if part == "GENERATED" else ""
            print(line)
        if part == "GENERATED": print("   worst:", " ".join(f"{k}({100*res[k]['plain'][1]:.0f})" for k in order[-4:]))
# work / tool
def acc(rs, key, f):
    ok = t = 0
    for r in rs:
        e = r["expect"].get(key)
        if e is None: continue
        t += 1; ok += f(r["a"]) == e
    return f"{ok}/{t}"
def top(a, k): x = a[k]; return x["choice"] if x["probabilities"][x["choice"]] >= .5 else "unsure"
W = {"sh_work": lambda a: top(a, "sh_work"), "w_verbs": lambda a: top(a, "w_verbs"), "w_noother+is_request": lambda a: "other" if n(a, "w_is_request") <= .3 else top(a, "w_noother")}
tl = lambda x: "none" if x in ("tests", "none") else x
L = {"sh_language": lambda a: tl(top(a, "sh_language")), "l_notool gated by nouls": lambda a: top(a, "l_notool") if max(n(a, "l_rules"), n(a, "l_order"), n(a, "l_owners"), n(a, "p_asks")) >= .7 else "none",
     "l_notool gated by l_needs": lambda a: top(a, "l_notool") if n(a, "l_needs") >= .5 else "none"}
print("\n== work (choice with P>=0.5 equals the label)")
for k, f in W.items(): print(f"{k:24}", " | ".join(f"{a} {acc(rows[a], 'work', f)}" for a in ARMS if a in ("plain", "lower", "inject")))
print("== tool (tests and none both count as none)")
for k, f in L.items(): print(f"{k:24}", " | ".join(f"{a} {acc([dict(r, expect=dict(r['expect'], tool=tl(r['expect']['tool']))) for r in rows[a] if 'tool' in r['expect']], 'tool', f)}" for a in ARMS if a in ("plain", "lower", "inject")))
