#!/usr/bin/env python3
"""The MindHole Kit as a release: one kind of hub, with the tool. One check per claim.

usage: python3 docs/check_kit_release.py c1|c2|c3|c4|c5|c6   (--list prints the ids)
Exit 0: the claim's check passes. Exit 1: it fails (each failure is printed). Prints `N checks`.

This file was check_informal_release.py (T24). scientific-method-overhaul c22 (retire; Ty, 2026-11-23)
dropped the release for a hub with no tool: c1 and c2 are rewritten for it, c3 to c6 are as they were.

c1 runs the install of hubkit/README.md (its "## Install" sh block) in a scratch dir, with a PATH
   of python3, git, bash and swipl (a dir of links), then runs the hub's own tests in the new hub
   with that PATH.
c2 (c22) the kit names no release and no edition for a hub with no tool: no file under hubkit/ holds
   the two phrases that the spec check greps for, hubkit/editions is gone, kit.json has no editions,
   HUB-CORE.md has no "Without orbit-kb" section and no second store map, README.md has no line on
   it; hubkit.py refuses to install that edition and to upgrade a hub that kit v0.7.2 (0.11.2) made
   with it, and `edition formal` moves such a hub; a hub that kit 0.11.2 made with the tool
   upgrades; UPGRADING.md has the 0.12.0 section. The fail-safe stays: hubflow-test.py --case
   case_t24_no_orbit_kb passes.
c3 (0.3.0 M-C) reads hubkit/hub/PRINCIPLES.md: a short file (70 lines or fewer outside the vocabulary block; 60 before 0.8.0) that comes from the
   prompt. It names the version on the last line of prompt/SAGITTARIUS.md ("Sagittarius X.Y.Z"), each
   part (## heading) has a line From the prompt: "Section" that names a section of the prompt, and it
   cites no section of docs/PHILOSOPHY.md. hubkit/README.md and INSTRUCTIONS.md say that it comes from
   the prompt, not that it states the philosophy.
c4 also upgrades a hub made from the 0.3.0 kit (git archive 4d0c5bc) to this kit, and runs the
   UPGRADING.md command that keeps the hub's own sessions/launch.sh.
"""
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KITDIR = os.path.join(ROOT, "hubkit")
HUB = os.path.join(KITDIR, "hub")
CORE = os.path.join(HUB, "HUB-CORE.md")
README = os.path.join(ROOT, "README.md")
KREADME = os.path.join(KITDIR, "README.md")
INSTR = os.path.join(KITDIR, "INSTRUCTIONS.md")
UPGRADING = os.path.join(KITDIR, "UPGRADING.md")
KIT = os.path.join(KITDIR, "kit.json")
T24_VERSION = "0.4.0"  # the kit version of the informal release (T24); later releases have their own sections
FACTS = os.path.join(KITDIR, "tools", "store-facts.json")
FLOWTEST = os.path.join(HUB, ".claude", "scripts", "hubflow-test.py")
PRINCIPLES = os.path.join(HUB, "PRINCIPLES.md")
PROMPT = os.path.join(ROOT, "prompt", "SAGITTARIUS.md")
CHANGELOG = os.path.join(ROOT, "CHANGELOG.md")
REPO_URL = "https://github.com/theTyster/sagittarius"
OLD_KIT_COMMIT = "4d0c5bc"  # the redesign branch with hub kit 0.3.0 (T22), before T24
PHRASES = ("informal " + "release", "informal " + "edition")  # what checks/informal_release.sh of the spec greps for
OLD_TAG = "v0.7.2"  # Sagittarius 0.7.2 holds MindHole Kit 0.11.2, the last kit with two editions
HUBKIT = os.path.join(KITDIR, "tools", "hubkit.py")

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


def lacks(name, text, *phrases):
    t = words(text)
    for ph in phrases:
        check(f"{name}: lacks '{ph}'", ph.lower() not in t, "still there")


