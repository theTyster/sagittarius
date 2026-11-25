#!/usr/bin/env python3
"""Black-box tests of strike, replace and erase (spec KB kb-crud: c1 to c4, c6). Usage: kb_crud.py ORBIT_KB.
Each test is one scratch KB. Exit 0 when all pass."""
import os
import re
import subprocess
import sys
import tempfile

OK = os.path.abspath(sys.argv[1])
ENV = dict(os.environ, HUB_SESSION="kb-crud-test")
ENV.pop("ORBIT_KB_WRITER", None)
FAILS = []
PASSED = 0


def run(d, *args):
    r = subprocess.run([OK, "--dir", d, *args], capture_output=True, text=True, env=ENV)
    return r.returncode, r.stdout + r.stderr


def fixture(extra=()):
    d = os.path.join(tempfile.mkdtemp(prefix="kbcrud-"), "kb")
    subprocess.run([OK, "init", d, "--request", "fixture", "--uses", "discovery"], capture_output=True, env=ENV, check=True)
    facts = ["goal(g1, feature, agent, 'fixture goal')", "no_premises(g1)", "claim(c1, introduce, 'fixture claim')",
             "cites(c1, 'the request')", "example(c1, 'case')", "example(c1, 'second case')", "check(k1, c1)",
             "checks_that(k1, 'old check')", "check(k2, c1)", "checks_that(k2, 'new check')",
             "question(q1, g1, 'a question')", "option(q1, 'A', 'a')", "option(q1, 'B', 'b')",
             "question(q2, g1, 'a typo question')", "option(q2, 'A', 'a')",
             "finding(f1, trace('a finding'), system)", *extra]
    code, out = run(d, "add", *facts)
    assert code == 0, out[-500:]
    return d


def text(d):
    return open(os.path.join(d, "kb.pl")).read()


def ck(name, ok, detail=""):
    global PASSED
    if ok:
        PASSED += 1
        print("PASS " + name)
    else:
        FAILS.append(name)
        print("FAIL %s %s" % (name, str(detail)[-400:]))


def opens(d):
    return run(d, "show", "open")[1]


def lint_clean(d):
    code, out = run(d, "lint")
    return "0 error(s)" in out, out


def t_supersede_every_kind():
    d = fixture(["premise(p1, g1, 'a premise')", "premise(p2, g1, 'another')", "signal(s1, handoff, agent, 'x')",
                 "signal(s2, handoff, agent, 'y')", "finding(f2, trace('b'), system)"])
    for old, new, fact in [("k1", "k3", "check(k3, c1)"), ("q1", "q3", "question(q3, g1, 'new q')"),
                           ("f1", "f2", None), ("p1", "p2", None), ("s1", "s2", None)]:
        if fact:
            code, out = run(d, "add", fact, *(["checks_that(k3, 'a new check')"] if new == "k3" else []))
            ck("add " + new, code == 0, out)
        code, out = run(d, "add", "supersedes(%s, %s)" % (new, old))
        ck("supersedes %s -> %s accepted" % (new, old), code == 0, out)
    o = opens(d)
    ck("superseded k1, q1 are not in show open", not re.search(r"\b(k1|q1)\b", o), o)
    code, out = run(d, "add", "supersedes(k1, q1)")
    ck("supersedes of two kinds is refused", code != 0 and "E4" in out, out)
    ck("lint has no error", lint_clean(d)[0], lint_clean(d)[1])
    code, out = run(d, "add", "supersedes(c1, k2)")
    ck("a claim cannot replace a check", code != 0, out)


def t_strike():
    d = fixture()
    code, out = run(d, "strike", "q1", "--why", "no longer asked")
    ck("strike q1 exits 0", code == 0, out)
    ck("q1 is not in show open", not re.search(r"\bq1\b", opens(d)), opens(d))
    ck("question(q1 stays in kb.pl", "question(q1," in text(d))
    ck("the report names it struck, with who and why", re.search(r"q1 struck by agent at \S+: no longer asked", run(d, "report")[1]))
    ck("lint has no error", lint_clean(d)[0], lint_clean(d)[1])
    code, out = run(d, "strike", "q1", "--why", "again")
    ck("a struck record cannot be struck twice", code != 0, out)
    code, out = run(d, "strike", "q1")
    ck("strike needs --why", code != 0 and "--why" in out, out)
    code, out = run(d, "strike", "nope", "--why", "x")
    ck("an unknown id is refused", code != 0, out)
    code, out = run(d, "strike", "example(c1)#2", "--why", "bad example")
    ck("an attachment is struck by its address", code == 0 and "struck(at(example, c1, 2)" in text(d), out)
    ck("only that example no longer counts", "second case" not in run(d, "report")[1] and "case" in run(d, "report")[1], run(d, "report")[1])
    code, out = run(d, "strike", "example(c1)#9", "--why", "x")
    ck("a bad address is refused", code != 0, out)
    d2 = fixture()
    code, out = run(d2, "strike", "k1", "--why", "obsolete")
    ck("a struck check is not in show open", code == 0 and not re.search(r"\bk1\b", opens(d2)), opens(d2))


