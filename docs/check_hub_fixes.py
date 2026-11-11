#!/usr/bin/env python3
"""T31: an agent in a hub can run what the hub guidance tells it. One check per claim.

usage: python3 docs/check_hub_fixes.py t31c1|...|t31c9|t46c3|t49c1|t50c1|t50c2|t50c4 (t31c7 is superseded by t31c8, t46c2 by t46c3) [--list]   (--list prints the claim ids)
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
t50c1 (retire) the repo has no microsite: neither the deck directory nor the Pages workflow is in the tree, and no
      tracked file outside tmp/ names the deck files, their build and check scripts, or the workflow.
t50c2 (retire) README.md, CLAUDE.md and docs/PHILOSOPHY.md do not point at the decks.
t50c4 (preserve) hubkit/docs/index.html stays: the local briefing that step 1 of hubkit/INSTRUCTIONS.md opens.
"""
import os
import re
import shlex
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


CO = re.compile(r"prompt/(PANES|SAGITTARIUS)\.md|kb/bin/|kb/share/|kb/tests/|hubkit/|docs/[A-Z]+\.md|site/")
PLACE = re.compile(r"checkout|Sagittarius repository|installed|on PATH|on your PATH", re.I)


def t31c2():
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
                m = CO.search(ln)
                if not m:
                    continue
                win = " ".join(ls[max(0, i - 2): i + 3])
                ok = bool(PLACE.search(win)) or (ln.startswith("Source:") and "Sagittarius repository" in whole)
                check(f"t31c2 {os.path.relpath(p, HUB)}:{i + 1} `{m.group(0)}` is placed", ok, ln.strip())


def t31c3():
    t = read(os.path.join(HUB, ".claude", "skills", "hub-rotate", "SKILL.md"))
    i = t.find("is it durable?")
    sec = re.sub(r"\s+", " ", t[i:i + 700]).lower()
    check("t31c3 hub-rotate durable step exists", i >= 0, "missing")
    check("t31c3 the durable step promotes to the project KB", "project kb" in sec, sec[:200])


def t31c4():
    t = read(os.path.join(ROOT, "prompt", "SAGITTARIUS.md"))
    ls = t.splitlines()
    first = next((i for i, ln in enumerate(ls) if "hubflow" in ln), None)
    check("t31c4 prompt uses hubflow", first is not None, "never")
    if first is None:
        return
    win = " ".join(ls[first: first + 3])
    check("t31c4 first use of hubflow gives python3 .claude/scripts/hubflow.py",
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
    i = w.find("**the hypothesis.**")
    j = w.find("**the vote.**")
    para = w[i:j] if i >= 0 and j > i else ""
    check("t31c9 the hypothesis paragraph is found", bool(para), "missing")
    check("t31c9 err-soft names hypotheses, premises and claims",
          re.search(r"err toward the general and soft in [^.]*\bhypothes[^.]*\bpremises[^.]*\bclaims", para) is not None, para[-400:])
    check("t31c9 oscillation is an intentional heuristic", "oscillation is an intentional heuristic" in para, para[-300:])
    check("t31c9 the prompt stays within 230 lines", len(read(os.path.join(ROOT, "prompt", "SAGITTARIUS.md")).splitlines()) <= 230, "too long")


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
    check("t50c4 the briefing is the hubkit briefing", "hubflow-starter" not in read(p) and "hub kit" in read(p).lower(),
          read(p)[:200])
    ins = read(os.path.join(ROOT, "hubkit", "INSTRUCTIONS.md"))
    m = re.search(r"^## Step 1[^\n]*\n(.*?)(?=^## )", ins, re.S | re.M)
    step1 = m.group(1) if m else ""
    check("t50c4 Step 1 of hubkit/INSTRUCTIONS.md opens docs/index.html", "`docs/index.html`" in step1, step1[:300])


# t46c2 is superseded by t46c3: its Step 5 check conflicts with t32c2. It stays above as the record.
# t31c7 is superseded by t31c8 (u47): its second check pinned the T29 wording, which u47 says is too narrow.
# The function stays above as the record. It is no longer a claim of this file.
CLAIMS = {k: globals()[k] for k in ("t31c1", "t31c2", "t31c3", "t31c4", "t31c5", "t31c6", "t31c8", "t31c9", "t46c3", "t49c1", "t50c1", "t50c2", "t50c4")}

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
