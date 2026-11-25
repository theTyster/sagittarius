#!/usr/bin/env python3
"""The runner of the conformance evals: the plan and its cost, the budget gate, the run record.

Usage:
  runner.py plan [--tasks N] [--arms N] [--runs N] [--criteria N]   the plan; makes no call
  runner.py live --budget USD [same options] [--out DIR]           starts only at budget >= estimate
  runner.py record OUT_DIR --agent-model M --prompt FILE           writes OUT_DIR/record.json
  runner.py check RUN_DIR                                           the record and the hint lines

`live --dry-run` is the same as `plan`. A live run with no budget, or with a budget under the
estimate, prints the plan, says why, makes no call and exits 4.

Model commands. This cut has no live command of its own: a live run calls the command in
CONFORMANCE_AGENT_CMD once per session (arguments: task id, arm, run number, transcript path)
and the command in CONFORMANCE_S1_CMD once per transcript (argument: the request file), and
refuses (exit 3) when either is unset. The tests set them to stubs. Nothing here calls a model.

Defaults (q4 of the KB prompt-evals, the pilot; a guess until Ty answers): 10 tasks x 2 arms
(the prompt, no prompt) x 3 runs = 60 Haiku sessions; 12 criteria (q6); the cost figures are
the note on q4. Python 3 standard library only.
"""
import argparse
import hashlib
import json
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))

# The figures of the note on q4 (discovery, 2026-11-25).
SESSION_USD = 0.10          # upper guess of one Haiku session
PLANTED = 12                # planted breaches, one for each criterion of the pilot
LABELLED_JUDGED = 80        # 40 labelled transcripts, judged twice
TOKENS_PER_QUESTION = 7100  # the largest recorded transcript, paid once per question at worst
TOOL_RESULT_FACTOR = 3      # tool results not cut (a guess)
S1_USD_PER_MTOK = 0.042

# A hint line of the System 1 hook (s1/hook.py): "System 1: work=build (0.83)", or one of its
# fixed lines "System 1: no view (...)", "System 1: unsure", "System 1: no signal".
HINT = re.compile(r"System 1: (?:[a-z_]+=[^\s;()]+ \(\d*\.?\d+\)|no view|unsure|no signal)")
RECORD_FIELDS = ("agent_model", "prompt_file", "prompt_sha256", "commit", "s1_hooks")


def plan(tasks=10, arms=2, runs=3, criteria=12):
    sessions = tasks * arms * runs
    transcripts = sessions + PLANTED + LABELLED_JUDGED
    questions = transcripts * criteria
    s1_calls = transcripts  # one request holds the questions of one transcript (questions.py)
    haiku_usd = sessions * SESSION_USD
    mtok = questions * TOKENS_PER_QUESTION * TOOL_RESULT_FACTOR / 1e6
    s1_usd = mtok * S1_USD_PER_MTOK
    total = round(haiku_usd + s1_usd, 2)
    lines = [
        f"Haiku sessions: {tasks} tasks x {arms} arms x {runs} runs = {sessions}",
        f"Transcripts for System 1: {sessions} runs + {PLANTED} planted + {LABELLED_JUDGED} "
        f"labelled (40 judged twice) = {transcripts}",
        f"System 1 calls: {s1_calls} (one request per transcript, {criteria} questions each = "
        f"{questions} questions)",
        f"Haiku cost: {sessions} x {SESSION_USD:.2f} USD = {haiku_usd:.2f} USD",
        f"System 1 cost: {questions} x {TOKENS_PER_QUESTION} tokens x {TOOL_RESULT_FACTOR} = "
        f"{mtok:.2f} M tokens x {S1_USD_PER_MTOK} USD/M = {s1_usd:.2f} USD",
        f"Estimate: {haiku_usd:.2f} + {s1_usd:.2f} = {total:.2f} USD (at most; output tokens of "
        "System 1 and the labelling sessions are not in it)",
    ]
    return {"sessions": sessions, "s1_calls": s1_calls, "questions": questions,
            "estimate_usd": total, "lines": lines}


def task_ids(n):
    with open(os.path.join(ROOT, "evals", "tools.json"), encoding="utf-8") as f:
        ids = [c["id"] for c in json.load(f)["evals"]]
    return ids[:n]


def sha256(path):
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


def write_record(out, agent_model, prompt_file, s1_hooks="off"):
    commit = subprocess.run(["git", "-C", ROOT, "rev-parse", "HEAD"], capture_output=True,
                            text=True).stdout.strip()
    rec = {"agent_model": agent_model, "prompt_file": prompt_file,
           "prompt_sha256": sha256(prompt_file) if prompt_file != "none" else None,
           "commit": commit, "s1_hooks": s1_hooks}
    os.makedirs(out, exist_ok=True)
    with open(os.path.join(out, "record.json"), "w", encoding="utf-8") as f:
        json.dump(rec, f, indent=1)
        f.write("\n")
    return rec


