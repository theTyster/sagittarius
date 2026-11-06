#!/usr/bin/env python3
"""System 1 hook for Claude Code (T07). Event: UserPromptSubmit. Python 3 standard library only.

Reads the hook JSON on stdin (prompt, transcript_path, session_id), asks Jev the questions in
s1/questions.json about {message: the prompt, recent: the last agent message, at most 600
characters}, and prints one line of the answers outside the unsure band as additionalContext:

    {"hookSpecificOutput": {"hookEventName": "UserPromptSubmit",
                            "additionalContext": "System 1: work=build (0.83); ..."}}

Output shape: https://code.claude.com/docs/en/hooks ("UserPromptSubmit decision control").

Fails open: on any error, a timeout, a missing key, a missing questions file or bad stdin it
prints nothing and exits 0. It never blocks a prompt.

Env: TYPESAFE_API_KEY (the key), S1_OFF=1 (do nothing), S1_TIMEOUT (seconds, default 4),
S1_QUESTIONS (default s1/questions.json), S1_REDACT (default s1/redact.txt: one name per line,
'#' starts a comment), S1_LOG (default ~/.claude/logs/s1.jsonl).
"""
import json
import os
import sys
import threading

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import jev  # noqa: E402

DEFAULT_TIMEOUT = 4.0
GRACE = 0.5  # seconds past the timeout before the hook stops waiting for the call
RECENT_MAX = 600
REDACTED = "[redacted]"
CHOICE_MIN = 0.5  # a choice is shown when P(choice) >= 0.5, as in the calibration


def _timeout(env):
    try:
        t = float(env.get("S1_TIMEOUT", DEFAULT_TIMEOUT))
        return t if t > 0 else DEFAULT_TIMEOUT
    except (TypeError, ValueError):
        return DEFAULT_TIMEOUT


def load_redactions(path):
    """[(name, REDACTED), ...] from a file with one name per line. A missing file gives []."""
    try:
        with open(path, encoding="utf-8") as f:
            lines = f.read().splitlines()
    except FileNotFoundError:
        return []
    names = [x.strip() for x in lines]
    return [(n, REDACTED) for n in names if n and not n.startswith("#")]


def last_agent_message(path):
    """The text of the last assistant message in a transcript JSONL, or "".
    One message is spread over several lines (one per content block) that share message.id;
    their text blocks are joined. Subagent (sidechain) lines are skipped."""
    if not path:
        return ""
    try:
        with open(path, encoding="utf-8") as f:
            raw = f.read().splitlines()
    except OSError:
        return ""
    found = []  # (message id, [texts]) for assistant lines that hold text
    for line in raw:
        try:
            d = json.loads(line)
        except ValueError:
            continue
        if not isinstance(d, dict) or d.get("type") != "assistant" or d.get("isSidechain"):
            continue
        m = d.get("message")
        if not isinstance(m, dict):
            continue
        c = m.get("content")
        if isinstance(c, str):
            texts = [c]
        elif isinstance(c, list):
            texts = [b["text"] for b in c
                     if isinstance(b, dict) and b.get("type") == "text" and isinstance(b.get("text"), str)]
        else:
            texts = []
        texts = [t for t in texts if t.strip()]
        if texts:
            found.append((m.get("id"), texts))
    if not found:
        return ""
    last_id = found[-1][0]
    if last_id is None:
        return "\n".join(found[-1][1])
    return "\n".join(t for mid, ts in found if mid == last_id for t in ts)


def build_state(prompt, transcript_path, pairs):
    """{message, recent}, redacted, then recent cut to RECENT_MAX characters.
    recent carries the "Agent: " prefix the calibration used."""
    recent = last_agent_message(transcript_path)
    st = jev.redact({"message": prompt, "recent": ("Agent: " + recent) if recent else ""}, pairs)
    st["recent"] = st["recent"][:RECENT_MAX]
    return st


def _p(x):
    if isinstance(x, bool) or not isinstance(x, (int, float)) or not 0 <= x <= 1:
        raise ValueError(f"not a probability: {x!r}")
    return float(x)


def _noul(a):
    if a.get("type") != "noul":
        raise ValueError("not a noul answer")
    p = _p(a["noul"])
    return jev.band(p), p


