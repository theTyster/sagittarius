#!/usr/bin/env python3
"""T22: an agent in a hub knows the stores and the workflow. One check per claim.

usage: python3 docs/check_hub_guidance.py c1|c2|...|c12 [--design DIR]   (--list prints the ids)
Exit 0: the claim's check passes. Exit 1: it fails (each failure is printed). Prints `N checks`.

c1 compares HUB-CORE.md "What lives where" with hubkit/tools/store-facts.json (the facts of the
   hub design KB's eff_fact/2, eff_cell/3, fact_desc/2). When the design KB is on this machine
   (--design DIR, $HUB_DESIGN_KB, or ~/Projects/mine/sagittarius/tmp/hub-design-kb) the JSON is
   also compared with a fresh export of it. Names, owners and cells must agree.
The other claims check the texts the ticket names, and run the behaviour tests for c3, c4, c6.
"""
import json
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HUB = os.path.join(ROOT, "hubkit", "hub")
CORE = os.path.join(HUB, "HUB-CORE.md")
FLOW = os.path.join(HUB, ".claude", "scripts", "hubflow.py")
FLOWTEST = os.path.join(HUB, ".claude", "scripts", "hubflow-test.py")
SKILL_FLOW = os.path.join(HUB, ".claude", "skills", "hub-flow", "SKILL.md")
SKILL_ROT = os.path.join(HUB, ".claude", "skills", "hub-rotate", "SKILL.md")
FACTS = os.path.join(ROOT, "hubkit", "tools", "store-facts.json")
EXPORT = os.path.join(ROOT, "hubkit", "tools", "export-store-facts.pl")
OKB = os.path.join(ROOT, "kb", "bin", "orbit-kb")
PROMPT = os.path.join(ROOT, "prompt", "SAGITTARIUS.md")
PANES = os.path.join(ROOT, "prompt", "PANES.md")
UPGRADING = os.path.join(ROOT, "hubkit", "UPGRADING.md")
KIT = os.path.join(ROOT, "hubkit", "kit.json")

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


def words(text):
    return re.sub(r"\s+", " ", text).lower()


def has(name, text, *phrases):
    t = words(text)
    for ph in phrases:
        check(f"{name}: has '{ph}'", ph.lower() in t, "missing")


def lacks(name, text, *phrases):
    t = words(text)
    for ph in phrases:
        check(f"{name}: lacks '{ph}'", ph.lower() not in t, "still there")


def section(text, heading):
    """The body of a '## heading' section, up to the next '## '."""
    m = re.search(r"^## " + re.escape(heading) + r"\s*$", text, re.M)
    if not m:
        return ""
    rest = text[m.end():]
    n = re.search(r"^## ", rest, re.M)
    return rest[:n.start()] if n else rest


def table(text, first_header):
    """The rows (list of cell lists) of the md table whose header row starts with first_header."""
    lines = text.splitlines()
    for i, ln in enumerate(lines):
        if ln.startswith("|") and [c.strip() for c in ln.strip().strip("|").split("|")][0] == first_header:
            rows = []
            for r in lines[i + 2:]:
                if not r.startswith("|"):
                    break
                rows.append([c.strip() for c in r.strip().strip("|").split("|")])
            return rows
    return None


def names(cell):
    c = cell.strip()
    return set() if c in ("", "-", "none") else {x.strip().strip("`") for x in c.split(",")}


def run(cmd, **kw):
    return subprocess.run(cmd, capture_output=True, text=True, **kw)


def case_run(name, *cases, need=1):
    """Run hubflow-test.py --case ...; every PASS counts, any FAIL fails, and at least `need` must pass."""
    args = [sys.executable, "-I", FLOWTEST]
    for c in cases:
        args += ["--case", c]
    p = run(args)
    last = (p.stdout.strip().splitlines() or [""])[-1]
    m = re.match(r"(\d+) passed, (\d+) failed", last)
    ok = bool(m) and int(m.group(2)) == 0 and int(m.group(1)) >= need and p.returncode == 0
    fails = [x for x in p.stdout.splitlines() if x.startswith("FAIL")]
    check(f"{name}: hubflow-test {' '.join(cases)} passes at least {need} checks", ok, (last, fails[:3], p.stderr[-200:]))


