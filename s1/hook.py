#!/usr/bin/env python3
"""System 1 hook for Claude Code (T07). Event: UserPromptSubmit. Python 3 standard library only.

Reads the hook JSON on stdin (prompt, transcript_path, session_id), asks Jev the questions in
s1/questions.json about {message: the prompt, recent: the last 3 messages before it}, and prints
one line of the answers outside the unsure band as additionalContext:

    {"hookSpecificOutput": {"hookEventName": "UserPromptSubmit",
                            "additionalContext": "System 1: work=build (0.83); ..."}}

Output shape: https://code.claude.com/docs/en/hooks ("UserPromptSubmit decision control").

What is sent (T20): `recent` is a list, oldest first, of the last 3 messages before the prompt
(S1_CONTEXT_MESSAGES raises the count; never below 3). Each item is {"role": "you" | "agent",
"text": the complete text}. A message is a user prompt or an assistant reply; tool calls, tool
results, meta lines and subagent (sidechain) lines are not messages. An assistant reply is all
the agent text of one turn (between two user prompts). Each text is sent whole.
Only when the state and the longest question would pass Jev's per-question context (32k tokens,
counted here as CONTEXT_CHARS characters) are the messages beyond 3 dropped, oldest first. If the
3 whole messages still do not fit, they are sent whole with the TypeSafe-Danger-Zone-Long-Context
header (262k tokens; slower, same price; the log line has "long_context": true). Only beyond 262k
is the oldest message cut from its start; the log line then has "trimmed": true. The transcript
read starts with the last 2 MiB and goes back, at most 8 MiB, until it has the messages.
The hook sends the complete messages as written, with no redaction (T43, u123): no name list is
applied to them.

Fails open: on any error, a timeout, a missing key, a missing questions file or bad stdin it
prints nothing and exits 0. It never blocks a prompt.

Env: TYPESAFE_API_KEY (the key), S1_OFF=1 (do nothing), S1_TIMEOUT (seconds, default 4),
S1_CONTEXT_MESSAGES (default 3, never below 3),
S1_QUESTIONS (default s1/questions.json), S1_LOG (default ~/.claude/logs/s1.jsonl).
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
CONTEXT_MESSAGES = 3  # the least number of messages in recent (T20, Ty)
TAIL_BYTES = 2 * 1024 * 1024  # the first read: the end of the transcript
MAX_TAIL_BYTES = 8 * 1024 * 1024  # the read goes back at most this far (as the status line)
CONTEXT_TOKENS = 32000  # Jev's default per-question context (models page)
CHARS_PER_TOKEN = 3  # a cautious count: fewer characters per token than English text has
CONTEXT_CHARS = CONTEXT_TOKENS * CHARS_PER_TOKEN
LONG_CONTEXT_TOKENS = 262000  # with the long-context header (TypeSafe docs, models page)
LONG_CONTEXT_CHARS = LONG_CONTEXT_TOKENS * CHARS_PER_TOKEN
CHOICE_MIN = 0.5  # a choice is shown when P(choice) >= 0.5, as in the calibration


def _timeout(env):
    try:
        t = float(env.get("S1_TIMEOUT", DEFAULT_TIMEOUT))
        return t if t > 0 else DEFAULT_TIMEOUT
    except (TypeError, ValueError):
        return DEFAULT_TIMEOUT


def _tail_lines(path, size=TAIL_BYTES):
    """The lines in the last `size` bytes of a file, decoded with errors="replace".
    The first line is dropped when the read starts mid-file (it is likely cut)."""
    with open(path, "rb") as f:
        f.seek(0, os.SEEK_END)
        end = f.tell()
        start = max(0, end - size)
        f.seek(start)
        data = f.read(end - start)
    lines = data.decode("utf-8", errors="replace").splitlines()
    return lines[1:] if start > 0 else lines


def _count(env):
    try:
        n = int(env.get("S1_CONTEXT_MESSAGES", CONTEXT_MESSAGES))
    except (TypeError, ValueError):
        return CONTEXT_MESSAGES
    return max(n, CONTEXT_MESSAGES)


def _message(d):
    """(key, role, [texts]) for a transcript line that is part of a message, else None."""
    if not isinstance(d, dict) or d.get("isSidechain") or d.get("isMeta"):
        return None
    kind = d.get("type")
    m = d.get("message")
    if kind not in ("user", "assistant") or not isinstance(m, dict):
        return None
    c = m.get("content")
    if isinstance(c, str):
        texts = [c]
    elif isinstance(c, list):
        if any(isinstance(b, dict) and b.get("type") == "tool_result" for b in c):
            return None
        texts = [b["text"] for b in c
                 if isinstance(b, dict) and b.get("type") == "text" and isinstance(b.get("text"), str)]
    else:
        texts = []
    texts = [t for t in texts if t.strip()]
    if not texts:
        return None
    role = "agent" if kind == "assistant" else "you"
    key = ("agent", m.get("id")) if kind == "assistant" and m.get("id") is not None else None
    return key, role, texts


def _messages(lines):
    """The messages of transcript lines, oldest first: [{"role", "text"}]. An assistant reply is
    all the agent text between two user prompts (one turn): the lines of every API message in
    it (one line per content block, each response with its own message.id) are joined in order."""
    out = []  # [key, role, [texts]]
    for line in lines:
        try:
            d = json.loads(line)
        except ValueError:
            continue
        got = _message(d)
        if not got:
            continue
        key, role, texts = got
        if role == "agent" and out and out[-1][1] == "agent":  # one turn is one reply (T20 c9)
            out[-1][2].extend(texts)
        else:
            out.append([key, role, list(texts)])
    return [{"role": r, "text": "\n".join(ts)} for _, r, ts in out]


def recent_messages(path, n, prompt=None):
    """The last n messages before the prompt, oldest first. The read starts with the last
    TAIL_BYTES and doubles, at most MAX_TAIL_BYTES, until it has n + 1 messages (one more, in
    case the prompt is already in the transcript) or the whole file."""
    if not path:
        return []
    size = TAIL_BYTES
    while True:
        try:
            with open(path, "rb") as f:
                f.seek(0, os.SEEK_END)
                whole = f.tell() <= size
            msgs = _messages(_tail_lines(path, size))
        except OSError:
            return []
        if whole or len(msgs) > n or size >= MAX_TAIL_BYTES:
            break
        size = min(size * 2, MAX_TAIL_BYTES)
    if prompt is not None and msgs and msgs[-1]["role"] == "you" and msgs[-1]["text"].strip() == prompt.strip():
        msgs = msgs[:-1]
    return msgs[-n:]


def _fit(state, questions):
    """Fit the state to the context (T30 c1). Returns (trimmed, long_context).

    Over the default context: drop the messages beyond 3, oldest first. If the 3 still do not
    fit, keep them whole and ask for the long context (LONG_CONTEXT_CHARS). Only past that is
    the oldest cut from its start."""
    longest = max((len(json.dumps(v)) for v in questions.values()), default=0)

    def size():
        return len(json.dumps(state)) + longest

    trimmed = False
    rec = state["recent"]
    while size() > CONTEXT_CHARS and len(rec) > CONTEXT_MESSAGES:
        rec.pop(0)
        trimmed = True
    long_context = size() > CONTEXT_CHARS
    while size() > LONG_CONTEXT_CHARS and rec:
        over = size() - LONG_CONTEXT_CHARS  # each character takes at least one in the JSON
        t = rec[0]["text"]
        if over >= len(t):
            rec.pop(0)
        else:
            rec[0]["text"] = t[over:]
        trimmed = True
    return trimmed, long_context


def build_state(prompt, transcript_path, n=CONTEXT_MESSAGES, questions=None):
    """{message, recent} as written (no redaction, T43), then fitted. Returns (state, trimmed, long_context)."""
    recent = recent_messages(transcript_path, n, prompt)
    st = {"message": prompt, "recent": recent}
    trimmed, long_context = _fit(st, questions or {})
    return st, trimmed, long_context


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


def _skip(log_path, key, reason, extra=None, **fields):
    """One log line that says why the hook made no call or printed nothing. No key."""
    rec = {"time": jev._now(), "skipped": reason}
    rec.update(fields)
    rec.update(extra or {})
    jev._log(log_path, key, rec)


def run(raw, env, transport=None):
    """The hook's stdout for stdin text raw: a JSON hook result, or "" for nothing.
    Never raises. Every skip except S1_OFF writes one log line with the reason."""
    if env.get("S1_OFF", "").strip() not in ("", "0"):
        return ""
    log_path = env.get(jev.LOG_ENV) or jev.DEFAULT_LOG
    key = env.get(jev.KEY_ENV) or ""
    extra = {}
    try:
        try:
            payload = json.loads(raw)
        except ValueError as e:
            _skip(log_path, key, f"stdin: not JSON ({e})")
            return ""
        if not isinstance(payload, dict) or not isinstance(payload.get("prompt"), str):
            _skip(log_path, key, "stdin: no prompt")
            return ""
        tpath = payload.get("transcript_path")
        tpath = tpath if isinstance(tpath, str) else ""
        extra = {"session_id": payload.get("session_id"),
                 "transcript": os.path.basename(tpath) or None}
        try:
            with open(env.get("S1_QUESTIONS") or os.path.join(HERE, "questions.json"),
                      encoding="utf-8") as f:
                questions = json.load(f)
            if not isinstance(questions, dict) or not questions:
                raise ValueError("not a non-empty object")
        except (OSError, ValueError) as e:
            _skip(log_path, key, f"questions: {type(e).__name__}: {e}", extra)
            return ""
        timeout = _timeout(env)
        if not key:  # judge would fall back to os.environ; the hook reads only env
            _skip(log_path, None, "no API key", extra, model=jev.DEFAULT_MODEL,
                  questions=list(questions), answers=None, latency=0.0, usage=None,
                  error=f"RuntimeError: missing API key (${jev.KEY_ENV})")
            return ""
        box = {}

        def call():  # the transcript read and the request both run inside the timeout
            try:
                state, trimmed, long_context = build_state(payload["prompt"], tpath, _count(env), questions)
            except Exception as e:
                box["error"] = f"state: {type(e).__name__}: {e}"
                return
            lx = dict(extra, trimmed=True) if trimmed else dict(extra)
            if long_context:
                lx["long_context"] = True
            box["answers"] = jev.judge(state, questions, timeout=timeout, key=key,
                                       log_path=log_path, transport=transport, log_extra=lx,
                                       long_context=long_context)

        t = threading.Thread(target=call, daemon=True)
        t.start()
        t.join(timeout + GRACE)
        if t.is_alive():
            _skip(log_path, key, f"timeout: the hook stopped waiting after {timeout + GRACE}s",
                  extra, model=jev.DEFAULT_MODEL, questions=list(questions),
                  latency=timeout + GRACE, error=f"timeout: after {timeout + GRACE}s")
            return ""
        if "error" in box:
            _skip(log_path, key, box["error"], extra)
            return ""
        answers = box.get("answers")
        if not answers:
            _skip(log_path, key, "no answers (the call's line has the error)", extra)
            return ""
        try:
            line = format_answers(answers, questions)
        except Exception as e:
            _skip(log_path, key, f"bad answers: {type(e).__name__}: {e}", extra)
            return ""
        if not line:
            return ""
        return json.dumps({"hookSpecificOutput": {"hookEventName": "UserPromptSubmit",
                                                  "additionalContext": line}})
    except Exception as e:
        _skip(log_path, key, f"error: {type(e).__name__}: {e}", extra)
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
