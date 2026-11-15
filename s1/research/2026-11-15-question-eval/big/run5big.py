import json, sys, time, threading, collections
src = open("run3big.py").read().split("allc = gen2.cases()")[0]; exec(src)
sys.path.insert(0, "../exp"); import heldout, heldout2, arch
hand = json.load(open("/home/user/sagittarius/s1/fixtures/calibration.json"))["cases"] + heldout.CASES + heldout2.CASES
allc = gen2.cases() + [dict(id="hand_" + c["id"], kind="hand", recent=c["recent"], message=c["message"], expect={k.replace("h_change_of_plan", "change").replace("h_", ""): v for k, v in c["expect"].items()}) for c in hand]
def extra(M): return {
 "f2": N(f"Does {M} say that something the agent did is wrong, broken or missing?", "Names a fault in the agent's own work, or says the work is not what was asked for", "Reports a problem in another part of the system, changes what the human asked for, asks for more, asks a neutral question, or accepts the work"),
 "uneasy": N(f"Does {M} show that the human is uneasy about the agent's work, or not convinced by it?", "Shows surprise, scepticism or disappointment about what the agent did", "Is content with the work, or talks about something else"),
 "about_agent": N(f"Is {M} about the work that the agent just did?")}
prev = {}
for l in open("res3.jsonl"):
    d = json.loads(l)
    if d["shape"] == "sent": prev[d["id"]] = d
for d in json.load(open("res4.json")):
    if d["arm"] == "plain" and d["kind"] == "hand": prev[d["id"]] = d
lock = threading.Lock(); out = []
def one(c):
    ss = split(c["message"]); q = {f"{k}@{i}": v for i in range(len(ss)) for k, v in extra(f"`sentences[{i}]`").items()}
    a = jev.judge({"message": c["message"], "recent": c["recent"], "sentences": ss}, q, timeout=60)
    with lock: out.append((c["id"], a))
with ThreadPoolExecutor(8) as ex: list(ex.map(one, [c for c in allc if c["id"] in prev]))
band = lambda p: "yes" if p >= .7 else "no" if p <= .3 else "unsure"
def div(r, x, v):
    n = lambda k, i: (x if k in ("f2", "uneasy", "about_agent") else r["a"])[f"{k}@{i}"]["noul"]
    best = 0
    for i in range(r["nsent"]):
        top = r["a"][f"react@{i}"]["choice"]; blocked = top in ("changes_request", "adds_request", "answers")
        fault = n("f2" if "f2" in v else "d_faults", i)
        if blocked: fault = min(fault, .29)
        if "about" in v and n("about_agent", i) < .5: fault = min(fault, .29)
        s = max(n("d_doubts", i), fault, n("uneasy", i) if "uneasy" in v else 0)
        best = max(best, s)
    return r["has_agent"] * best
for v in ("v3", "v3+f2", "v3+uneasy", "v3+f2+uneasy", "v3+about", "v3+f2+about+uneasy"):
    for part, sel in (("round-2 hard set", lambda k: k != "hand"), ("HAND", lambda k: k == "hand")):
        ok = w = t = 0; km = collections.Counter(); kt = collections.Counter()
        for cid, x in out:
            r = prev[cid]; e = r["expect"].get("divergence")
            if e is None or not x or not sel(r["kind"]): continue
            g = band(div(r, x, v)); t += 1; ok += g == e; w += g not in (e, "unsure"); kt[r["kind"]] += 1; km[r["kind"]] += g != e
        print(f"{v:20} {part:16} {ok}/{t} ({100*ok/t:.1f}%) wrong {w}  " + " ".join(f"{k[:11]}:{100*km[k]/kt[k]:.0f}" for k in ("subtle","lookalike","unrelated","mix_approve_doubt","mix_dispute_add","change","dispute","doubt","approve","add") if kt[k]))
