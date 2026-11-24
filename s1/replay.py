#!/usr/bin/env python3
"""The replay experiment of one candidate question of System 1 (scientific-method-overhaul c35,
q17, rk10). Python 3 standard library only. How to use it: s1/REPLAY.md.

    python3 s1/replay.py run --cases FILE [--out FILE] [--live --hub-dir DIR] [--timeout S]
    python3 s1/replay.py draft --hub-dir DIR --question Q [--last N] [--out FILE]

run: each case of the file is judged in two arms: "today" (the state of today) and "record" (the
same state with the record of the case in it). The rule of the question (s1/trees.py) reads the
answers of each arm and gives a label; the thresholds of the case file, written before the run,
give the verdict: meets, conflicts or unresolved. The output is one JSON record with the answer
of each case in each arm. Exit code: 0 meets, 1 conflicts, 77 unresolved (the code that `orbit
run` records as unresolved), 2 a file that cannot be run.

Without --live it asks nothing: it reads the recorded answers of each case ("recorded"), for the
tests. With --live each arm of each case is one call to the System 1 model ($TYPESAFE_API_KEY),
through bench.ask, logged to the bench log and never to the log of the hook.

rk10: the log of a machine holds sessions of every hub. A case that came from the log names its
session ("source": {"kind": "log", "session_id": ...}); run refuses it unless --hub-dir is given
and that session is a session of that hub. draft takes only sessions of --hub-dir.
"""
import argparse
import datetime as dt
import hashlib
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import jev  # noqa: E402
import record  # noqa: E402
import trees  # noqa: E402

ARMS = ("today", "record")
VERDICT_EXIT = {"meets": 0, "conflicts": 1, "unresolved": 77}
QUESTIONS = ("drift", "dispute", "difference", "requests")


def asked_for(question, arm, state, tree):
    """The questions of one arm of one case."""
    rec = state.get("record")
    if question == "drift":
        return trees.ask_drift(tree, rec) if arm == "record" else {"d_drift": tree["d_drift"]}
    if question == "dispute":
        return trees.ask_dispute(tree)
    if question == "difference":
        return trees.ask_difference(tree, rec) if rec else {}
    if question == "requests":
        return trees.ask_requests(tree, state.get("sentences") or [], rec)
    raise ValueError(f"unknown question {question!r} (one of {', '.join(QUESTIONS)})")


def label_of(question, arm, answers, state):
    """(label, hint) that the rule gives for the answers of one arm of one case."""
    rec = state.get("record")
    if question == "drift":
        out = trees.read_drift(answers, rec) if arm == "record" else trees.read_drift_today(answers)
        return ("drift" if out["drifts"] else "revision" if out["revisions"] else "none"), out["hint"]
    if question == "dispute":
        out = trees.read_dispute(answers)
        return out["kind"] or "neither", out["part"]
    if question == "difference":
        parts = [x["part"] for x in trees.read_difference(answers, rec) if x["part"]]
        return ("user" if parts else "none"), "; ".join(parts) or None
    out = trees.read_requests(answers, state.get("sentences") or [], rec)
    return ",".join(r["kind"] for r in out["requests"]) or "none", out["part"]


def _time(s):
    try:
        t = dt.datetime.fromisoformat(str(s).replace("Z", "+00:00"))
    except ValueError:
        return None
    return t if t.tzinfo else t.replace(tzinfo=dt.timezone.utc)


def check_file(doc, now):
    """Raises ValueError when the case file cannot be run: no thresholds written before the run."""
    if doc.get("question") not in QUESTIONS:
        raise ValueError(f"question: one of {', '.join(QUESTIONS)}")
    th = doc.get("thresholds")
    if not isinstance(th, dict) or th.get("rule") not in ("two_arm", "accuracy"):
        raise ValueError("thresholds: an object with rule two_arm or accuracy, written before the run")
    w = _time(th.get("written"))
    if w is None:
        raise ValueError("thresholds.written: the time when the thresholds were written (ISO 8601)")
    if w > now:
        raise ValueError("thresholds.written is later than this run: thresholds are written before the run")
    if th["rule"] == "two_arm" and not (isinstance(th.get("target"), list) and isinstance(th.get("hint_labels"), list)):
        raise ValueError("thresholds of rule two_arm: target (the groups where a hint is wanted) and hint_labels")
    if th["rule"] == "accuracy" and not all(isinstance(th.get(k), (int, float)) for k in ("meets_at", "conflicts_below")):
        raise ValueError("thresholds of rule accuracy: meets_at and conflicts_below (fractions of correct labels)")
    cases = doc.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("cases: a non-empty list")
    for c in cases:
        if not isinstance(c, dict) or not c.get("id") or not c.get("group") or not isinstance(c.get("state"), dict):
            raise ValueError("each case: id, group, state, label")


