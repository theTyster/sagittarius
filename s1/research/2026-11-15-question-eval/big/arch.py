"""The candidate architecture, in one place: answers of the sentence fan-out request -> signals."""
def per_sentence(a, nsent):
    return [{k: a[f"{k}@{i}"] for k in ("react", "d_doubts", "d_faults", "c_cand", "q_human_asks", "q_undecided")} for i in range(nsent)]
def signals(a, nsent, has_agent, agent_q, variant="v2"):
    S = per_sentence(a, nsent); n = lambda s, k: s[k]["noul"]
    top = lambda s: s["react"]["choice"]
    chg = max(n(s, "c_cand") for s in S)
    if variant == "v0":   # plain union
        div = max(max(n(s, "d_doubts"), n(s, "d_faults")) for s in S)
    elif variant == "v1":  # + code gate
        div = has_agent * max(max(n(s, "d_doubts"), n(s, "d_faults")) for s in S)
    else:                 # + a fault does not count in a sentence that changes or adds to the request
        def f(s):
            fault = n(s, "d_faults")
            if variant == "v2" and n(s, "c_cand") >= 0.5: fault = min(fault, 0.29)
            if variant == "v3" and top(s) in ("changes_request", "adds_request", "answers"): fault = min(fault, 0.29)
            if variant == "v4" and (n(s, "c_cand") >= 0.5 or top(s) in ("changes_request", "adds_request")): fault = min(fault, 0.29)
            return max(n(s, "d_doubts"), fault)
        div = has_agent * max(f(s) for s in S)
    q = agent_q * max(max(n(s, "q_human_asks"), n(s, "q_undecided")) for s in S)
    return {"divergence": div, "change": has_agent * chg, "questions": q}