def t_erase():
    d = fixture()
    code, out = run(d, "erase", "q2", "--why", "added by mistake")
    t = text(d)
    ck("erase q2 exits 0", code == 0, out)
    ck("question(q2 and option(q2 leave kb.pl", "question(q2," not in t and "option(q2," not in t)
    ck("one erased line stays, without the text", re.search(r"erased\(q2, agent, '[^']+', 'added by mistake'\)", t) and "typo question" not in t, t[-300:])
    ck("lint has no error", lint_clean(d)[0], lint_clean(d)[1])
    code, out = run(d, "erase", "option(q1)#2", "--why", "typo option")
    ck("an attachment is erased by its address", code == 0 and "option(q1, 'B', b)" not in text(d) and "option(q1, 'A', a)" in text(d), out)
    code, out = run(d, "erase", "q1")
    ck("erase needs --why", code != 0, out)
    ck("erase leaves the other KB records", "question(q1," in text(d))


def t_human():
    d = fixture()
    code, out = run(d, "add", "answer(q1, 'A', human)", "--by", "human")
    assert code == 0, out
    code, out = run(d, "replace", "answer(q1)#1", "answer(q1, 'B', agent)")
    ck("an agent's replace of the human's answer needs a disclosure", code != 0 and "disclos" in out.lower(), out)
    ck("nothing was written without it", "answer(q1, 'B', agent)" not in text(d))
    code, out = run(d, "strike", "answer(q1)#1", "--why", "x")
    ck("strike of the human's record needs one too", code != 0, out)
    code, out = run(d, "erase", "answer(q1)#1", "--why", "x")
    ck("erase of the human's record needs one too", code != 0 and "answer(q1, 'A', human)" in text(d), out)
    code, out = run(d, "replace", "answer(q1)#1", "answer(q1, 'B', agent)", "--disclose", "Ty said B in the chat")
    t = text(d)
    ck("with a disclosure it is accepted", code == 0, out)
    ck("the old answer stays, struck, with the disclosure",
       "answer(q1, 'A', human)" in t and "struck(at(answer, q1, 1)" in t and "Ty said B in the chat" in t, t[-500:])
    ck("the report shows it as a divergence for the human", "divergence for the human" in run(d, "report")[1], run(d, "report")[1])
    ck("lint has no error", lint_clean(d)[0], lint_clean(d)[1])
    d2 = fixture()
    run(d2, "add", "answer(q1, 'A', human)", "--by", "human")
    code, out = run(d2, "strike", "answer(q1)#1", "--why", "the human changed it", "--by", "human")
    ck("the human changes his own record with no disclosure", code == 0, out)
    d3 = fixture(["hypothesis(hy1, g1, human, 'the words of Ty')"])
    code, out = run(d3, "replace", "hy1", "hypothesis(hy2, g1, agent, 'mine')")
    ck("a hypothesis of the human is a record of the human", code != 0, out)


def t_replace_item():
    d = fixture()
    code, out = run(d, "replace", "k1", "check(k3, c1)", "checks_that(k3, 'better')", "--why", "better check")
    ck("replace k1 by k3 exits 0", code == 0, out)
    t = text(d)
    ck("k3 is added and supersedes(k3, k1)", "check(k3, c1)" in t and "supersedes(k3, k1)" in t, t[-300:])
    ck("k1 is not in show open", not re.search(r"\bk1\b", opens(d)), opens(d))
    code, out = run(d, "replace", "k2", "question(q9, g1, 'x')")
    ck("a replacement of another kind is refused, and nothing is written", code != 0 and "question(q9" not in text(d), out)
    code, out = run(d, "replace", "example(c1)#1", "example(c1, 'better case')")
    ck("an attachment replaced: new one added, old struck", code == 0 and "better case" in text(d) and "struck(at(example, c1, 1)" in text(d), out)


def t_unchanged():
    d = fixture()
    a = opens(d)
    ck("a KB with no struck record reads as before (show open stable)", a == opens(d) and "struck" not in run(d, "report")[1].lower().replace("struck through", ""), a)


if __name__ == "__main__":
    for n, f in sorted(globals().items()):
        if n.startswith("t_") and callable(f):
            try:
                f()
            except Exception as e:
                FAILS.append(n)
                print("FAIL %s crashed: %r" % (n, e))
    print("kb_crud: %d passed, %d failed %s" % (PASSED, len(FAILS), " ".join(FAILS)))
    sys.exit(1 if FAILS else 0)