def section(text, heading, level="##"):
    """The body of the first heading that starts with `heading`, up to the next heading of that level."""
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
            return rows
    return None


def paragraphs(text):
    return [p for p in re.split(r"\n\s*\n", text) if p.strip()]


def run(cmd, **kw):
    return subprocess.run(cmd, capture_output=True, text=True, **kw)


def readme_bin(where, inst):
    """A dir of links to the tools that the README's Install section names: python3, git, swipl; and bash, to run the block."""
    tools = ["python3", "git", "bash", "swipl"]
    b = os.path.join(where, "bin")
    os.makedirs(b)
    for t in tools:
        p = shutil.which(t)
        if p:
            os.symlink(p, os.path.join(b, t))
    print("c1: PATH tools: " + " ".join(tools))
    return b


def bare_env(where, path):
    home = os.path.join(where, "home")
    os.makedirs(home, exist_ok=True)
    tmp = os.path.join(where, "tmp")
    os.makedirs(tmp, exist_ok=True)
    return {"PATH": path, "HOME": home, "TMPDIR": tmp, "LANG": "C.UTF-8",
            "GIT_AUTHOR_NAME": "Test", "GIT_AUTHOR_EMAIL": "test@example.invalid",
            "GIT_COMMITTER_NAME": "Test", "GIT_COMMITTER_EMAIL": "test@example.invalid"}


def last_counts(out):
    last = (out.strip().splitlines() or [""])[-1]
    m = re.match(r"(\d+) passed, (\d+) failed", last)
    return (int(m.group(1)), int(m.group(2))) if m else None


# ------------------------------------------------------------------ c1
def c1():
    rd = read(README)
    lines = [ln for ln in rd.splitlines() if "informal" in ln.lower()]
    check("c1 README.md has no line on a release with no tool (c22)", not lines, lines)
    intro = rd[:rd.find("## Use it")] if "## Use it" in rd else ""
    has("c1 README.md intro stays for the formal-methods audience", intro, "knowledge base", "lean proof")
    has("c1 README.md 'Use it' keeps the formal install", section(rd, "Use it"), "SWI-Prolog", "./install.py")
    kr = read(KREADME)
    inst = section(kr, "Install")
    check("c1 hubkit/README.md has an Install section", bool(inst), "missing")
    has("c1 hubkit/README.md Install", inst, "Python 3", "git", "SWI-Prolog 9", "no bash")
    lacks("c1 hubkit/README.md Install", inst, "--edition", "no prolog")
    blocks = re.findall(r"```sh\n(.*?)```", inst, re.S)
    check("c1 the Install section has one sh block", len(blocks) == 1, len(blocks))
    if len(blocks) != 1:
        return
    with tempfile.TemporaryDirectory(prefix="t24-c1-") as t:
        b = readme_bin(t, inst)
        check("c1 python3, git and swipl are on the scratch PATH", all(shutil.which(x, path=b) for x in ("python3", "git", "swipl")), b)
        env = bare_env(t, b)
        hub = os.path.join(t, "hub")
        env.update({"KIT": KITDIR, "HUB": hub})
        p = run(["bash", "-euo", "pipefail", "-c", blocks[0]], cwd=t, env=env, timeout=600)
        check("c1 the install block runs", p.returncode == 0, (p.returncode, p.stdout[-300:], p.stderr[-300:]))
        check("c1 the hub has its manifest", os.path.isfile(os.path.join(hub, ".hub-template.json")), hub)
        check("c1 the hub has its flow db", os.path.isfile(os.path.join(hub, "flow", "flow.db")), hub)
        check("c1 the hub has its own orbit-kb and orbit", all(os.access(os.path.join(hub, ".claude", "orbit-kb", "bin", x), os.X_OK) for x in ("orbit-kb", "orbit")), hub)
        p = run([shutil.which("python3", path=b), os.path.join(".claude", "scripts", "hubflow-test.py")], cwd=hub, env=env, timeout=900)
        n = last_counts(p.stdout)
        check("c1 the hub's own tests pass there (N passed, 0 failed)", p.returncode == 0 and n and n[1] == 0 and n[0] >= 100,
              (n, [x for x in p.stdout.splitlines() if x.startswith("FAIL")][:5], p.stderr[-300:]))
        skipped = [x for x in p.stdout.splitlines() if x.startswith("SKIP")]
        print(f"c1: the hub's tests: {n}; skipped there: {skipped}")
        p = run([shutil.which("python3", path=b), os.path.join(".claude", "scripts", "hubflow.py"), "check"], cwd=hub, env=env)
        check("c1 hubflow.py check exits 0 in the new hub", p.returncode == 0, (p.returncode, p.stderr[-300:]))


