"""Live check of the built hook on the fresh cases: the plain answers against the fan-out (hook.combine).
Needs TYPESAFE_API_KEY. python3 check.py [repeat]"""
import json, os, sys, collections
HERE = os.path.dirname(os.path.abspath(__file__)); S1 = os.path.join(HERE, "..", "..", "..")
sys.path.insert(0, S1); sys.path.insert(0, HERE)
import jev, hook, cases
from concurrent.futures import ThreadPoolExecutor
Q = json.load(open(os.path.join(S1, "questions.json"))); FAN = json.load(open(os.path.join(S1, "fanout.json")))
def one(c):
    st = {"message": c["message"], "recent": c["recent"], "sentences": hook.split_parts(c["message"])}
    q = dict(Q); q.update(hook.fanout_questions(FAN, len(st["sentences"])))
    raw = jev.judge(st, q, timeout=60)
    return c, raw, hook.combine(raw, st) if raw else None, len(st["sentences"])
with ThreadPoolExecutor(6) as ex: rows = list(ex.map(one, cases.CASES * int(sys.argv[1] if len(sys.argv) > 1 else 1)))
band = lambda p: "yes" if p >= .7 else "no" if p <= .3 else "unsure"
SIG = {"divergence": "h_divergence", "change": "h_change_of_plan", "questions": "h_questions", "effort": "h_effort", "reversal": "h_reversal"}
print("failed calls:", sum(r[1] is None for r in rows), "| parts:", sorted(collections.Counter(r[3] for r in rows).items()))
for sig, qid in SIG.items():
    line = f"{sig:10}"
    for name, f in (("plain", lambda r: r[1].get(qid, {"noul": 0.5})["noul"]), ("fan-out", lambda r: r[2][qid]["noul"]),
                    ("fan-out or plain yes", lambda r: max(r[2][qid]["noul"], r[1].get(qid, {"noul": 0})["noul"] if r[1].get(qid, {"noul": 0})["noul"] >= .7 and any(m["role"] == "agent" for m in r[0]["recent"]) else 0))):
        ok = w = t = 0; miss = []
        for r in rows:
            e = r[0]["expect"].get(sig)
            if e is None or r[1] is None: continue
            p = f(r); g = band(p); t += 1; ok += g == e; w += g not in (e, "unsure")
            if g != e: miss.append(f"{r[0]['id']}{'!' if g != 'unsure' else ''}:{p:.2f}")
        line += f" | {name} {ok}/{t} wrong {w} [{' '.join(miss[:14])}]"
    print(line)
