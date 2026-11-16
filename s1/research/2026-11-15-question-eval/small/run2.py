import json, sys, copy
sys.path.insert(0, "/home/user/sagittarius/s1")
import jev, heldout, heldout2
from qsets import N
from concurrent.futures import ThreadPoolExecutor
Q0 = json.load(open("/home/user/sagittarius/s1/questions.json"))
def trim(q):
    q = copy.deepcopy(q)
    q["instructions"] = q["instructions"].replace("the newest message in `message`", "`message`").replace(", given the conversation in `recent`", "").replace("If the work in `message` needs", "If the work in `message` needs")
    return q
M = "`message`"
X = {
 "x_change": N(f"Does {M} change what the human asked for before?",
    "Replaces, drops or reverses an earlier request or preference",
    "Continues the earlier request, corrects a mistake of the agent, or asks for something new"),
 "x_change_nocrit": N(f"Does {M} replace, drop or reverse something that the human asked for before?"),
 "x_div_crit": N(f"Does {M} say or suggest that the agent's own result, plan, or reading of the request is wrong, missed something, or is not what was meant?",
    "Faults the agent's work, or shows doubt, surprise or a pointed question about it",
    "Reports a problem in the system that the agent did not cause, makes a new request, or changes a preference"),
 "x_asks_proof": N(f"Does {M} ask for a proof?", "Asks to prove something, or to show it formally", "Asks to test, check, review or try to break something"),
 "x_every_case": N(f"Does {M} ask for certainty that something holds in every case?",
    "Wants a guarantee for all inputs or all situations, with no exception", "Is satisfied by examples, tests or a review"),
 "x_universal": N(f"Does {M} state a rule that must hold in every case, with no exception?"),
 "x_disputes": N(f"Does {M} say that the agent got something wrong?",
    "Says a result is wrong, incomplete, or not what was asked for", "Accepts the result, or asks for something else without faulting it"),
 "x_doubts": N(f"Does {M} doubt or question what the agent did?",
    "Asks whether the agent really did something, why it did it that way, or shows surprise at it",
    "Asks about the system or the task, not about the agent's own work"),
 "x_undecided": N(f"Does {M} say that the human does not know or has not decided something yet?"),
 "x_asks_back": N(f"Does {M} ask the agent a question that must be answered before the work can go on?"),
}
fx = json.load(open("/home/user/sagittarius/s1/fixtures/calibration.json"))["cases"]
def one(c):
    s0 = {"message": c["message"], "recent": c["recent"]}
    q = dict(Q0); q.update({"c_" + k[2:]: trim(v) for k, v in Q0.items()}); q.update(X)
    sh = {"message": c["message"], "recent": [{"role": "human" if m["role"] == "you" else "agent", "text": m["text"]} for m in c["recent"]]}
    return {"id": c["id"], "expect": c["expect"], "has_agent": any(m["role"] == "agent" for m in c["recent"]), "a0": jev.judge(s0, q, timeout=30), "ah": jev.judge(sh, Q0, timeout=30)}
with ThreadPoolExecutor(4) as ex:
    rows = list(ex.map(one, fx + heldout.CASES + heldout2.CASES))
json.dump(rows, open("raw_r2.json", "w"), indent=1)
print(len(rows), sum(r["a0"] is None or r["ah"] is None for r in rows))
