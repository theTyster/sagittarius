#!/usr/bin/env python3
"""The System 1 workbench: ask the System 1 model again, with a question file you edit, about prompts it
has already judged, and see what changed. Python 3 standard library only. It calls the network (one
call per judgment) and needs $TYPESAFE_API_KEY. Run by a person, never by a test.

    python3 s1/bench.py --questions my-questions.json [--hub PATH] [--session ID] [--since ISO] [--last N]
                        [--baseline] [--dry-run] [--json]

Each judgment of the selection (the newest 5 unless --last says otherwise; the same selection as
s1inspect.py) is asked again with the state the log holds (the message and the messages before it) and
the questions of --questions. For each question the output puts the logged answer beside the new one and
marks a change of band (yes / no / unsure; a choice shown at P >= 0.5) with *.

--pipeline FILE replaces the one call with your own routing: a Python file that defines
    run(state, ask, questions) -> {question id: answer}
where ask(questions_dict) makes one call and returns its answers (or None), and questions is the dict of
--questions. It may ask in stages (ask one question first, then only the questions of that branch), split
or merge questions, or skip some. It may also define hint(answers, questions) -> str, the line the agent
would get; without it the hook's format_answers is used. The new answers are compared with the logged
ones question by question, by id.

--baseline also asks the checkout's own questions.json again, so a change can be told apart from the
model's own variation between two calls. --dry-run asks nothing: it says how many calls a run would make.

The calls are logged to $S1_BENCH_LOG (default ~/.claude/logs/s1-bench.jsonl), never to the hook's log, so
the views and s1inspect show only real prompts. For the tracked calibration cases use calibrate.py:
    python3 s1/calibrate.py --questions my-questions.json
"""
import argparse
import json
import os
import sys
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import jev  # noqa: E402
import s1inspect  # noqa: E402

BENCH_LOG = os.environ.get("S1_BENCH_LOG") or os.path.expanduser("~/.claude/logs/s1-bench.jsonl")
DEFAULT_LAST = 5


def reading(a):
    """(band, p, text) of one answer as the hook reads it, or (None, None, '-') for none."""
    if not isinstance(a, dict):
        return None, None, "-"
    x = s1inspect._answer(None, a, None)
    if x.get("malformed"):
        return "malformed", None, "malformed"
    if x["type"] == "noul":
        return x["band"], x["value"], f"{x['band']} {x['value']:.2f}"
    if x["type"] == "choice":
        shown = x["choice"] if x["band"] == "shown" else "unsure"
        return shown, x["p"], f"{shown} ({x['choice']} {x['p']:.2f})"
    return str(x["type"]), None, str(x["type"])


