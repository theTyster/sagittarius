#!/usr/bin/env python3
"""Sagittarius 0.3.0 alignment, the MindHole packages M-B, M-F and M-G: the hub's own text carries the
hub's rules, a handoff carries the KB, a closed ticket leaves its outcomes, and the display name.
One check per claim of the spec KB (tmp/kb-sagittarius-030).

usage: python3 docs/check_mindhole.py mb1|mb2|mb3|mb4|mb5|mb6|mf1|mf4|mg [--list]   (--list prints the ids)
Exit 0: the claim's check passes. Exit 1: it fails (each failure is printed). Prints `N checks`.

mb1 (c_m_b_1) both HUB-CORE.md files tell a session to read its inbox (`view v_inbox`) at session start and
    after a compaction, in "Flow state lives in the db"; the formal one then follows each kb ref.
mb2 (c_m_b_2) the hypothesis rows of both store tables say what the human wants for the ticket, with its
    premises and falsifiers, and do not name discovery as its author; the tables are not edited by hand.
mb3 (c_m_b_3) the vote is a fact kind (owner spec) with a row in both editions; the count line of the formal
    table is the count of store-facts.json; in the informal edition the vote is a note on the ticket's thread.
mb4 (c_m_b_4) the models row says "solver and model-checker models, and Lean definitions and theorems".
mb5 (c_m_b_5) the informal edition keeps a record of a divergence: a note on the ticket's thread.
mb6 (c_m_b_6) the briefing page names the review session, gives build the build only, and has no analyses/ slot.
mf1 (c_m_f_1) the handoff example of the formal hub-flow skill carries a kb ref and runs as written
    (hubflow-test case_030_handoff_example).
mf4 (c_m_f_4) before a spec KB is archived, the formal hub-rotate and hub-flow skills propose each lasting
    outcome of the ticket to the project KB and list the proposals for the human, who ratifies them.
mg  (c_m_g) "MindHole" is the display name: the title and first lines of hubkit/README.md and
    hubkit/INSTRUCTIONS.md, the briefing page, README.md and CLAUDE.md say it; the identifiers stay.
"""
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CORE = os.path.join(ROOT, "hubkit", "hub", "HUB-CORE.md")
ICORE = os.path.join(ROOT, "hubkit", "editions", "informal", "HUB-CORE.md")
FACTS = os.path.join(ROOT, "hubkit", "tools", "store-facts.json")
SKILLS = os.path.join(ROOT, "hubkit", "hub", ".claude", "skills")
FLOWTEST = os.path.join(ROOT, "hubkit", "hub", ".claude", "scripts", "hubflow-test.py")
BRIEF = os.path.join(ROOT, "hubkit", "docs", "index.html")
failures = []
count = 0


def check(name, ok, detail=""):
    global count
    count += 1
    if not ok:
        failures.append(f"{name}: {str(detail)[:300]}")


def read(p):
    try:
        with open(p, encoding="utf-8") as f:
            return f.read()
    except OSError:
        return ""


def flat(t):
    return " ".join(t.split())


def section(text, heading):
    m = re.search(r"^#+ " + re.escape(heading) + r"[^\n]*\n(.*?)(?=^#+ |\Z)", text, re.S | re.M)
    return m.group(1) if m else ""


def rows(text, kind):
    return [ln for ln in text.splitlines() if ln.startswith(f"| `{kind}` |")]


def cells(row):
    return [c.strip() for c in row.strip().strip("|").split("|")]


def storemap_clean(name):
    p = subprocess.run([sys.executable, "-I", os.path.join(ROOT, "hubkit", "tools", "storemap.py"), "--check"], capture_output=True, text=True)
    check(f"{name}: storemap.py --check passes (the tables are made from store-facts.json, not by hand)", p.returncode == 0, p.stderr)


def facts():
    try:
        return {f["name"]: f for f in json.loads(read(FACTS))["facts"]}
    except (ValueError, KeyError):
        return {}


