#!/usr/bin/env python3
"""Tempering tool (T13, dl_temper): find where a statement stops being acceptable.

    python3 s1/temper.py STATEMENT --source TEXT [--kind hypothesis|requirement]

Productized from the review session's calibrated loop (tmp/hub-design-kb/s1/run.py: temper,
p3_judge, verdict, propose, falsify, h_judge; design dvh7, dvh8). The prompts, thresholds and
questions are copied, not redesigned.

Judges (they decide):
  System 1 model     j_adds (choice: what the statement adds), j_contra (does the falsifier
                     contradict it; yes at 0.6), j_observable, and (0.3.0 S-B: the System 1 model is
                     the only judge) j_forbids, j_faithful, j_finding. Collapsed (hypotheses only) is
                     the definition of Hypothesis.lean: the statement forbids no single concrete case,
                     so no case can show it false (j_forbids no). Being true of a correct system is not
                     collapse. A statement that says some cases behave differently today reports a
                     finding (j_finding yes), not a rule: it is not accepted.
Proposers (they never judge; their output is only text to be judged):
  haiku              one move per step (drop an assumption | sharpen the conclusion, <= 35 words)
  haiku, own call    the falsifier

Output: the bracket (last accepted, first rejected, why) as text and as Prolog facts.

Every model call is logged to $TEMPER_LOG (default ~/.claude/logs/temper.jsonl) with exactly one
role: proposer, falsifier or judge. Each judged statement also logs a verdict record that lists the
ids of the judge calls it came from, with its falsifier and the booleans collapsed, faithful, finding.

Injectable for tests: claude(prompt, model) -> str; System 1 model transport (see jev.py).
Every claude child gets stdin from /dev/null (c2): without it the child reads the parent's stdin.
"""
import argparse
import itertools
import json
import os
import re
import subprocess
import sys
import tempfile
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import jev  # noqa: E402

DEFAULT_LOG = os.path.expanduser("~/.claude/logs/temper.jsonl")
LOG_ENV = "TEMPER_LOG"
YES, NO = 0.7, 0.3
CONF = 0.5
CONTRA_YES = 0.6   # calibrated on 8 clear cases (yes 0.79-0.97, no 0.05-0.34) and 4 runs of one accepted case (0.68-0.79)
SYSTEM = "You are a text editor and judge. You have no tools. Answer only what is asked."

ADDS = {"nothing": "Only the expected outcome and which facts should decide it",
        "cause": "A reason why the problem happens",
        "mechanism": "How the system works inside: a cache, a job, a query, a code path",
        "data": "A field, a table, a file, a format or where data is stored",
        "design": "A fix, a design or a way to build something"}
JQ = {"j_adds": {"type": "choice", "instructions": "Beyond the problem in `source`, what does `statement` add? Pick the first option that applies in this order: design, cause, mechanism, data, nothing.", "criteria": ADDS},
      "j_contra": {"type": "noul", "instructions": "If the result in `falsifier` were observed, would `statement` be false?"},
      "j_observable": {"type": "noul", "instructions": "Could a person check the result in `falsifier` by looking at the running system, its data, its logs or a test?"},
      # 0.3.0 S-B: the hypothesis judge (Hypothesis.lean: Collapsed, Fits). The System 1 model asks them.
      "j_forbids": {"type": "noul", "instructions": "Does `statement` forbid one single concrete case: one input, and an outcome for that input that would make `statement` false if a system showed it? A statement that says which facts decide a value forbids every other value for those facts: one input with any other value is such a case. A statement that only says that some dependence, some difference or some cause exists forbids no single case."},
      "j_faithful": {"type": "noul", "instructions": "Is `statement` about the problem in `source` (not another problem), without changing what a good outcome is? Saying which facts decide the outcome is still about the problem."},
      "j_finding": {"type": "noul", "instructions": "Does `statement` say that some cases behave differently, or are wrong, in the system today (a report about the current system), and not only a rule that every case must hold?"}}

