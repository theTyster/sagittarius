import json, sys
rows = json.load(open(f"raw_{sys.argv[1]}.json"))
OLD = {"h_divergence":"divergence","h_change_of_plan":"change","h_effort":"effort","h_proof":"proof","h_questions":"questions","h_work":"work","h_language":"language"}
def band(p): return "yes" if p>=.7 else "no" if p<=.3 else "unsure"
def nv(a,k): return a[k]["noul"]
def ch(a,k):
    x=a[k]; p=x["probabilities"][x["choice"]]; return (x["choice"] if p>=.5 else "unsure"), p
def cur(r,s):
    k={v:k for k,v in OLD.items()}[s]; a=r["a0"]
    return ch(a,k) if s in("work","language") else (band(nv(a,k)), nv(a,k))
def pre(src,p):
    def f(r,s):
        a=r[src]; k=p+s
        return ch(a,k) if s in("work","language") else (band(nv(a,k)), nv(a,k))
    return f
def atomic(r,s):
    a=r["a1"]; g=lambda k: nv(a,"a_"+k); ha=r["has_agent"]
    if s=="divergence":
        p=max(g("disputes"),g("doubts"),g("misread")) if ha else 0.0
    elif s=="change":
        p=g("changes_request") if ha or True else 0.0
        if max(g("disputes"),g("misread"))>=.7: p=min(p,0.29)
    elif s=="effort":
        e=a["a_effort"]; p=e["probabilities"]["2"]
        if g("pasted")>=.7: p=min(p,.29)
    elif s=="proof": p=max(g("asks_proof"),g("every_case"))
    elif s=="questions":
        p=0.0 if not ha or g("agent_asked")<=.3 else max(g("undecided"),g("asks_back"),1-g("answers_all"))
    elif s=="work":
        if g("is_request")<=.3: return "other",1-g("is_request")
        return ch(a,"a_work")
    elif s=="language":
        c,p=ch(a,"a_tool"); m=max(g("about_rules"),g("about_order"),g("about_owners"),g("asks_proof"),g("every_case"))
        return (c if m>=.7 else "tests"), p
    return band(p),p
V={"cur":cur,"terse/S0":pre("a0","t_"),"terse/S1":pre("a1","n_"),"atomic":atomic}
for part,sel in (("fixture",lambda r:not r["id"].startswith("h")),("heldout",lambda r:r["id"].startswith("h"))):
    print("==",part)
    for s in ("divergence","change","effort","proof","questions","work","language"):
        line=f"{s:11}"
        for name,f in V.items():
            ok=n=wrong=0; miss=[]
            for r in rows:
                if not sel(r): continue
                e={OLD.get(k,k):v for k,v in r["expect"].items()}
                if s not in e: continue
                got,p=f(r,s); n+=1
                if got==e[s]: ok+=1
                else:
                    if got!="unsure": wrong+=1
                    miss.append(f"{r['id']}{'!' if got!='unsure' else ''}:{p:.2f}")
            line+=f" | {name} {ok}/{n} w{wrong} {' '.join(miss)}"
        print(line)