# ------------------------------------------------------------------ c1
def design_dir(arg):
    for d in (arg, os.environ.get("HUB_DESIGN_KB"), os.path.expanduser("~/Projects/mine/sagittarius/tmp/hub-design-kb")):
        if d and os.path.isfile(os.path.join(d, "load.pl")):
            return d
    return None


def c1(arg):
    try:
        facts = json.loads(read(FACTS))
    except ValueError:
        check("c1: hubkit/tools/store-facts.json exists and is JSON", False, FACTS)
        return
    d = design_dir(arg)
    if d and os.path.isfile(EXPORT):
        with tempfile.TemporaryDirectory() as t:
            out = os.path.join(t, "f.json")
            p = run(["swipl", "-g", f"consult(load),consult('{EXPORT}'),export_store_facts('{out}'),halt", "-t", "halt"], cwd=d)
            fresh = None
            try:
                fresh = json.loads(read(out))
            except ValueError:
                pass
            check("c1: the design KB exports (swipl)", fresh is not None, p.stderr[-300:])
            check("c1: store-facts.json equals a fresh export of the design KB", fresh == facts, "regenerate with hubkit/tools/storemap.py --export")
    else:
        print("c1: note: the design KB is not on this machine; the json is not compared with it")
    check("c1: seven stores", [s["name"] for s in facts["stores"]] == ["spec", "project", "ledger", "memory", "weeks", "bespoke", "tracker"])
    check("c1: every fact kind has a description and one owner", all(f["desc"] and f["owner"] for f in facts["facts"]))
    sec = section(read(CORE), "What lives where")
    check("c1: HUB-CORE.md has a 'What lives where' section", bool(sec), "missing")
    stores = table(sec, "Store")
    check("c1: the stores table exists (header: Store | Owns | Lives in the hub | Used with)", stores is not None and len(stores[0]) == 4 if stores else False, stores)
    if stores:
        got = {r[0].strip("`"): r for r in stores}
        check("c1: the stores table has the seven stores", set(got) == {s["name"] for s in facts["stores"]}, sorted(got))
        for s in facts["stores"]:
            r = got.get(s["name"])
            if not r:
                continue
            check(f"c1: store {s['name']} owns Ty's definition", r[1] == s["owns"], r[1][:120])
            check(f"c1: store {s['name']} says where it lives", len(r[2]) > 3, r[2])
            check(f"c1: store {s['name']} names its command or help topic", len(r[3]) > 3, r[3])
        check("c1: the project store names orbit-kb help project", "orbit-kb help project" in got.get("project", ["", "", "", ""])[3])
        check("c1: the ledger names hubflow", "hubflow" in got.get("ledger", ["", "", "", ""])[3])
        check("c1: the spec store names orbit-kb", "orbit-kb" in got.get("spec", ["", "", "", ""])[3])
    rows = table(sec, "Fact kind")
    check("c1: the fact table exists (Fact kind | What it is | Owner | Pinned in | Read from | Copied in)", rows is not None and len(rows[0]) == 6 if rows else False, rows)
    if rows:
        got = {r[0].strip("`"): r for r in rows}
        want = {f["name"]: f for f in facts["facts"]}
        check(f"c1: the fact table has the {len(want)} fact kinds of the design", set(got) == set(want),
              (sorted(set(want) - set(got)), sorted(set(got) - set(want))))
        for n, f in want.items():
            r = got.get(n)
            if not r:
                continue
            check(f"c1: {n} description", r[1] == f["desc"], r[1][:80])
            check(f"c1: {n} owner", r[2].strip("`") == f["owner"], (r[2], f["owner"]))
            check(f"c1: {n} pinned in", names(r[3]) == set(f["pinned"]), (r[3], f["pinned"]))
            check(f"c1: {n} read from", names(r[4]) == set(f["read"]), (r[4], f["read"]))
            check(f"c1: {n} copied in", names(r[5]) == set(f["copied"]), (r[5], f["copied"]))


# ------------------------------------------------------------------ c2
COPY = ("pinned copy", "digest", "stale", "unpinned copy", "re-pin")


