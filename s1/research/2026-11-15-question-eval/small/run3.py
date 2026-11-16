import json, sys
sys.path.insert(0, "/home/user/sagittarius/s1")
import jev, heldout, heldout2
from run2 import Q0, X
from concurrent.futures import ThreadPoolExecutor
FILL = ("I'll start by reading the code that this touches. The entry point is in src/app/main.py, which wires the routes and the "
"services together; the handler in question lives in src/app/handlers/core.py and calls into the service layer. Let me look at how "
"the service is built and what it depends on.\n\nThe service takes a repository and a clock. The repository has four methods: get, "
"list, save and delete. The list method takes a filter and a page; the page defaults to 50 rows. There is one caller outside the "
"handler: the nightly job in jobs/nightly.py, which lists everything with no filter. I will keep that caller working.\n\nNow the tests. "
"tests/test_core.py has 14 tests for this handler; they use a fake repository and a fixed clock. I ran the suite before any change: "
"212 passed, 3 skipped, in 41 seconds. The three skipped tests need a network and are skipped on every machine.\n\nPlan: write the "
"check first, see it fail, then make the change, then run the suite again. I wrote the check in tests/test_core.py; it failed as "
"expected with an assertion error on the second line, which shows that the check can fail.\n\nMaking the change now. I edited "
"src/app/handlers/core.py and src/app/services/core_service.py. The handler change is twelve lines; the service change is a new "
"keyword argument with a default, so the nightly job needs no change. I also updated the docstring of the service method, because it "
"described the old behavior.\n\nRunning the check again: it passes. Running the whole suite: 213 passed, 3 skipped, in 43 seconds. "
"The linter reports nothing. The type checker reports one new warning in the handler, about an Optional that I narrowed with an "
"assert; I replaced the assert with an explicit branch, and the warning is gone.\n\nI looked at the callers once more to be sure that "
"nothing else reads the old field. A search for the old name finds two places in the docs and none in the code; I updated both doc "
"pages. I did not touch the changelog, because this project writes it at release time from the commit messages.\n\nOne thing I noticed "
"and did not change: the fake repository in the tests sorts by id, and the real one sorts by creation time. They agree today because "
"ids grow with time. I left it alone, since it is outside this request.\n\n")
def pad(c, tail_only=None):
    rec = [dict(m) for m in c["recent"]]
    idx = max((i for i, m in enumerate(rec) if m["role"] == "agent"), default=None)
    if idx is None: return None
    rec[idx]["text"] = FILL + rec[idx]["text"]
    if tail_only: rec[idx]["text"] = rec[idx]["text"][-tail_only:]
    return {"message": c["message"], "recent": rec}
fx = json.load(open("/home/user/sagittarius/s1/fixtures/calibration.json"))["cases"]
q = dict(Q0); q["x_change"] = X["x_change"]
def one(c):
    s = pad(c)
    if s is None: return None
    return {"id": c["id"], "expect": c["expect"], "pad": jev.judge(s, q, timeout=30), "tail": jev.judge(pad(c, 1500), q, timeout=30), "plain": jev.judge({"message": c["message"], "recent": c["recent"]}, q, timeout=30)}
with ThreadPoolExecutor(4) as ex:
    rows = [r for r in ex.map(one, fx + heldout.CASES + heldout2.CASES) if r]
json.dump(rows, open("raw_r3.json", "w"), indent=1)
OLD = {"h_divergence":"divergence","h_change_of_plan":"change","h_effort":"effort","h_proof":"proof","h_questions":"questions"}
QQ = {"divergence":"h_divergence","change":"x_change","effort":"h_effort","proof":"h_proof","questions":"h_questions"}
band = lambda p: "yes" if p>=.7 else "no" if p<=.3 else "unsure"
print(len(rows), "cases with an agent reply; filler", len(FILL), "chars")
for s, qid in QQ.items():
    line = f"{s:11}"
    for src in ("plain", "pad", "tail"):
        ok = n = w = 0; m = []; shift = []
        for r in rows:
            e = {OLD.get(k, k): v for k, v in r["expect"].items()}
            if s not in e: continue
            p = r[src][qid]["noul"]; g = band(p); n += 1; shift.append(abs(p - r["plain"][qid]["noul"]))
            if g == e[s]: ok += 1
            else: w += g != "unsure"; m.append(f"{r['id']}{'!' if g!='unsure' else ''}:{p:.2f}")
        line += f" | {src} {ok}/{n} w{w} meanshift {sum(shift)/max(n,1):.3f} {' '.join(m)}"
    print(line)
