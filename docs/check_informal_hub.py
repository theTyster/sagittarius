#!/usr/bin/env python3
"""T32: an informal hub loads only informal rules. One check per claim.

usage: python3 docs/check_informal_hub.py t32c2|...|t32c8|t36c1|...|t36c6|t41c1|...|t41c5|t44c1|t44c2|iuxc3e|iuxc4 (t32c1 is superseded by iuxc3e, t32c6 and t36c3 by iuxc4) [--list]   (--list prints the claim ids)
Exit 0: the claim's check passes. Exit 1: it fails (each failure is printed). Prints `N checks`.

t32c1 installs hubs from this kit with --edition informal|formal and with no --edition (a PATH with
      and without an `orbit-kb` stub), reads the edition that .hub-template.json records, upgrades
      each hub to a copy of the kit with a newer version, and switches one with `hubkit.py edition`.
t32c2 installs an informal hub and greps its always-loaded text (CLAUDE.md, each file it imports
      with @, and the hub-flow and hub-rotate SKILL.md) for the formal words; reads the informal
      part of INSTRUCTIONS.md (all but "## The formal edition"); installs a formal hub and compares
      it with the kit's hub/ files, which keep the formal text.
t32c3 reads the informal store map (the informal-map block) in both HUB-CORE files: one generated
      table with each of the fact kinds of hubkit/tools/store-facts.json; runs storemap.py --check,
      and once on a copy with a row removed (it must fail).
t32c4 reads the seed and the informal HUB-CORE.md, then records one verdict in a new informal hub
      with the command that HUB-CORE.md gives, and reads it back with `hubflow.py show`.
t32c5 reads hubkit/hub/PRINCIPLES.md for principles 4, 5 and 8 of docs/PHILOSOPHY.md.
t32c6 reads the tool list of hubkit/README.md "## Install", runs its sh block with relative KIT and
      HUB and a PATH of exactly those tools, and runs check_informal_release.py c1 (T24), which
      must print the same list as its PATH.
t32c7 reads INSTRUCTIONS.md step 5 for the command that resumes a named session.
t32c8 installs a formal and an informal hub (hubkit.py install, then hubflow.py init) and runs
      `orbit-kb show open` at each root: the formal hint names specs/<slug>/ and hubflow where SLUG,
      the informal one names the ledger and no spec KB path.
t41c1 reads the hypothesis principle, the informal hypothesis row of both HUB-CORE files and of
      storemap.py for the expected result, the falsifier and the premises.
t41c2 installs an informal and a formal hub: the informal --help lists no kb ref kind, no --analysis
      and no analysis column, and refuses `ref ID add kb:X` and --analysis (add, handoff, set) with a
      line that names the formal edition; the formal hub keeps all of it.
t41c3 installs an informal hub at mono/hub inside `git init mono` and runs hubflow from mono/hub with
      no HUBFLOW_HUB and no --hub: the informal help, and the db at mono/hub/flow.
t41c4 reads the skip principle for the agent park limit, and parks an item as an agent.
t41c5 reads the formal What lives where hypothesis row of hub/HUB-CORE.md (from the hub design KB)
      for the expected result, the falsifier and the premises.
t44c1 an informal hub accepts no formal-only part on any path: `add KIND --ref kb:X` and import of a kb
      ref or analysis exit 1 and make no item, `show` (md and json) and `view` have no analysis, --help has no "kb ref"; the formal hub keeps the three.
t44c2 the informal hypothesis row of storemap.py (INFORMAL) names the expected result, the falsifier and
      the premises; the check also runs on mutant copies of the row, which must each fail. T44_STOREMAP
      names another storemap.py to read (a red run on a mutant copy).
iuxc3e (install UX c3; supersedes t32c1) t32c1 with one change: with no --edition, install picks informal also
      when an orbit-kb is on PATH (the human chooses formal at setup, not the PATH).
iuxc4 (install UX c4; supersedes t32c6 and t36c3) no engine file of the kit is a shell script; the install of
      hubkit/README.md needs no bash: each line of its sh block is one python3 or git command, run here with no
      shell and a PATH of only python3 and git, KIT and HUB relative; README and the informal HUB-CORE.md name
      Python 3 and git and no bash and no POSIX tool list; check_informal_release.py c1 (T24) still passes.
"""
import json
import os
import re
import shlex
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KITDIR = os.path.join(ROOT, "hubkit")
HUB = os.path.join(KITDIR, "hub")
HUBKIT = os.path.join(KITDIR, "tools", "hubkit.py")
STOREMAP = os.path.join(KITDIR, "tools", "storemap.py")
FACTS = os.path.join(KITDIR, "tools", "store-facts.json")
CORE = os.path.join(HUB, "HUB-CORE.md")
ICORE = os.path.join(KITDIR, "editions", "informal", "HUB-CORE.md")
KREADME = os.path.join(KITDIR, "README.md")
INSTR = os.path.join(KITDIR, "INSTRUCTIONS.md")
PRINCIPLES = os.path.join(HUB, "PRINCIPLES.md")
PHIL = os.path.join(ROOT, "docs", "PHILOSOPHY.md")
OKB = os.path.join(ROOT, "kb", "bin", "orbit-kb")
INFORMAL = ("ledger", "memory", "weeks", "bespoke", "tracker")
IBEGIN = "<!-- informal-map:begin"
IEND = "<!-- informal-map:end -->"
# The words that an informal hub's always-loaded text must not name (ticket c2). "Lean" is matched
# as a capitalised word, so "lean back" (a principle) is not a hit.
BANNED = (("spec KB", re.compile(r"spec kb", re.I)), ("project KB", re.compile(r"project kb", re.I)),
          ("orbit-kb", re.compile(r"orbit-kb", re.I)), ("draft/4", re.compile(r"draft/4")),
          ("pin-item", re.compile(r"pin-item", re.I)), ("Prolog", re.compile(r"prolog", re.I)),
          ("Lean", re.compile(r"\bLean\b")), ("SMT", re.compile(r"\bSMT\b")), ("TLA+", re.compile(r"TLA\+")))

failures = []
count = 0


def check(name, ok, detail=""):
    global count
    count += 1
    if not ok:
        failures.append(f"{name}: {str(detail)[:400]}")


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


def section(text, heading, level="##"):
    m = re.search(r"^" + level + r" " + re.escape(heading) + r".*$", text, re.M)
    if not m:
        return ""
    rest = text[m.end():]
    n = re.search(r"^" + level + r" ", rest, re.M)
    return rest[:n.start()] if n else rest


def table(text, first_header):
    lines = text.splitlines()
    for i, ln in enumerate(lines):
        if ln.startswith("|") and [c.strip() for c in ln.strip().strip("|").split("|")][0] == first_header:
            rows = []
            for r in lines[i + 2:]:
                if not r.startswith("|"):
                    break
                rows.append([c.strip() for c in r.strip().strip("|").split("|")])
            return lines[i], rows
    return None, None


def run(cmd, **kw):
    return subprocess.run(cmd, capture_output=True, text=True, **kw)


def bin_with(where, tools, stub_okb=False):
    """A dir of links to exactly `tools` (found on the current PATH), plus an orbit-kb stub if asked."""
    b = os.path.join(where, "bin")
    os.makedirs(b, exist_ok=True)
    for t in tools:
        p = shutil.which(t)
        if p:
            os.symlink(p, os.path.join(b, t))
    if stub_okb:
        s = os.path.join(b, "orbit-kb")
        with open(s, "w") as f:
            f.write("#!/bin/sh\nexit 0\n")
        os.chmod(s, 0o755)
    return b


def hk(args, path=None):
    env = dict(os.environ)
    if path is not None:
        env["PATH"] = path
    return run([sys.executable, "-I", HUBKIT] + args, env=env)


def manifest(hub):
    try:
        return json.loads(read(os.path.join(hub, ".hub-template.json")))
    except ValueError:
        return {}


def hubflow(hub, args, session=None):
    env = {k: v for k, v in os.environ.items() if k not in ("HUB_SESSION", "HUBFLOW_DB_DIR", "HUBFLOW_HUB")}
    if session:
        env["HUB_SESSION"] = session
    return run([sys.executable, "-I", os.path.join(hub, ".claude", "scripts", "hubflow.py")] + args, cwd=hub, env=env)


def install(t, name, edition):
    hub = os.path.join(t, name)
    os.makedirs(hub)
    run(["git", "init", "-q", hub])
    p = hk(["install", "--hub", hub] + (["--edition", edition] if edition else []))
    return hub, p


