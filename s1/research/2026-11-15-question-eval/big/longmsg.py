import json, sys, re, random, time, threading, collections
src = open("run3big.py").read().split("allc = gen2.cases()")[0]; exec(src)
import gen
R = random.Random(5)
CHAT = ["Um, so anyway.", "Let me think about how to say this.", "Okay, where was I.", "Right, so the next part.", "Sorry, I'm talking this through as I go.", "And another thing while I'm at it."]
POOL = [s for d in gen.SPEC.values() for s in d]
def ramble(n):
    out = []
    while sum(len(x) + 1 for x in out) < n: out.append(R.choice(POOL) if R.random() < .8 else R.choice(CHAT))
    return out
def voiced(t): return re.sub(r"[.,;:!?']", "", t.lower())
SIG = {"doubt": ("I'm not sure you actually tested that last change. Did you run it against real data?", dict(divergence="yes", change="no")),
       "dispute": (None, dict(divergence="yes", change="no")), "change": (None, dict(divergence="no", change="yes")), "none": ("", dict(divergence="no", change="no"))}
cases = []
for (t, req, done, chg, addr, wrong, q, ans) in gen.CTX[:8]:
    D = [gen.H(req), gen.A(f"Delivered: {done}. Tests pass.")]; Qc = [gen.H(req), gen.A(f"One question before I start. {q}")]
    for kind, (txt, exp) in SIG.items():
        s = {"dispute": "About what you just delivered: " + wrong, "change": "And about what I asked for before: " + chg}.get(kind, txt)
        for pos in (("start", "middle", "end") if kind != "none" else ("-",)):
            body = ramble(6800); i = {"start": 0, "middle": len(body) // 2, "end": len(body), "-": 0}[pos]
            if s: body.insert(i, s)
            for punct in (True, False):
                m = " ".join(body); cases.append(dict(id=f"L{len(cases)}", kind=f"{kind}", pos=pos, punct=punct, recent=D, message=m if punct else voiced(m), expect=dict(exp, effort="yes")))
    for kind, s, e in (("answer", ans, "no"), ("open", "About your question, I don't know yet. What would each option change?", "yes")):
        body = ramble(6800); body.insert(len(body) // 2, s)
        for punct in (True, False):
            m = " ".join(body); cases.append(dict(id=f"L{len(cases)}", kind=kind, pos="middle", punct=punct, recent=Qc, message=m if punct else voiced(m), expect=dict(questions=e)))
for (t, req, done, chg, addr, wrong, q, ans) in gen.CTX[8:16]:
    D = [gen.H(req), gen.A(f"Delivered: {done}. Tests pass.")]
    for kind, rec, last, exp in (("rev_first", [], chg, dict(change="no", divergence="no")), ("rev_final_change", D, chg, dict(change="yes", divergence="no")), ("rev_final_same", D, req, dict(change="no", divergence="no"))):
        body = ramble(6500); n = len(body)
        first = req if kind != "rev_final_same" else "Maybe we should change it: " + chg
        mid = ("Actually no, scratch that. " + (chg if kind != "rev_final_same" else "Hmm, or maybe not."))
        body.insert(int(n * .8), "Hmm, wait. Thinking about it more, forget what I just said. My final decision: " + last)
        body.insert(int(n * .5), mid if kind != "rev_final_same" else "Actually I am going back and forth on this.")
        body.insert(int(n * .2), "So here is what I want. " + first)
        for punct in (True, False):
            m = " ".join(body); cases.append(dict(id=f"L{len(cases)}", kind=kind, pos="-", punct=punct, recent=rec, message=m if punct else voiced(m), expect=dict(exp, selfrev="yes")))
for c in cases: c["expect"].setdefault("selfrev", "no")
def chunks(msg, size=600):
    parts = re.split(r"(?<=[.!?])\s+", msg)
    if len(parts) < 4: w = msg.split(" "); parts = [" ".join(w[i:i + 25]) for i in range(0, len(w), 25)]
    out = [""]
    for p in parts:
        if len(out[-1]) + len(p) > size and out[-1]: out.append("")
        out[-1] = (out[-1] + " " + p).strip()
    return out
F2 = N("x", "Names a fault in the agent's own work, or says the work is not what was asked for", "Reports a problem in another part of the system, changes what the human asked for, asks for more, asks a neutral question, or accepts the work")
def fan(parts):
    q = {}
    for k, _ in enumerate(parts):
        M = f"`sentences[{k}]`"; c = core(M)
        for name in ("react", "d_doubts", "c_cand", "q_human_asks", "q_undecided"): q[f"{name}@{k}"] = c[name]
        q[f"rev@{k}"] = N(f"Does {M} take back or replace something that the human said earlier in the same message?")
        q[f"d_faults@{k}"] = dict(F2, instructions=f"Does {M} say that something the agent did is wrong, broken or missing?")
    return q
import arch
lock = threading.Lock(); out = []
def one(c):
    r = {"c": c}
    st = {"message": c["message"], "recent": c["recent"]}
    wq = {k: qs.SH[k] for k in ("h_divergence", "h_change_of_plan", "h_questions", "h_effort")}; wq.update({k: core("`message`")[k] for k in ("c_cand", "d_doubts", "q_terse")})
    wq["rev_whole"] = N("Does the human change their mind within `message`?", "Takes back or replaces a decision that the same message stated earlier", "States each decision once and keeps it")
    r["whole"] = jev.judge(st, wq, timeout=90)
    for name, parts in (("fan6", split(c["message"])), ("chunk", chunks(c["message"]))):
        a = jev.judge(dict(st, sentences=parts), fan(parts), timeout=90)
        r[name] = dict(arch.signals(a, len(parts), bool(c["recent"]), bool(c["recent"]) and "?" in c["recent"][-1]["text"], "v3"), selfrev=max(a[f"rev@{i}"]["noul"] for i in range(len(parts)))) if a else None; r[name + "_n"] = len(parts)
    with lock: out.append(r)
with ThreadPoolExecutor(6) as ex: list(ex.map(one, cases))
band = lambda p: "yes" if p >= .7 else "no" if p <= .3 else "unsure"
print(len(out), "cases; mean chars", sum(len(r["c"]["message"]) for r in out) // len(out), "; parts fan6", collections.Counter(r["fan6_n"] for r in out).most_common(3), "chunk", collections.Counter(r["chunk_n"] for r in out).most_common(3), "; failed", sum(r["whole"] is None or r["fan6"] is None or r["chunk"] is None for r in out))
SH = {"divergence": "h_divergence", "change": "h_change_of_plan", "questions": "h_questions", "selfrev": "rev_whole"}
ALT = {"divergence": "d_doubts", "change": "c_cand", "questions": "q_terse", "selfrev": "rev_whole"}
for punct in (True, False):
    print("\n== punctuation kept" if punct else "\n== voiced: lower case, no punctuation")
    for sig in ("divergence", "change", "questions", "selfrev"):
        line = f"{sig:10}"
        for name, f in (("shipped", lambda r: r["whole"][SH[sig]]["noul"]), ("whole " + ALT[sig], lambda r: r["whole"][ALT[sig]]["noul"]), ("fan-out first 6", lambda r: r["fan6"][sig]), ("fan-out all chunks", lambda r: r["chunk"][sig])):
            ok = w = t = 0; km = collections.Counter()
            for r in out:
                c = r["c"]; e = c["expect"].get(sig)
                if e is None or c["punct"] != punct or r["whole"] is None or r["fan6"] is None or r["chunk"] is None: continue
                g = band(f(r)); t += 1; ok += g == e; w += g not in (e, "unsure")
                if g != e: km[f"{c['kind']}@{c['pos']}"] += 1
            line += f" | {name} {ok}/{t} w{w} [{' '.join(f'{k}:{v}' for k, v in km.most_common(6))}]"
        print(line[:560])
    e = [r["whole"]["h_effort"]["noul"] for r in out if r["c"]["punct"] == punct and r["whole"] and "effort" in r["c"]["expect"]]
    print(f"effort (shipped): yes in {sum(x >= .7 for x in e)}/{len(e)}, lowest {min(e):.2f}")