def load_pipeline(path):
    """The module of --pipeline (run, and hint if it has one), or None."""
    if not path:
        return None
    import importlib.util
    spec = importlib.util.spec_from_file_location("s1_bench_pipeline", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    if not callable(getattr(mod, "run", None)):
        raise ValueError(f"--pipeline {path}: it defines no run(state, ask, questions)")
    return mod


def hint_of(answers, questions, pipe):
    """The line the agent would get from these answers, or None."""
    if not answers:
        return None
    try:
        if pipe is not None and callable(getattr(pipe, "hint", None)):
            return pipe.hint(answers, questions)
        import hook
        return hook.format_answers(answers, questions)
    except Exception as e:
        return f"(no line: {type(e).__name__}: {e})"


def ask(state, questions, timeout, transport=None, tag=None):
    """The answers of one call, or None on a failure (jev.judge logs it to the bench log)."""
    return jev.judge(state, questions, timeout=timeout, log_path=BENCH_LOG, transport=transport,
                     log_extra={"bench": tag or "new"})


def compare(rec, new, base, qids):
    """One judgment's rows: (qid, logged text, baseline text or None, new text, changed)."""
    rows = []
    logged = rec.get("answers") or {}
    for q in qids:
        lb, _, lt = reading(logged.get(q))
        nb, _, nt = reading((new or {}).get(q))
        bt = reading((base or {}).get(q))[2] if base is not None else None
        rows.append({"question": q, "logged": lt, "baseline": bt, "new": nt,
                     "changed": new is not None and lb != nb})
    return rows


def run(args, transport=None):
    log, _bad = s1inspect.read_log(args.log)
    last = args.last if args.last is not None else DEFAULT_LAST
    pairs, info = s1inspect.select(log, args.hub, args.projects, args.session, args.since, last, False)
    pairs = [(i, r) for i, r in pairs if isinstance(r.get("state"), dict) and r.get("answers")]
    newq, err = s1inspect.load_questions(args.questions)
    if newq is None:
        raise ValueError(f"--questions {args.questions}: {err}")
    baseq = None
    if args.baseline:
        baseq, err = s1inspect.load_questions(os.path.join(HERE, "questions.json"))
        if baseq is None:
            raise ValueError(f"questions.json of the checkout: {err}")
    pipe = load_pipeline(args.pipeline)
    calls = len(pairs) * (2 if baseq else 1)
    if pipe is not None:
        calls = f"{len(pairs)} runs of the pipeline" + (f" + {len(pairs)} baseline calls" if baseq else "")
    if args.dry_run:
        return {"judgments": len(pairs), "calls": calls, "questions": list(newq), "results": []}

    def one(pair):
        _i, rec = pair
        st = rec["state"]
        if pipe is not None:
            n = [0]

            def asker(qs):
                n[0] += 1
                return ask(st, qs, args.timeout, transport, f"pipeline:{n[0]}")
            try:
                new = pipe.run(st, asker, newq)
            except Exception as e:
                new = None
                print(f"bench: the pipeline failed: {type(e).__name__}: {e}", file=sys.stderr)
        else:
            new = ask(st, newq, args.timeout, transport, "new")
        base = ask(st, baseq, args.timeout, transport, "baseline") if baseq else None
        qids = list(dict.fromkeys(list(newq) + list((new or {}).keys()) + list((rec.get("answers") or {}).keys())))
        return {"time": rec.get("time"), "session": s1inspect._short(rec.get("session_id")),
                "message": s1inspect._text((st or {}).get("message")), "failed": new is None,
                "rows": compare(rec, new, base, qids),
                "logged_hint": hint_of(rec.get("answers"), newq, None),
                "new_hint": hint_of(new, newq, pipe)}

    with ThreadPoolExecutor(max_workers=4) as ex:
        results = list(ex.map(one, pairs))
    return {"judgments": len(pairs), "calls": calls, "questions": list(newq), "results": results}


def render(out):
    calls = out["calls"] if isinstance(out["calls"], str) else f"{out['calls']} calls"
    lines = [f"{out['judgments']} judgments, {calls}; questions: {', '.join(out['questions'])}"]
    changed = {}
    for r in out["results"]:
        msg = " ".join((r["message"] or "").split())
        lines.append("")
        lines.append(f"{r['time']}  session {r['session']}  {msg[:90]}{'…' if len(msg) > 90 else ''}")
        if r["failed"]:
            lines.append("  the new call failed (see the bench log)")
        if r.get("new_hint") is not None:
            lines.append(f"   line: logged {r.get('logged_hint')}")
            lines.append(f"         new    {r['new_hint']}")
        has_base = any(x["baseline"] is not None for x in r["rows"])
        for x in r["rows"]:
            mark = "*" if x["changed"] else " "
            base = f"  baseline {x['baseline']:<26}" if has_base else ""
            lines.append(f" {mark} {x['question']:<18} logged {x['logged']:<26}{base}  new {x['new']}")
            if x["changed"]:
                changed[x["question"]] = changed.get(x["question"], 0) + 1
    lines.append("")
    lines.append("changed bands: " + (", ".join(f"{q} {n}" for q, n in changed.items()) or "none"))
    lines.append(f"calls logged to {BENCH_LOG}")
    return "\n".join(lines)


def parser():
    p = argparse.ArgumentParser(description="Ask System 1 again with an edited question file; compare.")
    p.add_argument("--questions", required=True, help="the question file to try (a copy of s1/questions.json)")
    p.add_argument("--hub")
    p.add_argument("--session")
    p.add_argument("--since")
    p.add_argument("--last", type=int, help=f"the newest N judgments (default {DEFAULT_LAST})")
    p.add_argument("--log", default=os.environ.get(jev.LOG_ENV) or jev.DEFAULT_LOG)
    p.add_argument("--projects", default=s1inspect.DEFAULT_PROJECTS)
    p.add_argument("--pipeline", help="a Python file with run(state, ask, questions): your own routing")
    p.add_argument("--baseline", action="store_true", help="also ask the checkout's questions.json again")
    p.add_argument("--dry-run", action="store_true", help="ask nothing; count the calls")
    p.add_argument("--timeout", type=float, default=30.0)
    p.add_argument("--json", action="store_true")
    return p


def main(argv=None, transport=None):
    args = parser().parse_args(argv)
    try:
        out = run(args, transport)
    except (OSError, ValueError) as e:
        print(f"bench: {e}", file=sys.stderr)
        return 2
    if args.dry_run:
        calls = out["calls"] if isinstance(out["calls"], str) else f"{out['calls']} calls"
        print(f"dry run: {out['judgments']} judgments, {calls}; nothing was asked")
    else:
        print(json.dumps(out, ensure_ascii=False, indent=1) if args.json else render(out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