def _choice(a, question):
    """(choice, P(choice)) or None when unsure. P is probabilities[choice], else confidence."""
    if a.get("type") != "choice":
        raise ValueError("not a choice answer")
    c = a["choice"]
    if c not in question.get("criteria", {}):
        raise ValueError(f"unknown choice {c!r}")
    probs = a.get("probabilities")
    p = _p(probs[c] if isinstance(probs, dict) and c in probs else a["confidence"])
    return (c, p) if p >= CHOICE_MIN else None


def format_answers(answers, questions):
    """One line, or "" when every answer is unsure. Raises on a malformed answer."""
    parts = []
    w = _choice(answers["h_work"], questions["h_work"])
    if w:
        parts.append(f"work={w[0]} ({w[1]:.2f})")
    d, dp = _noul(answers["h_divergence"])
    c, cp = _noul(answers["h_change_of_plan"])
    if d == "yes" and c == "yes":
        parts.append("divergence or change of plan: check which (prompt rule)")
    else:
        if d != "unsure":
            parts.append(f"divergence {'likely' if d == 'yes' else 'unlikely'} ({dp:.2f})")
        if c != "unsure":
            parts.append(f"change of plan {'likely' if c == 'yes' else 'unlikely'} ({cp:.2f})")
    e, ep = _noul(answers["h_effort"])
    if e == "yes":
        parts.append(f"effort significant ({ep:.2f}): consider a shift up")
    elif e == "no":
        parts.append(f"effort not significant ({ep:.2f})")
    lang = _choice(answers["h_language"], questions["h_language"])
    if lang:
        parts.append(f"formal tool: {lang[0]} ({lang[1]:.2f})")
    return ("System 1: " + "; ".join(parts)) if parts else ""


def run(raw, env, transport=None):
    """The hook's stdout for stdin text raw: a JSON hook result, or "" for nothing.
    Never raises."""
    try:
        if env.get("S1_OFF", "").strip() not in ("", "0"):
            return ""
        payload = json.loads(raw)
        if not isinstance(payload, dict) or not isinstance(payload.get("prompt"), str):
            return ""
        with open(env.get("S1_QUESTIONS") or os.path.join(HERE, "questions.json"),
                  encoding="utf-8") as f:
            questions = json.load(f)
        if not isinstance(questions, dict) or not questions:
            return ""
        tpath = payload.get("transcript_path")
        tpath = tpath if isinstance(tpath, str) else ""
        extra = {"session_id": payload.get("session_id"),
                 "transcript": os.path.basename(tpath) or None}
        state = build_state(payload["prompt"],
                            tpath, load_redactions(env.get("S1_REDACT") or os.path.join(HERE, "redact.txt")))
        timeout = _timeout(env)
        log_path = env.get(jev.LOG_ENV) or jev.DEFAULT_LOG
        key = env.get(jev.KEY_ENV) or ""
        if not key:  # judge would fall back to os.environ; the hook reads only env
            jev._log(log_path, None, {"time": jev._now(), "model": jev.DEFAULT_MODEL,
                                      "questions": list(questions), "state": state,
                                      "answers": None, "latency": 0.0, "usage": None,
                                      "error": f"RuntimeError: missing API key (${jev.KEY_ENV})",
                                      **extra})
            return ""
        box = {}

        def call():
            box["answers"] = jev.judge(state, questions, timeout=timeout, key=key,
                                       log_path=log_path, transport=transport, log_extra=extra)

        t = threading.Thread(target=call, daemon=True)
        t.start()
        t.join(timeout + GRACE)
        if t.is_alive():
            jev._log(log_path, key, {"time": jev._now(), "model": jev.DEFAULT_MODEL,
                                     "questions": list(questions), "state": state,
                                     "answers": None, "latency": timeout + GRACE, "usage": None,
                                     "error": f"timeout: the hook stopped waiting after "
                                              f"{timeout + GRACE}s", **extra})
            return ""
        answers = box.get("answers")
        if not answers:
            return ""
        line = format_answers(answers, questions)
        if not line:
            return ""
        return json.dumps({"hookSpecificOutput": {"hookEventName": "UserPromptSubmit",
                                                  "additionalContext": line}})
    except Exception:
        return ""


def main(transport=None):
    """Script entry: stdin to stdout. Always returns 0."""
    try:
        if os.environ.get("S1_OFF", "").strip() not in ("", "0"):
            return 0
        out = run(sys.stdin.read(), dict(os.environ), transport=transport)
        if out:
            sys.stdout.write(out + "\n")
            sys.stdout.flush()
    except Exception:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
