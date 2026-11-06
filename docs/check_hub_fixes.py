#!/usr/bin/env python3
"""T31: an agent in a hub can run what the hub guidance tells it. One check per claim.

usage: python3 docs/check_hub_fixes.py t31c1|...|t31c9 (t31c7 is superseded by t31c8) [--list]   (--list prints the claim ids)
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


# t31c7 is superseded by t31c8 (u47): its second check pinned the T29 wording, which u47 says is too narrow.
# The function stays above as the record. It is no longer a claim of this file.
CLAIMS = {k: globals()[k] for k in ("t31c1", "t31c2", "t31c3", "t31c4", "t31c5", "t31c6", "t31c8", "t31c9")}

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