# ------------------------------------------------------------------ c2
def manifest(hub):
    try:
        return json.loads(read(os.path.join(hub, ".hub-template.json")))
    except ValueError:
        return {}


def hk(script, *args):
    return run([sys.executable, "-I", script] + list(args))


def c2():
    hits = []
    for b, dirs, files in os.walk(KITDIR):
        dirs[:] = [d for d in dirs if d not in ("__pycache__", "node_modules")]
        for f in files:
            t = read(os.path.join(b, f)).lower()
            hits += [(os.path.relpath(os.path.join(b, f), ROOT), ph) for ph in PHRASES if ph in t]
    check("c2 no file under hubkit/ names a release or an edition with no tool", not hits, hits[:8])
    check("c2 hubkit/editions is gone", not os.path.exists(os.path.join(KITDIR, "editions")), "still there")
    kit = json.loads(read(KIT) or "{}")
    check("c2 kit.json has no editions", "editions" not in kit, sorted(kit))
    core = read(CORE)
    check("c2 HUB-CORE.md has no 'Without orbit-kb' section", not section(core, "Without orbit-kb"), "still there")
    check("c2 HUB-CORE.md has no second store map", "informal-map" not in core and "Informal home" not in core, "still there")
    check("c2 HUB-CORE.md keeps What lives where", bool(section(core, "What lives where")), "missing")
    sm = read(os.path.join(KITDIR, "tools", "storemap.py"))
    check("c2 storemap.py makes no second map", "informal" not in sm.lower(), "still there")
    s = run([sys.executable, "-I", os.path.join(KITDIR, "tools", "storemap.py"), "--check"])
    check("c2 the generated map of HUB-CORE.md is current (storemap.py --check)", s.returncode == 0, s.stderr)
    check("c2 README.md has no line on it", "informal" not in read(README).lower(), "still there")
    up = section(read(UPGRADING), "0.12.0", level="###")
    has("c2 UPGRADING.md 0.12.0", up, "Ty, 2026-11-23", "a hub needs the tool", "SWI-Prolog 9", "edition --hub", "formal", "refuses", "fail-safe")
    # the fail-safe for a tool that cannot be asked stays
    p = run([sys.executable, "-I", FLOWTEST, "--case", "case_t24_no_orbit_kb"])
    n = last_counts(p.stdout)
    check("c2 the fail-safe stays: hubflow-test --case case_t24_no_orbit_kb passes (>= 11 checks)", p.returncode == 0 and n and n[1] == 0 and n[0] >= 11,
          (n, [x for x in p.stdout.splitlines() if x.startswith("FAIL")][:5]))
    # hubs that the last kit with two editions made (git archive of OLD_TAG), against this kit
    if run(["git", "-C", ROOT, "rev-parse", "-q", "--verify", OLD_TAG + "^{commit}"]).returncode != 0:
        print(f"c2: note: this tree is no git checkout with the tag {OLD_TAG}; the hubs of the old kit are not tried (hubkit-test.py case_c22_one_kind_of_hub tries the rule on a made-up hub)")
        return
    with tempfile.TemporaryDirectory(prefix="c22-") as t:
        old = os.path.join(t, "old")
        os.makedirs(old)
        a = subprocess.run(f"git -C '{ROOT}' archive {OLD_TAG} hubkit kb prompt modules.py MODULES.json VERSION | tar -x -C '{old}'",
                           shell=True, capture_output=True, text=True)
        check(f"c2 the kit of {OLD_TAG} is archived", a.returncode == 0 and os.path.isfile(os.path.join(old, "hubkit", "kit.json")), a.stderr[-300:])
        if a.returncode != 0:
            return
        oldkit = os.path.join(old, "hubkit", "tools", "hubkit.py")
        check("c2 that kit is 0.11.2", json.loads(read(os.path.join(old, "hubkit", "kit.json"))).get("version") == "0.11.2", "other version")
        fh, ih = os.path.join(t, "formal"), os.path.join(t, "notool")
        p1, p2 = hk(oldkit, "install", "--hub", fh, "--edition", "formal"), hk(oldkit, "install", "--hub", ih, "--edition", "informal")
        check("c2 setup: the old kit installs both hubs", p1.returncode == 0 and p2.returncode == 0, (p1.stderr, p2.stderr))
        # the hub with the tool upgrades
        p = hk(HUBKIT, "upgrade", "--hub", fh)
        check("c2 a 0.11.2 hub with the tool: the dry run exits 0 and adds bin/orbit", p.returncode == 0 and "add\t.claude/orbit-kb/bin/orbit\n" in p.stdout, (p.stdout[-400:], p.stderr))
        p = hk(HUBKIT, "upgrade", "--hub", fh, "--yes")
        m = manifest(fh)
        check("c2 a 0.11.2 hub with the tool upgrades with no pending merge", p.returncode == 0 and m.get("pending") == [] and m.get("edition") == "formal"
              and os.access(os.path.join(fh, ".claude", "orbit-kb", "bin", "orbit"), os.X_OK) and read(os.path.join(fh, "HUB-CORE.md")) == core, (p.stdout[-300:], p.stderr))
        # the hub with no tool is refused with one line, and nothing is copied
        before = read(os.path.join(ih, ".hub-template.json")), read(os.path.join(ih, "HUB-CORE.md"))
        for args in (("upgrade",), ("upgrade", "--yes")):
            p = hk(HUBKIT, *args, "--hub", ih)
            e = p.stderr
            check(f"c2 {' '.join(args)} of a hub with no tool fails with one line: ended in 0.12.0, what to install, what to run",
                  p.returncode == 2 and len(e.strip().splitlines()) == 1 and "Traceback" not in e and "ended in MindHole Kit 0.12.0" in e
                  and "SWI-Prolog" in e and "edition --hub" in e, (p.returncode, e[-400:]))
        check("c2 nothing was copied", before == (read(os.path.join(ih, ".hub-template.json")), read(os.path.join(ih, "HUB-CORE.md")))
              and not os.path.exists(os.path.join(ih, ".claude", "orbit-kb")), "changed")
        p = hk(HUBKIT, "edition", "--hub", ih, "formal", "--yes")
        m = manifest(ih)
        check("c2 `edition formal --yes` moves that hub: the kit's HUB-CORE.md, its own orbit-kb, no pending merge",
              p.returncode == 0 and m.get("edition") == "formal" and m.get("pending") == [] and read(os.path.join(ih, "HUB-CORE.md")) == core
              and os.access(os.path.join(ih, ".claude", "orbit-kb", "bin", "orbit-kb"), os.X_OK), (p.stdout[-400:], p.stderr))
        p = hk(HUBKIT, "install", "--hub", os.path.join(t, "new"), "--edition", "informal")
        check("c2 install refuses that edition and writes nothing", p.returncode == 1 and "0.12.0" in p.stderr and not os.path.exists(os.path.join(t, "new")), p.stderr)