def mb1():
    for label, path in (("formal", CORE), ("informal", ICORE)):
        sec = flat(section(read(path), "Flow state lives in the db"))
        check(f"mb1 {label} HUB-CORE.md 'Flow state lives in the db' names the inbox view", "view v_inbox" in sec, sec[:200])
        check(f"mb1 {label}: read it at session start and after a compaction",
              re.search(r"session start|start of (a|each|every) session", sec) is not None and "compaction" in sec, sec[:300])
    sec = flat(section(read(CORE), "Flow state lives in the db"))
    check("mb1 formal: then follow each item's kb ref and read what is open there", "hubflow.py where" in sec and "show open" in sec, sec[:300])
    check("mb1 informal: names no formal tool", "orbit-kb" not in flat(section(read(ICORE), "Flow state lives in the db")))


def mb2():
    f = facts().get("hypothesis", {})
    check("mb2 store-facts.json: the hypothesis says what the human wants", "what the human wants" in f.get("desc", ""), f.get("desc"))
    for label, path in (("formal", CORE), ("informal", ICORE)):
        t = read(path)
        rs = rows(t, "hypothesis")
        check(f"mb2 {label}: has hypothesis rows", rs, path)
        for r in rs:
            check(f"mb2 {label}: the hypothesis row says what the human wants", "what the human wants" in r, r[:160])
            check(f"mb2 {label}: the hypothesis row names premises and the result that would show it false",
                  "premises" in r and "show it false" in r, r[:200])
            check(f"mb2 {label}: the hypothesis row does not make discovery its only author",
                  "discovery believes" not in r.lower() and "believed to be" not in r, r[:160])
    storemap_clean("mb2")


def mb3():
    fs = facts()
    v = fs.get("vote", {})
    check("mb3 store-facts.json has the fact kind vote, owned by spec", v.get("owner") == "spec", v)
    check("mb3 the vote names GO, NO-GO and HOLD", all(w in v.get("desc", "") for w in ("GO", "NO-GO", "HOLD")), v.get("desc"))
    core = read(CORE)
    check("mb3 formal table has a vote row", len(rows(section(core, "What lives where"), "vote")) == 1)
    m = re.search(r"^The (\d+) fact kinds:", core, re.M)
    check("mb3 the count line of the formal table equals store-facts.json", m and int(m.group(1)) == len(fs), (m and m.group(0), len(fs)))
    for label, path in (("formal", CORE), ("informal", ICORE)):
        t = read(path)
        b, e = t.find("<!-- informal-map:begin"), t.find("<!-- informal-map:end")
        rs = rows(t[b:e], "vote")
        check(f"mb3 {label}: the informal map has a vote row", len(rs) == 1, rs)
        if rs:
            c = cells(rs[0])
            check(f"mb3 {label}: in the informal edition the vote is a note on the ticket's thread", c[1] == "`ledger`" and "note" in c[2], c)
    storemap_clean("mb3")


def mb4():
    f = facts().get("models", {})
    want = "solver and model-checker models, and Lean definitions and theorems"
    check("mb4 store-facts.json: the models description", want in f.get("desc", "").lower(), f.get("desc"))
    rs = rows(read(CORE), "models")
    check("mb4 the formal fact table has one models row", len(rs) >= 1, rs)
    for r in rs:
        check("mb4 the models row does not call Lean a model", "Formal models (Lean" not in r, r[:120])
    check("mb4 the formal fact row says Lean definitions and theorems", any(want in r.lower() for r in rs), rs[:1])
    storemap_clean("mb4")


def mb5():
    for label, path in (("formal", CORE), ("informal", ICORE)):
        t = read(path)
        b, e = t.find("<!-- informal-map:begin"), t.find("<!-- informal-map:end")
        rs = rows(t[b:e], "divergences")
        check(f"mb5 {label}: the informal map has a divergences row", len(rs) == 1, rs)
        if rs:
            c = cells(rs[0])
            check(f"mb5 {label}: the informal edition keeps a divergence (not `not kept`)", c[1] == "`ledger`", c[1])
            check(f"mb5 {label}: as a note on the ticket's thread", "hubflow.py note" in c[2] and "divergence" in c[2], c[2][:200])
    storemap_clean("mb5")