def loaded_text(hub):
    """CLAUDE.md, the files it imports with a line `@FILE`, and the two shipped SKILL.md: {rel: text}."""
    out = {}
    cl = read(os.path.join(hub, "CLAUDE.md"))
    out["CLAUDE.md"] = cl
    for ln in cl.splitlines():
        m = re.match(r"^@(\S+)\s*$", ln.strip())
        if m:
            out[m.group(1)] = read(os.path.join(hub, m.group(1)))
    for s in ("hub-flow", "hub-rotate"):
        rel = os.path.join(".claude", "skills", s, "SKILL.md")
        out[rel] = read(os.path.join(hub, rel))
    return out


def banned_hits(text):
    hits = []
    for i, ln in enumerate(text.splitlines(), 1):
        for name, rx in BANNED:
            if rx.search(ln):
                hits.append((i, name, ln.strip()[:100]))
    return hits


# ------------------------------------------------------------------ c1
def t32c1(okb_default="formal"):
    h = hk(["--help"])
    has("t32c1 hubkit.py --help", h.stdout, "--edition", "informal", "formal", "edition --hub")
    kit = json.loads(read(os.path.join(KITDIR, "kit.json")))
    eds = kit.get("editions", {})
    check("t32c1 kit.json lists the informal edition's files", bool(eds.get("informal")), eds)
    check("t32c1 the informal HUB-CORE.md is in the kit and differs from the formal one",
          os.path.isfile(ICORE) and read(ICORE) != read(CORE), ICORE)
    with tempfile.TemporaryDirectory(prefix="t32-c1-") as t:
        for ed in ("informal", "formal"):
            hub, p = install(t, ed, ed)
            check(f"t32c1 install --edition {ed} exits 0", p.returncode == 0, (p.returncode, p.stderr))
            check(f"t32c1 install --edition {ed} records it", manifest(hub).get("edition") == ed, manifest(hub))
            want = ICORE if ed == "informal" else CORE
            check(f"t32c1 the {ed} hub has the {ed} HUB-CORE.md", read(os.path.join(hub, "HUB-CORE.md")) == read(want), ed)
        hub, p = install(t, "bogus", "semi")
        check("t32c1 install --edition semi is refused (exit 1)", p.returncode == 1 and not os.path.exists(os.path.join(hub, "HUB-CORE.md")), (p.returncode, p.stderr))
        nob = bin_with(os.path.join(t, "nob"), ["python3", "git"])
        withb = bin_with(os.path.join(t, "withb"), ["python3", "git"], stub_okb=True)
        for name, b, want in (("no orbit-kb on PATH", nob, "informal"), ("orbit-kb on PATH", withb, okb_default)):
            hub = os.path.join(t, "default-" + want + ("-okb" if b == withb else ""))
            os.makedirs(hub)
            p = hk(["install", "--hub", hub], path=b)
            check(f"t32c1 default with {name}: {want}", p.returncode == 0 and manifest(hub).get("edition") == want, (p.stderr, manifest(hub)))
        # an upgrade keeps the edition
        kit2 = os.path.join(t, "kit2")
        for d in ("hub", "editions", "tools"):
            if os.path.isdir(os.path.join(KITDIR, d)):
                shutil.copytree(os.path.join(KITDIR, d), os.path.join(kit2, d))
        k2 = dict(kit, version="9.9.9")
        with open(os.path.join(kit2, "kit.json"), "w") as f:
            json.dump(k2, f)
        for rel in ("hub/HUB-CORE.md", "editions/informal/HUB-CORE.md"):
            p2 = os.path.join(kit2, rel)
            if os.path.isfile(p2):
                with open(p2, "a") as f:
                    f.write("\nA line of release 9.9.9.\n")
        for ed in ("informal", "formal"):
            hub = os.path.join(t, ed)
            p = hk(["upgrade", "--hub", hub, "--kit", kit2, "--yes"])
            m = manifest(hub)
            check(f"t32c1 upgrade of the {ed} hub runs", p.returncode == 0, (p.returncode, p.stderr))
            check(f"t32c1 upgrade keeps the edition {ed}", m.get("edition") == ed and m.get("template_version") == "9.9.9", m)
            src = os.path.join(kit2, "editions", "informal", "HUB-CORE.md") if ed == "informal" else os.path.join(kit2, "hub", "HUB-CORE.md")
            check(f"t32c1 the upgraded {ed} hub has the new {ed} HUB-CORE.md", read(os.path.join(hub, "HUB-CORE.md")) == read(src), ed)
            s = hk(["status", "--hub", hub, "--kit", kit2])
            check(f"t32c1 status of the upgraded {ed} hub names the edition and lists no kit-differs", ed in s.stdout and "kit-differs" not in s.stdout, s.stdout[-300:])
        # a hub switches its edition
        hub = os.path.join(t, "informal")
        p = hk(["edition", "--hub", hub, "--kit", kit2])
        check("t32c1 `edition --hub` prints the edition", p.returncode == 0 and "informal" in p.stdout, (p.returncode, p.stdout, p.stderr))
        p = hk(["edition", "--hub", hub, "--kit", kit2, "formal", "--yes"])
        check("t32c1 `edition formal --yes` switches the hub", p.returncode == 0 and manifest(hub).get("edition") == "formal"
              and read(os.path.join(hub, "HUB-CORE.md")) == read(os.path.join(kit2, "hub", "HUB-CORE.md")), (p.returncode, p.stdout[-200:], p.stderr))
        # a hub made before editions (no edition recorded) upgrades as the formal hub it is
        hub = os.path.join(t, "formal")
        m = manifest(hub)
        m.pop("edition", None)
        m["template_version"] = "0.3.0"
        with open(os.path.join(hub, ".hub-template.json"), "w") as f:
            json.dump(m, f)
        p = hk(["upgrade", "--hub", hub, "--kit", kit2, "--yes"])
        check("t32c1 a hub with no edition recorded upgrades as formal", p.returncode == 0 and manifest(hub).get("edition") == "formal"
              and read(os.path.join(hub, "HUB-CORE.md")) == read(os.path.join(kit2, "hub", "HUB-CORE.md")), (p.returncode, p.stderr))


# ------------------------------------------------------------------ c2
def t32c2():
    with tempfile.TemporaryDirectory(prefix="t32-c2-") as t:
        hub, p = install(t, "informal", "informal")
        check("t32c2 an informal hub installs", p.returncode == 0, p.stderr)
        files = loaded_text(hub)
        check("t32c2 CLAUDE.md imports HUB-CORE.md and PRINCIPLES.md", "HUB-CORE.md" in files and "PRINCIPLES.md" in files, sorted(files))
        for rel, text in files.items():
            check(f"t32c2 {rel} is not empty", bool(text.strip()), rel)
            hits = banned_hits(text)
            check(f"t32c2 informal {rel} names no formal word", not hits, hits[:4])
        allt = "\n".join(files.values())
        for s in INFORMAL:
            check(f"t32c2 the loaded text names the store `{s}`", f"`{s}`" in allt, "missing")
        has("t32c2 the loaded text", allt, "hubflow.py", "hub-flow", "hub-rotate", "outbound-staging", "TECHNOLOGIES.md", "informal")
        core = files.get("HUB-CORE.md", "")
        has("t32c2 the informal HUB-CORE.md says the hub is informal", core, "informal edition")
        fh, p = install(t, "formal", "formal")
        check("t32c2 a formal hub installs", p.returncode == 0, p.stderr)
        kit = json.loads(read(os.path.join(KITDIR, "kit.json")))
        for rel in kit["engine"] + kit["owned"]:
            check(f"t32c2 formal {rel} is the kit's hub/ file", read(os.path.join(fh, rel)) == read(os.path.join(HUB, rel)), rel)
        ff = loaded_text(fh)
        has("t32c2 the formal HUB-CORE.md keeps the formal text", ff.get("HUB-CORE.md", ""), "orbit-kb pin-item", "draft/4", "spec kb",
            "## panes", "## without orbit-kb")
        has("t32c2 the formal hub-flow SKILL.md keeps the formal text", ff.get(os.path.join(".claude", "skills", "hub-flow", "SKILL.md"), ""),
            "draft/4", "spec-triage", "PANES.md")
        has("t32c2 the formal CLAUDE.md keeps the project KB", ff.get("CLAUDE.md", ""), "project kb", "repo-map")
    ins = read(INSTR)
    formal = section(ins, "The formal edition")
    check("t32c2 INSTRUCTIONS.md has a section '## The formal edition'", bool(formal), "missing")
    rest = ins.replace(formal, "") if formal else ins
    hits = banned_hits(rest)
    check("t32c2 INSTRUCTIONS.md outside 'The formal edition' names no formal word", not hits, hits[:5])
    has("t32c2 INSTRUCTIONS.md", ins, "--edition")