def check_hub(doc, hub_dir, projects):
    """rk10: every case from the log is of a session of the one hub. Raises ValueError."""
    logged = [c for c in doc["cases"] if isinstance(c.get("source"), dict) and c["source"].get("kind") == "log"]
    if not logged:
        return
    if not hub_dir:
        raise ValueError("cases from the log need --hub-dir: the replay takes only sessions of one hub (rk10)")
    import s1inspect
    sids, _dirs = s1inspect.hub_sessions(hub_dir, projects)
    bad = [c["id"] for c in logged if c["source"].get("session_id") not in sids]
    if bad:
        raise ValueError(f"cases of a session that is not of the hub {hub_dir}: {', '.join(map(str, bad))} (rk10)")


def verdict(th, cases):
    """(verdict, reason, counts) by the thresholds. cases: the result rows of run()."""
    counts = {}
    for arm in ARMS:
        rows = [c[arm] for c in cases]
        counts[arm] = {
            "failed": sum(r["failed"] for r in rows),
            "correct": sum(1 for c in cases if c["label"] is not None and c[arm]["label"] == c["label"]),
            "hits": sum(1 for c in cases if c["group"] in th.get("target", []) and c["label"] is not None
                        and c[arm]["label"] == c["label"]),
            "false_hints": sum(1 for c in cases if c["group"] not in th.get("target", [])
                               and c[arm]["label"] in th.get("hint_labels", [])),
        }
    unjudged = [c["id"] for c in cases if c["label"] is None]
    failed = counts["today"]["failed"] + counts["record"]["failed"]
    if unjudged:
        return "unresolved", f"{len(unjudged)} cases have no label yet: {', '.join(map(str, unjudged))}", counts
    if failed > th.get("max_failed", 0):
        return "unresolved", f"{failed} arms of cases got no answer (max_failed {th.get('max_failed', 0)})", counts
    if th["rule"] == "two_arm":
        gain = counts["record"]["hits"] - counts["today"]["hits"]
        more = counts["record"]["false_hints"] - counts["today"]["false_hints"]
        said = (f"hits on {'/'.join(th['target'])}: record {counts['record']['hits']}, today {counts['today']['hits']}; "
                f"false hints on the other groups: record {counts['record']['false_hints']}, today {counts['today']['false_hints']}")
        if more > th.get("max_extra_false", 0) or gain <= 0:
            return "conflicts", said, counts
        if gain >= th.get("min_gain", 1):
            return "meets", said, counts
        return "unresolved", said + f" (a gain of {gain} is under min_gain {th.get('min_gain', 1)})", counts
    arm = th.get("arm", "record")
    frac = counts[arm]["correct"] / len(cases)
    said = f"arm {arm}: {counts[arm]['correct']} of {len(cases)} labels correct ({frac:.2f})"
    if frac >= th["meets_at"]:
        return "meets", said, counts
    return ("conflicts" if frac < th["conflicts_below"] else "unresolved"), said, counts