MOVE_TEXT = {"drop_assumption": "Remove one assumption (a cause, a mechanism, a data shape or a design) and keep the rest.",
             "sharpen_conclusion": "Say more exactly which outcome is expected, so that more results would show it false. Never add a cause, a mechanism, a data shape or a design."}


def band(p):
    return "yes" if p >= YES else "no" if p <= NO else "unsure"


def q(s):
    return "'" + str(s).replace("\\", "\\\\").replace("'", "''").replace("\n", "\\n") + "'"


def refuse_real(what):
    """Under a test runner a real claude or network call is a bug: fail loudly, reach nothing."""
    if ("unittest" in sys.modules or "pytest" in sys.modules) and not os.environ.get("TEMPER_ALLOW_REAL"):
        raise RuntimeError(f"real {what} call under a test runner: inject a fake (or set TEMPER_ALLOW_REAL=1)")


def run_claude(prompt, model, system=SYSTEM):
    """A plain model call: no tools, no settings, no project context, an empty working directory.
    stdin is /dev/null (c2). Returns stdout, or "" if the child fails."""
    refuse_real("claude")
    with tempfile.TemporaryDirectory() as empty:
        try:
            r = subprocess.run(["claude", "-p", "--model", model, "--system-prompt", system,
                                "--tools", "", "--setting-sources", "", prompt],
                               stdin=subprocess.DEVNULL, capture_output=True, text=True, timeout=180, cwd=empty)
        except (OSError, subprocess.SubprocessError):
            return ""
    return r.stdout.strip()