# ------------------------------------------------------------------ c3
def block(text):
    if IBEGIN not in text or IEND not in text:
        return ""
    return text[text.index(IBEGIN):text.index(IEND) + len(IEND)]


def t32c3():
    facts = json.loads(read(FACTS) or "{}")
    kinds = {f["name"]: f["owner"] for f in facts.get("facts", [])}
    check("t32c3 store-facts.json has 29 fact kinds", len(kinds) == 29, len(kinds))
    fb, ib = block(read(CORE)), block(read(ICORE))
    check("t32c3 the formal HUB-CORE.md has the informal map", bool(fb), "missing")
    check("t32c3 the informal HUB-CORE.md has the informal map", bool(ib), "missing")
    check("t32c3 the two maps are one table (the same generated text)", fb == ib, "differ")
    check("t32c3 the informal HUB-CORE.md has one informal map and no other fact table",
          read(ICORE).count(IBEGIN) == 1 and "<!-- store-map:begin" not in read(ICORE), "count")
    head, rows = table(ib, "Fact kind")
    check("t32c3 the map is a table (Fact kind | Informal home | How)", head is not None
          and [c.strip() for c in head.strip().strip("|").split("|")] == ["Fact kind", "Informal home", "How"], head)
    rows = rows or []
    got = {r[0].strip("`"): r for r in rows}
    check("t32c3 one row per fact kind of the design", len(rows) == len(got) and set(got) == set(kinds),
          (sorted(set(kinds) - set(got)), sorted(set(got) - set(kinds))))
    for k, owner in kinds.items():
        r = got.get(k)
        if not r or len(r) != 3:
            continue
        home = r[1].strip("`")
        check(f"t32c3 {k}: an informal home or not kept", home in INFORMAL + ("not kept",), home)
        if owner in INFORMAL:
            check(f"t32c3 {k}: owned by {owner}, kept there", home == owner, (home, owner))
        check(f"t32c3 {k}: says how", len(r[2]) > 15, r[2])
    check("t32c3 sop is named as not kept (owned outside the hub)", got.get("sop", ["", ""])[1].strip("`") == "not kept"
          and "outside the hub" in words(got.get("sop", ["", "", ""])[2]), got.get("sop"))
    check("t32c3 sessions stay with bespoke", got.get("sessions", ["", ""])[1].strip("`") == "bespoke", got.get("sessions"))
    hits = banned_hits(ib)
    check("t32c3 the map names no formal word", not hits, hits[:4])
    p = run([sys.executable, "-I", STOREMAP, "--check"])
    check("t32c3 storemap.py --check: both HUB-CORE files are current", p.returncode == 0, p.stderr)
    with tempfile.TemporaryDirectory(prefix="t32-c3-") as t:
        cp = os.path.join(t, "HUB-CORE.md")
        with open(cp, "w") as f:
            f.write(re.sub(r"^\| `sop` .*\n", "", read(ICORE), flags=re.M))
        p = run([sys.executable, "-I", STOREMAP, "--hub-core", cp, "--check"])
        check("t32c3 storemap.py --check fails on a copy with the sop row removed", p.returncode == 1, (p.returncode, p.stderr))


# ------------------------------------------------------------------ c4
def t32c4():
    seed = json.loads(read(os.path.join(HUB, "flow", "seed.json")) or "{}")
    roles = [s.get("role") for s in seed.get("sessions", [])]
    check("t32c4 the seed has a review session", "review" in roles, roles)
    core = read(ICORE)
    sec = section(core, "Verify")
    check("t32c4 the informal HUB-CORE.md has a 'Verify' section", bool(sec), "missing")
    has("t32c4 'Verify'", sec, "review", "did not make", "verdict", "note", "pass", "fail")
    cmds = [ln.strip() for ln in sec.splitlines() if re.search(r"hubflow\.py note ID \"verdict:", ln)]
    check("t32c4 'Verify' gives one verdict command (hubflow.py note ID \"verdict: ...\")", len(cmds) == 1, cmds)
    has("t32c4 the informal hub-flow SKILL.md", read(os.path.join(KITDIR, "editions", "informal", ".claude", "skills", "hub-flow", "SKILL.md")), "verdict")
    if len(cmds) != 1:
        return
    with tempfile.TemporaryDirectory(prefix="t32-c4-") as t:
        hub, p = install(t, "hub", "informal")
        check("t32c4 an informal hub installs", p.returncode == 0, p.stderr)
        p = hubflow(hub, ["init"])
        check("t32c4 hubflow init with the kit's seed", p.returncode == 0, p.stderr)
        p = hubflow(hub, ["add", "thread", "--title", "Build the export", "--ref", "issue:12"], session="build")
        iid = p.stdout.strip().split()[-1] if p.stdout.strip() else ""
        check("t32c4 the build session adds a thread", p.returncode == 0 and iid.startswith("T-"), (p.stdout, p.stderr))
        env = {k: v for k, v in os.environ.items() if k not in ("HUB_SESSION", "HUBFLOW_DB_DIR", "HUBFLOW_HUB")}
        p = run(["bash", "-c", cmds[0].replace("note ID ", f"note {iid} ")], cwd=hub, env=env)
        check("t32c4 the verdict command of HUB-CORE.md runs", p.returncode == 0, (p.returncode, p.stderr))
        p = hubflow(hub, ["show", iid, "--format", "json"])
        try:
            ev = json.loads(p.stdout).get("events", [])
        except ValueError:
            ev = []
        v = [e for e in ev if e.get("verb") == "note" and str(e.get("note", "")).startswith("verdict:")]
        check("t32c4 show lists one verdict note on the item", len(v) == 1, ev)
        check("t32c4 the verdict was recorded by the review session", bool(v) and v[0].get("by_session") == "review", v)
        p = hubflow(hub, ["check"])
        check("t32c4 hubflow check exits 0 after the verdict", p.returncode == 0, p.stderr)


# ------------------------------------------------------------------ c5
P_WANT = (("4. Orbit the intent. Do not translate it", ("orbit", "the request", "each step")),
          ("5. The hypothesis is the closest formal statement of intent", ("hypothesis", "weak", "strong", "show it false")),
          ("8. Speed comes from skipping work, never from hiding it", ("skip", "never hide", "only the human skips", "due")))


def t32c5():
    pr = read(PRINCIPLES)
    heads = {re.sub(r"^#+\s*", "", ln).strip() for ln in read(PHIL).splitlines() if ln.startswith("#")}
    secs = re.split(r"^## ", pr, flags=re.M)[1:]
    for src, phrases in P_WANT:
        check(f"t32c5 docs/PHILOSOPHY.md has '{src}'", src in heads, "missing")
        mine = [s for s in secs if re.search(r'^Source: docs/PHILOSOPHY\.md, "' + re.escape(src) + r'"\s*$', s, re.M)]
        check(f"t32c5 PRINCIPLES.md has a principle that cites '{src}'", len(mine) == 1, len(mine))
        if mine:
            has(f"t32c5 the principle of '{src[:2]}'", mine[0], *phrases)
    hits = banned_hits(pr)
    check("t32c5 PRINCIPLES.md names no formal word", not hits, hits[:4])
    p = run([sys.executable, os.path.join(ROOT, "docs", "check_informal_release.py"), "c3"])
    check("t32c5 check_informal_release.py c3 (short, no KB syntax, sources) passes", p.returncode == 0, p.stdout[-300:])


# ------------------------------------------------------------------ c6
def readme_tools():
    """The tools that hubkit/README.md "## Install" says the hub needs: python3, git, bash and the
    backticked names of the paragraph that says POSIX."""
    inst = section(read(KREADME), "Install")
    paras = [p for p in re.split(r"\n\s*\n", inst) if "POSIX" in p]
    if not paras:
        return inst, None
    return inst, ["python3", "git", "bash"] + re.findall(r"`([a-z0-9]+)`", paras[0])


