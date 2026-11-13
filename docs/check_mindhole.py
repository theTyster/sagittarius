#!/usr/bin/env python3
"""Sagittarius 0.3.0 alignment, the MindHole packages M-B, M-F and M-G: the hub's own text carries the
hub's rules, a handoff carries the KB, a closed ticket leaves its outcomes, and the display name.
One check per claim of the spec KB (tmp/kb-sagittarius-030).

usage: python3 docs/check_mindhole.py mb1|mb2|mb3|mb4|mb5|mb6|mb7|mf1|mf4|mg|mg2|u1|u2|u3|u4|u6|lp|pr [--list]   (--list prints the ids)
Exit 0: the claim's check passes. Exit 1: it fails (each failure is printed). Prints `N checks`.

mb1 (c_m_b_1) both HUB-CORE.md files tell a session to read its inbox (`view v_inbox`) at session start and
    after a compaction, in "Flow state lives in the db"; the formal one then follows each kb ref.
What this file does not do: mb2 to mb5 read the kit tree only. They do not compare store-facts.json or the
tables with the hub design KB, so they can pass while the spec checks m_b_2 to m_b_5 (tmp/kb-sagittarius-030,
checks/check.py) fail. The comparison with the design KB is check_hub_guidance.py c1 and the spec checks.

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
mb7 (review finding 6) the informal hub-flow skill teaches the two notes that the informal map names:
    "divergence: ..." and "vote: GO: ..." on the ticket's thread.
mg2 (Ty, 2026-11-12: the hub is the MindHole; the template is the MindHole Kit, with its own version line)
    hubkit/README.md, hubkit/INSTRUCTIONS.md and the MindHole Kit section of README.md call the template the
    MindHole Kit: no "hub kit", no "the MindHole Kit is the hub", no "the MindHole is the kit", no "MindHole hub",
    no "MindHole <N.N.N>"; both HUB-CORE.md files say they ship with the MindHole Kit; the versions table of
    CHANGELOG.md has the row "MindHole Kit" with the version of hubkit/kit.json (review finding 7).
u1  (UAT U1) step 3 of INSTRUCTIONS.md and UPGRADING.md say what the last line of hubflow-test.py looks like in
    a hub (", 3 skipped" in a formal hub) and name each check that hubflow-test.py skips as "not run from the
    kit tree"; UPGRADING.md no longer says that the suite shows no SKIP.
u2  (UAT U2) step 3 of INSTRUCTIONS.md and the procedure of UPGRADING.md give an honest time for --mutants
    ("an hour or more on a loaded machine"), and say that it prints one line per mutant.
u3  (UAT U3) the commit step of INSTRUCTIONS.md checks `git config user.name` and `user.email` before the
    commit, and asks the human when one is empty.
u4  (UAT U4) a numbered step before the commit step makes the project store of a formal hub: the step points
    at "The formal edition", whose part with the same step number gives the project KB setup line.
lp  (review 2, finding 6) the informal HUB-CORE.md states the light path in its own paragraph, in its own words:
    an informal hub has no Sagittarius prompt, so the paragraph cites no prompt and names what brings review in.
pr  (review 2, finding 10) PRINCIPLES.md cites the sections that its text comes from: "Start light" cites
    "The light path" and "Signals" and names the six signals (a claim that burns too, as "a claim that needs a proof"); the part with "only the
    work that the request needs" cites "The orbit"; no part says "not logs", which the prompt does not say.
u6  (UAT U6) both CLAUDE.md templates (formal and informal) have a section for the human's own notes, such
    as a project order.
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
    want = "solver and model-checker models, and lean definitions and theorems"
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


def mb7():
    t = flat(read(os.path.join(ROOT, "hubkit", "editions", "informal", ".claude", "skills", "hub-flow", "SKILL.md")))
    ic = read(ICORE)
    for note in ('"divergence: ', '"vote: GO: '):
        check(f"mb7 the informal map names the note {note}", note in ic, "the informal HUB-CORE.md map changed")
        check(f"mb7 the informal hub-flow skill gives a $HF note example of {note}", f"$HF note T-0002 {note}" in t, t[:200])
    check("mb7 the informal skill says a vote is GO, NO-GO or HOLD", all(w in t for w in ("NO-GO", "HOLD")), t[:200])


def mg2():
    for rel in ("hubkit/README.md", "hubkit/INSTRUCTIONS.md"):
        t = flat(read(os.path.join(ROOT, rel)))
        check(f"mg2 {rel} does not call the kit the hub kit", re.search(r"hub kit(?!\.json)", t, re.I) is None, re.findall(r"[^.]*hub kit[^.]*", t, re.I)[:2])
        check(f"mg2 {rel} does not say the MindHole Kit is the hub", re.search(r"MindHole Kit\W* is the hub\b", t) is None,
              re.findall(r"[^.]*MindHole Kit\W* is the hub[^.]*", t)[:1])
        check(f"mg2 {rel} does not call the kit the MindHole", re.search(r"MindHole\W* is the (hub )?kit|MindHole hub|MindHole \d|MindHole <version>", t) is None,
              re.findall(r"[^.]*(?:MindHole\W* is the (?:hub )?kit|MindHole hub|MindHole <version>)[^.]*", t)[:1])
    head = flat("\n".join(read(os.path.join(ROOT, "hubkit", "README.md")).splitlines()[:6]))
    check("mg2 hubkit/README.md says in its first lines that the MindHole Kit is the template", re.search(r"MindHole Kit\W* is (a|the) [^.]*\btemplate\b", head), head[:300])
    check("mg2 hubkit/README.md names the version line MindHole Kit <version>", "MindHole Kit <version>" in read(os.path.join(ROOT, "hubkit", "README.md")))
    readme = read(os.path.join(ROOT, "README.md"))
    sec = flat(section(readme, "The MindHole Kit"))
    check("mg2 README.md has a section 'The MindHole Kit' that names hubkit/", "hubkit/" in sec, sec[:200])
    check("mg2 README.md names the version line MindHole Kit <version>", "MindHole Kit <version>" in flat(sec), sec[:200])
    check("mg2 README.md does not call the kit the hub kit", "hub kit" not in flat(readme).lower(), re.findall(r"[^.]*hub kit[^.]*", flat(readme), re.I)[:2])
    check("mg2 README.md does not say the MindHole Kit is the hub", re.search(r"MindHole Kit\W* is the hub\b", flat(readme)) is None)
    check("mg2 README.md does not call the kit the MindHole", re.search(r"MindHole\W* is the (hub )?kit|MindHole hub|MindHole <version>", flat(readme)) is None)
    for label, path in (("formal", CORE), ("informal", ICORE)):
        top = flat("\n".join(read(path).splitlines()[:5]))
        check(f"mg2 the {label} HUB-CORE.md says it ships with the MindHole Kit", "ships with the MindHole Kit" in top, top[:200])
    kit = json.loads(read(os.path.join(ROOT, "hubkit", "kit.json")) or "{}").get("version")
    row = [ln for ln in read(os.path.join(ROOT, "CHANGELOG.md")).splitlines() if ln.startswith("| MindHole Kit")]
    check("mg2 the versions table of CHANGELOG.md has one row named MindHole Kit", len(row) == 1 and cells(row[0])[0] == "MindHole Kit", row)
    check("mg2 the MindHole Kit row of CHANGELOG.md names the kit.json version", row and cells(row[0])[1] == kit, (row, kit))


def kit_tree_skips():
    t = read(FLOWTEST)
    return re.findall(r'r\.skip\("([^"]+)", "not run from the kit tree', t)


def u1():
    skips = kit_tree_skips()
    check("u1 hubflow-test.py has checks that skip outside the kit tree", len(skips) >= 1, skips)
    ins = read(os.path.join(ROOT, "hubkit", "INSTRUCTIONS.md"))
    s3 = flat(section(ins, "Step 3"))
    up = flat(read(os.path.join(ROOT, "hubkit", "UPGRADING.md")))
    for label, t in (("INSTRUCTIONS.md step 3", s3), ("UPGRADING.md", up)):
        check(f"u1 {label} gives the last line of a formal hub: 0 failed, {len(skips)} skipped", f"0 failed, {len(skips)} skipped" in t, t[:300])
        check(f"u1 {label} quotes the reason of those skips", "not run from the kit tree" in t, t[:300])
        for s in skips:
            check(f"u1 {label} names the skip {s}", s in t, "missing")
    check("u1 INSTRUCTIONS.md step 3 no longer says the last line must be N passed, 0 failed (with no skips)",
          re.search(r'last line must be "N passed, 0 failed"', s3) is None, s3[:200])
    check("u1 UPGRADING.md no longer says the suite shows no SKIP", re.search(r"shows no `?SKIP`?\.", up) is None,
          re.findall(r"[^.]*shows no `?SKIP[^.]*", up)[:2])


def u2():
    ins = flat(section(read(os.path.join(ROOT, "hubkit", "INSTRUCTIONS.md")), "Step 3"))
    proc = flat(section(read(os.path.join(ROOT, "hubkit", "UPGRADING.md")), "The procedure"))
    for label, t in (("INSTRUCTIONS.md step 3", ins), ("UPGRADING.md, The procedure", proc)):
        check(f"u2 {label} says --mutants takes an hour or more on a loaded machine", "an hour or more on a loaded machine" in t, t[:300])
        check(f"u2 {label} says --mutants prints one line per mutant", "one line per mutant" in t, t[:300])
        check(f"u2 {label} no longer says 10 minutes", "10 minutes" not in t)


def steps(ins):
    return [(int(m.group(1)), m.group(2), m.group(3)) for m in re.finditer(r"^## Step (\d+): ([^\n]*)\n(.*?)(?=^## |\Z)", ins, re.M | re.S)]


def u3():
    ins = read(os.path.join(ROOT, "hubkit", "INSTRUCTIONS.md"))
    com = [(n, b) for n, h, b in steps(ins) if h.startswith("commit")]
    check("u3 INSTRUCTIONS.md has one commit step", len(com) == 1, [h for _, h, _ in steps(ins)])
    if not com:
        return
    b = com[0][1]
    first_commit = b.find("git commit")
    for w in ("git config user.name", "git config user.email"):
        check(f"u3 the commit step runs `{w}`", w in b, b[:300])
        check(f"u3 the commit step runs `{w}` before the first git commit", 0 <= b.find(w) < first_commit, (b.find(w), first_commit))
    fb = flat(b)
    check("u3 the commit step asks the human when one is empty", re.search(r"empty[^.]*ask|ask[^.]*empty", fb, re.I), fb[:400])


def u4():
    ins = read(os.path.join(ROOT, "hubkit", "INSTRUCTIONS.md"))
    st = steps(ins)
    check("u4 the steps are numbered 1 to N with no gap", [n for n, _, _ in st] == list(range(1, len(st) + 1)), [n for n, _, _ in st])
    com = [n for n, h, _ in st if h.startswith("commit")]
    fs = [(n, h, b) for n, h, b in st if "formal edition only" in h]
    check("u4 one numbered step is for the formal edition only", len(fs) == 1, [h for _, h, _ in st])
    if not (com and fs):
        return
    n, h, b = fs[0]
    check("u4 the formal step comes right before the commit step", n == com[0] - 1, (n, com))
    fb = flat(b)
    check("u4 the formal step says an informal hub skips it", re.search(r"informal hub skips", fb), fb[:300])
    check("u4 the formal step points at The formal edition", '"The formal edition"' in fb, fb[:300])
    check("u4 the formal step's check names project-kb/", "project-kb/" in fb, fb[:300])
    formal = section(ins, "The formal edition")
    part = re.search(r"\*\*Step %d \(formal\)[^*]*\*\*(.*?)(?=^- |\Z)" % n, formal, re.S | re.M)
    check(f"u4 The formal edition has a part labeled Step {n} (formal)", part is not None, formal[:300])
    if part:
        check(f"u4 that part gives the project KB setup line", ".claude/orbit-kb/bin/orbit-kb init project-kb" in part.group(1), part.group(1)[:300])
    six = flat(section(ins, f"Step {com[0]}"))
    check("u4 the commit step names project-kb as made by the formal step", f"step {n}" in six.lower(), six[:300])


def u6():
    for label, rel in (("formal", ("hubkit", "hub", "CLAUDE.md")), ("informal", ("hubkit", "editions", "informal", "CLAUDE.md"))):
        t = read(os.path.join(ROOT, *rel))
        sec = flat(section(t, "Your notes"))
        check(f"u6 the {label} CLAUDE.md template has a section Your notes", bool(sec), [ln for ln in t.splitlines() if ln.startswith("## ")])
        check(f"u6 the {label} section names a project order as an example", "project order" in sec, sec[:200])
        check(f"u6 the {label} section says the notes are the human's", "human" in sec, sec[:200])


def lp():
    sec = section(read(ICORE), "Verify")
    paras = [flat(p) for p in re.split(r"\n\s*\n", sec) if p.strip()]
    lpp = [p for p in paras if "light path" in p]
    check("lp the informal Verify section has one light path paragraph", len(lpp) == 1, lpp)
    if lpp:
        check("lp the light path paragraph cites no prompt (an informal hub has none)", "prompt" not in lpp[0], lpp[0][:200])
        check("lp the light path paragraph is apart from the verifier rule", "Verify belongs" not in lpp[0], lpp[0][:300])
        check("lp the paragraph names what brings review in", all(w in lpp[0] for w in ("handoff", "disagree", "asks")), lpp[0][:300])


def pr():
    t = read(os.path.join(ROOT, "hubkit", "hub", "PRINCIPLES.md"))
    parts = {s.splitlines()[0].strip(): s for s in re.split(r"^## ", t, flags=re.M)[1:]}
    cites = {k: re.findall(r'^From the prompt: "([^"]+)"\s*$', v, re.M) for k, v in parts.items()}
    sl = [k for k in parts if k.startswith("Start light")]
    check("pr PRINCIPLES.md has the part Start light", len(sl) == 1, list(parts))
    if sl:
        s, c = flat(parts[sl[0]]), cites[sl[0]]
        check("pr Start light cites The light path and Signals", "The light path" in c and "Signals" in c, c)
        for w, what in (("question", "questions"), ("disagree", "a divergence"), ("someone else built", "a build by someone else"),
                        ("needs a proof", "a claim that burns (in words without the KB term burn, which check_informal_release c3 bans)"), ("changes hands", "a handoff"), ("careful message", "effort")):
            check(f"pr Start light names the signal {what}", w in s, s[:300])
    for k, v in parts.items():
        if "only the work that the request needs" in flat(v):
            check(f"pr the part '{k}' cites The orbit for 'only the work that the request needs'", "The orbit" in cites[k], cites[k])
    check("pr PRINCIPLES.md does not say 'not logs' (the prompt does not)", "not logs" not in flat(t))
    check("pr PRINCIPLES.md stays short (60 lines or fewer)", len(t.splitlines()) <= 60, len(t.splitlines()))


CLAIMS = {k: globals()[k] for k in ("mb1", "mb2", "mb3", "mb4", "mb5", "mb6", "mb7", "mf1", "mf4", "mg", "mg2", "u1", "u2", "u3", "u4", "u6", "lp", "pr")}

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