# ------------------------------------------------------------------ c3
CORE_PHRASES = ("clear", "accurate", "honest", "fast", "start light", "shift up", "signal", "lean back",
                "grades its own work", "disclose", "guess")
KB_SYNTAX = ("orbit-kb", "kb.pl", "attest", "prolog", "burn", "lint", "query", "lean proof", "theorem")


def c3():
    pr = read(PRINCIPLES)
    check("c3 hubkit/hub/PRINCIPLES.md exists", bool(pr), PRINCIPLES)
    n = len(pr.splitlines())
    # scientific-method-overhaul c10, c12, c16: one more part (verdicts, the two judgments, Sound Basis) and the
    # generated vocabulary block; the limit is 70 lines outside that block (it was 60 lines in all)
    n -= len(re.findall(r"\n", "".join(re.findall(r"<!-- vocabulary:begin -->.*?<!-- vocabulary:end -->\n?", pr, re.S))))
    check("c3 PRINCIPLES.md is short (at most 70 lines outside the vocabulary block)", 0 < n <= 70, n)
    check("c3 the hub CLAUDE.md imports it (@PRINCIPLES.md)",
          any(ln.strip() == "@PRINCIPLES.md" for ln in read(os.path.join(HUB, "CLAUDE.md")).splitlines()), "no import line")
    kit = json.loads(read(KIT))
    check("c3 kit.json ships PRINCIPLES.md", "PRINCIPLES.md" in kit["engine"] + kit["owned"], kit)
    has("c3 PRINCIPLES.md has the core of the philosophy", pr, *CORE_PHRASES)
    lacks("c3 PRINCIPLES.md has no KB syntax", pr, *KB_SYNTAX)
    m = re.search(r"\b[a-z_]+\([^)]*\)", pr)
    check("c3 PRINCIPLES.md has no term like name(args)", m is None, m and m.group(0))
    prompt = read(PROMPT)
    heads = {ln[3:].strip() for ln in prompt.splitlines() if ln.startswith("## ")}
    last = [ln for ln in prompt.splitlines() if ln.strip()][-1:]
    pv = re.search(r"Sagittarius (\d+\.\d+\.\d+)", last[0]) if last else None
    check("c3 the last line of prompt/SAGITTARIUS.md names its version", pv is not None, last)
    if pv:
        check(f"c3 PRINCIPLES.md names the version of the prompt (Sagittarius {pv.group(1)})", f"Sagittarius {pv.group(1)}" in pr, "missing")
    check("c3 PRINCIPLES.md cites no section of docs/PHILOSOPHY.md", "PHILOSOPHY" not in pr, "still there")
    secs = re.split(r"^## ", pr, flags=re.M)[1:]
    check("c3 PRINCIPLES.md has at least four principles (## headings)", len(secs) >= 4, len(secs))
    for s in secs:
        title = s.splitlines()[0].strip()
        src = re.findall(r'^From the prompt: "([^"]+)"\s*$', s, re.M)
        check(f"c3 principle '{title}' names the section of the prompt that it comes from", len(src) >= 1, "no 'From the prompt: \"...\"' line")
        for x in src:
            check(f"c3 principle '{title}': the section '{x}' is in prompt/SAGITTARIUS.md", x in heads, x)
    for rel in (KREADME, INSTR):
        t = words(read(rel))
        check(f"c3 {os.path.basename(rel)} no longer says that PRINCIPLES.md states the philosophy", "states the sagittarius philosophy" not in t, "still there")
        check(f"c3 {os.path.basename(rel)} says that PRINCIPLES.md comes from the prompt", re.search(r"principles\.md`? comes from the (sagittarius )?prompt", t) is not None, "missing")
    up = read(UPGRADING)
    # The release that brought PRINCIPLES.md from the prompt is 0.7.0; a later patch (0.7.1) has its own
    # section, and a hub at 0.6.0 reads both (UPGRADING step 2). So the 0.7.0 section must say it.
    has("c3 UPGRADING.md 0.7.0 tells a hub to import it", section(up, "0.7.0", "###"), "@PRINCIPLES.md", "CLAUDE.md")