def t32c6():
    inst, tools = readme_tools()
    check("t32c6 hubkit/README.md has an Install section", bool(inst), "missing")
    has("t32c6 README Install", inst, "Python 3", "git", "bash 4", "POSIX")
    check("t32c6 README Install names the POSIX tools", tools is not None and {"awk", "find", "sort", "comm"} <= set(tools or []), tools)
    has("t32c6 README Install says KIT and HUB may be relative", inst, "relative")
    blocks = re.findall(r"```sh\n(.*?)```", inst, re.S)
    check("t32c6 the Install section has one sh block", len(blocks) == 1, len(blocks))
    if not tools or len(blocks) != 1:
        return
    with tempfile.TemporaryDirectory(prefix="t32-c6-") as t:
        b = bin_with(t, tools)
        missing = [x for x in tools if not os.path.exists(os.path.join(b, x))]
        check("t32c6 every listed tool is on this machine", not missing, missing)
        work = os.path.join(t, "work")
        os.makedirs(work)
        home = os.path.join(t, "home")
        os.makedirs(home)
        env = {"PATH": b, "HOME": home, "TMPDIR": t, "LANG": "C.UTF-8",
               "GIT_AUTHOR_NAME": "Test", "GIT_AUTHOR_EMAIL": "test@example.invalid",
               "GIT_COMMITTER_NAME": "Test", "GIT_COMMITTER_EMAIL": "test@example.invalid",
               "KIT": os.path.relpath(KITDIR, work), "HUB": "myhub"}
        p = run(["bash", "-euo", "pipefail", "-c", blocks[0]], cwd=work, env=env, timeout=900)
        hub = os.path.join(work, "myhub")
        check("t32c6 the block runs with relative KIT and HUB and exactly the listed tools", p.returncode == 0,
              (p.returncode, p.stdout[-300:], p.stderr[-300:]))
        check("t32c6 the hub is at the relative HUB, with its manifest and flow db",
              os.path.isfile(os.path.join(hub, ".hub-template.json")) and os.path.isfile(os.path.join(hub, "flow", "flow.db")), hub)
        last = [ln for ln in p.stdout.splitlines() if re.match(r"\d+ passed, \d+ failed", ln)]
        check("t32c6 the hub's tests say N passed, 0 failed", bool(last) and re.search(r" 0 failed(, \d+ skipped)?$", last[-1]), last)
    p = run([sys.executable, os.path.join(ROOT, "docs", "check_informal_release.py"), "c1"], timeout=1800)
    check("t32c6 check_informal_release.py c1 (T24) passes", p.returncode == 0, p.stdout[-400:])
    m = re.search(r"^c1: PATH tools: (.*)$", p.stdout, re.M)
    check("t32c6 T24 c1 runs with exactly the README's list on PATH", m is not None and sorted(m.group(1).split()) == sorted(tools),
          (m and m.group(1), tools))


# ------------------------------------------------------------------ c7
def t32c7():
    sec = section(read(INSTR), "Step 5")
    check("t32c7 INSTRUCTIONS.md has a step 5", bool(sec), "missing")
    start = re.findall(r'claude --name "([^"]+)"', sec)
    resume = re.findall(r'claude --resume "([^"]+)"', sec)
    check("t32c7 step 5 starts a session with a name", len(start) == 1, start)
    check("t32c7 step 5 gives the command that resumes it by that name", len(resume) == 1 and resume == start, (start, resume))
    check("t32c7 the resume line sets HUB_SESSION and the hub cwd",
          re.search(r'cd "\$HUB" && HUB_SESSION=<name> claude --resume', sec) is not None, sec[:300])
    check("t32c7 step 5 names no launch.sh", "launch.sh" not in sec, "still there")


# ------------------------------------------------------------------ c8
def t32c8():
    with tempfile.TemporaryDirectory(prefix="t32-c8-") as t:
        withb = bin_with(os.path.join(t, "withb"), ["python3", "git"], stub_okb=True)
        for ed in ("formal", "informal"):
            if ed == "formal":  # the default install where orbit-kb is on PATH: no --edition, so a kit before T32 makes it too
                hub = os.path.join(t, ed)
                os.makedirs(hub)
                p = hk(["install", "--hub", hub], path=withb)
                check("t32c8 the default install with orbit-kb on PATH makes a formal hub",
                      p.returncode == 0 and manifest(hub).get("edition", "formal") == "formal", (p.stderr, manifest(hub)))
            else:
                hub, p = install(t, ed, ed)
            check(f"t32c8 a {ed} hub installs", p.returncode == 0, p.stderr)
            p = hubflow(hub, ["init"])
            check(f"t32c8 hubflow init in the {ed} hub", p.returncode == 0, p.stderr)
            env = dict(os.environ, ORBIT_KB_LIB=os.path.join(ROOT, "kb", "share", "orbit-kb"))
            env.pop("ORBIT_KB", None)
            p = run([OKB, "show", "open"], cwd=hub, env=env, timeout=120)
            out = p.stdout + p.stderr
            check(f"t32c8 {ed}: show open with no KB exits 2", p.returncode == 2, p.returncode)
            if ed == "formal":
                check("t32c8 formal: the hint names specs/<slug>/", "specs/<slug>/" in out, out[-300:])
                check("t32c8 formal: the hint names hubflow where SLUG", "hubflow where SLUG" in out, out[-300:])
            else:
                check("t32c8 informal: the hint says this is an informal hub", "informal hub" in out, out[-300:])
                check("t32c8 informal: the hint names the ledger and hubflow.py", "ledger" in out and "hubflow.py" in out, out[-300:])
                check("t32c8 informal: the hint names no spec KB path", "specs/<slug>/" not in out and "hubflow where" not in out, out[-300:])


# ------------------------------------------------------------------ T36
# What an informal hub's engine output must not name (t36c1).
FORMAL_OUT = (("spec KB", re.compile(r"spec kb", re.I)), ("orbit-kb", re.compile(r"orbit-kb", re.I)),
              ("specs/", re.compile(r"specs/")), ("project KB", re.compile(r"project kb", re.I)),
              ("question server", re.compile(r"question server", re.I)),
              ("spec_kbs_untriaged", re.compile(r"spec_kbs_untriaged")),
              ("analyses", re.compile(r"analyses", re.I)))
WEEK = "2026-11-09"  # a Monday


def formal_hits(text):
    return [(n, ln.strip()[:90]) for ln in text.splitlines() for n, rx in FORMAL_OUT if rx.search(ln)]


def t36c1():
    with tempfile.TemporaryDirectory(prefix="t36-c1-") as t:
        outs = {}
        for ed in ("informal", "formal"):
            hub, p = install(t, ed, ed)
            check(f"t36c1 a {ed} hub installs", p.returncode == 0, p.stderr)
            check(f"t36c1 the {ed} hub records its edition", manifest(hub).get("edition") == ed, manifest(hub))
            p = hubflow(hub, ["init"])
            check(f"t36c1 hubflow init in the {ed} hub", p.returncode == 0, p.stderr)
            if ed == "informal":  # T44 c1: an informal hub refuses a kb ref (the t36c1 fixture added one)
                p = hubflow(hub, ["add", "ask", "--title", "Plain ask", "--ref", "kb:some-slug"], session="build")
                check("t36c1 the informal hub refuses an item with a kb ref (exit 1)", p.returncode == 1, (p.returncode, p.stderr))
                hubflow(hub, ["add", "ask", "--title", "Plain ask"], session="build")
            else:
                hubflow(hub, ["add", "ask", "--title", "Plain ask", "--ref", "kb:some-slug"], session="build")
            got = {}
            for name, args in (("--help", ["--help"]), ("rotate", ["rotate", "--week-start", WEEK]),
                               ("where", ["where", "nope"]), ("spec-triage", ["spec-triage", "nope", "keep", "--note", "x"]),
                               ("triage bad", ["triage", "A-0001", "bogus", "--note", "x"]),
                               ("triage kb ref", ["triage", "A-0001", "keep", "--note", "x"]),
                               ("no command", ["frobnicate"])):
                p = hubflow(hub, args, session="build")
                got[name] = p
            outs[ed] = got
        inf, frm = outs["informal"], outs["formal"]
        for name, p in inf.items():
            hits = formal_hits(p.stdout + p.stderr)
            check(f"t36c1 informal `{name}` names no formal word", not hits, hits[:4])
        check("t36c1 informal --help exits 0 and still gives usage", inf["--help"].returncode == 0 and "usage" in inf["--help"].stdout.lower()
              and "rotate" in inf["--help"].stdout and "triage" in inf["--help"].stdout, inf["--help"].stderr)
        check("t36c1 informal rotate runs (exit 0) and lists untriaged", inf["rotate"].returncode == 0 and "untriaged:" in inf["rotate"].stdout,
              (inf["rotate"].returncode, inf["rotate"].stdout, inf["rotate"].stderr))
        check("t36c1 informal where and spec-triage are refused (exit 1)", inf["where"].returncode == 1 and inf["spec-triage"].returncode == 1,
              (inf["where"].returncode, inf["spec-triage"].returncode))
        check("t36c1 informal triage of a bad disposition exits 1", inf["triage bad"].returncode == 1, inf["triage bad"].returncode)
        check("t36c1 the formal agent triage of an item with a kb ref still escalates (fail-safe)",
              "escalate" in frm["triage kb ref"].stdout, (frm["triage kb ref"].stdout, frm["triage kb ref"].stderr))
        # the formal hub keeps the text
        h = frm["--help"].stdout
        for w in ("spec KB", "orbit-kb", "specs/", "project KB", "question server"):
            check(f"t36c1 the formal --help still names {w}", w in h, w)
        check("t36c1 the formal rotate prints spec_kbs_untriaged", "spec_kbs_untriaged" in frm["rotate"].stdout, frm["rotate"].stdout)
        check("t36c1 the formal where error names the spec KB", "spec KB" in frm["where"].stderr, frm["where"].stderr)


