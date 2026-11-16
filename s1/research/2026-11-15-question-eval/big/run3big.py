import json, sys, os, re, time, threading
sys.path.insert(0, "/home/user/sagittarius/s1")
import jev, gen2, qs
from qs import N, C, REACT
from concurrent.futures import ThreadPoolExecutor
FILL = eval("(" + re.search(r'FILL = \((.*?)\)\ndef pad', open("../exp/run3.py").read(), re.S).group(1) + ")")
def core(M):
    return {
     "sh_divergence": dict(qs.SH["h_divergence"], instructions=qs.SH["h_divergence"]["instructions"].replace("the newest message in `message`", M)),
     "d_doubts": N(f"Does {M} doubt or question what the agent did?", "Asks whether the agent really did something, why it did it that way, or shows surprise at it", "Asks about the system or the task, not about the agent's own work"),
     "d_disputes": N(f"Does {M} say that the agent got something wrong?", "Says a result is wrong, incomplete, or not what was asked for", "Accepts the result, or asks for something else without faulting it"),
     "d_faults": N(f"Does {M} say that something the agent did is wrong, broken or missing?", "Names a fault in the agent's work, or says the work is not what was asked for", "Changes what the human asked for, asks for more, asks a neutral question, or accepts the work"),
     "d_faults2": N(f"Does {M} report that the agent's work does not do what the human asked for?"),
     "d_notwork": N(f"Does {M} say that the result does not work or is not right?"),
     "c_cand": N(f"Does {M} change what the human asked for before?", "Replaces, drops or reverses an earlier request or preference", "Continues the earlier request, corrects a mistake of the agent, or asks for something new"),
     "q_terse": N(f"Does {M} leave a question of the agent open, or answer it with a new question?", "Says it does not know yet, or asks something back that must be settled first", "Answers what the agent asked, or the agent asked nothing"),
     "q_human_asks": N(f"Does {M} ask the agent a question about the task?"),
     "q_undecided": N(f"Does {M} say that the human does not know or has not decided something yet?"),
     "react": C(f"What does {M} do, in relation to the agent's last reply?", REACT),
    }
def split(msg):
    s = [x.strip() for x in re.split(r"(?<=[.!?])\s+", msg) if x.strip()]
    return s[:6] or [msg]
def agent_idx(rec): return max((i for i, m in enumerate(rec) if m["role"] == "agent"), default=None)
def build(c, shape, arm):
    rec = [dict(m) for m in c["recent"]]; i = agent_idx(rec)
    if arm == "long" and i is not None: rec[i]["text"] = FILL + rec[i]["text"]
    if shape == "whole":
        q = core("`message`"); q["q_agent_asked"] = N("Does the agent's last reply in `recent` ask the human a question?")
        return {"message": c["message"], "recent": rec}, q
    if shape == "trim":
        st = {"message": c["message"]}
        if i is not None:
            st["agent_reply_end"] = rec[i]["text"][-400:]
            prev = [m["text"] for m in rec[:i] if m["role"] == "you"]
            if prev: st["human_request_before"] = prev[-1]
        return st, core("`message`")
    if shape == "sent":
        ss = split(c["message"]); q = {}
        for k, s in enumerate(ss):
            for name, v in core(f"`sentences[{k}]`").items():
                if name in ("react", "d_doubts", "d_faults", "c_cand", "q_human_asks", "q_undecided"): q[f"{name}@{k}"] = v
        return {"message": c["message"], "recent": rec, "sentences": ss}, q
allc = gen2.cases(); OUT = "res3.jsonl"; done = set()
if os.path.exists(OUT):
    for l in open(OUT): d = json.loads(l); done.add((d["id"], d["shape"], d["arm"]))
lock = threading.Lock(); f = open(OUT, "a"); n = [0, 0, 0]
def one(job):
    c, shape, arm = job
    st, q = build(c, shape, arm); a = None
    for t in range(4):
        a = jev.judge(st, q, timeout=60)
        if a: break
        time.sleep(2 * (t + 1))
    with lock:
        n[0] += 1; n[1] += a is None; n[2] += len(json.dumps(st)) + len(json.dumps(q))
        if a: f.write(json.dumps({"id": c["id"], "shape": shape, "arm": arm, "kind": c["kind"], "expect": c["expect"], "nsent": len(split(c["message"])), "agent_q": (lambda i: i is not None and "?" in c["recent"][i]["text"])(agent_idx(c["recent"])), "has_agent": agent_idx(c["recent"]) is not None, "a": a}) + "\n"); f.flush()
jobs = [(c, s, a) for s, a in (("whole", "plain"), ("whole", "long"), ("trim", "plain"), ("trim", "long"), ("sent", "plain")) for c in allc
        if (c["id"], s, a) not in done and not (a == "long" and agent_idx(c["recent"]) is None)]
print(len(jobs), "jobs", flush=True)
with ThreadPoolExecutor(8) as ex: list(ex.map(one, jobs))
print("done", n, "approx tokens", n[2] // 4, flush=True)
