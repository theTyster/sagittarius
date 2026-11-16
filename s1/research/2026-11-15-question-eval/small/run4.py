import json, sys
sys.path.insert(0, "/home/user/sagittarius/s1")
import jev, heldout, heldout2, run3
from run2 import Q0, X
from concurrent.futures import ThreadPoolExecutor
fx = json.load(open("/home/user/sagittarius/s1/fixtures/calibration.json"))["cases"]
q = dict(Q0); q["x_change"] = X["x_change"]
BIG = run3.FILL + run3.FILL.replace("core", "billing").replace("14 tests", "22 tests") + run3.FILL.replace("core", "export").replace("212", "305")
def st(c, tail):
    rec = [dict(m) for m in c["recent"]]
    idx = max((i for i, m in enumerate(rec) if m["role"] == "agent"), default=None)
    if idx is None: return None
    t = BIG + rec[idx]["text"]
    rec[idx]["text"] = t if tail is None else t[-tail:]
    return {"message": c["message"], "recent": rec}
ARMS = {"big": None, "tail1000": 1000, "tail500": 500, "tail250": 250}
def one(c):
    if st(c, None) is None: return None
    return {"id": c["id"], "expect": c["expect"], **{a: jev.judge(st(c, t), q, timeout=30) for a, t in ARMS.items()}}
with ThreadPoolExecutor(4) as ex:
    rows = [r for r in ex.map(one, fx + heldout.CASES + heldout2.CASES) if r]
json.dump(rows, open("raw_r4.json", "w"), indent=1)
OLD = {"h_divergence":"divergence","h_change_of_plan":"change","h_effort":"effort","h_proof":"proof","h_questions":"questions"}
QQ = {"divergence":"h_divergence","change":"x_change","effort":"h_effort","proof":"h_proof","questions":"h_questions"}
band = lambda p: "yes" if p>=.7 else "no" if p<=.3 else "unsure"
print("agent reply", len(BIG), "chars + original")
for s, qid in QQ.items():
    line = f"{s:11}"
    for src in ARMS:
        ok = n = 0; m = []
        for r in rows:
            e = {OLD.get(k, k): v for k, v in r["expect"].items()}
            if s not in e: continue
            p = r[src][qid]["noul"]; g = band(p); n += 1
            if g == e[s]: ok += 1
            else: m.append(f"{r['id']}{'!' if g!='unsure' else ''}:{p:.2f}")
        line += f" | {src} {ok}/{n} {' '.join(m)}"
    print(line)
