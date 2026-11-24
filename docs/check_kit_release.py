#!/usr/bin/env python3
"""The MindHole Kit as a release: one kind of hub, with the tool. One check per claim.

usage: python3 docs/check_kit_release.py c1|c2|c3|c4|c5|c6|t32c5|t32c7|t36c2|t36c4|t36c5|t36c6|t41c1|t41c4|t41c5|iuxc4   (--list prints the ids)
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
        # The hub's own tests run the tool on check commands (true, sh -c, env): those come from the
        # system, not from the kit. The install block above ran with the README's tools only.
        for t2 in ("true", "false", "sh", "env"):
            p2 = shutil.which(t2)
            if p2 and not os.path.lexists(os.path.join(b, t2)):
                os.symlink(p2, os.path.join(b, t2))
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

# ------------------------------------------------------------------ ported from check_informal_hub.py
# The ids below were in docs/check_informal_hub.py (T32, T36, T41, install UX). They are not about the
# edition with no tool, so they stay, on the one kind of hub (scientific-method-overhaul c22 removed only
# their second-edition halves). Where a claim of that ticket changed the text, the id names the claim.
PHIL = os.path.join(ROOT, "docs", "PHILOSOPHY.md")
BANNED = (("spec KB", re.compile(r"spec kb", re.I)), ("project KB", re.compile(r"project kb", re.I)),
          ("orbit-kb", re.compile(r"orbit-kb", re.I)), ("draft/4", re.compile(r"draft/4")),
          ("pin-item", re.compile(r"pin-item", re.I)), ("Prolog", re.compile(r"prolog", re.I)),
          ("Lean", re.compile(r"\bLean\b")), ("SMT", re.compile(r"\bSMT\b")), ("TLA+", re.compile(r"TLA\+")))
# c1, c2 of scientific-method-overhaul: the part that cites "The hypothesis" states the goal and each hypothesis
# apart (it was: "what the human wants"), and names the case that would show the hypothesis false
P_WANT = (("The orbit", ("orbit", "the request", "each step")),
          ("The hypothesis", ("hypothesis", "the goal", "show the hypothesis false", "go on")),
          ("Delivery", ("skip", "never hide", "only the human skips", "due")))
HYP_FROM = 'From the prompt: "The hypothesis"'
HYP_PARTS = (("the expected result", re.compile(r"\bexpect", re.I)), ("the falsifier", re.compile(r"show (it|the hypothesis) false", re.I)),
             ("the premises", re.compile(r"\bpremises\b", re.I)))


def principle_parts():
    return re.split(r"^## ", read(PRINCIPLES), flags=re.M)[1:]


def bin_with(where, tools):
    b = os.path.join(where, "bin")
    os.makedirs(b, exist_ok=True)
    for t in tools:
        p = shutil.which(t)
        if p:
            os.symlink(p, os.path.join(b, t))
    return b


def new_hub(t, name="hub"):
    hub = os.path.join(t, name)
    os.makedirs(hub)
    run(["git", "init", "-q", hub])
    return hub, hk(HUBKIT, "install", "--hub", hub)


def hubflow(hub, args, session=None, now=None):
    env = {k: v for k, v in os.environ.items() if k not in ("HUB_SESSION", "HUBFLOW_DB_DIR", "HUBFLOW_HUB")}
    if session:
        env["HUB_SESSION"] = session
    if now:
        env["HUBFLOW_NOW"] = now
    return run([sys.executable, "-I", os.path.join(hub, ".claude", "scripts", "hubflow.py")] + args, cwd=hub, env=env)


def t32c5():
    pr = read(PRINCIPLES)
    heads = {ln[3:].strip() for ln in read(PROMPT).splitlines() if ln.startswith("## ")}
    secs = principle_parts()
    for src, phrases in P_WANT:
        check(f"t32c5 prompt/SAGITTARIUS.md has '{src}'", src in heads, "missing")
        mine = [s for s in secs if re.search(r'^From the prompt: "' + re.escape(src) + r'"\s*$', s, re.M)]
        check(f"t32c5 PRINCIPLES.md has a principle that comes from '{src}'", len(mine) == 1, len(mine))
        if mine:
            has(f"t32c5 the principle from '{src}'", mine[0], *phrases)
    w = words(pr)
    for old in ("wait for the answer", "say what you believe the problem is"):
        check(f"t32c5 PRINCIPLES.md no longer says '{old}'", old not in w, "still there")
    hits = [(i, n, ln.strip()[:100]) for i, ln in enumerate(pr.splitlines(), 1) for n, rx in BANNED if rx.search(ln)]
    check("t32c5 PRINCIPLES.md names no formal word", not hits, hits[:4])
    c3()


def t32c7():
    sec = section(read(INSTR), "Step 5")
    check("t32c7 INSTRUCTIONS.md has a step 5", bool(sec), "missing")
    start = re.findall(r'claude --name "([^"]+)"', sec)
    check("t32c7 step 5 starts a session with a name", len(start) == 1, start)
    check("t32c7 the launcher line sets HUB_SESSION and the hub cwd",
          re.search(r'cd "\$HUB" && HUB_SESSION=<name> claude --name', sec) is not None, sec[:300])
    check("t32c7 step 5 says how to resume it by that name: the same line with --resume in place of --name",
          start and re.search(r'`--resume "%s"` in place of `--name "%s"`' % (re.escape(start[0]), re.escape(start[0])), re.sub(r"\s+", " ", sec)) is not None,
          sec[:500])
    check("t32c7 step 5 gives no second (resume) command line", not re.findall(r'^\s*cd [^\n]*claude --resume', sec, re.M), sec[:300])
    check("t32c7 step 5 names no launch.sh", "launch.sh" not in sec, "still there")


def t36c2():
    """A hub of kit 0.4.0 (made at 41377fc; it records no edition) upgrades. c22: it is read as formal, whatever
    the PATH holds (it was: the edition with no tool when no orbit-kb is on the PATH)."""
    with tempfile.TemporaryDirectory(prefix="t36-c2-") as t:
        wt = os.path.join(t, "old-kit")
        p = run(["git", "-C", ROOT, "worktree", "add", "--detach", wt, "41377fc"])
        check("t36c2 a worktree of the 0.4.0 kit (41377fc) is made", p.returncode == 0, p.stderr[-300:])
        if p.returncode != 0:
            return
        try:
            hub = os.path.join(t, "old-hub")
            os.makedirs(hub)
            run(["git", "init", "-q", hub])
            q = hk(os.path.join(wt, "hubkit", "tools", "hubkit.py"), "install", "--hub", hub)
        finally:
            run(["git", "-C", ROOT, "worktree", "remove", "--force", wt])
            run(["git", "-C", ROOT, "worktree", "prune"])
        m = manifest(hub)
        check("t36c2 that hub is 0.4.0 and records no edition", q.returncode == 0 and m.get("template_version") == "0.4.0" and "edition" not in m, (q.stderr, m))
        bare = bin_with(os.path.join(t, "bare"), ["python3", "git"])
        env = dict(os.environ, PATH=bare)
        plan = run([sys.executable, "-I", HUBKIT, "upgrade", "--hub", hub], env=env)
        check("t36c2 the dry run with no orbit-kb on the PATH exits 0 and names the formal edition", plan.returncode == 0 and "(formal edition)" in plan.stdout
              and "records no edition" in plan.stdout, (plan.stdout[:300], plan.stderr))
        p = run([sys.executable, "-I", HUBKIT, "upgrade", "--hub", hub, "--yes"], env=env)
        m = manifest(hub)
        check("t36c2 the upgrade exits 0, records formal, and the hub has its own orbit-kb", p.returncode == 0 and m.get("edition") == "formal"
              and os.access(os.path.join(hub, ".claude", "orbit-kb", "bin", "orbit-kb"), os.X_OK), (p.stdout[-200:], p.stderr))
        s = run([sys.executable, "-I", HUBKIT, "status", "--hub", hub], env=env)
        check("t36c2 status of the upgraded hub names its edition", "(formal edition" in s.stdout, s.stdout[:200])


def t36c4():
    k = json.loads(read(KIT) or "{}")
    ver = tuple(int(x) for x in k.get("version", "0.0.0").split("."))
    check("t36c4 kit.json version is 0.5.0 or later", ver >= (0, 5, 0), k.get("version"))
    up = read(UPGRADING)
    heads = re.findall(r"^### (\d+\.\d+\.\d+)", up, re.M)
    at = heads.index("0.5.0") if "0.5.0" in heads else -1
    check("t36c4 UPGRADING.md has a 0.5.0 section, newest first", at >= 0 and heads[at:at + 2] == ["0.5.0", "0.4.0"]
          and heads == sorted(heads, key=lambda v: tuple(int(x) for x in v.split(".")), reverse=True), heads[:3])
    sec = section(up, "0.5.0", level="###")
    check("t36c4 the 0.5.0 section is not empty", len(sec) > 200, len(sec))
    # c22: the section no longer tells how to switch to the edition with no tool, or its bash 4 requirement
    has("t36c4 the 0.5.0 section", sec, "T32", "T36", "edition", "premises")
    sec4 = section(up, "0.4.0", level="###")
    check("t36c4 the 0.4.0 section no longer holds the T32 edition bullet", "A hub knows its edition" not in sec4, "still there")
    check("t36c4 the 0.4.0 section keeps the transcripts bullet", "An agent, not code, puts meeting transcripts" in sec4, "missing")
    has("t36c4 the 0.5.0 section tells a 0.4.0 hub with an older db to migrate", sec, "migrate")


def skip_part(name):
    mine = [s for s in principle_parts() if s.startswith("Skip, never hide")]
    check(f"{name} PRINCIPLES.md has the skip principle", len(mine) == 1, len(mine))
    return mine[0] if mine else ""


def t36c5():
    part = skip_part("t36c5")
    if part:
        has("t36c5 the skip principle states what the ledger does", part, "human_skip", "park", "--until", "due", "comes back")
    with tempfile.TemporaryDirectory(prefix="t36-c5-") as t:
        hub, p = new_hub(t)
        hubflow(hub, ["init"])
        hf = lambda args, now: hubflow(hub, args, session="build", now=now)
        p = hf(["add", "ask", "--note", "Test ask: case, options, default.", "--no-kb", "--title", "Skipped for now", "--waits-on", "me", "--ref", "issue:5"], "2026-09-01T00:00:00Z")
        check("t36c5 an ask is added", p.returncode == 0, p.stderr)
        p = hf(["park", "A-0001", "--until", "2026-10-15", "--note", "human: later"], "2026-09-02T00:00:00Z")
        check("t36c5 park --until records the hold", p.returncode == 0, p.stderr)
        p = hf(["rotate", "--week-start", "2026-10-05"], "2026-10-06T00:00:00Z")
        check("t36c5 before the date the item is not due", p.returncode == 0 and "untriaged: none" in p.stdout, (p.stdout, p.stderr))
        p = hf(["rotate", "--week-start", "2026-10-19"], "2026-10-20T00:00:00Z")
        check("t36c5 after the date the item is due again for triage", p.returncode == 1 and "untriaged: A-0001" in p.stdout, (p.returncode, p.stdout, p.stderr))


def t41c4():
    part = skip_part("t41c4")
    if part:
        w = words(part)
        check("t41c4 the skip principle says an agent may park", re.search(r"an agent (can|may)( still)? park", w) is not None, w[:400])
        check("t41c4 the skip principle says only an item that is not escalated", "not escalated" in w or "non-escalated" in w, w[:400])
        check("t41c4 the skip principle says the park event names the agent", re.search(r"park event names the agent", w) is not None, w[:400])
        check("t41c4 the skip principle calls it a known limit", "known limit" in w, w[:400])
    with tempfile.TemporaryDirectory(prefix="t41-c4-") as t:
        hub, p = new_hub(t)
        hubflow(hub, ["init"])
        p = hubflow(hub, ["add", "ask", "--note", "Test ask: case, options, default.", "--no-kb", "--title", "Park me", "--waits-on", "me", "--ref", "issue:5"], session="build")
        check("t41c4 an ask is added", p.returncode == 0, p.stderr)
        p = hubflow(hub, ["park", "A-0001", "--until", "2026-12-01"], session="build")
        check("t41c4 an agent parks a non-escalated item (exit 0)", p.returncode == 0, p.stderr)
        s = hubflow(hub, ["show", "A-0001"], session="build").stdout
        ev = [ln for ln in s.splitlines() if "| parked |" in ln]
        check("t41c4 the park event names the agent session and says agent", len(ev) == 1 and "| build | agent |" in ev[0], ev or s[-300:])


def hyp_part(name):
    mine = [s for s in principle_parts() if HYP_FROM in s]
    check(f"{name} PRINCIPLES.md has the hypothesis principle", len(mine) == 1, len(mine))
    return mine[0] if mine else ""


def hyp_parts(name, text):
    for part, rx in HYP_PARTS:
        check(f"{name} names {part}", rx.search(words(text)) is not None, text[:300])


def core_row(kind):
    return [ln for ln in read(CORE).splitlines() if ln.startswith(f"| `{kind}` | ") and "| `spec` |" in ln]


def t36c6():
    part = hyp_part("t36c6")
    if part:
        body = words(part)
        check("t36c6 the hypothesis principle asks for the premises beside the hypothesis", "premises" in body and "beside" in body, body[:300])
    # c2: the hypothesis row is the row of What lives where (the second store map is gone, c22); it keeps the premises beside it
    rows = core_row("hypothesis")
    check("t36c6 HUB-CORE.md has the hypothesis row", len(rows) == 1, len(rows))
    if rows:
        check("t36c6 the hypothesis row asks for the premises beside it", "premises" in rows[0].lower() and "beside" in rows[0].lower(), rows[0][:200])
    p = run([sys.executable, os.path.join(KITDIR, "tools", "storemap.py"), "--check"])
    check("t36c6 storemap.py --check: HUB-CORE.md is current", p.returncode == 0, p.stderr)
    has("t36c6 PHILOSOPHY.md keeps the premises sentence", read(PHIL), "lists its premises beside it")


def t41c1():
    part = hyp_part("t41c1")
    if part:
        hyp_parts("t41c1 the hypothesis principle", part)
        has("t41c1 the hypothesis principle", part, "assume little", "which result you expect", "beside")
        # c1, c2: the goal apart from the hypothesis; the agent says that its drafts are its own
        has("t41c1 the hypothesis principle (c1, c2)", part, "the goal and each hypothesis apart", "its own")


def t41c5():
    # c1, c2: the What lives where row of the hypothesis is a claim about an avenue, with author, state, premises
    # and the case that would show it false; the goal has its own row (it was: "what the human wants ... the result it expects")
    rows = core_row("hypothesis")
    check("t41c5 HUB-CORE.md has the What lives where hypothesis row", len(rows) == 1, len(rows))
    if rows:
        has("t41c5 the hypothesis row (c2)", rows[0], "avenue to the goal", "author", "proposed, adopted, retired or defeated", "premises", "show it false")
    g = core_row("goal")
    check("t41c5 HUB-CORE.md has the What lives where goal row, owned by spec (c1)", len(g) == 1, len(g))
    if g:
        has("t41c5 the goal row (c1)", g[0], "the intent", "names no avenue")
    p = run([sys.executable, os.path.join(KITDIR, "tools", "storemap.py"), "--check"])
    check("t41c5 storemap.py --check: HUB-CORE.md is current", p.returncode == 0, p.stderr)


def iuxc4():
    import shlex
    kit = json.loads(read(KIT) or "{}")
    sh = [f for f in kit.get("engine", []) if f.endswith(".sh") or read(os.path.join(HUB, f)).startswith("#!/usr/bin/env bash")
          or read(os.path.join(HUB, f)).startswith("#!/bin/")]
    check("iuxc4 kit.json lists no shell engine file", not sh, sh)
    sh_files = [os.path.relpath(os.path.join(b, f), KITDIR) for b, _, fs in os.walk(KITDIR) for f in fs if f.endswith(".sh")]
    check("iuxc4 the kit holds no .sh file", not sh_files, sh_files)
    inst = section(read(KREADME), "Install")
    w = words(inst)
    check("iuxc4 README Install says Python 3 and git", "python 3" in w and "git" in w, inst[:200])
    check("iuxc4 README Install says it needs no bash", "no bash" in w, inst[:300])
    check("iuxc4 README Install has no POSIX tool list", "posix" not in w and "`awk`" not in inst, inst[:300])
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
        b = bin_with(t, ["python3", "git", "swipl"])  # c22: a hub needs the tool, so swipl is a requirement of the README
        work, home = os.path.join(t, "work"), os.path.join(t, "home")
        os.makedirs(work)
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
        check("iuxc4 every line of the block runs with no shell, relative KIT and HUB, and only python3, git and swipl on PATH",
              outs and all(o[1] == 0 for o in outs) and len(outs) == len(lines), outs[-1:] if outs else "no lines")
        hub = os.path.join(work, "myhub")
        check("iuxc4 the hub is at the relative HUB, with its manifest and flow db",
              os.path.isfile(os.path.join(hub, ".hub-template.json")) and os.path.isfile(os.path.join(hub, "flow", "flow.db")), hub)



CLAIMS = {"c1": c1, "c2": c2, "c3": c3, "c4": c4, "c5": c5, "c6": c6, "t32c5": t32c5, "t32c7": t32c7, "t36c2": t36c2, "t36c4": t36c4,
          "t36c5": t36c5, "t36c6": t36c6, "t41c1": t41c1, "t41c4": t41c4, "t41c5": t41c5, "iuxc4": iuxc4}

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
