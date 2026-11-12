#!/usr/bin/env python3
"""T31: an agent in a hub can run what the hub guidance tells it. One check per claim.

usage: python3 docs/check_hub_fixes.py t31c3|...|t31c9|t46c3|t49c1|t50c1|t50c2|t50c4|t51c5|iuxc1|iuxc3k|iuxc6|iuxc6u|m030d1|m030d3 (t31c7 is superseded by t31c8, t46c2 by t46c3, t31c1 and t31c2 by iuxc3k) [--list]   (--list prints the claim ids)
Exit 0: the claim's check passes. Exit 1: it fails (each failure is printed). Prints `N checks`.

t31c1 runs the project KB setup line that hubkit/INSTRUCTIONS.md (and hubkit/README.md, when it has one) gives.
t31c2 scans the hubkit/hub/ tree for checkout-only paths that no nearby text places in the checkout.
t31c3 reads the hub-rotate skill's durability step.
t31c4 reads where SAGITTARIUS.md first uses `hubflow`.
t31c5 runs `orbit-kb show open` at a hub root with no KB and reads the hint.
t31c6 reads the landing check (LAND_CHECK, default the design KB's land_check.sh) for a loop that runs every
      claim id of the docs/check_*.py scripts that take one (each script prints its ids with --list).
t31c7 reads the DECOMPOSE step 4 of the core help topic against the wording of the prompt's Roles section.
t31c8 (u47) the prompt, PHILOSOPHY and the core help say: after a shift up the human, the agent and the CPU use
      the formal language as the shared substrate, and the human reads, reviews and understands it.
t31c9 (u57) the hypothesis paragraph of the prompt names hypotheses, premises and claims for err-soft, and keeps
      "oscillation is an intentional heuristic".
t46c2 help project, next to the automatic record of a dropped edit (T45), and the session setup of the hub kit
      (INSTRUCTIONS.md Step 5, HUB-CORE.md) say how a pane gets HUB_SESSION. Superseded by t46c3.
t46c3 the same, with the orbit-kb text of INSTRUCTIONS.md in "The formal edition" (t32c2 bans formal words
      elsewhere) and Step 5 pointing to it.
t49c1 (u114, u120, u125, u127) the formal weeks row of "What lives where" in hubkit/hub/HUB-CORE.md takes the
      design KB text of kg_def_v2(weeks) word for word: it names human transcripts and Claude Code session logs.
iuxc1 (install UX c1) setup asks the human what the hub is for, first, and keeps the answer word for word in
      CLAUDE.md under "What this hub is for" (both editions; an owned file), and in the formal edition as the
      project KB request; more than three questions are allowed at setup only.
iuxc3k (install UX c3; supersedes t31c1 and t31c2) the project KB setup line of INSTRUCTIONS.md runs the hub's own
      orbit-kb (.claude/orbit-kb/bin/orbit-kb), as written, at the root of a new formal hub; no hub text runs a bare
      `orbit-kb` command; and the checkout-path scan of t31c2 no longer reads the hub path .claude/orbit-kb/bin/
      as the checkout path kb/bin/.
iuxc6 (install UX c6) a normal install runs no test suite and ends with hubkit status and hubflow check, each with
      a reason for the user; a UAT install (step 1 asks; install --uat records it) also runs the plain suite and
      the mutants, with the reason that they test the kit.
iuxc6u (Ty, 2026-11-12; beside iuxc6) a normal upgrade (hubkit/UPGRADING.md, "The procedure") runs no test
      suite and ends its checks with hubkit status and hubflow check, each with a one-line reason; only a UAT
      upgrade (a hub whose .hub-template.json records "uat": true) also runs the plain suite and the mutants,
      with the reason that they test the kit.
m030d1 (0.3.0 M-D c_m_d_1) "The formal edition" of hubkit/INSTRUCTIONS.md gives one launcher line for a pane
      that sets HUB_SESSION and appends the prompt, PANES.md and the role file; the check runs that line with
      a stub claude and a scratch HOME, and reads what the stub got. The step checks that the pane can say
      the last line of its prompt. Review findings 4 and 5 (kit3): the file gives that launcher once (a resume is
      the same line with --resume in place of --name, said in words), and the "Panes" section of the root
      README.md gives the same line, character for character, and no other launcher.
m030d3 (0.3.0 M-D c_m_d_3) hubkit/README.md and hubkit/UPGRADING.md say which Sagittarius version the kit
      pairs with: the major and minor version of the last line of prompt/SAGITTARIUS.md.
t50c1 (retire) the repo has no microsite: neither the deck directory nor the Pages workflow is in the tree, and no
      tracked file outside tmp/ names the deck files, their build and check scripts, or the workflow.
t50c2 (retire) README.md, CLAUDE.md and docs/PHILOSOPHY.md do not point at the decks.
t50c4 (preserve) hubkit/docs/index.html stays: the local briefing that step 1 of hubkit/INSTRUCTIONS.md opens. It
      names the MindHole (Ty, 2026-11-12: the kit is the MindHole; it was "hub kit").
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
HUB = os.path.join(ROOT, "hubkit", "hub")
OKB = os.path.join(ROOT, "kb", "bin", "orbit-kb")
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


def okb(args, cwd):
    env = dict(os.environ, ORBIT_KB_LIB=os.path.join(ROOT, "kb", "share", "orbit-kb"))
    env.pop("ORBIT_KB", None)
    return subprocess.run([OKB] + args, cwd=cwd, env=env, capture_output=True, text=True, timeout=120)


def t31c1():
    lines = []
    for f in ("INSTRUCTIONS.md", "README.md"):
        for ln in read(os.path.join(ROOT, "hubkit", f)).splitlines():
            for m in re.finditer(r"`(orbit-kb init project-kb[^`]*)`", ln):
                lines.append((f, m.group(1)))
    check("t31c1 INSTRUCTIONS.md gives the setup line", any(f == "INSTRUCTIONS.md" for f, _ in lines), "no line")
    for f, cmd in lines:
        with tempfile.TemporaryDirectory() as d:
            # a placeholder such as TEXT or '<text>' is filled with a real request
            run = re.sub(r"'?<[^>]*>'?|'?\bTEXT\b'?", "'a request'", cmd)
            p = okb(shlex.split(run)[1:], d)
            check(f"t31c1 {f}: `{cmd}` exits 0", p.returncode == 0, f"exit {p.returncode}: {p.stderr.strip()[:200]}")


CO = re.compile(r"prompt/(PANES|SAGITTARIUS)\.md|kb/bin/|kb/share/|kb/tests/|hubkit/|docs/[A-Z]+\.md")
PLACE = re.compile(r"checkout|Sagittarius repository|installed|on PATH|on your PATH", re.I)


def t31c2(co=CO, prefix="t31c2"):
    for dp, dn, fn in os.walk(HUB):
        dn[:] = [x for x in dn if x != ".git"]
        for n in fn:
            if n.endswith("-test.py") or n.endswith(".pyc"):
                continue
            p = os.path.join(dp, n)
            try:
                ls = open(p, encoding="utf-8").read().splitlines()
            except (OSError, UnicodeDecodeError):
                continue
            whole = "\n".join(ls)
            for i, ln in enumerate(ls):
                m = co.search(ln)
                if not m:
                    continue
                win = " ".join(ls[max(0, i - 2): i + 3])
                ok = bool(PLACE.search(win)) or (ln.startswith("Source:") and "Sagittarius repository" in whole)
                check(f"{prefix} {os.path.relpath(p, HUB)}:{i + 1} `{m.group(0)}` is placed", ok, ln.strip())


def t31c3():
    t = read(os.path.join(HUB, ".claude", "skills", "hub-rotate", "SKILL.md"))
    i = t.find("is it durable?")
    sec = re.sub(r"\s+", " ", t[i:i + 700]).lower()
    check("t31c3 hub-rotate durable step exists", i >= 0, "missing")
    check("t31c3 the durable step promotes to the project KB", "project kb" in sec, sec[:200])


def t31c4():
    # 0.3.0: the prompt holds no hub text; the hub's pane text (PANES.md) gives the command.
    t = read(os.path.join(ROOT, "prompt", "PANES.md"))
    ls = t.splitlines()
    first = next((i for i, ln in enumerate(ls) if "hubflow" in ln), None)
    check("t31c4 PANES.md uses hubflow", first is not None, "never")
    if first is None:
        return
    win = " ".join(ls[first: first + 3])
    check("t31c4 first use of hubflow in PANES.md gives python3 .claude/scripts/hubflow.py",
          "python3 .claude/scripts/hubflow.py" in win, win[:200])


def t31c5():
    with tempfile.TemporaryDirectory() as d:
        os.makedirs(os.path.join(d, "specs"))
        os.makedirs(os.path.join(d, "flow"))
        open(os.path.join(d, "flow", "seed.json"), "w").write("{}")
        p = okb(["show", "open"], d)
        out = p.stdout + p.stderr
        check("t31c5 show open with no KB exits 2", p.returncode == 2, f"exit {p.returncode}")
        check("t31c5 the hint names specs/<slug>/", "specs/<slug>/" in out, out[-300:])
        check("t31c5 the hint names hubflow where SLUG", "hubflow where SLUG" in out, out[-300:])


LAND = os.environ.get("LAND_CHECK", "/home/ty/Projects/mine/sagittarius/tmp/hub-design-kb/land_check.sh")
LISTED = ("check_hub_guidance.py", "check_informal_release.py", "check_words.py", "check_hub_fixes.py")


def t31c6():
    land = read(LAND)
    check("t31c6 land_check.sh exists", bool(land), LAND)
    for n in LISTED:
        check(f"t31c6 land_check.sh names {n}", n in land, "missing")
    check("t31c6 land_check.sh asks each script for its ids with --list", "--list" in land, "no --list")
    for n in LISTED:
        p = subprocess.run([sys.executable, os.path.join(ROOT, "docs", n), "--list"], capture_output=True, text=True)
        ids = p.stdout.split()
        check(f"t31c6 {n} --list prints its claim ids", p.returncode == 0 and len(ids) >= 3, f"exit {p.returncode}: {p.stdout[:100]}{p.stderr[:100]}")
        want = {"check_hub_guidance.py": 12, "check_informal_release.py": 6, "check_words.py": 3}.get(n)
        if want:
            check(f"t31c6 {n} --list prints {want} ids", len(ids) == want, ids)
    p = subprocess.run(["bash", "-n", LAND], capture_output=True, text=True)
    check("t31c6 land_check.sh parses", p.returncode == 0, p.stderr)


def t31c7():
    t = read(os.path.join(ROOT, "kb", "share", "orbit-kb", "help", "core.txt"))
    w = re.sub(r"\s+", " ", t)
    check("t31c7 core help no longer says the human never has to read formal text",
          "never has to read formal text" not in w, "old phrase present")
    check("t31c7 core help says the shifted-up human reads and reviews the formal text",
          re.search(r"shifted up, the human reads and reviews the formal text too, so write it to be read", w) is not None,
          "wording missing")


def flat(p):
    return re.sub(r"\s+", " ", read(os.path.join(ROOT, *p.split("/")))).lower()


def t31c8():
    core = flat("kb/share/orbit-kb/help/core.txt")
    check("t31c8 core help no longer says the human never has to read formal text",
          "never has to read formal text" not in core, "old phrase present")
    for p in ("prompt/SAGITTARIUS.md", "docs/PHILOSOPHY.md", "kb/share/orbit-kb/help/core.txt"):
        w = flat(p)
        check(f"t31c8 {p} names the human, the agent and the CPU",
              re.search(r"the human, the agent,? and the cpu all use the formal language as the shared substrate", w) is not None,
              "wording missing")
        check(f"t31c8 {p} says the human reads, reviews and understands it",
              re.search(r"the human reads, reviews,? and understands it", w) is not None, "wording missing")
        check(f"t31c8 {p} keeps 'write it to be read'", "write it to be read" in w, "missing")


def t31c9():
    w = flat("prompt/SAGITTARIUS.md")
    i = w.find("## the hypothesis")
    j = w.find("## signals", i + 1)
    para = w[i:j] if i >= 0 and j > i else ""
    check("t31c9 the hypothesis section is found", bool(para), "missing")
    check("t31c9 err-soft names hypotheses, premises and claims",
          re.search(r"err toward the general and soft in [^.]*\bhypothes[^.]*\bpremises[^.]*\bclaims", para) is not None, para[-400:])
    check("t31c9 oscillation is an intentional heuristic", "oscillation is an intentional heuristic" in para, para[-300:])


def t46c2():
    # T46 c2: the automatic record of a dropped edit (T45) runs in the session of HUB_SESSION; help project
    # says, next to the auto record, how a pane gets it, and so does the session setup of the hub kit.
    hp = re.sub(r"\s+", " ", read(os.path.join(ROOT, "kb", "share", "orbit-kb", "help", "project.txt")))
    i = hp.find("record each new drop in the hub ledger themselves")
    check("t46c2 help project states the auto record", i >= 0, "phrase missing")
    near = hp[max(0, i - 300):i + 900] if i >= 0 else ""
    check("t46c2 help project names HUB_SESSION next to the auto record", "HUB_SESSION" in near, near[:300])
    check("t46c2 help project says how a pane gets HUB_SESSION (set where it is started: HUB_SESSION=NAME claude)",
          re.search(r"HUB_SESSION=\S+ claude", near) is not None, near[:300])
    check("t46c2 help project says that with no session the record is refused with a warning",
          re.search(r"no HUB_SESSION.{0,200}warn", near, re.I) is not None, near[:300])
    ins = read(os.path.join(ROOT, "hubkit", "INSTRUCTIONS.md"))
    m = re.search(r"^## Step 5[^\n]*\n(.*?)(?=^## )", ins, re.S | re.M)
    step5 = re.sub(r"\s+", " ", m.group(1)) if m else ""
    check("t46c2 INSTRUCTIONS.md has Step 5 (sessions)", bool(step5), "missing")
    check("t46c2 INSTRUCTIONS.md Step 5 says orbit-kb records a dropped edit in the session of HUB_SESSION",
          "orbit-kb" in step5 and "dropped edit" in step5 and "HUB_SESSION" in step5, step5[-400:])
    t46_core()


def t46_core():
    core = read(os.path.join(HUB, "HUB-CORE.md"))
    m = re.search(r"^## Flow state lives in the db\n(.*?)(?=^## )", core, re.S | re.M)
    flow = re.sub(r"\s+", " ", m.group(1)) if m else ""
    check("t46c2 HUB-CORE.md (flow state) says orbit-kb records a dropped edit in the session of HUB_SESSION",
          "orbit-kb" in flow and "dropped edit" in flow and "HUB_SESSION" in flow, flow[:400])



def t46c3():
    # T46 c3 supersedes c2: t32c2 (docs/check_informal_hub.py) bans formal words such as orbit-kb outside
    # "The formal edition" of INSTRUCTIONS.md, so the session setup says it there, and Step 5 points to it.
    hp = re.sub(r"\s+", " ", read(os.path.join(ROOT, "kb", "share", "orbit-kb", "help", "project.txt")))
    i = hp.find("record each new drop in the hub ledger themselves")
    check("t46c3 help project states the auto record", i >= 0, "phrase missing")
    near = hp[max(0, i - 300):i + 900] if i >= 0 else ""
    check("t46c3 help project names HUB_SESSION next to the auto record", "HUB_SESSION" in near, near[:300])
    check("t46c3 help project says how a pane gets HUB_SESSION (set where it is started: HUB_SESSION=NAME claude)",
          re.search(r"HUB_SESSION=\S+ claude", near) is not None, near[:300])
    check("t46c3 help project says that with no session the record is refused with a warning",
          re.search(r"no HUB_SESSION.{0,200}warn", near, re.I) is not None, near[:300])
    ins = read(os.path.join(ROOT, "hubkit", "INSTRUCTIONS.md"))
    m = re.search(r"^## Step 5[^\n]*\n(.*?)(?=^## )", ins, re.S | re.M)
    step5 = re.sub(r"\s+", " ", m.group(1)) if m else ""
    check("t46c3 INSTRUCTIONS.md Step 5 points to The formal edition for the writes of a formal hub",
          "The formal edition" in step5 and "HUB_SESSION" in step5, step5[-400:])
    m = re.search(r"^## The formal edition\n(.*?)(?=^## |\Z)", ins, re.S | re.M)
    formal = re.sub(r"\s+", " ", m.group(1)) if m else ""
    check("t46c3 INSTRUCTIONS.md (The formal edition) says orbit-kb records a dropped edit in the session of HUB_SESSION, "
          "set where the pane is started (Step 5), and warns without it",
          all(w in formal for w in ("orbit-kb", "dropped edit", "HUB_SESSION", "Step 5", "warn")), formal[-500:])
    t46_core()


T49C1_TEXT = ("The raw material of each week: meeting and other human transcripts, Claude Code session logs, and the "
              "reports written that week. An agent reads a human transcript and records what is needed in the ledger, "
              "with a transcript ref; Claude Code session logs are indexed into the ledger; analyses that last go to "
              "the project KB.")


def t49c1():
    core = read(os.path.join(HUB, "HUB-CORE.md"))
    m = re.search(r"^## What lives where\n(.*?)(?=^## )", core, re.S | re.M)
    sec = m.group(1) if m else ""
    check("t49c1 HUB-CORE.md has the What lives where section", bool(sec), "missing")
    rows = [l for l in sec.splitlines() if l.startswith("| `weeks` |")]
    check("t49c1 the formal weeks row is found", len(rows) == 1, rows)
    row = rows[0] if rows else ""
    check("t49c1 the weeks row names human transcripts", "human transcripts" in row, row[:300])
    check("t49c1 the weeks row names Claude Code session logs", "Claude Code session logs" in row, row[:300])
    check("t49c1 the weeks row has the design KB text word for word", T49C1_TEXT in row, row[:400])
    p = subprocess.run([sys.executable, os.path.join(ROOT, "hubkit", "tools", "storemap.py"), "--check"],
                       capture_output=True, text=True)
    check("t49c1 storemap --check passes", p.returncode == 0, p.stdout[-200:] + p.stderr[-200:])


def t51c5():
    ins = read(os.path.join(ROOT, "hubkit", "INSTRUCTIONS.md"))
    lines = [l for l in ins.splitlines() if l.startswith("docs/index.html")]
    check("t51c5 INSTRUCTIONS lists docs/index.html", len(lines) == 1, lines)
    check("t51c5 nothing says the briefing is published as the repo's site", "published as the repo" not in ins,
          [l for l in ins.splitlines() if "published as the repo" in l])


# ---- install UX (discovery GO 2026-11-11) ----
CO_HUB = re.compile(r"prompt/(PANES|SAGITTARIUS)\.md|(?<!orbit-)kb/bin/|(?<!orbit-)kb/share/|kb/tests/|hubkit/|docs/[A-Z]+\.md|site/")
HUBKIT = os.path.join(ROOT, "hubkit", "tools", "hubkit.py")


def ins_sections():
    ins = read(os.path.join(ROOT, "hubkit", "INSTRUCTIONS.md"))
    return ins, {m.group(1): m.group(2) for m in re.finditer(r"^## ([^\n]+)\n(.*?)(?=^## |\Z)", ins, re.M | re.S)}


def sec_of(secs, prefix):
    return next((v for k, v in secs.items() if k.startswith(prefix)), "")


def iuxc1():
    ins, secs = ins_sections()
    s1 = sec_of(secs, "Step 1")
    check("iuxc1 INSTRUCTIONS has Step 1", bool(s1), "missing")
    qs = re.findall(r"^(\d+)\. (.*(?:\n   .*)*)", s1, re.M)
    first = qs[0][1] if qs else ""
    check("iuxc1 the first question of step 1 asks what the hub is for", re.search(r"what is this hub for", first, re.I) is not None, first[:200])
    check("iuxc1 step 1 says the answer is kept word for word", "word for word" in re.sub(r"\s+", " ", s1), s1[:300])
    check("iuxc1 step 1 allows more than three questions as a cold-start allowance, at setup only",
          "cold-start allowance" in re.sub(r"\s+", " ", s1) and "three questions" not in [h for h in secs if h.startswith("Step 1")][0], list(secs)[:4])
    s2 = re.sub(r"\s+", " ", sec_of(secs, "Step 2"))
    check("iuxc1 step 2 writes answer 1 word for word under What this hub is for in CLAUDE.md",
          "What this hub is for" in s2 and "word for word" in s2 and "CLAUDE.md" in s2, s2[:300])
    for rel in ("hubkit/hub/CLAUDE.md", "hubkit/editions/informal/CLAUDE.md"):
        cl = read(os.path.join(ROOT, rel))
        imports = cl.find("\n@")
        at = cl.find("\n## What this hub is for\n")
        others = [m.start() for m in re.finditer(r"^## ", cl, re.M)]
        check(f"iuxc1 {rel} has the section What this hub is for, the first section", at >= 0 and others and others[0] == at + 1 and at > imports, (at, others[:2]))
    kit = json.loads(read(os.path.join(ROOT, "hubkit", "kit.json")) or "{}")
    check("iuxc1 CLAUDE.md is an owned file (an upgrade never writes it)", "CLAUDE.md" in kit.get("owned", []), kit.get("owned"))
    formal = re.sub(r"\s+", " ", sec_of(secs, "The formal edition"))
    check("iuxc1 The formal edition: the project KB request is answer 1 of step 1, word for word",
          re.search(r"init project-kb --request '<answer 1 of step 1, word for word>'", formal) is not None, formal[:400])


def iuxc3k():
    ins, secs = ins_sections()
    lines = []
    for f in ("INSTRUCTIONS.md", "README.md"):
        for ln in read(os.path.join(ROOT, "hubkit", f)).splitlines():
            for m in re.finditer(r"`(\.claude/orbit-kb/bin/orbit-kb init project-kb[^`]*)`", ln):
                lines.append((f, m.group(1)))
    check("iuxc3k INSTRUCTIONS.md gives the setup line with the hub's own orbit-kb", any(f == "INSTRUCTIONS.md" for f, _ in lines), "no line")
    with tempfile.TemporaryDirectory(prefix="iuxc3k-") as t:
        for n, (f, cmd) in enumerate(lines):
            hub = os.path.join(t, f"hub{n}")
            p = subprocess.run([sys.executable, "-I", HUBKIT, "install", "--hub", hub, "--edition", "formal"], capture_output=True, text=True)
            check(f"iuxc3k install a formal hub for {f}", p.returncode == 0, p.stderr[-200:])
            run = re.sub(r"'?<[^>]*>'?|'?\bTEXT\b'?", "'a request'", cmd)
            env = {k: v for k, v in os.environ.items() if k not in ("ORBIT_KB_LIB", "ORBIT_KB")}
            env["PATH"] = os.pathsep.join(os.path.dirname(x) for x in (shutil.which("swipl"), shutil.which("env")) if x)
            try:
                q = subprocess.run(shlex.split(run), cwd=hub, env=env, capture_output=True, text=True, timeout=120)
                rc, err = q.returncode, q.stderr
            except OSError as e:
                rc, err = None, repr(e)
            check(f"iuxc3k {f}: `{cmd}` exits 0 at the root of a new formal hub, with no orbit-kb on PATH", rc == 0 and os.path.isfile(os.path.join(hub, "project-kb", "kb.pl")), f"exit {rc}: {err.strip()[:200]}")
    bare = []
    texts = {"hubkit/INSTRUCTIONS.md": read(os.path.join(ROOT, "hubkit", "INSTRUCTIONS.md"))}
    for dp, dn, fn in os.walk(HUB):
        for n in fn:
            if n.endswith(".md"):
                texts[os.path.relpath(os.path.join(dp, n), ROOT)] = read(os.path.join(dp, n))
    texts["hubkit/tools/storemap.py"] = read(os.path.join(ROOT, "hubkit", "tools", "storemap.py"))
    for rel, text in texts.items():
        for i, ln in enumerate(text.splitlines()):
            for m in re.finditer(r"`orbit-kb (?!\w+`)[a-z][^`]*`|`orbit-kb (help|lint|query|show|init|add|attest|run|pin-item|draft|serve|release)\b[^`]*`", ln):
                bare.append(f"{rel}:{i + 1}: {m.group(0)}")
    check("iuxc3k no hub text gives a bare `orbit-kb ...` command (it would run the one on PATH)", not bare, bare[:6])
    t31c2(co=CO_HUB, prefix="iuxc3k (t31c2 scan)")
    check("iuxc3k the scan still flags the checkout path kb/bin/repo-map", CO_HUB.search("run `kb/bin/repo-map` here") is not None, "not flagged")
    check("iuxc3k the scan reads .claude/orbit-kb/bin/ as a hub path", CO_HUB.search("run `.claude/orbit-kb/bin/orbit-kb help`") is None, "flagged")
    for txt in ("~/sagittarius/kb/bin/orbit-kb", "../kb/bin/repo-map", "sagittarius/kb/share/orbit-kb"):  # review of 4756916
        check(f"iuxc3k the scan still flags the checkout path {txt}", CO_HUB.search(f"run `{txt}` here") is not None, "not flagged")
    check("iuxc3k the scan reads .claude/orbit-kb/share/ as a hub path", CO_HUB.search("see `.claude/orbit-kb/share/orbit-kb/help`") is None, "flagged")


def iuxc6():
    ins, secs = ins_sections()
    steps = {k: v for k, v in secs.items() if re.match(r"Step \d", k)}
    for k, v in steps.items():
        if "-test.py" in v:
            check(f"iuxc6 {k}: a step that runs a test suite is the UAT step", "UAT" in k, k)
    uat = [(k, v) for k, v in steps.items() if "UAT" in k]
    check("iuxc6 one step is for UAT installs only", len(uat) == 1, list(steps))
    if uat:
        k, v = uat[0]
        w = re.sub(r"\s+", " ", v)
        check("iuxc6 the UAT step runs the plain suite and the mutants", "hubflow-test.py" in w and "--mutants" in w, w[:300])
        check("iuxc6 the UAT step says they test the kit itself", "test the kit" in w.lower(), w[:300])
        check("iuxc6 the UAT step says a normal install skips it", "normal install" in w.lower() and "skip" in w.lower(), w[:300])
    s1 = sec_of(secs, "Step 1")
    check("iuxc6 step 1 asks whether this is a UAT install, default no", re.search(r"UAT install.*Default: no", re.sub(r"\s+", " ", s1)) is not None, s1[-400:])
    check("iuxc6 step 2 records a UAT install with --uat", "--uat" in sec_of(secs, "Step 2"), "missing")
    last = sec_of(secs, "Step 7")
    w7 = re.sub(r"\s+", " ", last)
    for cmd in ("hubkit.py status", "hubflow.py check"):
        m = re.search(re.escape(cmd) + r"[^.]*?\.?`?[^.]*?\b(shows|tells) you\b", w7)
        check(f"iuxc6 step 7 ends the install with {cmd} and a one-line reason for the user", m is not None, w7[:500])
    rd = read(os.path.join(ROOT, "hubkit", "README.md"))
    inst = re.search(r"^## Install\n(.*?)(?=^## )", rd, re.M | re.S)
    block = re.findall(r"```sh\n(.*?)```", inst.group(1) if inst else "", re.S)
    check("iuxc6 the README install block runs no test suite", block and "-test.py" not in block[0], block)
    check("iuxc6 the README install block ends with hubkit status and hubflow check", block and
          [ln for ln in block[0].strip().splitlines()][-2:] and "status" in block[0].strip().splitlines()[-2] and block[0].strip().splitlines()[-1].endswith("check"), block)
    h = subprocess.run([sys.executable, "-I", HUBKIT, "--help"], capture_output=True, text=True)
    check("iuxc6 hubkit.py --help names --uat", "--uat" in h.stdout, h.stdout[:200])


def iuxc6u():
    up = read(os.path.join(ROOT, "hubkit", "UPGRADING.md"))
    m = re.search(r"^## The procedure[^\n]*\n(.*?)(?=^## )", up, re.M | re.S)
    proc = m.group(1) if m else ""
    check("iuxc6u UPGRADING.md has The procedure", bool(proc), "missing")
    steps = {int(n): re.sub(r"\s+", " ", body) for n, body in re.findall(r"^(\d+)\. (.*?)(?=^\d+\. |^\S|\Z)", proc, re.M | re.S)}
    tests = {n: w for n, w in steps.items() if "-test.py" in w}
    check("iuxc6u one step of the procedure runs the test suites", len(tests) == 1, sorted(tests))
    for n, w in tests.items():
        # the sentence that runs the suites names the UAT condition
        for sent in re.split(r"(?<=\.) ", w):
            if "-test.py" in sent:
                check(f"iuxc6u step {n}: the suites run only for a UAT upgrade (\"uat\": true)",
                      "UAT" in sent and '"uat": true' in w, sent[:300])
        check(f"iuxc6u step {n} runs the plain suite and the mutants", "hubflow-test.py" in w and "--mutants" in w, w[:300])
        check(f"iuxc6u step {n} says they test the kit", "test the kit" in w.lower(), w[:300])
        check(f"iuxc6u step {n} says a normal upgrade skips them", "normal upgrade" in w.lower() and "skip" in w.lower(), w[:300])
    w7 = steps.get(7, "")
    for cmd in ("hubkit.py status", "hubflow.py check"):
        m = re.search(re.escape(cmd) + r"[^.]*?\.?`?[^.]*?\b(shows|tells) you\b", w7)
        check(f"iuxc6u step 7 ends a normal upgrade with {cmd} and a one-line reason", m is not None, w7[:500])


def m030d1():
    ins, secs = ins_sections()
    formal = secs.get("The formal edition", "")
    lines = [ln.strip() for ln in formal.splitlines() if re.search(r"HUB_SESSION=\S+ (command )?claude[^\n]*--append-system-prompt", ln)]
    start = [ln for ln in lines if "--name" in ln]
    check("m030d1 The formal edition gives one launcher line that sets HUB_SESSION and appends the prompt", len(start) == 1, lines)
    w = re.sub(r"\s+", " ", formal)
    check("m030d1 the step checks that the pane can say the last line of its prompt", re.search(r"last line", w) is not None, w[-400:])
    for ln in lines:
        check("m030d1 the launcher appends the prompt, PANES.md and the role file",
              all(x in ln for x in ("SAGITTARIUS.md", "PANES.md", "panes/<name>.md")), ln)
    check("m030d1 the formal edition gives the launcher once (no second, resume line)", len(lines) == 1, lines)
    every = [ln.strip() for ln in ins.splitlines() if "--append-system-prompt" in ln]
    check("m030d1 INSTRUCTIONS.md holds one launcher line in all", len(every) == 1, every)
    check("m030d1 the formal edition says how to resume: the same line with --resume in place of --name",
          re.search(r'`--resume "hub-<name>"` in place of `--name "hub-<name>"`', w) is not None, w[-600:])
    rd = read(os.path.join(ROOT, "README.md"))
    pm = re.search(r"^## Panes\n(.*?)(?=^## )", rd, re.M | re.S)
    panes = pm.group(1) if pm else ""
    rl = [ln.strip() for ln in panes.splitlines() if "claude" in ln and ("--append-system-prompt" in ln or "--name" in ln)]
    check("m030d1 README.md Panes gives the launcher line of INSTRUCTIONS.md, character for character", start and rl == start[:1], (rl, start[:1]))
    check("m030d1 README.md Panes keeps: command claude, or the full path of the binary",
          "command claude" in panes and "full path of the binary" in re.sub(r"\s+", " ", panes), panes[-300:])
    pan = re.sub(r"\s+", " ", read(os.path.join(ROOT, "prompt", "PANES.md")))
    check("m030d1 PANES.md names no tmux session (the launcher names the session hub-<name>; review finding 12)",
          re.search(r"tmux session|`sagit`", pan) is None, pan[:300])
    check("m030d1 PANES.md does not take the role from a window line that the launcher does not give",
          "name of your window" not in pan, pan[:300])
    if len(start) != 1:
        return
    with tempfile.TemporaryDirectory(prefix="m030d1-") as t:
        home, hub, stub = (os.path.join(t, x) for x in ("home", "hub", "bin"))
        pdir = os.path.join(home, ".claude", "sagittarius")
        os.makedirs(os.path.join(pdir, "panes"))
        os.makedirs(hub)
        os.makedirs(stub)
        for rel, txt in (("SAGITTARIUS.md", "PROMPT-TEXT\nThis is Sagittarius 9.9.9 (test).\n"), ("PANES.md", "PANES-TEXT\n"),
                         ("panes/build.md", "ROLE-BUILD-TEXT\n"), ("panes/review.md", "ROLE-REVIEW-TEXT\n")):
            with open(os.path.join(pdir, rel), "w") as f:
                f.write(txt)
        out = os.path.join(t, "got.json")
        with open(os.path.join(stub, "claude"), "w") as f:
            f.write("#!%s\nimport json, os, sys\njson.dump({'s': os.environ.get('HUB_SESSION'), 'cwd': os.getcwd(), 'a': sys.argv[1:]}, open(%r, 'w'))\n"
                    % (sys.executable, out))
        os.chmod(os.path.join(stub, "claude"), 0o755)
        cmd = start[0].replace("<name>", "build")
        env = dict(os.environ, HOME=home, HUB=hub, PATH=stub + os.pathsep + os.environ.get("PATH", ""))
        p = subprocess.run(["sh", "-c", cmd], env=env, capture_output=True, text=True, timeout=30)
        got = json.loads(read(out) or "{}")
        check("m030d1 the launcher line runs", p.returncode == 0 and bool(got), (p.returncode, p.stderr[-200:]))
        a = got.get("a", [])
        app = a[a.index("--append-system-prompt") + 1] if "--append-system-prompt" in a[:-1] else ""
        check("m030d1 the pane gets HUB_SESSION and the hub as cwd", got.get("s") == "build" and os.path.realpath(got.get("cwd", "")) == os.path.realpath(hub), got)
        i = [app.find(x) for x in ("PROMPT-TEXT", "PANES-TEXT", "ROLE-BUILD-TEXT")]
        check("m030d1 the appended text is the prompt, then PANES.md, then the role file", -1 not in i and i == sorted(i), app[:200])
        check("m030d1 the appended text holds the last line of the prompt", "This is Sagittarius 9.9.9" in app, app[-200:])
        check("m030d1 the appended text holds no other role file", "ROLE-REVIEW-TEXT" not in app, app[-200:])


def m030d3():
    pr = read(os.path.join(ROOT, "prompt", "SAGITTARIUS.md"))
    last = [ln for ln in pr.splitlines() if ln.strip()][-1:]
    m = re.search(r"Sagittarius (\d+)\.(\d+)\.\d+", last[0]) if last else None
    check("m030d3 the last line of the prompt names its version", m is not None, last)
    if not m:
        return
    mm = f"{m.group(1)}.{m.group(2)}"
    for rel in ("README.md", "UPGRADING.md"):
        t = re.sub(r"\s+", " ", read(os.path.join(ROOT, "hubkit", rel)))
        check(f"m030d3 hubkit/{rel} says that the kit pairs with Sagittarius {mm}",
              re.search(r"pairs with Sagittarius " + re.escape(mm) + r"\b", t) is not None, "missing")
        other = [x for x in re.findall(r"pairs with Sagittarius (\d+\.\d+)\b", t) if x != mm]
        check(f"m030d3 hubkit/{rel} names no other Sagittarius version as the pair", not other, other)


def git(*args):
    return subprocess.run(["git"] + list(args), cwd=ROOT, capture_output=True, text=True)


# The names are split so this file does not name them itself (t50c1 scans every tracked file).
T50_GONE = ("si" "te/index.html", "si" "te/essentials.html", "build_" "essentials", "check_" "essentials",
            "si" "te/check_names.sh", "pages" ".yml")
T50_PATHS = ("si" "te", ".github/workflows/pages" ".yml")


def t50c1():
    for p in T50_PATHS:
        check(f"t50c1 {p} is not on disk", not os.path.exists(os.path.join(ROOT, p)), "present")
        g = git("ls-files", "--", p)
        check(f"t50c1 {p} is not tracked", g.returncode == 0 and not g.stdout.strip(), g.stdout[:200] + g.stderr[:200])
    for name in T50_GONE:
        g = git("grep", "-n", "-F", name, "--", ".", ":!tmp")
        check(f"t50c1 no tracked file outside tmp/ names {name}", g.returncode == 1, g.stdout[:300] + g.stderr[:200])


def t50c2():
    deck = re.compile(r"\bsite/|github\.io|\bdecks?\b|\bslides?\b", re.I)
    for p in ("README.md", "CLAUDE.md", "docs/PHILOSOPHY.md"):
        for i, ln in enumerate(read(os.path.join(ROOT, *p.split("/"))).splitlines(), 1):
            m = deck.search(ln)
            check(f"t50c2 {p}:{i} does not point at the decks", m is None, ln.strip())
    claude = read(os.path.join(ROOT, "CLAUDE.md"))
    check("t50c2 CLAUDE.md has no Decks row", "| Decks |" not in claude, "row present")


def t50c4():
    p = os.path.join(ROOT, "hubkit", "docs", "index.html")
    check("t50c4 hubkit/docs/index.html is on disk", os.path.isfile(p), "missing")
    g = git("ls-files", "--", "hubkit/docs/index.html")
    check("t50c4 hubkit/docs/index.html is tracked", g.stdout.strip() == "hubkit/docs/index.html", g.stdout + g.stderr)
    check("t50c4 the briefing is the hubkit briefing", "hubflow-starter" not in read(p) and "mindhole" in read(p).lower(),
          read(p)[:200])
    ins = read(os.path.join(ROOT, "hubkit", "INSTRUCTIONS.md"))
    m = re.search(r"^## Step 1[^\n]*\n(.*?)(?=^## )", ins, re.S | re.M)
    step1 = m.group(1) if m else ""
    check("t50c4 Step 1 of hubkit/INSTRUCTIONS.md opens docs/index.html", "`docs/index.html`" in step1, step1[:300])


# t46c2 is superseded by t46c3: its Step 5 check conflicts with t32c2. It stays above as the record.
# t31c7 is superseded by t31c8 (u47): its second check pinned the T29 wording, which u47 says is too narrow.
# The function stays above as the record. It is no longer a claim of this file.
# t31c1 and t31c2 are superseded by iuxc3k (install UX c3): the setup line runs the hub's own orbit-kb at
# .claude/orbit-kb/bin/orbit-kb, which the t31c1 pattern does not match and the t31c2 scan reads as the checkout's
# kb/bin/. Both functions stay above as the record; iuxc3k reruns the t31c2 scan with the narrower pattern.
CLAIMS = {k: globals()[k] for k in ("t31c3", "t31c4", "t31c5", "t31c6", "t31c8", "t31c9", "t46c3", "t49c1", "t50c1", "t50c2", "t50c4", "t51c5",
                                      "iuxc1", "iuxc3k", "iuxc6", "iuxc6u", "m030d1", "m030d3")}

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
