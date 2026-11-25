#!/usr/bin/env python3
"""Black-box tests of the default of a question (spec KB question-default-option: c1 to c3). Usage: kb_default_option.py ORBIT_KB."""
import os
import re
import subprocess
import sys
import tempfile

OK = os.path.abspath(sys.argv[1])
ENV = dict(os.environ, HUB_SESSION="qdo-test")
ENV.pop("ORBIT_KB_WRITER", None)
FAILS, PASSED = [], 0


def run(d, *args):
    r = subprocess.run([OK, "--dir", d, *args], capture_output=True, text=True, env=ENV)
    return r.returncode, r.stdout + r.stderr


def fixture(extra=()):
    d = os.path.join(tempfile.mkdtemp(prefix="qdo-"), "kb")
    subprocess.run([OK, "init", d, "--request", "fixture", "--uses", "discovery"], capture_output=True, env=ENV, check=True)
    code, out = run(d, "add", "goal(g1, feature, agent, 'g')", "no_premises(g1)", "question(q1, g1, 'Which?')",
                    "option(q1, 'A', 'a')", "option(q1, 'B', 'b')", *extra)
    assert code == 0, out[-400:]
    return d


def ck(name, ok, detail=""):
    global PASSED
    if ok:
        PASSED += 1
        print("PASS " + name)
    else:
        FAILS.append(name)
        print("FAIL %s %s" % (name, str(detail)[-400:]))


def kbtext(d):
    return open(os.path.join(d, "kb.pl")).read()


def defaults(d, q):
    return re.findall(r"D = (.*)", run(d, "query", "-n", "0", "assumed(%s, D)" % q)[1])


def t_gate():
    d = fixture()
    code, out = run(d, "add", "assumed(q1, 'C, which is neither')")
    ck("a default that is no option is refused", code != 0 and "E22" in out, out)
    ck("nothing was written", "assumed(q1" not in kbtext(d))
    code, out = run(d, "add", "assumed(q1, 'A')")
    ck("the text of an option is accepted", code == 0, out)
    d2 = fixture()
    code, out = run(d2, "add", "question(q2, g1, 'New?')", "option(q2, 'Yes', 'y')", "assumed(q2, 'Yes')")
    ck("options and default in one add are accepted", code == 0, out)
    code, out = run(d2, "add", "question(q3, g1, 'New?')", "option(q3, 'Yes', 'y')", "assumed(q3, 'Maybe')")
    ck("options and a bad default in one add are refused", code != 0 and "E22" in out, out)
    code, out = run(d2, "add", "question(q4, g1, 'Free?')", "assumed(q4, 'anything')")
    ck("a question with no options takes any default", code == 0, out)


def t_replace_default():
    d = fixture(["assumed(q1, 'A')"])
    code, out = run(d, "replace", "assumed(q1)#1", "assumed(q1, 'B')", "--why", "A went out of date")
    ck("replace the default exits 0", code == 0, out)
    ck("one default counts, it is B", defaults(d, "q1") == ["'B'"] or defaults(d, "q1") == ["B"], defaults(d, "q1"))
    ck("the old default stays in kb.pl", "assumed(q1, 'A')" in kbtext(d))
    code, out = run(d, "replace", "assumed(q1)#2", "assumed(q1, 'C')", "--why", "x")
    ck("replacing by a text that is no option is refused", code != 0 and "E22" in out, out)


MIG = ["goal(g1, feature, agent, 'g')", "no_premises(g1)",
       "question(q1, g1, 't')", "option(q1, 'Two tickets', 'a')", "option(q1, 'One ticket', 'b')", "assumed(q1, 'two tickets: desk speed first')",
       "question(q2, g1, 'u')", "option(q2, 'Yes', 'a')", "option(q2, 'No', 'b')", "assumed(q2, 'Maybe later')",
       "question(q3, g1, 'v')", "option(q3, 'A', 'a')", "assumed(q3, 'A')",
       "question(q4, g1, 'w')", "assumed(q4, 'free')"]


def old_kb():
    """A KB with defaults that are no options, as an older orbit-kb wrote it: the facts go straight into kb.pl."""
    d = os.path.join(tempfile.mkdtemp(prefix="qdo-m-"), "kb")
    subprocess.run([OK, "init", d, "--request", "fixture", "--uses", "discovery"], capture_output=True, env=ENV, check=True)
    code, out = run(d, "add", *[f for f in MIG if not f.startswith("assumed(q1, 'two") and not f.startswith("assumed(q2")])
    assert code == 0, out
    with open(os.path.join(d, "kb.pl"), "a") as f:
        f.write("assumed(q1, 'two tickets: desk speed first').\nassumed(q2, 'Maybe later').\n")
    return d


def t_migration():
    d = old_kb()
    code, out = run(d, "migrate", "check")
    ck("check names the two steps", code == 1 and "link tool" in out and "keep tool" in out and "q(q1," in out and "q(q2," in out, out)
    ck("a default that is an option, and a question with no options, are not named", "q(q3" not in out and "q(q4" not in out, out)
    code, out = run(d, "migrate", "plan")
    seen = re.search(r"^Seen: (\S+)", out, re.M)
    ck("plan shows the writes", code == 0 and seen and "+ assumed(q1, 'Two tickets')" in out and "+ option(q2, 'Maybe later'" in out, out)
    code, out = run(d, "migrate", "apply", "--seen", seen.group(1))
    ck("apply exits 0", code == 0, out)
    t = kbtext(d)
    ck("the old lines stay in kb.pl", "assumed(q1, 'two tickets: desk speed first')." in t and "assumed(q2, 'Maybe later')." in t)
    ck("q1: the option is the default, once", defaults(d, "q1") in (["'Two tickets'"], ["Two tickets"]), defaults(d, "q1"))
    ck("q2: the default is an option now", "option(q2, 'Maybe later'" in t and len(defaults(d, "q2")) == 1, defaults(d, "q2"))
    code, out = run(d, "migrate", "check")
    ck("check is clean after apply", code == 0, out)
    code, out = run(d, "lint")
    ck("lint has no error", "0 error(s)" in out, out)
    before = kbtext(d)
    code, out = run(d, "migrate", "plan")
    seen = re.search(r"^Seen: (\S+)", out, re.M)
    run(d, "migrate", "apply", "--seen", seen.group(1) if seen else "sha256:" + "0" * 64)
    ck("a second apply writes nothing", kbtext(d) == before, out)
    # every default is an option now
    pairs = re.findall(r"assumed\((q\d), ('.*?'|\w+)\)\.", re.sub(r"struck\(fact\(.*", "", kbtext(d)))
    ck("scan: each default of a question with options is one of its options (struck ones aside)",
       all(re.search(r"option\(%s, %s," % (q, re.escape(v)), kbtext(d)) for q, v in pairs if q in ("q2", "q3")), pairs)


if __name__ == "__main__":
    for n, f in sorted(globals().items()):
        if n.startswith("t_") and callable(f):
            try:
                f()
            except Exception as e:
                FAILS.append(n)
                print("FAIL %s crashed: %r" % (n, e))
    print("kb_default_option: %d passed, %d failed %s" % (PASSED, len(FAILS), " ".join(FAILS)))
    sys.exit(1 if FAILS else 0)