def make_old_hub(t):
    """A hub of kit 0.4.0 made at commit 41377fc: {path} or None. The scratch worktree is removed."""
    wt = os.path.join(t, "old-kit")
    p = run(["git", "-C", ROOT, "worktree", "add", "--detach", wt, "41377fc"])
    if p.returncode != 0:
        return None, p.stderr
    try:
        hub = os.path.join(t, "old-hub")
        os.makedirs(hub)
        run(["git", "init", "-q", hub])
        q = run([sys.executable, "-I", os.path.join(wt, "hubkit", "tools", "hubkit.py"), "install", "--hub", hub])
        if q.returncode != 0:
            return None, q.stderr
        return hub, ""
    finally:
        run(["git", "-C", ROOT, "worktree", "remove", "--force", wt])
        run(["git", "-C", ROOT, "worktree", "prune"])


def t36c2():
    with tempfile.TemporaryDirectory(prefix="t36-c2-") as t:
        hub, err = make_old_hub(t)
        check("t36c2 a 0.4.0 hub is made at 41377fc", hub is not None, err)
        if hub is None:
            return
        m = manifest(hub)
        check("t36c2 that hub is 0.4.0 and records no edition", m.get("template_version") == "0.4.0" and "edition" not in m, m)
        bare = bin_with(os.path.join(t, "bare"), ["python3", "git"])
        withb = bin_with(os.path.join(t, "withb"), ["python3", "git"], stub_okb=True)
        check("t36c2 the PATH without orbit-kb has none", shutil.which("orbit-kb", path=bare) is None, bare)
        for name, path, want in (("no orbit-kb", bare, "informal"), ("orbit-kb on PATH", withb, "formal")):
            h = os.path.join(t, "h-" + want)
            shutil.copytree(hub, h)
            plan = hk(["upgrade", "--hub", h], path=path)
            check(f"t36c2 the dry run with {name} exits 0", plan.returncode == 0, plan.stderr)
            if want == "informal":
                ok = (f"({want} edition)" in plan.stdout) or ("hubkit.py edition informal" in plan.stdout)
                check("t36c2 the plan with no orbit-kb says informal or tells how to switch", ok, plan.stdout[:300])
            p = hk(["upgrade", "--hub", h, "--yes"], path=path)
            m = manifest(h)
            check(f"t36c2 the upgrade with {name} exits 0", p.returncode == 0, (p.stdout[-200:], p.stderr))
            plan_says = "hubkit.py edition informal" in plan.stdout
            if want == "informal":
                check("t36c2 the upgrade with no orbit-kb picks informal as install does, or the plan says how", m.get("edition") == "informal" or plan_says, (m.get("edition"), plan.stdout[:300]))
                if m.get("edition") == "informal":
                    check("t36c2 the picked informal hub has the informal HUB-CORE.md", read(os.path.join(h, "HUB-CORE.md")) == read(ICORE), "differs")
            else:
                check("t36c2 the upgrade with orbit-kb on PATH keeps the formal hub", m.get("edition") == "formal", m)
        s = hk(["status", "--hub", os.path.join(t, "h-informal")], path=bare)
        check("t36c2 status of the upgraded hub names its edition", "edition)" in s.stdout, s.stdout[:200])


def t36c3():
    core, rd = read(ICORE), read(KREADME)
    inst = section(rd, "Install")
    paras = [p for p in re.split(r"\n\s*\n", inst) if "POSIX" in p]
    tools = re.findall(r"`([a-z]+)`", paras[0]) if paras else []
    check("t36c3 README Install lists the POSIX tools", len(tools) >= 10, tools)
    check("t36c3 README Install says bash 4 or later", re.search(r"bash 4 or later", inst) is not None, "missing")
    w = words(core)
    check("t36c3 the informal HUB-CORE.md says bash 4 or later", "bash 4 or later" in w, "missing")
    check("t36c3 the informal HUB-CORE.md says Python 3 and git", "python 3" in w and "git" in w, "missing")
    miss = [x for x in tools if f"`{x}`" not in core]
    check("t36c3 the informal HUB-CORE.md names each POSIX tool of the README", not miss, miss)
    check("t36c3 the informal HUB-CORE.md no longer says it needs nothing else", "and nothing else" not in w, "still there")


def t36c4():
    k = json.loads(read(os.path.join(KITDIR, "kit.json")) or "{}")
    # T48 c3: schema 5 ships as the next kit version (0.5.1), so 0.5.0 is no longer the newest release;
    # T36 c4 still holds for the 0.5.0 section: it exists, right above 0.4.0, and the kit is 0.5.0 or later
    ver = tuple(int(x) for x in k.get("version", "0.0.0").split("."))
    check("t36c4 kit.json version is 0.5.0 or later", ver >= (0, 5, 0), k.get("version"))
    up = read(os.path.join(KITDIR, "UPGRADING.md"))
    heads = re.findall(r"^### (\d+\.\d+\.\d+)", up, re.M)
    at = heads.index("0.5.0") if "0.5.0" in heads else -1
    check("t36c4 UPGRADING.md has a 0.5.0 section, newest first", at >= 0 and heads[at:at + 2] == ["0.5.0", "0.4.0"]
          and heads == sorted(heads, key=lambda v: tuple(int(x) for x in v.split(".")), reverse=True), heads[:3])
    sec = section(up, "0.5.0", level="###")
    check("t36c4 the 0.5.0 section is not empty", len(sec) > 200, len(sec))
    has("t36c4 the 0.5.0 section", sec, "T32", "T36", "--edition", "edition informal", "premises", "bash 4")
    sec4 = section(up, "0.4.0", level="###")
    check("t36c4 the 0.4.0 section no longer holds the T32 edition bullet", "A hub knows its edition" not in sec4, "still there")
    check("t36c4 the 0.4.0 section keeps the transcripts bullet", "An agent, not code, puts meeting transcripts" in sec4, "missing")
    has("t36c4 the 0.5.0 section tells a 0.4.0 hub with an older db to migrate", sec, "migrate")


def t36c5():
    pr = read(PRINCIPLES)
    secs = re.split(r"^## ", pr, flags=re.M)[1:]
    mine = [s for s in secs if s.startswith("Skip, never hide")]
    check("t36c5 PRINCIPLES.md has the skip principle", len(mine) == 1, len(mine))
    if mine:
        has("t36c5 the skip principle states what the ledger does", mine[0], "human_skip", "park", "--until", "due", "comes back")
    with tempfile.TemporaryDirectory(prefix="t36-c5-") as t:
        hub, p = install(t, "hub", "informal")
        hubflow(hub, ["init"])

        def hf(args, now, session="build"):
            env = {k: v for k, v in os.environ.items() if k not in ("HUB_SESSION", "HUBFLOW_DB_DIR", "HUBFLOW_HUB")}
            env["HUBFLOW_NOW"] = now
            env["HUB_SESSION"] = session
            return run([sys.executable, "-I", os.path.join(hub, ".claude", "scripts", "hubflow.py")] + args, cwd=hub, env=env)

        p = hf(["add", "ask", "--title", "Skipped for now", "--waits-on", "me", "--ref", "issue:5"], "2026-09-01T00:00:00Z")
        check("t36c5 an ask is added", p.returncode == 0, p.stderr)
        p = hf(["park", "A-0001", "--until", "2026-10-15", "--note", "human: later"], "2026-09-02T00:00:00Z")
        check("t36c5 park --until records the hold", p.returncode == 0, p.stderr)
        p = hf(["rotate", "--week-start", "2026-10-05"], "2026-10-06T00:00:00Z")
        check("t36c5 before the date the item is not due", p.returncode == 0 and "untriaged: none" in p.stdout, (p.stdout, p.stderr))
        p = hf(["rotate", "--week-start", "2026-10-19"], "2026-10-20T00:00:00Z")
        check("t36c5 after the date the item is due again for triage", p.returncode == 1 and "untriaged: A-0001" in p.stdout, (p.returncode, p.stdout, p.stderr))


