import json, sys, time, threading, collections
src = open("run3big.py").read().split("allc = gen2.cases()")[0]; exec(src)
sys.path.insert(0, "../exp"); import gen, heldout, heldout2, arch
hand = json.load(open("/home/user/sagittarius/s1/fixtures/calibration.json"))["cases"] + heldout.CASES + heldout2.CASES
allc = gen.cases() + [dict(id="hand_" + c["id"], kind="hand", recent=c["recent"], message=c["message"],
        expect={k.replace("h_change_of_plan", "change").replace("h_", ""): v for k, v in c["expect"].items()}) for c in hand]
lock = threading.Lock(); out = []
SHQ = {k: qs.SH[k] for k in ("h_divergence", "h_change_of_plan", "h_questions")}
def one(job):
    c, arm = job; st, q = build(c, "sent", arm); q = dict(q); q.update(SHQ); a = None
    for t in range(4):
        a = jev.judge(st, q, timeout=60)
        if a: break
        time.sleep(2)
    i = agent_idx(c["recent"])
    with lock: out.append({"id": c["id"], "arm": arm, "kind": c["kind"], "expect": c["expect"], "nsent": len(split(c["message"])), "has_agent": i is not None, "agent_q": i is not None and "?" in c["recent"][i]["text"], "a": a})
jobs = [(c, a) for a in ("plain", "long") for c in allc if not (a == "long" and agent_idx(c["recent"]) is None)]
with ThreadPoolExecutor(8) as ex: list(ex.map(one, jobs))
json.dump(out, open("res4.json", "w"))
band = lambda p: "yes" if p >= .7 else "no" if p <= .3 else "unsure"
SH = {"divergence": "h_divergence", "change": "h_change_of_plan", "questions": "h_questions"}
for part, sel in (("HAND 104", lambda r: r["kind"] == "hand"), ("GENERATED round-1 set", lambda r: r["kind"] != "hand")):
    for arm in ("plain", "long"):
        for sig in ("divergence", "change", "questions"):
            line = f"{part:22} {arm:5} {sig:10}"
            for name, f in (("shipped", lambda r: r["a"][SH[sig]]["noul"]), ("fan-out v3", lambda r: arch.signals(r["a"], r["nsent"], r["has_agent"], r["agent_q"], "v3")[sig])):
                ok = w = t = 0; km = collections.Counter()
                for r in out:
                    e = r["expect"].get(sig)
                    if e is None or not sel(r) or r["arm"] != arm or not r["a"]: continue
                    g = band(f(r)); t += 1; ok += g == e; w += g not in (e, "unsure")
                    if g != e: km[r["kind"] if r["kind"] != "hand" else r["id"][5:] + ("!" if g != "unsure" else "")] += 1
                line += f" | {name} {ok}/{t} ({100*ok/max(t,1):.1f}%) wrong {w}  [{' '.join(f'{k}:{v}' for k, v in km.most_common(7))}]"
            print(line[:330])
