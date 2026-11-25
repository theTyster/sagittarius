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
    # c2, review run 20, case 1: the default first, while the question has no option, then options that do not hold it
    d3 = fixture()
    run(d3, "add", "question(q5, g1, 'Order?')")
    code, out = run(d3, "add", "assumed(q5, 'C, a sentence')")
    ck("the default first, while the question has no option: accepted", code == 0, out)
    code, out = run(d3, "add", "option(q5, 'A', 'a')", "option(q5, 'B', 'b')")
    ck("then options that do not hold it: refused (E22)", code != 0 and "E22" in out and "option(q5" not in kbtext(d3), out)
    code, out = run(d3, "add", "option(q5, 'C, a sentence', 'c')", "option(q5, 'D', 'd')")
    ck("options that hold the default: accepted", code == 0, out)
    # c3, review run 20, case 2: a second default beside the first
    d4 = fixture(["assumed(q1, 'A')"])
    code, out = run(d4, "add", "assumed(q1, 'B')")
    ck("a second default beside the first is refused", code != 0 and "defaults" in out and "assumed(q1, 'B')" not in kbtext(d4), out)
    ck("one default counts", len(defaults(d4, "q1")) == 1, defaults(d4, "q1"))
    code, out = run(d4, "add", "option(q1, 'Z', 'z')")
    ck("an option that leaves the default right is accepted", code == 0, out)
    # an old KB that is wrong already is let alone by an unrelated option, and lint names it (W21)
    d5 = old_kb()
    ck("lint names a default that is no option (W21)", "W21 q2" in run(d5, "lint")[1] and "W21 q1" in run(d5, "lint")[1], run(d5, "lint")[1])
    code, out = run(d5, "add", "option(q2, 'Maybe', 'm')")
    ck("an old question that was wrong is not made worse by an option: accepted", code == 0, out)
    code, out = run(d5, "add", "assumed(q2, 'Another sentence')")
    ck("a new bad default on it is refused", code != 0, out)


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
    ck("check names the link step (q1) and the agent step (q2)", code == 1 and "link tool 1" in out and "means agent 1" in out and "q(q1," in out and "q(q2," in out, out)
    ck("a default that is an option, and a question with no options, are not named", "q(q3" not in out and "q(q4" not in out, out)
    code, out = run(d, "migrate", "plan")
    seen = re.search(r"^Seen: (\S+)", out, re.M)
    ck("plan shows the writes, and no fixed time", code == 0 and seen and "+ assumed(q1, 'Two tickets')" in out and "2026-11-26T00:00:00Z" not in out, out)
    ck("the agent step writes nothing", "option(q2" not in out, out)
    code, out = run(d, "migrate", "apply", "--seen", seen.group(1))
    ck("apply exits 0", code == 0, out)
    t = kbtext(d)
    ck("the old lines stay in kb.pl", "assumed(q1, 'two tickets: desk speed first')." in t and "assumed(q2, 'Maybe later')." in t)
    ck("q1: the option is the default, once", defaults(d, "q1") in (["'Two tickets'"], ["Two tickets"]), defaults(d, "q1"))
    ck("the struck record carries the time of the write, not a fixed time",
       "2026-11-26T00:00:00Z" not in t and re.search(r"struck\(fact\(assumed\(q1.*'(\d{4}-\d\d-\d\dT[\d:]+Z)'", t) is not None, t[-400:])
    code, out = run(d, "migrate", "check")
    ck("check still names q2 for the agent: it is not done while a default is no option", code == 1 and "means agent" in out and "q(q2," in out, out)
    code, out = run(d, "replace", "assumed(q2)#1", "assumed(q2, 'No')", "--why", "Maybe later means No for now")
    ck("the agent links q2 by replace", code == 0, out)
    code, out = run(d, "migrate", "check")
    ck("check is clean after the agent step", code == 0, out)
    ck("lint has no error and no W21", "0 error(s)" in run(d, "lint")[1] and "W21" not in run(d, "lint")[1], run(d, "lint")[1])
    before = kbtext(d)
    code, out = run(d, "migrate", "plan")
    seen = re.search(r"^Seen: (\S+)", out, re.M)
    run(d, "migrate", "apply", "--seen", seen.group(1) if seen else "sha256:" + "0" * 64)
    ck("a second apply writes nothing", kbtext(d) == before, out)


def t_migration_ambiguous():
    d = old_kb_with(["option(q1, 'Yes', 'a')", "option(q1, 'Yes, but later', 'b')", "assumed(q1, 'Yes, but later on Tuesday')"])
    code, out = run(d, "migrate", "check")
    ck("a default that begins with two options is taken by link (q1)", "link tool 1" in out and "q(q1,'Yes, but later on Tuesday','Yes, but later')" in out, out)
    ck("and by no agent step", "means" not in out, out)
    code, out = run(d, "migrate", "plan")
    seen = re.search(r"^Seen: (\S+)", out, re.M)
    run(d, "migrate", "apply", "--seen", seen.group(1))
    ck("the longest option is the default", defaults(d, "q1") in (["'Yes, but later'"], ["Yes, but later"]), defaults(d, "q1"))
    ck("check is clean", run(d, "migrate", "check")[0] == 0, run(d, "migrate", "check")[1])


def old_kb_with(facts):
    d = os.path.join(tempfile.mkdtemp(prefix="qdo-m-"), "kb")
    subprocess.run([OK, "init", d, "--request", "fixture", "--uses", "discovery"], capture_output=True, env=ENV, check=True)
    code, out = run(d, "add", "goal(g1, feature, agent, 'g')", "no_premises(g1)", "question(q1, g1, 't')",
                    *[f for f in facts if not f.startswith("assumed(")])
    assert code == 0, out
    with open(os.path.join(d, "kb.pl"), "a") as f:
        for x in facts:
            if x.startswith("assumed("):
                f.write(x + ".\n")
    return d


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