def t36c6():
    pr = read(PRINCIPLES)
    secs = re.split(r"^## ", pr, flags=re.M)[1:]
    mine = [s for s in secs if "5. The hypothesis is the closest formal statement of intent" in s]
    check("t36c6 PRINCIPLES.md has the hypothesis principle", len(mine) == 1, len(mine))
    if mine:
        body = words(mine[0])
        check("t36c6 the hypothesis principle asks for the premises beside the hypothesis", "premises" in body and "beside" in body, body[:300])
    for name, path in (("informal", ICORE), ("formal", CORE)):
        t = read(path)
        rows = [ln for ln in t.splitlines() if ln.startswith("| `hypothesis` | `ledger`")]
        check(f"t36c6 the {name} HUB-CORE.md has the informal hypothesis row", len(rows) == 1, len(rows))
        if rows:
            check(f"t36c6 the {name} hypothesis row asks for the premises beside it", "premises" in rows[0].lower() and "beside" in rows[0].lower(), rows[0][:200])
    p = run([sys.executable, STOREMAP, "--check"])
    check("t36c6 storemap.py --check: both HUB-CORE files are current", p.returncode == 0, p.stderr)
    has("t36c6 PHILOSOPHY.md section 5 keeps the premises sentence", read(PHIL), "lists its premises beside it")


# ------------------------------------------------------------------ T41
HYP_PARTS = (("the expected result", re.compile(r"\bexpect", re.I)), ("the falsifier", re.compile(r"show (it|the hypothesis) false", re.I)),
             ("the premises", re.compile(r"\bpremises\b", re.I)))


def hyp_parts(name, text):
    for part, rx in HYP_PARTS:
        check(f"{name} names {part}", rx.search(words(text)) is not None, text[:300])


def t41c1():
    pr = read(PRINCIPLES)
    secs = re.split(r"^## ", pr, flags=re.M)[1:]
    mine = [s for s in secs if "5. The hypothesis is the closest formal statement of intent" in s]
    check("t41c1 PRINCIPLES.md has the hypothesis principle", len(mine) == 1, len(mine))
    if mine:
        hyp_parts("t41c1 the hypothesis principle", mine[0])
        has("t41c1 the hypothesis principle", mine[0], "assume little", "which result you expect", "beside")
    for name, path in (("informal", ICORE), ("formal", CORE)):
        rows = [ln for ln in read(path).splitlines() if ln.startswith("| `hypothesis` | `ledger`")]
        check(f"t41c1 the {name} HUB-CORE.md has the informal hypothesis row", len(rows) == 1, len(rows))
        if rows:
            hyp_parts(f"t41c1 the {name} HUB-CORE.md hypothesis row", rows[0])
    src = [ln for ln in read(STOREMAP).splitlines() if ln.strip().startswith('"hypothesis":')]
    check("t41c1 storemap.py has one hypothesis row", len(src) == 1, len(src))
    if src:
        hyp_parts("t41c1 the storemap.py hypothesis row", src[0])
    p = run([sys.executable, STOREMAP, "--check"])
    check("t41c1 storemap.py --check: both HUB-CORE files are current", p.returncode == 0, p.stderr)


def ref_kinds(helptext):
    m = re.search(r"ref ID add\|rm KIND:REF\s+KIND:(.*?)\n  link ", helptext, re.S)
    return m.group(1).split() if m else None


def t41c2():
    with tempfile.TemporaryDirectory(prefix="t41-c2-") as t:
        res = {}
        for ed in ("informal", "formal"):
            hub, p = install(t, ed, ed)
            check(f"t41c2 a {ed} hub installs", p.returncode == 0, p.stderr)
            hubflow(hub, ["init"])
            p = hubflow(hub, ["add", "ask", "--title", "Plain ask", "--waits-on", "me", "--ref", "issue:1"], session="build")
            check(f"t41c2 a plain ask is added in the {ed} hub", p.returncode == 0, p.stderr)
            r = {"help": hubflow(hub, ["--help"]).stdout}
            r["ref kb"] = hubflow(hub, ["ref", "A-0001", "add", "kb:some-slug"], session="build")
            r["show"] = hubflow(hub, ["show", "A-0001"], session="build").stdout
            r["add analysis"] = hubflow(hub, ["add", "ask", "--title", "With analysis", "--waits-on", "me", "--ref", "issue:2",
                                              "--analysis", "some-slug"], session="build")
            r["handoff analysis"] = hubflow(hub, ["handoff", "--to", "review", "--title", "Hand over", "--analysis", "some-slug"], session="build")
            r["set analysis"] = hubflow(hub, ["set", "A-0001", "--analysis", "some-slug"], session="build")
            res[ed] = r
        inf, frm = res["informal"], res["formal"]
        h = inf["help"]
        check("t41c2 the informal --help has a ref kind list", ref_kinds(h) is not None, h[-400:])
        check("t41c2 the informal --help lists no kb ref kind", "kb" not in (ref_kinds(h) or ["kb"]), ref_kinds(h))
        check("t41c2 the informal --help names no kb ref of a capsule", "kb and file" not in words(h), "still there")
        check("t41c2 the informal --help shows no --analysis", "--analysis" not in h, "still there")
        check("t41c2 the informal --help shows no analysis column", re.search(r"\banalysis\b", h) is None,
              [ln for ln in h.splitlines() if "analysis" in ln][:3])
        for name in ("ref kb", "add analysis", "handoff analysis", "set analysis"):
            p = inf[name]
            check(f"t41c2 informal `{name}` is refused (exit 1)", p.returncode == 1, (p.returncode, p.stdout, p.stderr))
            check(f"t41c2 informal `{name}` says it belongs to the formal edition", "formal edition" in p.stderr, p.stderr)
            check(f"t41c2 informal `{name}` names no formal word", not formal_hits(p.stdout + p.stderr), formal_hits(p.stdout + p.stderr))
        check("t41c2 the refused kb ref is not on the informal item", "kb:some-slug" not in inf["show"], inf["show"])
        # the formal hub is unchanged
        f = frm["help"]
        check("t41c2 the formal --help lists the kb ref kind", "kb" in (ref_kinds(f) or []), ref_kinds(f))
        check("t41c2 the formal --help shows --analysis and the analysis column", "--analysis SLUG" in f and "analysis (a slug" in f, "missing")
        check("t41c2 the formal --help names the kb ref of a capsule", "kb and file" in words(f), "missing")
        for name in ("ref kb", "add analysis", "handoff analysis", "set analysis"):
            p = frm[name]
            check(f"t41c2 formal `{name}` still works (exit 0)", p.returncode == 0, (p.returncode, p.stderr))
        check("t41c2 the formal item keeps its kb ref", "kb:some-slug" in frm["show"], frm["show"])