def mb6():
    t = read(BRIEF)
    m = re.search(r'<section id="sessions">(.*?)</section>', t, re.S)
    sec = m.group(1) if m else ""
    check("mb6 the briefing has a sessions section", bool(sec))
    check("mb6 the build session does not review", re.search(r"<strong>build</strong></td><td>[^<]*review", sec) is None, sec[:300])
    check("mb6 the briefing names the review session", "<strong>review</strong>" in sec, sec[:300])
    check("mb6 the briefing lists no analyses/ slot", "analyses/" not in t)


def mf1():
    skill = read(os.path.join(SKILLS, "hub-flow", "SKILL.md"))
    ex = [ln for ln in skill.splitlines() if "$HF handoff --to" in ln]
    check("mf1 the formal hub-flow skill has a handoff example", bool(ex))
    check("mf1 each handoff example carries a kb ref", ex and all("--ref kb:" in ln for ln in ex), ex)
    p = subprocess.run([sys.executable, "-I", FLOWTEST, "--case", "case_030_handoff_example"], capture_output=True, text=True)
    last = (p.stdout.strip().splitlines() or [""])[-1]
    check("mf1 hubflow-test case_030_handoff_example passes (the example runs and keeps its kb ref)",
          p.returncode == 0 and re.match(r"[1-9]\d* passed, 0 failed", last), (last, p.stderr[-200:]))


def mf4():
    for name, sec_of in (("hub-rotate", lambda t: t), ("hub-flow", lambda t: section(t, "The spec KB of a closed ticket"))):
        t = sec_of(read(os.path.join(SKILLS, name, "SKILL.md")))
        f = flat(t)
        m = re.search(r"[^.]*\bpropos\w*[^.]*lasting outcome[^.]*\.", f)
        check(f"mf4 {name}: a step proposes each lasting outcome of the ticket to the project KB", m and "project KB" in m.group(0), f[:200])
        if m:
            check(f"mf4 {name}: the step comes before the archive (git rm)", "git rm" in f[m.end():], m.group(0))
        check(f"mf4 {name}: the proposals are listed for the human, who ratifies them", re.search(r"ratif", f) and re.search(r"report", f), f[:200])


def mg():
    for rel in ("hubkit/README.md", "hubkit/INSTRUCTIONS.md"):
        head = "\n".join(read(os.path.join(ROOT, rel)).splitlines()[:5])
        check(f"mg {rel}: the title names the MindHole", head.startswith("# ") and "MindHole" in head.splitlines()[0], head.splitlines()[:1])
        check(f"mg {rel}: the first lines name the MindHole", "MindHole" in head)
    b = read(BRIEF)
    check("mg the briefing page title names the MindHole", re.search(r"<title>[^<]*MindHole", b) is not None)
    check("mg the briefing page heading names the MindHole", re.search(r"<h1[^>]*>[^<]*MindHole", b) is not None)
    readme = read(os.path.join(ROOT, "README.md"))
    check("mg README.md has a MindHole section", re.search(r"^## [^\n]*MindHole", readme, re.M) is not None)
    check("mg CLAUDE.md names the MindHole in its table", re.search(r"^\| [^|]*MindHole", read(os.path.join(ROOT, "CLAUDE.md")), re.M) is not None)
    check("mg control: the identifiers stay (hubkit/, hubflow.py, HUB_SESSION, HUB-CORE.md)",
          os.path.isfile(os.path.join(ROOT, "hubkit", "tools", "hubkit.py")) and os.path.isfile(CORE)
          and os.path.isfile(os.path.join(ROOT, "hubkit", "hub", ".claude", "scripts", "hubflow.py"))
          and "HUB_SESSION" in read(os.path.join(ROOT, "hubkit", "INSTRUCTIONS.md")))


CLAIMS = {k: globals()[k] for k in ("mb1", "mb2", "mb3", "mb4", "mb5", "mb6", "mf1", "mf4", "mg")}

if __name__ == "__main__":
    a = sys.argv[1:]
    if a == ["--list"]:
        print("\n".join(CLAIMS))
        sys.exit(0)
    if not a or a[0] not in CLAIMS:
        print(__doc__)
        sys.exit(2)
    CLAIMS[a[0]]()
    for f in failures:
        print("FAIL " + f)
    print(f"{count} checks, {len(failures)} failed")
    sys.exit(1 if failures else 0)
