#!/usr/bin/env python3
"""The runner of the conformance evals: the plan and its cost, the budget gate, the run record.

Usage:
  runner.py plan [--tasks N] [--arms N] [--runs N] [--criteria N]   the plan; makes no call
  runner.py live --budget USD [same options] [--out DIR]           starts only at budget >= estimate
  runner.py record OUT_DIR --agent-model M --prompt FILE           writes OUT_DIR/record.json;
                                                                    s1_hooks from S1_OFF of this env
  runner.py check RUN_DIR                                           the record and the hint lines

`live --dry-run` is the same as `plan`. A live run with no budget, or with a budget under the
estimate, prints the plan, says why, makes no call and exits 4.

Model commands. The live commands are agent_cmd.sh (one Haiku session) and s1_cmd.py (one System
1 request; it leaves <run>.answers.json beside the request, and the run collects them into
answers.json, which score.py reads); a test sets stubs. A live run calls the command in
CONFORMANCE_AGENT_CMD once per session (arguments: task id, arm, run number, transcript path)
and the command in CONFORMANCE_S1_CMD once per transcript (argument: the request file), and
refuses (exit 3) when either is unset. The tests set them to stubs. Nothing here calls a model.
The agent command gets S1_OFF=1 in its environment; the run writes record.json, with s1_hooks
read from that environment, and runs `check` on the run at the end (exit 1 on a finding).
Counts under 1 and a budget that is not a finite number of 0 or more are refused (exit 2).

Defaults (q4 of the KB prompt-evals, the pilot; a guess until Ty answers): 10 tasks x 2 arms
(the prompt, no prompt) x 3 runs = 60 Haiku sessions; 12 criteria (q6); the cost figures are
the note on q4. Python 3 standard library only.
"""
import argparse
import hashlib
import json
import math
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))

# The agent under test: the current Haiku (Ty: "a haiku agent"; the newest one, a default).
AGENT_MODEL = "claude-haiku-5-5"
# The figures of the note on q4 (discovery, 2026-11-25), moved to AGENT_MODEL. The upper guess of
# one session was 0.10 USD at the prices of claude-haiku-4-5 (1 / 5 USD per million tokens in /
# out). claude-haiku-5-5 costs 0.10 / 0.50 (prompts up to 100K tokens), a tenth; its tokenizer
# may count up to 1.35 times the tokens: 0.10 x 0.1 x 1.35 = 0.0135, rounded up to 0.02.
SESSION_USD = 0.02          # upper guess of one session of AGENT_MODEL
PLANTED = 12                # planted breaches, one for each criterion of the pilot
LABELLED_JUDGED = 80        # 40 labelled transcripts, judged twice
TOKENS_PER_QUESTION = 7100  # the largest recorded transcript, paid once per question at worst
TOOL_RESULT_FACTOR = 3      # tool results not cut (a guess)
S1_USD_PER_MTOK = 0.042

# A hint line of the System 1 hook (s1/hook.py): a line that starts with "System 1:" (such as
# "System 1: work=build (0.83)", "System 1: effort significant (0.91)", "System 1: no view (...)")
# or with "System 1 (correction):" (the late fix, s1/hook.py CORRECTION_PREFIX). The line is
# looked for in every string of each JSON line of a transcript, split at its newlines, and in the
# raw text of a line that is not JSON.
HINT = re.compile(r"^\s*(System 1(?: \(correction\))?: .*)$")
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
        f"Agent model: {AGENT_MODEL}",
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


def write_record(out, agent_model, prompt_file, s1_hooks):
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


def _strings(o, depth=0):
    """Every string in o; a string that holds JSON (the stdout of a hook) is opened too."""
    if isinstance(o, str):
        yield o
        if depth < 4 and o.lstrip()[:1] in ("{", "["):
            try:
                inner = json.loads(o)
            except ValueError:
                return
            yield from _strings(inner, depth + 1)
    elif isinstance(o, dict):
        for v in o.values():
            yield from _strings(v, depth)
    elif isinstance(o, list):
        for v in o:
            yield from _strings(v, depth)


def hint_lines(line):
    """The hint lines of the System 1 hook in one line of a transcript file."""
    try:
        texts = list(_strings(json.loads(line)))
    except ValueError:
        texts = [line]
    found = []
    for t in texts:
        for part in t.splitlines():
            m = HINT.match(part)
            if m:
                found.append(m.group(1)[:120])
    return found