def t41c3():
    with tempfile.TemporaryDirectory(prefix="t41-c3-") as t:
        mono = os.path.join(t, "mono")
        os.makedirs(mono)
        run(["git", "init", "-q", mono])
        hub = os.path.join(mono, "hub")
        os.makedirs(hub)
        p = hk(["install", "--hub", hub, "--edition", "informal"])
        check("t41c3 an informal hub installs at mono/hub", p.returncode == 0 and manifest(hub).get("edition") == "informal", (p.stderr, manifest(hub)))
        env = {k: v for k, v in os.environ.items() if k not in ("HUB_SESSION", "HUBFLOW_DB_DIR", "HUBFLOW_HUB")}
        flow = os.path.join(hub, ".claude", "scripts", "hubflow.py")

        def hf(cwd, args):
            return run([sys.executable, "-I", flow] + args, cwd=cwd, env=env)

        top = run(["git", "rev-parse", "--show-toplevel"], cwd=hub).stdout.strip()
        check("t41c3 the git toplevel of mono/hub is mono", os.path.realpath(top) == os.path.realpath(mono), top)
        h = hf(hub, ["--help"])
        check("t41c3 --help from mono/hub exits 0", h.returncode == 0, h.stderr)
        check("t41c3 --help from mono/hub is the informal help", not formal_hits(h.stdout), formal_hits(h.stdout)[:4])
        sub = os.path.join(hub, "W0")
        os.makedirs(sub, exist_ok=True)
        h = hf(sub, ["--help"])
        check("t41c3 --help from mono/hub/W0 is the informal help", h.returncode == 0 and not formal_hits(h.stdout), formal_hits(h.stdout)[:4])
        p = hf(hub, ["init"])
        check("t41c3 init from mono/hub exits 0", p.returncode == 0, p.stderr)
        check("t41c3 init from mono/hub makes mono/hub/flow/flow.db", os.path.isfile(os.path.join(hub, "flow", "flow.db")), os.listdir(hub))
        check("t41c3 init from mono/hub makes no mono/flow", not os.path.exists(os.path.join(mono, "flow")), os.listdir(mono))
        # no manifest on the way up: the git toplevel, as before
        other = os.path.join(mono, "other")
        os.makedirs(other)
        h = hf(other, ["--help"])
        check("t41c3 --help from mono/other (no manifest above) falls back to mono: the formal help", "spec KB" in h.stdout, h.stdout[-300:])
        # --hub and HUBFLOW_HUB still win
        h = run([sys.executable, "-I", flow, "--hub", mono, "--help"], cwd=hub, env=env)
        check("t41c3 --hub mono from mono/hub gives the formal help", "spec KB" in h.stdout, h.stdout[-300:])
        h = run([sys.executable, "-I", flow, "--help"], cwd=hub, env={**env, "HUBFLOW_HUB": mono})
        check("t41c3 HUBFLOW_HUB=mono from mono/hub gives the formal help", "spec KB" in h.stdout, h.stdout[-300:])


def t41c4():
    pr = read(PRINCIPLES)
    secs = re.split(r"^## ", pr, flags=re.M)[1:]
    mine = [s for s in secs if s.startswith("Skip, never hide")]
    check("t41c4 PRINCIPLES.md has the skip principle", len(mine) == 1, len(mine))
    if mine:
        w = words(mine[0])
        check("t41c4 the skip principle says an agent may park", re.search(r"an agent (can|may)( still)? park", w) is not None, w[:400])
        check("t41c4 the skip principle says only an item that is not escalated", "not escalated" in w or "non-escalated" in w, w[:400])
        check("t41c4 the skip principle says the park event names the agent", re.search(r"park event names the agent", w) is not None, w[:400])
        check("t41c4 the skip principle calls it a known limit", "known limit" in w, w[:400])
    with tempfile.TemporaryDirectory(prefix="t41-c4-") as t:
        hub, p = install(t, "hub", "informal")
        hubflow(hub, ["init"])
        p = hubflow(hub, ["add", "ask", "--title", "Park me", "--waits-on", "me", "--ref", "issue:5"], session="build")
        check("t41c4 an ask is added", p.returncode == 0, p.stderr)
        p = hubflow(hub, ["park", "A-0001", "--until", "2026-12-01"], session="build")
        check("t41c4 an agent parks a non-escalated item (exit 0)", p.returncode == 0, p.stderr)
        s = hubflow(hub, ["show", "A-0001"], session="build").stdout
        ev = [ln for ln in s.splitlines() if "| parked |" in ln]
        check("t41c4 the park event names the agent session and says agent", len(ev) == 1 and "| build | agent |" in ev[0], ev or s[-300:])


def t41c5():
    # The formal "What lives where" row comes from fact_desc(hypothesis) in the hub design KB,
    # through store-facts.json (storemap.py --export); check_hub_guidance c1 keeps them equal.
    rows = [ln for ln in read(CORE).splitlines() if ln.startswith("| `hypothesis` | ") and "| `spec` |" in ln]
    check("t41c5 the formal HUB-CORE.md has the What lives where hypothesis row", len(rows) == 1, len(rows))
    if rows:
        hyp_parts("t41c5 the formal What lives where hypothesis row", rows[0])
    p = run([sys.executable, STOREMAP, "--check"])
    check("t41c5 storemap.py --check: both HUB-CORE files are current", p.returncode == 0, p.stderr)


def t44c1():
    with tempfile.TemporaryDirectory(prefix="t44-c1-") as t:
        res = {}
        for ed in ("informal", "formal"):
            hub, p = install(t, ed, ed)
            check(f"t44c1 a {ed} hub installs", p.returncode == 0, p.stderr)
            hubflow(hub, ["init"])
            r = {"add kb": hubflow(hub, ["add", "ask", "--title", "Kb ask", "--ref", "kb:some-slug"], session="build"),
                 "handoff kb": hubflow(hub, ["handoff", "--to", "review", "--title", "Hand over", "--ref", "kb:some-slug"], session="build"),
                 "ref kb": None}
            r["after refused"] = hubflow(hub, ["add", "ask", "--title", "Plain ask", "--ref", "issue:1"], session="build")
            r["ref kb"] = hubflow(hub, ["ref", "A-0001", "add", "kb:some-slug"], session="build")
            r["list"] = hubflow(hub, ["sql", "SELECT id, kind FROM item ORDER BY id"], session="build")
            r["show"] = hubflow(hub, ["show", "A-0001"], session="build")
            r["help"] = hubflow(hub, ["--help"]).stdout
            r["show json"] = hubflow(hub, ["show", "A-0001", "--format", "json"], session="build")
            r["view"] = hubflow(hub, ["view", "open", "--format", "tsv"], session="build")
            for nm, row in (("kb", {"kind": "ask", "title": "Imported kb", "refs": ["kb:some-slug"]}),
                            ("analysis", {"kind": "ask", "title": "Imported analysis", "analysis": "some-slug"}),
                            ("plain", {"kind": "ask", "title": "Imported plain", "refs": ["issue:9"]})):
                f = os.path.join(t, f"imp-{ed}-{nm}.jsonl")
                with open(f, "w") as fh:
                    fh.write(json.dumps(row) + "\n")
                r["import " + nm + " dry"] = hubflow(hub, ["import", f], session="build")
                r["import " + nm] = hubflow(hub, ["import", f, "--yes"], session="build")
            r["items after import"] = hubflow(hub, ["sql", "SELECT title FROM item ORDER BY id"], session="build")
            res[ed] = r
        inf, frm = res["informal"], res["formal"]
        for nm in ("kb", "analysis"):
            for how in (" dry", ""):
                p = inf["import " + nm + how]
                check(f"t44c1 informal import of a {nm} row{' (dry run)' if how else ' --yes'} exits 1 and names the formal edition",
                      p.returncode == 1 and "formal edition" in p.stdout + p.stderr, (p.returncode, p.stdout[-200:], p.stderr))
            check(f"t44c1 informal import of a {nm} row made no item", f"Imported {nm}" not in inf["items after import"].stdout,
                  inf["items after import"].stdout)
        check("t44c1 informal import of a plain row works", inf["import plain"].returncode == 0 and "Imported plain" in inf["items after import"].stdout,
              (inf["import plain"].returncode, inf["import plain"].stderr))
        try:
            ij = json.loads(inf["show json"].stdout)
        except ValueError:
            ij = {"item": {"analysis": "unparsed"}}
        check("t44c1 informal `show --format json` has no analysis key", "analysis" not in ij["item"], list(ij["item"]))
        check("t44c1 informal `view open` has no analysis column", "analysis" not in inf["view"].stdout.splitlines()[0].split("\t"),
              inf["view"].stdout[:200])
        for nm in ("kb", "analysis"):
            check(f"t44c1 formal import of a {nm} row still works", frm["import " + nm].returncode == 0 and f"Imported {nm}" in frm["items after import"].stdout,
                  (frm["import " + nm].returncode, frm["import " + nm].stderr))
        check("t44c1 formal `show --format json` keeps the analysis key", "analysis" in json.loads(frm["show json"].stdout)["item"], "missing")
        check("t44c1 formal `view open` keeps the analysis column", "analysis" in frm["view"].stdout.splitlines()[0].split("\t"), frm["view"].stdout[:200])
        p = inf["add kb"]
        check("t44c1 informal `add ask --ref kb:X` exits 1", p.returncode == 1, (p.returncode, p.stdout, p.stderr))
        check("t44c1 informal `add ask --ref kb:X` names the formal edition", "formal edition" in p.stderr, p.stderr)
        p = inf["handoff kb"]
        check("t44c1 informal `handoff --ref kb:X` exits 1", p.returncode == 1, (p.returncode, p.stdout, p.stderr))
        check("t44c1 the refused add made no item: the next item is A-0001", inf["after refused"].stdout.strip() == "A-0001",
              (inf["after refused"].stdout, inf["after refused"].stderr))
        check("t44c1 the informal ledger holds only that one item", "A-0001" in inf["list"].stdout and "H-" not in inf["list"].stdout
              and inf["list"].stdout.count("A-") == 1, inf["list"].stdout)
        check("t44c1 informal `ref ID add kb:X` is still refused", inf["ref kb"].returncode == 1, inf["ref kb"].returncode)
        check("t44c1 informal `show` has an item and no analysis line", inf["show"].returncode == 0 and "title: Plain ask" in inf["show"].stdout
              and not re.search(r"^analysis:", inf["show"].stdout, re.M), inf["show"].stdout[:300])
        h = inf["help"]
        check("t44c1 the informal --help has no \"kb ref\"", "kb ref" not in words(h), [ln for ln in h.splitlines() if "kb ref" in words(ln)])
        # the formal hub is unchanged
        check("t44c1 formal `add ask --ref kb:X` exits 0", frm["add kb"].returncode == 0, (frm["add kb"].returncode, frm["add kb"].stderr))
        check("t44c1 formal `handoff --ref kb:X` exits 0", frm["handoff kb"].returncode == 0, (frm["handoff kb"].returncode, frm["handoff kb"].stderr))
        check("t44c1 formal `show` keeps the analysis line", re.search(r"^analysis:", frm["show"].stdout, re.M) is not None, frm["show"].stdout[:300])
        check("t44c1 the formal --help still has the kb ref line", "ref rm the kb ref of an item that is escalated" in words(frm["help"]), "missing")


