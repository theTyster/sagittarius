import json, collections
R = collections.defaultdict(dict)
for l in open("res3.jsonl"):
    d = json.loads(l); R[d["id"]][(d["shape"], d["arm"])] = d
n = lambda a, k: a[k]["noul"]
def cd(a, k="react"): p = a[k]["probabilities"]; return p["corrects"] + p["doubts"]
def sk(r, name, f=n):
    a = r[("sent", "plain")]["a"]; return max(f(a, f"{name}@{i}") for i in range(r[("sent", "plain")]["nsent"]))
def W(arm): return lambda r: r[("whole", arm)]["a"]
def T(arm): return lambda r: r[("trim", arm)]["a"]
meta = lambda r: r[("sent", "plain")]
def archs(arm):
    w, t = W(arm), T(arm)
    D = {
     "A shipped question": lambda r: n(w(r), "sh_divergence"),
     "B max(doubts,faults)": lambda r: max(n(w(r), "d_doubts"), n(w(r), "d_faults")),
     "B' max(doubts,disputes)": lambda r: max(n(w(r), "d_doubts"), n(w(r), "d_disputes")),
     "B'' max(doubts,faults2)": lambda r: max(n(w(r), "d_doubts"), n(w(r), "d_faults2")),
     "B''' max(doubts,notwork)": lambda r: max(n(w(r), "d_doubts"), n(w(r), "d_notwork")),
     "B3 max(doubts,faults,notwork)": lambda r: max(n(w(r), "d_doubts"), n(w(r), "d_faults"), n(w(r), "d_notwork")),
     "T trimmed state: shipped": lambda r: n(t(r), "sh_divergence"),
     "T trimmed: max(doubts,faults)": lambda r: max(n(t(r), "d_doubts"), n(t(r), "d_faults")),
     "S per-sentence Choice, union": lambda r: sk(r, "react", cd),
     "S per-sentence nouls, union": lambda r: max(sk(r, "d_doubts"), sk(r, "d_faults")),
     "B+S max(whole, sentence nouls)": lambda r: max(n(w(r), "d_doubts"), n(w(r), "d_faults"), sk(r, "d_doubts"), sk(r, "d_faults")),
     "J cascade: Choice if sure, else B": lambda r: cd(w(r)) if max(w(r)["react"]["probabilities"].values()) >= .9 else max(n(w(r), "d_doubts"), n(w(r), "d_faults")),
     "whole Choice": lambda r: cd(w(r)),
    }
    C = {
     "A shipped question": lambda r: n(w(r), "sh_divergence") * 0 + 0.5,
     "c_cand whole": lambda r: n(w(r), "c_cand"), "c_cand trimmed state": lambda r: n(t(r), "c_cand"),
     "S per-sentence c_cand, union": lambda r: sk(r, "c_cand"),
     "S per-sentence Choice, union": lambda r: sk(r, "react", lambda a, k: a[k]["probabilities"]["changes_request"]),
     "max(whole, sentence)": lambda r: max(n(w(r), "c_cand"), sk(r, "c_cand")),
     "mean(whole, sentence)": lambda r: (n(w(r), "c_cand") + sk(r, "c_cand")) / 2,
    }
    g = lambda r: meta(r)["agent_q"]
    Q = {
     "q_terse": lambda r: n(w(r), "q_terse"),
     "code gate('?' in agent reply) * q_terse": lambda r: n(w(r), "q_terse") * g(r),
     "noul gate(agent asked) * q_terse": lambda r: n(w(r), "q_terse") * (n(w(r), "q_agent_asked") >= .5),
     "gate * max(human_asks, undecided)": lambda r: g(r) * max(n(w(r), "q_human_asks"), n(w(r), "q_undecided")),
     "gate * max(q_terse, human_asks, undecided)": lambda r: g(r) * max(n(w(r), "q_terse"), n(w(r), "q_human_asks"), n(w(r), "q_undecided")),
     "gate * sentence max(asks, undecided)": lambda r: g(r) * max(sk(r, "q_human_asks"), sk(r, "q_undecided")),
     "gate * sentence Choice asks_back": lambda r: g(r) * sk(r, "react", lambda a, k: a[k]["probabilities"]["asks_back"]),
     "trimmed state: gate * q_terse": lambda r: g(r) * n(t(r), "q_terse"),
    }
    return {"divergence": D, "change": C, "questions": Q}
band = lambda p: "yes" if p >= .7 else "no" if p <= .3 else "unsure"
KINDS = {"divergence": ["subtle","lookalike","mix_approve_doubt","mix_dispute_add","mix_dispute_change","mix_change_doubt","doubt","dispute","change","open","paste","add"], "change": ["mix_dispute_change","mix_change_doubt","mix_answer_change","change","add","answer","dispute","subtle"], "questions": ["mix_answer_open","mix_answer_add","open","answer","add","lookalike","approve"]}
def st(rs, sig, f, kind=None):
    ok = w = t = 0
    for r in rs:
        e = meta(r)["expect"].get(sig)
        if e is None or (kind and meta(r)["kind"] != kind): continue
        g = band(f(r)); t += 1; ok += g == e; w += g not in (e, "unsure")
    return ok, w, t
allr = list(R.values()); longr = [r for r in allr if ("whole", "long") in r]
for sig in ("divergence", "change", "questions"):
    print(f"\n== {sig}: agree%/wrong% plain | long ; MISS% per kind (plain):", " ".join(KINDS[sig]))
    out = []
    for name in archs("plain")[sig]:
        fp, fl = archs("plain")[sig][name], archs("long")[sig][name]
        ok, w, t = st(allr, sig, fp); ok2, w2, t2 = st(longr, sig, fl)
        km = []
        for kd in KINDS[sig]:
            a, b, c = st(allr, sig, fp, kd); km.append(f"{100*(c-a)/c:3.0f}" + ("!" if b else " "))
        out.append((ok - 3 * w, f"{name:42} {100*ok/t:5.1f}/{100*w/t:4.1f} | {100*ok2/t2:5.1f}/{100*w2/t2:4.1f}   {' '.join(km)}"))
    for _, l in sorted(out, reverse=True): print(l)
