#!/usr/bin/env python3
"""Observation harness for System 1 (0.3.0, suggestion 3): compare the hook's log with the session
transcripts, after the fact. Python 3 standard library only; no network; it reads and never writes.

    python3 s1/observe.py --log ~/.claude/logs/s1.jsonl --transcripts ~/.claude/projects [--json] [--session ID]

For each session in the log it counts:

    hints                the hints that named a signal
    shifted_after_hint   of those, the hints after which the agent shifted up in the same turn
    disputed             of those, the hints that the agent disputed in the same turn
    shifts_without_hint  the turns (not the shifts) where the agent shifted up with no hint that named a signal

The hook does not ask the agent to acknowledge a hint (q_sg3, default a): this tool compares
afterwards, so the hook stays fast.

Definitions (each a simplification; the output repeats them as "limits"):
- A hint names a signal when an answer of the log line is in the yes band (jev.band, P >= 0.7) for
  h_divergence (divergence), h_change_of_plan (divergence: a change of plan is narrowed as one),
  h_effort (effort), h_proof (burns) or h_questions (questions). A line with an error, a skip, or no
  answers is no hint.
- A hint belongs to the turn of its prompt: the user prompt whose text is the message that the log
  line holds (state.message); among prompts with the same text (a short "ok"), the one nearest in
  time; with no state in the line, the user prompt nearest in time (at most WINDOW seconds away).
- A turn is a user prompt and all agent text up to the next user prompt (tool results, meta and
  subagent lines are not prompts; as in hook.py).
- A shift is a line of the agent's reply that starts with "Shifting up:" (bold allowed). The prompt
  allows other words; the tool misses those.
- A dispute is a delivery in the turn whose "Signals:" field (bold allowed) says "no" for a signal
  that the hint named: "divergence: no", or a bare "Signals: no" for every signal. A field in a
  table or in other words is missed. A dispute in one line with no delivery is not counted.
- Only sessions that the log names are read, so a session with no hook line adds no shift.
"""
import argparse
import datetime as dt
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import hook  # noqa: E402  (the message rules of the hook: one turn is one reply)
import jev  # noqa: E402

WINDOW = 300  # seconds: the farthest a log line may be from its prompt when matched by time
SIGNALS = {"h_divergence": "divergence", "h_change_of_plan": "divergence", "h_effort": "effort",
           "h_proof": "burns", "h_questions": "questions"}
FIELD_NAMES = ("questions", "divergence", "someone else built", "burns", "handoff", "effort")
COUNTS = ("hints", "shifted_after_hint", "disputed", "shifts_without_hint")
SHIFT = re.compile(r"^\s*[*_]*Shifting up:", re.M)
LIMITS = [
    "a shift is a line that starts with \"Shifting up:\"; other words for a shift are missed",
    "a dispute is a delivery whose Signals field says \"no\" for the signal that the hint named "
    "(\"name: no\", or a bare \"no\" for every signal; the field name may be bold); "
    "a Signals field in a table, or in other words, is missed, and a dispute in one line with no "
    "delivery is not counted",
    "shifts_without_hint counts turns with a shift and no hint, not shifts: two shifts in one turn count once",
    "a hint names a signal only in the yes band (P >= 0.7) of divergence, change of plan, effort, "
    "and, when the question set has them, proof and questions",
    "a hint goes to the turn of its prompt (by the message text in the log; among prompts with the same "
    f"text, the nearest in time; else the nearest prompt within {WINDOW} s); a short prompt repeated "
    "close in time can still go to the wrong turn",
    "only sessions that the log names are read",
]


def _time(s):
    try:
        t = dt.datetime.fromisoformat(str(s).replace("Z", "+00:00"))
    except ValueError:
        return None
    return t if t.tzinfo else t.replace(tzinfo=dt.timezone.utc)


def signals_of(answers):
    """The signal names that a log line's answers name (the yes band), in a stable order."""
    out = []
    if not isinstance(answers, dict):
        return out
    for qid, name in SIGNALS.items():
        a = answers.get(qid)
        p = a.get("noul") if isinstance(a, dict) else None
        if isinstance(p, (int, float)) and not isinstance(p, bool) and 0 <= p <= 1 \
                and jev.band(p) == "yes" and name not in out:
            out.append(name)
    return out


def read_log(path, session=None):
    """{session_id: [hint records]} for the lines with answers. Bad lines are skipped."""
    out = {}
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            try:
                r = json.loads(line)
            except ValueError:
                continue
            if not isinstance(r, dict) or not r.get("session_id"):
                continue
            if session and r["session_id"] != session:
                continue
            ok = not r.get("skipped") and not r.get("error") and isinstance(r.get("answers"), dict)
            st = r.get("state")
            out.setdefault(r["session_id"], []).append({
                "time": _time(r.get("time")), "transcript": r.get("transcript"),
                "signals": signals_of(r.get("answers")) if ok else [],
                "message": st.get("message") if isinstance(st, dict) else None})
    return out


def find_transcript(root, names):
    """The first file under root whose name is one of names."""
    names = {n for n in names if n}
    for d, _, files in os.walk(root):
        for n in files:
            if n in names:
                return os.path.join(d, n)
    return None