def check_run(run_dir):
    """Findings: a missing record field, s1_hooks not off, a transcript with a hint line."""
    bad = []
    try:
        with open(os.path.join(run_dir, "record.json"), encoding="utf-8") as f:
            rec = json.load(f)
    except (OSError, ValueError) as e:
        return [f"no record that can be read: {e}"]
    for k in RECORD_FIELDS:
        if not rec.get(k) and not (k == "prompt_sha256" and rec.get("prompt_file") == "none"):
            bad.append(f"record.json has no {k}")
    if rec.get("s1_hooks") != "off":
        bad.append(f"record.json: s1_hooks is {rec.get('s1_hooks')!r}, not 'off'")
    tdir = os.path.join(run_dir, "transcripts")
    names = sorted(n for n in os.listdir(tdir) if n.endswith(".jsonl")) if os.path.isdir(tdir) else []
    if not names:
        bad.append("the run has no transcript")
    for n in names:
        with open(os.path.join(tdir, n), encoding="utf-8") as f:
            for i, line in enumerate(f, 1):
                m = HINT.search(line)
                if m:
                    bad.append(f"{n}:{i}: a System 1 hint line: {m.group(0)}")
    return bad


def live(a, p):
    if a.dry_run:
        print("Dry run: no call is made.")
        return 0
    if a.budget is None:
        print("No budget given (--budget USD): no call is made.")
        return 4
    if a.budget < p["estimate_usd"]:
        print(f"Budget {a.budget:.2f} USD is under the estimate {p['estimate_usd']:.2f} USD: "
              "no call is made.")
        return 4
    agent, s1 = os.environ.get("CONFORMANCE_AGENT_CMD"), os.environ.get("CONFORMANCE_S1_CMD")
    if not agent or not s1:
        print("CONFORMANCE_AGENT_CMD and CONFORMANCE_S1_CMD must name the model commands; this "
              "cut has no live command of its own. No call is made.")
        return 3
    out = a.out or os.path.join(HERE, "runs", "live")
    tdir = os.path.join(out, "transcripts")
    os.makedirs(tdir, exist_ok=True)
    print(f"Budget {a.budget:.2f} USD >= estimate {p['estimate_usd']:.2f} USD: the run starts.")
    import questions as qmod
    criteria = qmod.load_criteria()
    for tid in task_ids(a.tasks):
        for arm in ("prompt", "none")[:a.arms]:
            for r in range(1, a.runs + 1):
                t = os.path.join(tdir, f"{tid}.{arm}.r{r}.jsonl")
                subprocess.run([agent, str(tid), arm, str(r), t], check=True)
                req = os.path.join(out, f"{tid}.{arm}.r{r}.request.json")
                with open(req, "w", encoding="utf-8") as f:
                    json.dump(qmod.build_request(t, criteria), f)
                subprocess.run([s1, req], check=True)
    return 0


def main(argv):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    for name in ("plan", "live"):
        s = sub.add_parser(name)
        s.add_argument("--tasks", type=int, default=10)
        s.add_argument("--arms", type=int, default=2, choices=(1, 2))
        s.add_argument("--runs", type=int, default=3)
        s.add_argument("--criteria", type=int, default=12)
        if name == "live":
            s.add_argument("--budget", type=float, default=None)
            s.add_argument("--dry-run", action="store_true")
            s.add_argument("--out", default=None)
    s = sub.add_parser("record")
    s.add_argument("out")
    s.add_argument("--agent-model", required=True)
    s.add_argument("--prompt", required=True)
    s.add_argument("--s1-hooks", default="off")
    s = sub.add_parser("check")
    s.add_argument("run_dir")
    a = ap.parse_args(argv)
    if a.cmd in ("plan", "live"):
        p = plan(a.tasks, a.arms, a.runs, a.criteria)
        print("Plan:")
        for line in p["lines"]:
            print("  " + line)
        if a.cmd == "plan":
            print("Dry run: no call is made.")
            return 0
        return live(a, p)
    if a.cmd == "record":
        print(json.dumps(write_record(a.out, a.agent_model, a.prompt, a.s1_hooks), indent=1))
        return 0
    bad = check_run(a.run_dir)
    for b in bad:
        print(b)
    if not bad:
        print("the record names the model, the prompt digest, the commit and s1_hooks off; "
              "no transcript holds a System 1 hint line")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