def hooks_state(env):
    """off when the environment of the agent command turns the hook off (s1/hook.py: S1_OFF)."""
    return "off" if env.get("S1_OFF", "").strip() not in ("", "0") else "on"


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
                for h in hint_lines(line):
                    bad.append(f"{n}:{i}: a System 1 hint line: {h}")
    return bad


def bad_args(a):
    """Reasons to refuse: counts under 1, a budget that is not a finite number of 0 or more."""
    bad = [f"--{k} must be 1 or more, not {getattr(a, k)}" for k in ("tasks", "arms", "runs", "criteria")
           if getattr(a, k) < 1]
    b = getattr(a, "budget", None)
    if b is not None and (not math.isfinite(b) or b < 0):
        bad.append(f"--budget must be a finite number of 0 or more, not {b}")
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
        print("CONFORMANCE_AGENT_CMD and CONFORMANCE_S1_CMD must name the model commands "
              "(agent_cmd.sh and s1_cmd.py of this directory). No call is made.")
        return 3
    out = a.out or os.path.join(HERE, "runs", "live")
    tdir = os.path.join(out, "transcripts")
    os.makedirs(tdir, exist_ok=True)
    print(f"Budget {a.budget:.2f} USD >= estimate {p['estimate_usd']:.2f} USD: the run starts.")
    import questions as qmod
    criteria = qmod.load_criteria()
    # The System 1 hooks are off in the agent under test (q1 default); the record says what the
    # environment given to the agent command held, not what was meant.
    agent_env = dict(os.environ, S1_OFF="1")
    write_record(out, a.agent_model, a.prompt, hooks_state(agent_env))
    answers = {}
    for tid in task_ids(a.tasks):
        for arm in ("prompt", "none")[:a.arms]:
            for r in range(1, a.runs + 1):
                t = os.path.join(tdir, f"{tid}.{arm}.r{r}.jsonl")
                subprocess.run([agent, str(tid), arm, str(r), t], check=True, env=agent_env)
                req = os.path.join(out, f"{tid}.{arm}.r{r}.request.json")
                with open(req, "w", encoding="utf-8") as f:
                    json.dump(qmod.build_request(t, criteria), f)
                subprocess.run([s1, req], check=True)
                # The S1 command leaves <run>.answers.json beside the request (s1_cmd.py);
                # answers.json of the run dir is what score.py reads. A stub that leaves none
                # gives an empty set for that run.
                ans = os.path.join(out, f"{tid}.{arm}.r{r}.answers.json")
                if os.path.exists(ans):
                    with open(ans, encoding="utf-8") as f:
                        answers[f"{tid}.{arm}.r{r}"] = json.load(f)
                else:
                    answers[f"{tid}.{arm}.r{r}"] = {}
    with open(os.path.join(out, "answers.json"), "w", encoding="utf-8") as f:
        json.dump(answers, f, indent=1)
        f.write("\n")
    bad = check_run(out)
    for b in bad:
        print(b)
    return 1 if bad else 0


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
            s.add_argument("--agent-model", default=AGENT_MODEL)
            s.add_argument("--prompt", default=os.path.join(ROOT, "prompt", "SAGITTARIUS.md"))
    s = sub.add_parser("record")
    s.add_argument("out")
    s.add_argument("--agent-model", required=True)
    s.add_argument("--prompt", required=True)
    s = sub.add_parser("check")
    s.add_argument("run_dir")
    a = ap.parse_args(argv)
    if a.cmd in ("plan", "live"):
        refused = bad_args(a)
        if refused:
            for r in refused:
                print(r)
            print("No plan and no call.")
            return 2
        p = plan(a.tasks, a.arms, a.runs, a.criteria)
        print("Plan:")
        for line in p["lines"]:
            print("  " + line)
        if a.cmd == "plan":
            print("Dry run: no call is made.")
            return 0
        return live(a, p)
    if a.cmd == "record":
        # The record of a run started by hand: the hooks state is read from this environment.
        print(json.dumps(write_record(a.out, a.agent_model, a.prompt, hooks_state(os.environ)), indent=1))
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
