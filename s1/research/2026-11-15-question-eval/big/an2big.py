import json, collections
rows = collections.defaultdict(dict)
for l in open("res2.jsonl"):
    d = json.loads(l); rows[d["arm"]][d["id"]] = d
n = lambda a, k: a[k]["noul"]
ch = lambda a, k, o: sum(a[k]["probabilities"].get(x, 0) for x in o)
RV = ["react","react2","react_rev","react_shuf","react_shuf2","react_plus","react2_plus","react2_rev","react_names","react_how","react_main"]
V = {"divergence": {"sh_divergence": lambda a: n(a,"sh_divergence"), "d_crit": lambda a: n(a,"d_crit"), "d_doubts": lambda a: n(a,"d_doubts"), "max(disp,doubt)": lambda a: max(n(a,"d_disputes"),n(a,"d_doubts")),
   "max(r_corr,r_doubt)": lambda a: max(n(a,"r_corrects"),n(a,"r_doubts")), "max(s_corr,s_doubt)": lambda a: max(n(a,"s_corrects"),n(a,"s_doubts")), "react5 faults": lambda a: ch(a,"react5",("faults",)),
   "max(sh,react)": lambda a: max(n(a,"sh_divergence"), ch(a,"react",("corrects","doubts"))), "max(sh,react,d_doubts)": lambda a: max(n(a,"sh_divergence"), ch(a,"react",("corrects","doubts")), n(a,"d_doubts")),
   "mean(sh,react)": lambda a: (n(a,"sh_divergence") + ch(a,"react",("corrects","doubts")))/2,
   "mean(react x4 orders)": lambda a: sum(ch(a,k,("corrects","doubts")) for k in ("react","react_rev","react_shuf","react_shuf2"))/4},
 "change": {"sh_change_of_plan": lambda a: n(a,"sh_change_of_plan"), "c_cand": lambda a: n(a,"c_cand"), "c_cand_ex": lambda a: n(a,"c_cand_ex"), "r_changes": lambda a: n(a,"r_changes_request"), "s_changes": lambda a: n(a,"s_changes_request"),
   "react5 chg": lambda a: ch(a,"react5",("changes_request",)), "max(c_cand,react)": lambda a: max(n(a,"c_cand"), ch(a,"react",("changes_request",)))},
 "questions": {"sh_questions": lambda a: n(a,"sh_questions"), "q_terse": lambda a: n(a,"q_terse"), "r_asks_back": lambda a: n(a,"r_asks_back"), "s_asks_back": lambda a: n(a,"s_asks_back"), "max(q_terse,react)": lambda a: max(n(a,"q_terse"), ch(a,"react",("asks_back",)))}}
for k in RV:
    V["divergence"][k] = (lambda k: lambda a: ch(a,k,("corrects","doubts")))(k)
    V["change"][k] = (lambda k: lambda a: ch(a,k,("changes_request",)))(k)
    V["questions"][k] = (lambda k: lambda a: ch(a,k,("asks_back",)))(k)
band = lambda p: "yes" if p >= .7 else "no" if p <= .3 else "unsure"
KINDS = {"divergence": ["subtle","lookalike","mix_approve_doubt","mix_dispute_add","mix_dispute_change","mix_change_doubt","doubt","change","open","paste"], "change": ["mix_dispute_change","mix_change_doubt","mix_answer_change","change","add","answer","dispute"], "questions": ["mix_answer_open","mix_answer_add","open","answer","add","lookalike"]}
def st(arm, sig, f, kind=None):
    ok = w = t = 0
    for r in rows[arm].values():
        e = r["expect"].get(sig)
        if e is None or (kind and r["kind"] != kind): continue
        g = band(f(r["a"])); t += 1; ok += g == e; w += g not in (e, "unsure")
    return ok, w, t
for sig, vs in V.items():
    print(f"\n== {sig}: agree% / wrong%  for plain | noisy | long ; then MISS% per kind (plain):", " ".join(KINDS[sig]))
    res = []
    for name, f in vs.items():
        cells = []
        for arm in ("plain","noisy","long"):
            ok, w, t = st(arm, sig, f); cells.append(f"{100*ok/t:5.1f}/{100*w/t:4.1f}")
        km = []
        for kd in KINDS[sig]:
            ok, w, t = st("plain", sig, f, kd); km.append(f"{100*(t-ok)/t:3.0f}" + ("!" if w else " "))
        ok, w, t = st("plain", sig, f); res.append((ok - w, f"{name:24} {' | '.join(cells)}   {' '.join(km)}"))
    for _, line in sorted(res, reverse=True): print(line)
# order sensitivity and repeat consistency
ids = list(rows["plain"])
def flips(f, a1, a2):
    c = t = 0; d = 0.0
    for i in ids:
        if i in rows[a1] and i in rows[a2]:
            p, q = f(rows[a1][i]["a"]), f(rows[a2][i]["a"]); t += 1; c += band(p) != band(q); d += abs(p - q)
    return f"band changes {100*c/t:.1f}% meandiff {d/t:.3f}"
print("\n== repeat runs (same request again): plain vs rep1, rep1 vs rep2")
for name, f in (("sh_divergence", V["divergence"]["sh_divergence"]), ("react div", V["divergence"]["react"]), ("c_cand", V["change"]["c_cand"]), ("q_terse", V["questions"]["q_terse"]), ("d_doubts", V["divergence"]["d_doubts"])):
    print(f"{name:14}", flips(f, "plain", "rep1"), "|", flips(f, "rep1", "rep2"))
print("\n== option order: top option of react vs reordered copies (same request)")
for k in ("react_rev","react_shuf","react_shuf2","react_how","react_main","react_names"):
    same = sum(r["a"]["react"]["choice"] == r["a"][k]["choice"] for r in rows["plain"].values()); t = len(rows["plain"])
    dd = sum(abs(ch(r["a"],"react",("corrects","doubts")) - ch(r["a"],k,("corrects","doubts"))) for r in rows["plain"].values()) / t
    print(f"{k:12} same top option {100*same/t:.1f}%  mean |dP(divergence)| {dd:.3f}")
print("\n== what react picks per kind (plain):")
for kd in ("subtle","lookalike","mix_approve_doubt","mix_dispute_change","mix_change_doubt","mix_answer_open","mix_answer_change","paste","first"):
    c = collections.Counter(r["a"]["react"]["choice"] for r in rows["plain"].values() if r["kind"] == kd); print(f"{kd:20}", dict(c.most_common(4)))