def run(doc, live=False, timeout=30.0, transport=None, tree=None, path=None, hub_dir=None, now=None):
    """The output record of the experiment. doc: the case file, already checked."""
    tree = tree or trees.load()
    q = doc["question"]
    rows = []
    for c in doc["cases"]:
        row = {"id": c["id"], "group": c["group"], "label": None if c.get("unsure") else c.get("label")}
        for arm in ARMS:
            st = {k: v for k, v in c["state"].items() if k != "record"}
            if arm == "record" and c.get("record"):
                st["record"] = record.clean(c["record"])
            asked = asked_for(q, arm, st, tree)
            if not asked:
                answers = {}
            elif live:
                import bench
                answers = bench.ask(st, asked, timeout, transport, f"replay:{q}:{arm}")
            else:
                answers = (c.get("recorded") or {}).get(arm)
            failed = answers is None or any(k not in answers for k in asked)
            label, hint = ("no answer", None) if failed else label_of(q, arm, answers, st)
            row[arm] = {"asked": list(asked), "answers": answers, "failed": failed, "label": label, "hint": hint}
        rows.append(row)
    v, reason, counts = verdict(doc["thresholds"], rows)
    out = {"experiment": "s1-replay", "question": q, "claim": doc.get("claim"),
           "case_file": path, "thresholds": doc["thresholds"],
           "run": {"time": (now or dt.datetime.now(dt.timezone.utc)).isoformat(timespec="seconds"), "live": bool(live),
                   "model": jev.DEFAULT_MODEL if live else None, "sagittarius": jev.sagittarius_version(),
                   "hub_dir": hub_dir},
           "arms": counts, "cases": rows, "verdict": v, "reason": reason}
    if path:
        with open(path, "rb") as f:
            out["case_file_sha256"] = hashlib.sha256(f.read()).hexdigest()
    return out


def draft(args):
    """Case skeletons from the logged states of one hub (rk10): no label, no group, no record."""
    import s1inspect
    log, _bad = s1inspect.read_log(args.log)
    pairs, _info = s1inspect.select(log, args.hub_dir, args.projects, None, None, args.last, False)
    cases = []
    for i, r in pairs:
        if not isinstance(r.get("state"), dict) or r.get("combined"):
            continue
        st = {k: r["state"][k] for k in ("context", "message", "recent", "sentences") if k in r["state"]}
        cases.append({"id": f"log{i}", "group": "TO LABEL", "label": None, "unsure": True,
                      "source": {"kind": "log", "session_id": r.get("session_id"), "time": r.get("time")},
                      "state": st, "record": None})
    return {"question": args.question, "claim": None,
            "thresholds": {"written": "WRITE THE TIME, BEFORE THE RUN", "by": "WHO", "rule": "two_arm",
                           "target": [], "hint_labels": [], "min_gain": 1, "max_extra_false": 0, "max_failed": 0},
            "cases": cases}


def main(argv=None, transport=None):
    p = argparse.ArgumentParser(description="The replay experiment of one candidate question of System 1.")
    sub = p.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("run")
    r.add_argument("--cases", required=True)
    r.add_argument("--out")
    r.add_argument("--live", action="store_true", help="ask the System 1 model (costs money; text leaves the machine)")
    r.add_argument("--hub-dir", help="the one hub whose sessions the cases may come from (rk10)")
    r.add_argument("--projects", default=os.path.expanduser("~/.claude/projects"))
    r.add_argument("--timeout", type=float, default=30.0)
    d = sub.add_parser("draft")
    d.add_argument("--hub-dir", required=True)
    d.add_argument("--question", required=True, choices=QUESTIONS)
    d.add_argument("--last", type=int, default=30)
    d.add_argument("--log", default=os.environ.get(jev.LOG_ENV) or jev.DEFAULT_LOG)
    d.add_argument("--projects", default=os.path.expanduser("~/.claude/projects"))
    d.add_argument("--out")
    args = p.parse_args(argv)
    try:
        if args.cmd == "draft":
            out, code = draft(args), 0
        else:
            with open(args.cases, encoding="utf-8") as f:
                doc = json.load(f)
            check_file(doc, dt.datetime.now(dt.timezone.utc))
            check_hub(doc, args.hub_dir, args.projects)
            if args.live and not os.environ.get(jev.KEY_ENV) and transport is None:
                raise ValueError(f"--live needs ${jev.KEY_ENV}")
            out = run(doc, args.live, args.timeout, transport, path=args.cases, hub_dir=args.hub_dir)
            code = VERDICT_EXIT[out["verdict"]]
            print(f"replay {out['question']}: {out['verdict']} ({out['reason']})", file=sys.stderr)
    except (OSError, ValueError) as e:
        print(f"replay: {e}", file=sys.stderr)
        return 2
    text = json.dumps(out, ensure_ascii=False, indent=1)
    if args.out:
        with open(args.out, "w", encoding="utf-8") as f:
            f.write(text + "\n")
    else:
        print(text)
    return code


if __name__ == "__main__":
    sys.exit(main())