# ------------------------------------------------------------------ c4
def c4():
    check("c4 hubkit/hub/sessions is gone", not os.path.exists(os.path.join(HUB, "sessions")), "still there")
    kit = json.loads(read(KIT))
    left = [x for x in kit["engine"] + kit["owned"] if x.startswith("sessions/")]
    check("c4 kit.json lists no sessions/ path", not left, left)
    core = read(CORE)
    tree = re.findall(r"```\n(.*?)```", section(core, "Structure"), re.S)
    check("c4 HUB-CORE.md has a structure tree", bool(tree), "missing")
    check("c4 the structure tree does not list sessions/", bool(tree) and "sessions/" not in tree[0], tree[:1])
    for name, path in (("HUB-CORE.md", CORE), ("INSTRUCTIONS.md", INSTR), ("hubkit/README.md", KREADME),
                       ("hub-flow SKILL.md", os.path.join(HUB, ".claude", "skills", "hub-flow", "SKILL.md")),
                       ("TECHNOLOGIES.md", os.path.join(HUB, "TECHNOLOGIES.md")), ("hub CLAUDE.md", os.path.join(HUB, "CLAUDE.md")),
                       ("docs/index.html", os.path.join(KITDIR, "docs", "index.html"))):
        lacks(f"c4 {name}", read(path), "sessions/launch.sh", "sessions/ROLES", "launch.sh <")
    kr = read(KREADME)
    ps = [p for p in paragraphs(kr) if re.search(r"named sessions?", p, re.I) and "outside the hub" in words(p)]
    check("c4 one paragraph of hubkit/README.md says named sessions are set up outside the hub", len(ps) == 1, len(ps))
    sess = [p for p in paragraphs(kr) if re.search(r"\bsessions?\b", p, re.I) and re.search(r"launch|role|dotfiles|set up", p, re.I)]
    check("c4 at most one paragraph of hubkit/README.md is about setting up sessions", len(sess) <= 1, [p[:80] for p in sess])
    up = read(UPGRADING)
    sec = section(up, T24_VERSION, "###")  # the release that made T24; the kit version moved on (T36)
    has(f"c4 UPGRADING.md {T24_VERSION}", sec, "sessions/", "may keep its own", "sessions/ROLES")
    cmd = re.findall(r'`(git -C "\$HUB" checkout [^`]*sessions/launch\.sh[^`]*)`', sec)
    check("c4 UPGRADING.md gives the command that keeps sessions/launch.sh", len(cmd) == 1, cmd)
    with tempfile.TemporaryDirectory(prefix="t24-c4-") as t:
        old = os.path.join(t, "oldkit")
        os.makedirs(old)
        a = subprocess.run(f"git -C '{ROOT}' archive {OLD_KIT_COMMIT} hubkit | tar -x -C '{old}'", shell=True, capture_output=True, text=True)
        check("c4 the 0.3.0 kit comes out of git", a.returncode == 0, a.stderr)
        if a.returncode != 0:
            return
        oldkit = os.path.join(old, "hubkit")
        hub = os.path.join(t, "hub")
        env = {**os.environ, "HUB": hub, "GIT_AUTHOR_NAME": "Test", "GIT_AUTHOR_EMAIL": "test@example.invalid",
               "GIT_COMMITTER_NAME": "Test", "GIT_COMMITTER_EMAIL": "test@example.invalid"}
        os.makedirs(hub)
        run(["git", "init", "-q", hub])
        p = run([sys.executable, "-I", os.path.join(oldkit, "tools", "hubkit.py"), "install", "--hub", hub, "--kit", oldkit])
        run(["git", "-C", hub, "add", "-A"])
        run(["git", "-C", hub, "commit", "-q", "-m", "hub 0.3.0"], env=env)
        check("c4 a 0.3.0 hub has sessions/launch.sh", p.returncode == 0 and os.path.isfile(os.path.join(hub, "sessions", "launch.sh")), p.stderr)
        p = run([sys.executable, "-I", os.path.join(KITDIR, "tools", "hubkit.py"), "upgrade", "--hub", hub, "--yes"])
        check("c4 the upgrade removes the unchanged sessions/launch.sh", p.returncode == 0 and "remove\tsessions/launch.sh" in p.stdout
              and not os.path.exists(os.path.join(hub, "sessions", "launch.sh")), (p.returncode, p.stdout[-400:], p.stderr[-200:]))
        check("c4 the upgrade keeps the hub's sessions/ROLES", os.path.isfile(os.path.join(hub, "sessions", "ROLES")), "gone")
        if len(cmd) == 1:
            p = run(["bash", "-c", cmd[0]], env=env)
            check("c4 the UPGRADING.md command brings sessions/launch.sh back", p.returncode == 0
                  and os.path.isfile(os.path.join(hub, "sessions", "launch.sh")), (p.returncode, p.stderr))
            s = run([sys.executable, "-I", os.path.join(KITDIR, "tools", "hubkit.py"), "status", "--hub", hub])
            check("c4 then it is the hub's own file (status does not list it)", "sessions/launch.sh" not in s.stdout, s.stdout)


