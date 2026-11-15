import json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__)); S1 = os.path.join(HERE, "..", "..", ".."); sys.path.insert(0, S1); sys.path.insert(0, HERE)
import jev, hook, cases
Q = json.load(open(os.path.join(S1, "questions.json"))); FAN = json.load(open(os.path.join(S1, "fanout.json")))
for c in cases.CASES:
    if c["id"] not in sys.argv[1].split(","): continue
    st = {"message": c["message"], "recent": c["recent"], "sentences": hook.split_parts(c["message"])}
    q = hook.fanout_questions(FAN, len(st["sentences"])); a = jev.judge(st, q, timeout=60)
    print(c["id"], c["expect"], "| " + " ; ".join(f"{k}: rev {a[f'reverses@{k}']['noul']:.2f} chg {a[f'changes@{k}']['noul']:.2f} flt {a[f'faults@{k}']['noul']:.2f} dbt {a[f'doubts@{k}']['noul']:.2f} {a[f'react@{k}']['choice'][:7]}" for k in range(len(st["sentences"]))))
