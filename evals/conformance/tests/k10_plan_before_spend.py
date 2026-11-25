#!/usr/bin/env python3
"""k10: no paid run starts before its size and cost are stated.

Usage: k10_plan_before_spend.py SAGITTARIUS_DIR
With stubs in place of the model commands (CONFORMANCE_AGENT_CMD, CONFORMANCE_S1_CMD; the stubs
only write a line to a file), it checks evals/conformance/runner.py:
- a live run with no budget, and one with a budget under the estimate, print the plan (Haiku
  sessions, System 1 calls, the estimate with its arithmetic) and make no call;
- a dry run prints the same plan and makes no call;
- a budget that is not finite (nan, inf) and a count under 1 (--tasks -1, which would make a
  negative estimate) are refused with no call, even with a budget that would cover the estimate;
- the default plan is the pilot of q4: 60 sessions, 152 System 1 calls, 2.83 USD;
- a live run of 1 session with a budget at or above its estimate calls each stub once (so the
  gate is not a runner that never starts).
At cc64ef0 there is no such runner, and evals/run_tools.sh takes no budget: the check fails.
It never runs evals/run_tools.sh (that loads real credentials). No model is called.
Exit 0: pass. Exit 1: one finding or more, each on its own line.
"""
import os
import re
import subprocess
import sys
import tempfile

STUB = "#!/bin/sh\necho \"$0 $*\" >> \"$K10_CALLS\"\n"
AGENT_STUB = STUB + "[ -n \"$4\" ] && cp \"$K10_TRANSCRIPT\" \"$4\"\nexit 0\n"


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    root = argv[1]
    runner = os.path.join(root, "evals", "conformance", "runner.py")
    bad = []
    rt = os.path.join(root, "evals", "run_tools.sh")
    if os.path.exists(rt) and "--budget" not in open(rt, encoding="utf-8").read() \
            and not os.path.exists(runner):
        bad.append("evals/run_tools.sh takes no budget and starts its sessions with no plan")
    if not os.path.exists(runner):
        bad.append("no evals/conformance/runner.py that states the plan before a live run")
        for b in bad:
            print(b)
        return 1
    with tempfile.TemporaryDirectory(prefix="k10-") as tmp:
        return checks(root, runner, tmp, bad)


def checks(root, runner, tmp, bad):
    calls = os.path.join(tmp, "calls")
    env = dict(os.environ, K10_CALLS=calls, K10_TRANSCRIPT=os.path.join(
        root, "evals", "conformance", "fixtures", "run-sample", "transcripts", "t1-conforms.jsonl"))
    for name, body in (("agent", AGENT_STUB), ("s1", STUB)):
        p = os.path.join(tmp, name)
        with open(p, "w") as f:
            f.write(body)
        os.chmod(p, 0o755)
    env["CONFORMANCE_AGENT_CMD"] = os.path.join(tmp, "agent")
    env["CONFORMANCE_S1_CMD"] = os.path.join(tmp, "s1")

    def run(*args):
        r = subprocess.run([sys.executable, runner, *args, "--out", os.path.join(tmp, "out")]
                           if args[0] == "live" else [sys.executable, runner, *args],
                           capture_output=True, text=True, env=env)
        return r.returncode, r.stdout

    def n_calls():
        return sum(1 for _ in open(calls)) if os.path.exists(calls) else 0

    def plan_of(out):
        return [ln for ln in out.splitlines() if ln.startswith("  ")]

    _, dry = run("plan")
    plan = plan_of(dry)
    text = "\n".join(plan)
    for need, pat in (("the Haiku sessions", r"Haiku sessions: 10 tasks x 2 arms x 3 runs = 60\b"),
                      ("the System 1 calls", r"System 1 calls: 152\b"),
                      ("the estimate with its arithmetic", r"Estimate: 1\.20 \+ 1\.63 = 2\.83 USD")):
        if not re.search(pat, text):
            bad.append(f"the plan does not state {need} of the pilot ({pat})")
    # The cost of what live() makes: the sessions and their System 1 requests only (no planted or
    # labelled transcript exists yet). The pilot of 0.9.1: 10 tasks x 2 arms x 1 run, 14 criteria.
    _, small = run("plan", "--tasks", "10", "--arms", "2", "--runs", "1", "--criteria", "14")
    if not re.search(r"This live run: 0\.40 \+ 0\.25 = 0\.65 USD", small):
        bad.append("the plan does not state the cost of the live run alone (0.40 + 0.25 = 0.65 USD)")
    for label, args in (("a live run with no budget", ("live",)),
                        ("a live run with a budget under the estimate", ("live", "--budget", "1")),
                        ("a dry run", ("live", "--dry-run", "--budget", "100"))):
        before = n_calls()
        code, out = run(*args)
        if n_calls() != before:
            bad.append(f"{label} called a model command")
        if plan_of(out) != plan:
            bad.append(f"{label} does not print the same plan")
        if label != "a dry run" and code == 0:
            bad.append(f"{label} exits 0, as if it ran")
    for label, args in (("a budget of nan", ("live", "--budget", "nan")),
                        ("a budget of inf", ("live", "--budget", "inf")),
                        ("--tasks -1 with a budget of 1", ("live", "--tasks", "-1", "--budget", "1")),
                        ("--runs 0 with a budget of 100", ("live", "--runs", "0", "--budget", "100"))):
        before = n_calls()
        code, out = run(*args)
        if n_calls() != before:
            bad.append(f"{label} called a model command")
        if code == 0:
            bad.append(f"{label} is not refused (exit 0)")
    before = n_calls()
    code, out = run("live", "--tasks", "1", "--arms", "1", "--runs", "1", "--budget", "100")
    if code != 0 or n_calls() - before != 2:
        bad.append(f"a live run of 1 session with a budget above its estimate made "
                   f"{n_calls() - before} stub calls (exit {code}), not 2")
    for b in bad:
        print(b)
    if not bad:
        print("no budget, a budget under the estimate and a dry run print the plan and call "
              "nothing; a budget at or above the estimate starts the stubs")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