# ------------------------------------------------------------------ c5
def c5():
    # Ty, 2026-11-12: a hub is a MindHole; the template that makes one is the MindHole Kit (it was "the hub kit").
    for name, path in (("hubkit/README.md", KREADME), ("INSTRUCTIONS.md", INSTR)):
        t = read(path)
        has(f"c5 {name}", t, "the MindHole Kit", "part of Sagittarius", REPO_URL)
        lacks(f"c5 {name}", t, "hubflow-starter", "the hub kit")
    first = (read(KREADME).splitlines() or [""])[0]
    check("c5 hubkit/README.md is titled the MindHole Kit", first.lower().startswith("# the mindhole kit") and "hub kit" not in first.lower(), first)
    lacks("c5 hubkit/docs/index.html (the briefing the README links)", read(os.path.join(KITDIR, "docs", "index.html")), "hubflow-starter")
    kit_sec = section(read(README), "The MindHole Kit")
    check("c5 README.md has the section 'The MindHole Kit'", "hubkit/" in kit_sec, kit_sec[:120])
    lacks("c5 README.md section 'The MindHole Kit'", kit_sec, "hubflow-starter", "the hub kit")


# ------------------------------------------------------------------ c6
def c6():
    kit = json.loads(read(KIT))
    v = kit["version"]
    check("c6 kit.json version bumps from 0.3.0", tuple(map(int, v.split("."))) > (0, 3, 0), v)
    up = read(UPGRADING)
    first = re.search(r"^### (\d+\.\d+\.\d+)", up, re.M)
    check("c6 the newest UPGRADING.md section is the kit version", first is not None and first.group(1) == v, first and first.group(1))
    cl = read(CHANGELOG)
    entry = [ln for ln in cl.splitlines() if "T24" in ln]
    check("c6 CHANGELOG.md has a T24 entry", bool(entry), "no line names T24")
    t = T24_VERSION  # the T24 entry names the release that made T24 (T36 moved the kit on)
    check(f"c6 the CHANGELOG entry names hub kit {t}", any(t in ln for ln in entry) or (bool(entry) and t in cl[cl.find(entry[0]):cl.find(entry[0]) + 600]), entry)
    stale = [x for x in re.findall(r"hub kit is version (\d+\.\d+\.\d+)", words(cl)) if x != v]
    check("c6 CHANGELOG.md names no older hub kit version as current", not stale, stale)


CLAIMS = {"c1": c1, "c2": c2, "c3": c3, "c4": c4, "c5": c5, "c6": c6}

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
