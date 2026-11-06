#!/usr/bin/env python3
"""System 1 status line segment (T14). Python 3 standard library only; no network.

Claude Code runs a status line command and sends session JSON on stdin (it holds session_id and
transcript_path) and shows the first line of stdout. Docs: https://code.claude.com/docs/en/statusline

This script finds the newest line of the S1 log (written by s1/jev.py and s1/hook.py) that has the
same session_id and prints one segment:

    S1 build | div 0.85 | plan 0.10 | eff 0.91 | tool lean
         work choice | P(h_divergence) | P(h_change_of_plan) | P(h_effort) | h_language choice

All five judgments of the hook (T29 c6), each only when it is outside the unsure band, as the hook
decides it: a yes/no answer is shown when P <= 0.3 or P >= 0.7 (s1/jev.py band); a choice is shown
when P(choice) >= 0.5 (probabilities[choice], else confidence; hook.py CHOICE_MIN).

- No segment (empty output) when the log is missing or unreadable, when it has no line for the
  session, when stdin has no session_id, or when the newest line of the session is 10 minutes old
  or older (STALE_SECONDS).
- Newest line is an error line (error set, or answers null): prints `S1 err`.
- A choice (work, tool) with P below 0.5 is left out; a yes/no answer inside the band (0.3, 0.7) is
  left out.
- A missing or malformed answer is left out of the segment; with none left, nothing is printed.
- The log is read from its end in 64 KiB blocks, stopping at the first line that matches (at most
  MAX_SCAN bytes back). It never reads the whole file.
- Fails quiet: on any error it prints nothing and exits 0.

Env: S1_LOG (default ~/.claude/logs/s1.jsonl).
"""
import datetime as dt
import json
import os
import sys

STALE_SECONDS = 600
CHOICE_MIN = 0.5  # the hook's floor: a choice is shown when P(choice) >= 0.5
NO_MAX, YES_MIN = 0.3, 0.7  # jev.band: P <= 0.3 is no, P >= 0.7 is yes, between is unsure
BLOCK = 64 * 1024
MAX_SCAN = 8 * 1024 * 1024
DEFAULT_LOG = os.path.join("~", ".claude", "logs", "s1.jsonl")


def _tail_lines(path):
    """Complete lines of the file, newest first, read backwards in blocks (bytes)."""
    with open(path, "rb") as f:
        pos = f.seek(0, os.SEEK_END)
        floor = max(0, pos - MAX_SCAN)
        rest = b""
        while pos > floor:
            n = min(BLOCK, pos - floor)
            pos -= n
            f.seek(pos)
            parts = (f.read(n) + rest).split(b"\n")
            rest = parts[0]  # may be cut at the block start; completed by the next block
            for p in reversed(parts[1:]):
                if p.strip():
                    yield p
        if pos == 0 and rest.strip():  # the first line of the file is whole
            yield rest


def latest(session_id, path):
    """The newest log record (dict) for session_id, or None."""
    try:
        for raw in _tail_lines(path):
            try:
                d = json.loads(raw)
            except ValueError:
                continue
            if isinstance(d, dict) and d.get("session_id") == session_id:
                return d
    except OSError:
        pass
    return None


def _age(rec, now):
    t = dt.datetime.fromisoformat(str(rec["time"]).replace("Z", "+00:00"))
    if t.tzinfo is None:
        t = t.replace(tzinfo=dt.timezone.utc)
    return (now - t).total_seconds()


def _p(answers, qid):
    """P as text when the yes/no answer is outside the unsure band, else None."""
    a = answers.get(qid)
    if isinstance(a, dict) and a.get("type") == "noul":
        p = a.get("noul")
        if isinstance(p, (int, float)) and not isinstance(p, bool) and 0 <= p <= 1 \
                and (p <= NO_MAX or p >= YES_MIN):
            return f"{p:.2f}"
    return None


def _choice(a):
    """The choice when P(choice) >= CHOICE_MIN, else None. P is probabilities[choice], else
    confidence: the same rule as hook.py."""
    if not isinstance(a, dict) or a.get("type") != "choice" or not isinstance(a.get("choice"), str):
        return None
    probs = a.get("probabilities")
    p = probs.get(a["choice"]) if isinstance(probs, dict) else None
    if p is None:
        p = a.get("confidence")
    if isinstance(p, bool) or not isinstance(p, (int, float)) or p < CHOICE_MIN:
        return None
    return a["choice"]


def render(session_id, log_path, now=None):
    """The segment text for the session, or "" to show nothing. now: aware datetime (clock)."""
    try:
        if not isinstance(session_id, str) or not session_id:
            return ""
        rec = latest(session_id, os.path.expanduser(log_path))
        if rec is None:
            return ""
        now = now or dt.datetime.now(dt.timezone.utc)
        if _age(rec, now) >= STALE_SECONDS:
            return ""
        answers = rec.get("answers")
        if rec.get("error") or not isinstance(answers, dict):
            return "S1 err"
        parts = []
        c = _choice(answers.get("h_work"))
        if c:
            parts.append(c)
        for label, qid in (("div", "h_divergence"), ("plan", "h_change_of_plan"), ("eff", "h_effort")):
            p = _p(answers, qid)
            if p:
                parts.append(f"{label} {p}")
        lang = _choice(answers.get("h_language"))
        if lang:
            parts.append(f"tool {lang}")
        return ("S1 " + " | ".join(parts)) if parts else ""
    except Exception:
        return ""


def main():
    try:
        try:
            session = json.loads(sys.stdin.read()).get("session_id")
        except (ValueError, AttributeError):
            return 0
        out = render(session, os.environ.get("S1_LOG") or DEFAULT_LOG)
        if out:
            sys.stdout.write(out + "\n")
            sys.stdout.flush()
    except Exception:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
