import json
rows = json.load(open("raw_r2.json"))
OLD = {"h_divergence":"divergence","h_change_of_plan":"change","h_effort":"effort","h_proof":"proof","h_questions":"questions"}
band = lambda p: "yes" if p>=.7 else "no" if p<=.3 else "unsure"
nv = lambda r,src,k: r[src][k]["noul"]
V = {
 "divergence": {"cur":lambda r:nv(r,"a0","h_divergence"),"trim":lambda r:nv(r,"a0","c_divergence"),"crit":lambda r:nv(r,"a0","x_div_crit"),"role=human":lambda r:nv(r,"ah","h_divergence"),"max(disp,doubt)":lambda r:max(nv(r,"a0","x_disputes"),nv(r,"a0","x_doubts")) if r["has_agent"] else 0},
 "change": {"cur":lambda r:nv(r,"a0","h_change_of_plan"),"trim":lambda r:nv(r,"a0","c_change_of_plan"),"new":lambda r:nv(r,"a0","x_change"),"new-nocrit":lambda r:nv(r,"a0","x_change_nocrit"),"role=human":lambda r:nv(r,"ah","h_change_of_plan")},
 "effort": {"cur":lambda r:nv(r,"a0","h_effort"),"trim":lambda r:nv(r,"a0","c_effort"),"role=human":lambda r:nv(r,"ah","h_effort")},
 "proof": {"cur":lambda r:nv(r,"a0","h_proof"),"trim":lambda r:nv(r,"a0","c_proof"),"asks_proof":lambda r:nv(r,"a0","x_asks_proof"),"max(asks,every)":lambda r:max(nv(r,"a0","x_asks_proof"),nv(r,"a0","x_every_case"))},
 "universal": {"cur h_proof":lambda r:nv(r,"a0","h_proof"),"every_case":lambda r:nv(r,"a0","x_every_case"),"universal":lambda r:nv(r,"a0","x_universal"),"max":lambda r:max(nv(r,"a0","x_every_case"),nv(r,"a0","x_universal"))},
 "questions": {"cur":lambda r:nv(r,"a0","h_questions"),"trim":lambda r:nv(r,"a0","c_questions"),"max(undec,back)":lambda r:max(nv(r,"a0","x_undecided"),nv(r,"a0","x_asks_back")) if r["has_agent"] else 0,"role=human":lambda r:nv(r,"ah","h_questions")},
}
parts = (("fixture",lambda i:i[0] not in "hg"),("held1",lambda i:i[0]=="h"),("held2",lambda i:i[0]=="g"))
for s,vs in V.items():
    print("==",s)
    for name,f in vs.items():
        out=[]; misses=[]
        for pn,sel in parts:
            ok=n=w=0
            for r in rows:
                e={OLD.get(k,k):v for k,v in r["expect"].items()}
                if not sel(r["id"]) or s not in e: continue
                p=f(r); g=band(p); n+=1
                if g==e[s]: ok+=1
                else:
                    w+= g!="unsure"; misses.append(f"{r['id']}{'!' if g!='unsure' else ''}:{p:.2f}")
            out.append(f"{pn} {ok}/{n} w{w}")
        print(f"  {name:17} {' | '.join(out)}   {' '.join(misses)}")
# work / language under trim and role
for k in ("h_work","h_language"):
    for name,src,q in (("cur","a0",k),("trim","a0","c_"+k[2:]),("role=human","ah",k)):
        ok=n=0; m=[]
        for r in rows:
            if k not in r["expect"]: continue
            x=r[src][q]; p=x["probabilities"][x["choice"]]; g=x["choice"] if p>=.5 else "unsure"; n+=1
            if g==r["expect"][k]: ok+=1
            else: m.append(f"{r['id']}:{g}:{p:.2f}")
        print(k,name,f"{ok}/{n}"," ".join(m))