def turns(path):
    """[{"time", "prompt", "reply"}] of a transcript, oldest first."""
    out = []
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            try:
                d = json.loads(line)
            except ValueError:
                continue
            got = hook._message(d)
            if not got:
                continue
            _, role, texts = got
            if role == "you":
                out.append({"time": _time(d.get("timestamp")), "prompt": "\n".join(texts), "reply": []})
            elif out:
                out[-1]["reply"].extend(texts)
    for t in out:
        t["reply"] = "\n".join(t["reply"])
    return out


def signals_field(reply):
    """{signal name: "yes" | "no"} from the Signals field of a delivery in the reply, else {}."""
    m = re.search(r"^\s*[*_]*Signals:[*_]*(.*(?:\n[ \t]+\S.*)*)", reply, re.M)
    if not m:
        return {}
    text = " ".join(m.group(1).split())
    if re.fullmatch(r"(?i)(no|none)\.?", text):
        return dict.fromkeys(FIELD_NAMES, "no")  # "Signals: no": no signal fired, so each hint is disputed
    out = {}
    for name in FIELD_NAMES:
        v = re.search(re.escape(name) + r"\s*:\s*(yes|no)\b", text, re.I)
        if v:
            out[name] = v.group(1).lower()
    return out


def _turn_of(h, ts):
    cands, by_text = range(len(ts)), False
    if h["message"] is not None:
        same = [i for i in cands if ts[i]["prompt"].strip() == h["message"].strip()]
        if len(same) == 1 or (same and h["time"] is None):
            return same[-1]
        if same:
            cands, by_text = same, True  # prompts with the same text ("ok"): the one nearest in time
    if h["time"] is None:
        return None
    best = None
    for i in cands:
        t = ts[i]
        if t["time"] is None:
            continue
        gap = abs((t["time"] - h["time"]).total_seconds())
        if (gap <= WINDOW or by_text) and (best is None or gap < best[0]):
            best = (gap, i)
    if best is None and by_text:
        return cands[-1]  # the same text, and no prompt with a time: the latest
    return best[1] if best else None


def observe_session(sid, hints, root):
    c = dict.fromkeys(COUNTS, 0)
    c["unmatched_hints"] = 0
    path = find_transcript(root, [h["transcript"] for h in hints] + [sid + ".jsonl"])
    c["transcript"] = path
    ts = turns(path) if path else []
    hinted = set()
    for h in hints:
        if not h["signals"]:
            continue
        c["hints"] += 1
        i = _turn_of(h, ts)
        if i is None:
            c["unmatched_hints"] += 1
            continue
        hinted.add(i)
        reply = ts[i]["reply"]
        if SHIFT.search(reply):
            c["shifted_after_hint"] += 1
        field = signals_field(reply)
        if any(field.get(s) == "no" for s in h["signals"]):
            c["disputed"] += 1
    c["shifts_without_hint"] = sum(1 for i, t in enumerate(ts) if i not in hinted and SHIFT.search(t["reply"]))
    return c


def observe(log_path, transcripts_dir, session=None):
    """The counts over every session of the log (or one), per session, and the limits."""
    sessions = {}
    for sid, hints in read_log(log_path, session).items():
        sessions[sid] = observe_session(sid, hints, transcripts_dir)
    total = {k: sum(s[k] for s in sessions.values()) for k in COUNTS}
    total["unmatched_hints"] = sum(s["unmatched_hints"] for s in sessions.values())
    total["sessions"] = sessions
    total["limits"] = LIMITS
    return total


def text(r):
    out = []
    for sid, s in sorted(r["sessions"].items()):
        out.append(f"{sid}: {sentence(s)}" + ("" if s["transcript"] else " (no transcript found)"))
    out.append(f"all sessions: {sentence(r)}")
    if r["unmatched_hints"]:
        out.append(f"{r['unmatched_hints']} hint(s) had no turn in a transcript")
    out.append("limits:")
    out += [f"- {x}" for x in r["limits"]]
    return "\n".join(out)


def sentence(c):
    return (f"{c['hints']} hints named a signal; the agent shifted up after {c['shifted_after_hint']}; "
            f"the agent disputed {c['disputed']}; the agent shifted up {c['shifts_without_hint']} "
            f"time{'' if c['shifts_without_hint'] == 1 else 's'} with no hint.")


def main(argv=None):
    ap = argparse.ArgumentParser(description="Compare the System 1 log with the session transcripts, afterwards.")
    ap.add_argument("--log", required=True, help="the System 1 log (S1_LOG; default of the hook: ~/.claude/logs/s1.jsonl)")
    ap.add_argument("--transcripts", required=True, help="the folder that holds the session transcripts (searched below)")
    ap.add_argument("--session", help="only this session id")
    ap.add_argument("--json", action="store_true", help="print the counts as JSON")
    a = ap.parse_args(argv)
    log = os.path.expanduser(a.log)
    if not os.path.isfile(log):
        print(f"observe.py: no log at {log}", file=sys.stderr)
        return 2
    r = observe(log, os.path.expanduser(a.transcripts), a.session)
    print(json.dumps(r, indent=1) if a.json else text(r))
    return 0


if __name__ == "__main__":
    sys.exit(main())
