import json, sys, os
sys.path.insert(0, "/home/user/sagittarius/s1")
import jev, heldout, qsets
from concurrent.futures import ThreadPoolExecutor
Q0 = json.load(open("/home/user/sagittarius/s1/questions.json"))
fx = json.load(open("/home/user/sagittarius/s1/fixtures/calibration.json"))["cases"]
def s1(c):
    rec = c["recent"]; st = {"human_message": c["message"]}
    idx = max((i for i, m in enumerate(rec) if m["role"] == "agent"), default=None)
    if idx is not None: st["agent_reply"] = rec[idx]["text"]
    rest = [{"from": "human" if m["role"] == "you" else "agent", "text": m["text"]} for i, m in enumerate(rec) if i != idx]
    if rest: st["earlier"] = rest
    return st
def one(c):
    s0 = {"message": c["message"], "recent": c["recent"]}
    q0 = dict(Q0); q0.update({"t_" + k: v for k, v in qsets.terse("`message`", "`recent`").items()})
    q1 = {"n_" + k: v for k, v in qsets.terse("`human_message`", "`agent_reply`").items()}
    q1.update({"a_" + k: v for k, v in qsets.ATOMIC.items()})
    a0 = jev.judge(s0, q0, timeout=30); a1 = jev.judge(s1(c), q1, timeout=30)
    return {"id": c["id"], "expect": c["expect"], "has_agent": any(m["role"] == "agent" for m in c["recent"]), "len": len(c["message"]), "a0": a0, "a1": a1}
tag = sys.argv[1]
with ThreadPoolExecutor(4) as ex:
    rows = list(ex.map(one, fx + heldout.CASES))
json.dump(rows, open(f"raw_{tag}.json", "w"), indent=1)
print(len(rows), sum(r["a0"] is None for r in rows), sum(r["a1"] is None for r in rows))