def c2(_):
    core = read(CORE)
    has("c2 HUB-CORE.md", core, *COPY)
    has("c2 hub-flow SKILL.md", read(SKILL_FLOW), *COPY)
    helptext = run([sys.executable, "-I", FLOW, "--help"])
    has("c2 hubflow.py --help", helptext.stdout + helptext.stderr, *COPY)
    has("c2 HUB-CORE.md says when to re-pin", core, "each time an agent reads", "tracker item")
    lacks("c2 HUB-CORE.md", core, "never a copy of the ticket")


# ------------------------------------------------------------------ c3
def c3(_):
    core = read(CORE)
    has("c3 HUB-CORE.md", core, "specs/<slug>/", "kb:<slug>", "git is the archive", "only the spec kb decides what blocks")
    has("c3 UPGRADING.md", read(UPGRADING), "W*/analyses/<slug>/kb", "git mv", "specs/<slug>")
    core_help = read(os.path.join(ROOT, "kb", "share", "orbit-kb", "help", "core.txt"))
    check("c3 help core: the do-not-commit rule names the hub exception", re.search(r"in a hub", core_help, re.I) is not None
          and "commit" in core_help.lower(), "no hub exception")
    case_run("c3", "case_t22_spec_home", need=10)
    with tempfile.TemporaryDirectory() as t:
        kb = os.path.join(t, "specs", "demo")
        p = run([OKB, "init", kb, "--request", "Demo spec request T22", "--uses", "build"])
        check("c3: a spec KB can be made at specs/<slug>", p.returncode == 0, p.stderr)
        run([OKB, "--dir", kb, "add", "claim(c1, introduce, 'x')", "cites(c1, 'y')"])
        p = run([OKB, "--dir", kb, "show", "open"])
        check("c3: show open works at specs/<slug>", p.returncode == 0 and "c1" in p.stdout, p.stdout + p.stderr)
        sp = subprocess.Popen([OKB, "serve", "questions", "--root", t, "--port", "0"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        try:
            line = sp.stdout.readline()
            m = re.search(r"http://127\.0\.0\.1:\d+/", line)
            check("c3: serve --root starts", m is not None, line)
            if m:
                import urllib.request
                page = urllib.request.urlopen(m.group(0), timeout=20).read().decode("utf-8", "replace")
                check("c3: serve --root lists the spec KB under specs/", "Demo spec request T22" in page, page[:200])
        finally:
            sp.terminate()
            sp.wait(timeout=20)


# ------------------------------------------------------------------ c4
def c4(_):
    core = read(CORE)
    rot = read(SKILL_ROT)
    has("c4 HUB-CORE.md", core, "W*/reports/", "W*/transcripts/", "analyses are written in the project kb", "rotation never retires a spec kb",
        "archive, capsule, keep or escalate", "git rm")
    lacks("c4 hub-rotate SKILL.md slot table", rot, "├── analyses/", "| `analyses/` |")
    has("c4 hub-rotate SKILL.md", rot, "spec-triage", "spec_kbs_untriaged", "specs/<slug>")
    h = run([sys.executable, "-I", FLOW, "--help"])
    lacks("c4 hubflow.py --help", h.stdout + h.stderr, "each with an analyses/")
    has("c4 hubflow.py --help", h.stdout + h.stderr, "spec-triage")
    case_run("c4", "case_t22_rotate_open_spec", "case_t22_closed_spec", need=18)


# ------------------------------------------------------------------ c5
def c5(_):
    pr = read(PROMPT)
    i = pr.find("When you resume")
    check("c5 prompt has 'When you resume'", i >= 0, "missing")
    para = pr[i:i + 300]
    # 0.3.0: the prompt holds no hub text ("A workspace, such as a hub, names its own tools, roles,
    # and routing"): it keeps `orbit-kb show open` for a resume; the inbox and hubflow recipe live
    # in the hub's text (PANES.md, the hub-flow skill).
    has("c5 prompt resume paragraph", para, "orbit-kb show open")
    lacks("c5 prompt", pr, "hubflow")
    # Sagittarius 0.3.0 (c_m_b_1): the prompt has no hub lines; the hub's own HUB-CORE.md, always loaded in a
    # hub, holds the resume rule (read the inbox at session start and after a compaction, then each kb ref).
    flow = section(read(CORE), "Flow state lives in the db")
    has("c5 HUB-CORE.md 'Flow state lives in the db'", flow, "session start", "compaction", "v_inbox", "hubflow.py where", "orbit-kb show open")
    pan = read(PANES)
    has("c5 PANES.md handoff procedure", pan, "hubflow handoff", "inbox", "v_inbox", "hubflow where", "kb ref", "orbit-kb show open")
    has("c5 hub-flow SKILL.md reads the inbox", read(SKILL_FLOW), "v_inbox")
    has("c5 hub-flow SKILL.md points to PANES.md", read(SKILL_FLOW), "PANES.md")
    check("c5 the procedure is written once (one 'hubflow handoff' recipe in PANES.md)", words(pan).count("hubflow handoff") == 1, words(pan).count("hubflow handoff"))
    # Sagittarius 0.3.0 (c_m_f_3): the receiver records the handoff in the KB as a signal; the example runs as written
    ex = re.findall(r"`(orbit-kb add \"signal\([^`]*\)\")`", pan)
    check("c5 PANES.md: the receiver records the handoff in the KB as a signal (an orbit-kb add example)", len(ex) == 1 and "handoff" in ex[0], ex)
    if len(ex) == 1 and os.access(OKB, os.X_OK):  # the scratch copy of check_mutants.py holds no kb/bin
        with tempfile.TemporaryDirectory() as d:
            kb = os.path.join(d, "kb")
            init = run([OKB, "init", kb, "--request", "an invented request"])
            fact = re.search(r'"(signal\(.*\))"', ex[0]).group(1)
            add = run([OKB, "--dir", kb, "add", fact], env=dict(os.environ, CLAUDE_CODE_SESSION_ID="c5-check"))
            check("c5 the signal example of PANES.md runs in orbit-kb add", init.returncode == 0 and add.returncode == 0,
                  (init.stderr[-200:], add.stdout[-200:], add.stderr[-300:]))


# ------------------------------------------------------------------ c6
def c6(_):
    core, skill = read(CORE), read(SKILL_FLOW)
    for n, t in (("HUB-CORE.md", core), ("hub-flow SKILL.md", skill)):
        has(f"c6 {n}", t, "draft/4", "project kb", "outbound-staging", "a human sends", "pushed/2")
    has("c6 HUB-CORE.md", core, "orbit-kb draft attach")
    hd = run([OKB, "help", "draft"]).stdout
    has("c6 help draft", hd, "a human pastes it", "draft attach")
    lacks("c6 help draft", hd, "Paste it")
    t = subprocess.run(["bash", os.path.join(ROOT, "kb", "tests", "test_tracker_sync.sh")], capture_output=True, text=True, env={**os.environ, "ONLY": "TS6[01]"})
    last = [x for x in t.stdout.splitlines() if "pass=" in x]
    check("c6 test_tracker_sync.sh TS60-TS61 pass", t.returncode == 0 and last and "pass=2 fail=0" in last[-1], (last, t.stdout[-300:]))


# ------------------------------------------------------------------ c7
def c7(_):
    has("c7 HUB-CORE.md", read(CORE), "bespoke", "only if other agents can use it for other tasks", "a per-ticket helper stays with its ticket",
        "no pin from an open spec kb", "no listed use since the last rotation", "only unused tools are pruned", "at rotation", "triage decision",
        "never pruned")
    has("c7 hub-rotate SKILL.md", read(SKILL_ROT), "unused", "tool")


# ------------------------------------------------------------------ c8
def c8(_):
    core = read(CORE)
    has("c8 HUB-CORE.md", core, "sop is owned outside the hub", "the build does not need it", "product rules live in the project kb")
    rows = table(section(core, "What lives where"), "Fact kind") or []
    got = {r[0].strip("`"): r for r in rows}
    check("c8 the table has a sop row owned outside the hub", got.get("sop", ["", "", ""])[2].strip("`") == "outside", got.get("sop"))
    check("c8 the table has a product_rules row owned by the project KB", got.get("product_rules", ["", "", ""])[2].strip("`") == "project", got.get("product_rules"))


# ------------------------------------------------------------------ c9
def c9(_):
    pr = read(PROMPT)
    # 0.3.0: the prompt holds no hub text; HUB-CORE.md (the hub's own text) names the project KB and the stores.
    core = read(CORE)
    has("c9 HUB-CORE.md", core, "orbit-kb help project", "What lives where")
    has("c9 prompt says that a workspace names its own tools, roles, and routing", " ".join(pr.split()), "A workspace, such as a hub, names its own tools, roles, and routing")
    has("c9 HUB-CORE.md names the repo map", read(CORE), "kb/bin/repo-map")
    has("c9 the hub CLAUDE.md template names the repo map", read(os.path.join(HUB, "CLAUDE.md")), "repo-map")


# ------------------------------------------------------------------ c10
LANDED = {"T06": "kb/share/orbit-kb/modules/project.pl", "T10": "kb/bin/orbit-kb"}


def c10(_):
    cm = read(os.path.join(ROOT, "CLAUDE.md"))
    for ln in cm.splitlines():
        m = re.search(r"Planned \((T\d+)\)", ln)
        if not m:
            continue
        paths = re.findall(r"`([^`]+)`", ln) + ([LANDED[m.group(1)]] if m.group(1) in LANDED else [])
        gone = [p for p in paths if os.path.exists(os.path.join(ROOT, p.split()[0]))]
        check(f"c10 row says Planned ({m.group(1)}) but a path exists", not gone, (ln[:80], gone))
    low = cm.lower()
    for need in ("project kb module", "question view", "question server", "draft", "pin-item", "hook", "status line"):
        check(f"c10 CLAUDE.md has a row for '{need}'", need in low, "missing")
    for p in ("kb/share/orbit-kb/modules/project.pl", "s1/hook.py", "s1/statusline.py"):
        check(f"c10 CLAUDE.md names {p}", p in cm, "missing")


# ------------------------------------------------------------------ c11
def c11(_):
    kit = json.loads(read(KIT))
    v = kit["version"]
    check("c11 the kit version is bumped from 0.2.0", v != "0.2.0" and tuple(map(int, v.split("."))) > (0, 2, 0), v)
    up = read(UPGRADING)
    check(f"c11 UPGRADING.md has a section for {v}", re.search(r"^### " + re.escape(v) + r"\b", up, re.M) is not None, v)
    first = re.search(r"^### (\d+\.\d+\.\d+)", up, re.M)
    check("c11 the newest UPGRADING section is the kit version", first is not None and first.group(1) == v, first and first.group(1))
    check("c11 HUB-CORE.md is an engine file", "HUB-CORE.md" in kit["engine"], kit["engine"])
    # the entry that made these changes is 0.3.0 (T22); a later release need not repeat its words
    sec = up[up.find("### 0.3.0"):] if "### 0.3.0" in up else ""
    has("c11 the 0.3.0 entry names what changes", sec[:3000], "HUB-CORE.md", "specs/<slug>", "spec-triage")


# ------------------------------------------------------------------ c12
def c12(_):
    sec = section(read(CORE), "Panes")
    check("c12 HUB-CORE.md has a Panes section", bool(sec), "missing")
    has("c12 Panes section", sec, "prompt/PANES.md", "review", "discovery", "build", "make and judge", "named session",
        "outside the hub", "verify is review's", "fresh-eyes subagent", "records its verdicts")


CLAIMS = {f"c{i}": globals()[f"c{i}"] for i in range(1, 13)}

if __name__ == "__main__":
    a = sys.argv[1:]
    if a == ["--list"]:
        print("\n".join(CLAIMS))
        sys.exit(0)
    arg = None
    if "--design" in a:
        arg = a[a.index("--design") + 1]
    if not a or a[0] not in CLAIMS:
        print(__doc__)
        sys.exit(2)
    CLAIMS[a[0]](arg)
    for f in failures:
        print("FAIL " + f)
    print(f"{count} checks, {len(failures)} failed")
    sys.exit(1 if failures else 0)