def informal_hyp_row(path):
    """The informal hypothesis row of a storemap.py: its INFORMAL[\"hypothesis\"] text."""
    import importlib.util
    spec = importlib.util.spec_from_file_location("storemap_t44", path)
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m.INFORMAL["hypothesis"][1]


def hyp_missing(text):
    return [part for part, rx in HYP_PARTS if rx.search(words(text)) is None]


def t44c2():
    path = os.environ.get("T44_STOREMAP") or STOREMAP
    row = informal_hyp_row(path)
    miss = hyp_missing(row)
    check("t44c2 the informal hypothesis row of storemap.py names the expected result, the falsifier and the premises", not miss,
          (miss, row[:300]))
    # the check can fail: each part, cut from a copy of the real row, is found missing
    base = informal_hyp_row(STOREMAP)
    for part, cut in (("the expected result", (r"the result expected", "")), ("the falsifier", (r"the result that would show it false", "")),
                      ("the premises", (r"its premises beside it, ", ""))):
        mutant = re.sub(cut[0], cut[1], base)
        check(f"t44c2 a copy of the row without {part} is rejected", mutant != base and hyp_missing(mutant) == [part], (part, hyp_missing(mutant)))


# ------------------------------------------------------------------ install UX (discovery GO 2026-11-11)
def iuxc3e():
    t32c1(okb_default="informal")


def iuxc4():
    kit = json.loads(read(os.path.join(KITDIR, "kit.json")) or "{}")
    sh = [f for f in kit.get("engine", []) if f.endswith(".sh") or read(os.path.join(HUB, f)).startswith("#!/usr/bin/env bash")
          or read(os.path.join(HUB, f)).startswith("#!/bin/")]
    check("iuxc4 kit.json lists no shell engine file", not sh, sh)
    sh_files = [os.path.relpath(os.path.join(b, f), KITDIR) for b, _, fs in os.walk(KITDIR) for f in fs if f.endswith(".sh")]
    check("iuxc4 the kit holds no .sh file", not sh_files, sh_files)
    rd = read(KREADME)
    inst = section(rd, "Install")
    w = words(inst)
    check("iuxc4 README Install says Python 3 and git", "python 3" in w and "git" in w, inst[:200])
    check("iuxc4 README Install says it needs no bash", "no bash" in w, inst[:300])
    check("iuxc4 README Install has no POSIX tool list", "posix" not in w and "`awk`" not in inst, inst[:300])
    core = read(ICORE)
    wc = words(core)
    check("iuxc4 the informal HUB-CORE.md says Python 3 and git", "python 3" in wc and "git" in wc, "missing")
    check("iuxc4 the informal HUB-CORE.md needs no bash and no POSIX tool list", "bash 4" not in wc and "`awk`" not in core, "still there")
    blocks = re.findall(r"```sh\n(.*?)```", inst, re.S)
    check("iuxc4 the Install section has one sh block", len(blocks) == 1, len(blocks))
    if len(blocks) != 1:
        return
    lines = [ln for ln in blocks[0].splitlines() if ln.strip()]
    shellish = [ln for ln in lines if not re.match(r"^(python3|git) ", ln) or re.search(r"\$\(|&&|\|\||[|;<>`]|\bcd\b", ln)]
    check("iuxc4 each line of the block is one python3 or git command, with no shell syntax", not shellish, shellish)
    if shellish:
        return
    with tempfile.TemporaryDirectory(prefix="iux-c4-") as t:
        b = bin_with(t, ["python3", "git"])
        work = os.path.join(t, "work")
        os.makedirs(work)
        home = os.path.join(t, "home")
        os.makedirs(home)
        env = {"PATH": b, "HOME": home, "TMPDIR": t, "LANG": "C.UTF-8",
               "GIT_AUTHOR_NAME": "Test", "GIT_AUTHOR_EMAIL": "test@example.invalid",
               "GIT_COMMITTER_NAME": "Test", "GIT_COMMITTER_EMAIL": "test@example.invalid"}
        sub = {"KIT": os.path.relpath(KITDIR, work), "HUB": "myhub"}
        outs = []
        for ln in lines:
            argv = [re.sub(r"\$\{?(KIT|HUB)\}?", lambda m: sub[m.group(1)], a) for a in shlex.split(ln)]
            argv[0] = os.path.join(b, argv[0])
            p = run(argv, cwd=work, env=env, timeout=600)
            outs.append((ln, p.returncode, p.stdout[-200:], p.stderr[-200:]))
            if p.returncode != 0:
                break
        check("iuxc4 every line of the block runs with no shell, relative KIT and HUB, and only python3 and git on PATH",
              outs and all(o[1] == 0 for o in outs) and len(outs) == len(lines), outs[-1:] if outs else "no lines")
        hub = os.path.join(work, "myhub")
        check("iuxc4 the hub is at the relative HUB, with its manifest and flow db",
              os.path.isfile(os.path.join(hub, ".hub-template.json")) and os.path.isfile(os.path.join(hub, "flow", "flow.db")), hub)
    p = run([sys.executable, os.path.join(ROOT, "docs", "check_informal_release.py"), "c1"], timeout=1800)
    check("iuxc4 check_informal_release.py c1 (T24) passes", p.returncode == 0, p.stdout[-400:])


# t32c1 is superseded by iuxc3e (install UX c3: with no --edition, install no longer reads the PATH), and t32c6 and
# t36c3 by iuxc4 (install UX c4: the kit needs no bash and no POSIX tools). The functions stay above as the record.
CLAIMS = {k: globals()[k] for k in ("t32c2", "t32c3", "t32c4", "t32c5", "t32c7", "t32c8",
                                      "t36c1", "t36c2", "t36c4", "t36c5", "t36c6", "iuxc3e", "iuxc4",
                                      "t41c1", "t41c2", "t41c3", "t41c4", "t41c5", "t44c1", "t44c2")}

if __name__ == "__main__":
    a = sys.argv[1:]
    if a == ["--list"]:
        print("\n".join(CLAIMS))
        sys.exit(0)
    if not a or a[0] not in CLAIMS:
        print(__doc__)
        sys.exit(2)
    try:
        CLAIMS[a[0]]()
    except Exception as e:  # a check that cannot run is a failure, not a crash
        check(f"{a[0]} ran", False, repr(e))
    for f in failures:
        print("FAIL " + f)
    print(f"{count} checks, {len(failures)} failed")
    sys.exit(1 if failures else 0)