class Run:
    """The calls of one tempering: who made each, in which role, and what came back."""

    def __init__(self, claude=None, transport=None, log_path=None, jev_log=None, redactions=None):
        self.claude = claude or run_claude
        self.transport = transport
        self.log_path = log_path or os.environ.get(LOG_ENV) or DEFAULT_LOG
        self.jev_log = jev_log
        self.redactions = redactions
        self._ids = itertools.count(1)

    def log(self, rec):
        try:
            os.makedirs(os.path.dirname(self.log_path) or ".", exist_ok=True)
            with open(self.log_path, "a", encoding="utf-8") as f:
                f.write(json.dumps(rec, ensure_ascii=False, default=str) + "\n")
        except OSError:
            pass

    def _call(self, role, by, fn, **info):
        cid = next(self._ids)
        t0 = time.monotonic()
        out = fn()
        self.log({"event": "call", "id": cid, "role": role, "by": by, "at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                  "ms": int(1000 * (time.monotonic() - t0)), "ok": bool(out), **info})
        return cid, out

    def model(self, role, model, prompt, **info):
        return self._call(role, model, lambda: self.claude(prompt, model), **info)

    def jev(self, state):
        if self.transport is None:
            refuse_real("System 1 model network")
        return self._call("judge", "jev", lambda: jev.judge(state, JQ, transport=self.transport, log_path=self.jev_log,
                                                              redactions=self.redactions))


def p3_judge(run, statement, falsifier, source, kind="hypothesis"):
    jid, a = run.jev({"statement": statement, "falsifier": falsifier, "source": source})
    if a is None:
        return None
    tri = {"yes": True, "no": False, "unsure": None}
    fb = band(a["j_forbids"]["noul"])
    col = {"yes": False, "no": True, "unsure": None}[fb]
    if kind == "requirement":
        col = False   # collapse for a requirement = no observable contradicting falsifier: the System 1 model's j_contra and j_observable (dvh8)
    ad = a["j_adds"]
    ps = {"j_adds": (ad["choice"], ad["probabilities"].get(ad["choice"], 0.0)), "j_contra": a["j_contra"]["noul"],
          "j_observable": a["j_observable"]["noul"], "j_forbids": a["j_forbids"]["noul"],
          "j_faithful": a["j_faithful"]["noul"], "j_finding": a["j_finding"]["noul"], "h_collapsed": col,
          "h_faithful": tri[band(a["j_faithful"]["noul"])], "h_finding": tri[band(a["j_finding"]["noul"])]}
    return ps, [jid]


def verdict(ps):
    choice, conf = ps["j_adds"]
    cb = "yes" if ps["j_contra"] >= CONTRA_YES else "no" if ps["j_contra"] <= NO else "unsure"
    unsure = ([] if cb != "unsure" else ["j_contra"]) + [j for j in ("j_observable",) if band(ps[j]) == "unsure"]
    if conf < CONF:
        unsure.append("j_adds")
    for j, h in (("j_forbids", "h_collapsed"), ("j_faithful", "h_faithful"), ("j_finding", "h_finding")):
        if ps[h] is None:
            unsure.append(j)
    bad = []
    if conf >= CONF and choice != "nothing":
        bad.append("adds_" + choice)
    if cb == "no":
        bad.append("j_contra")
    if band(ps["j_observable"]) == "no":
        bad.append("j_observable")
    if ps["h_collapsed"] is True:
        bad.append("collapsed")
    if ps["h_faithful"] is False:
        bad.append("unfaithful")
    if ps["h_finding"] is True:
        bad.append("finding")
    if bad:            # a clear failure decides even if another answer is unsure
        return "reject", bad
    if unsure:
        return "unsure", unsure
    return "accept", []


def faithful_to_intent(ps):
    """Faithful, and no finding inside: False if either fails, None if either is unsure."""
    if ps["h_faithful"] is False or ps["h_finding"] is True:
        return False
    if ps["h_faithful"] is None or ps["h_finding"] is None:
        return None
    return True


def show(ps):
    c, k = ps["j_adds"]
    return {"adds": f"{c}:{k:.2f}", "contra": round(ps["j_contra"], 2), "obs": round(ps["j_observable"], 2),
            "collapsed": ps["h_collapsed"], "faithful": ps["h_faithful"], "finding": ps["h_finding"]}


# The proposer is told what failed in plain words, never the judge question names.
WHY_WORDS = {"j_contra": "the falsifier does not contradict it", "j_observable": "the falsifier cannot be observed",
             "collapsed": "no result could show it false",
             "unfaithful": "it is not the outcome that the source wants",
             "finding": "it reports that some cases differ today, not a rule that every case must hold"}


def propose(run, statement, source, move, why=()):
    if move == "drop_assumption":
        hint = "The statement names " + ", ".join(w.replace("adds_", "a ") for w in why if w.startswith("adds_")) + " that the source does not. Remove it; keep the expected outcome."
    elif why:
        hint = ("The statement does not say the wanted outcome well (" + ", ".join(WHY_WORDS.get(w, w) for w in why) + "). "
                "Name the outcome the source expects more exactly, so that a result of a faulty system would show the statement false "
                "and a system that works makes it true. Do not state the problem as it is today.")
    else:
        hint = "The statement is acceptable. Make its conclusion stronger by one step: say more exactly which outcome is expected and which facts should decide it. Do not say why it fails, how the system works inside, where data is stored, or how to fix it."
    return run.model("proposer", "haiku",
                     "You edit one statement by one small step. Source (what the owner asked for): " + source +
                     "\nStatement: " + statement + "\nAllowed step: " + MOVE_TEXT[move] + "\n" + hint +
                     "\nReply with the new statement only: at most 35 words, no quotes, no commentary.", move=move)[1]


def falsify(run, statement):
    return run.model("falsifier", "haiku",
                     "Write the falsifier of this statement: one observable result that would show it false. "
                     "One sentence, no commentary.\nStatement: " + statement)[1]


def move_for(bad):
    return "drop_assumption" if any(w.startswith("adds_") for w in bad) else "sharpen_conclusion"


def judged(run, n, statement, falsifier, source, kind):
    r = p3_judge(run, statement, falsifier, source, kind)
    if r is None:
        return None
    ps, ids = r
    v, bad = verdict(ps)
    run.log({"event": "verdict", "step": n, "statement": statement, "falsifier": falsifier, "verdict": v, "bad": bad,
             "collapsed": ps["h_collapsed"], "faithful": faithful_to_intent(ps), "finding": ps["h_finding"], "calls": ids})
    return ps, v, bad


def temper(statement, source, kind="hypothesis", *, falsifier=None, maxn=4,
           claude=None, transport=None, log_path=None, jev_log=None, redactions=None):
    """The loop (Ty's oscillation, u90): repair a rejected statement one move at a time, chosen by
    what failed; once accepted, probe one step past it (sharpen) to find the boundary.
    Returns (trace, bracket(kind, last_accepted, first_rejected_after_it, why))."""
    run = Run(claude, transport, log_path, jev_log, redactions)
    trace = []
    f = falsifier or falsify(run, statement)
    j = judged(run, 0, statement, f, source, kind)
    if j is None:
        return trace, ("error", None, None, "service")
    ps, v, bad = j
    trace.append((0, "start", statement, f, ps, v, bad))
    if v == "unsure":
        return trace, ("to_ty", None, statement, bad)
    last_ok = statement if v == "accept" else None
    cur, cur_bad = statement, bad
    for n in range(1, maxn + 1):
        move = "sharpen_conclusion" if last_ok == cur else move_for(cur_bad)
        nxt = propose(run, cur, source, move, cur_bad)
        if not nxt:
            break
        f = falsify(run, nxt)
        j = judged(run, n, nxt, f, source, kind)
        if j is None:
            return trace, ("error", last_ok, nxt, "service")
        ps, v2, bad2 = j
        trace.append((n, move, nxt, f, ps, v2, bad2))
        if v2 == "unsure":
            return trace, ("to_ty", last_ok, nxt, bad2)
        if v2 == "accept":
            last_ok, cur, cur_bad = nxt, nxt, []
            continue
        if last_ok is not None:      # the first rejection past an accepted version: the boundary
            return trace, ("bracket", last_ok, nxt, (move, bad2))
        cur, cur_bad = nxt, bad2     # still repairing
    return trace, (("open" if last_ok else "unrepaired"), last_ok, None, "max steps")


def facts(step, item, trace, br):
    out = []
    for n, move, st, f, ps, v, bad in trace:
        out.append(f"s1_step({q(step)}, {q(item)}, {n}, {move}, {q(st)}, {q(f)}, {v}, {bad}).")
        for j, val in show(ps).items():
            out.append(f"s1_judged({q(step)}, {q(item)}, {n}, {j}, {q(val)}).")
    kind, last_ok, first_bad, why = br
    out.append(f"s1_bracket({q(step)}, {q(item)}, {kind}, {q(last_ok)}, {q(first_bad)}, {q(why)}).")
    return "\n".join(out)


def format_bracket(br):
    kind, last_ok, first_bad, why = br
    if isinstance(why, tuple):
        why = f"{why[0]}: {', '.join(why[1])}"
    elif isinstance(why, list):
        why = "unsure about " + ", ".join(why)
    return (f"bracket: {kind}\nlast accepted: {last_ok}\nfirst rejected: {first_bad}\nwhy: {why}")


HEADER = ("% Generated by s1/temper.py. Do not edit.\n"
          ":- discontiguous s1_step/8, s1_judged/5, s1_bracket/6.\n")


def main(argv=None, **inject):
    ap = argparse.ArgumentParser(description="Temper a statement: find the last accepted and the first rejected version.")
    ap.add_argument("statement")
    ap.add_argument("--source", required=True, help="what the owner asked for (the problem the statement is about)")
    ap.add_argument("--kind", choices=("hypothesis", "requirement"), default="hypothesis")
    ap.add_argument("--falsifier", help="use this falsifier for the starting statement")
    ap.add_argument("--step", default="temper")
    ap.add_argument("--item", default="t1")
    a = ap.parse_args(argv)
    trace, br = temper(a.statement, a.source, a.kind, falsifier=a.falsifier, **inject)
    print(format_bracket(br))
    print()
    print(HEADER + facts(a.step, a.item, trace, br))
    return 0 if br[0] != "error" else 1


if __name__ == "__main__":
    sys.exit(main())
