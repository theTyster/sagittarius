"""Small Jev (TypeSafe System One) client. Python 3 standard library only.

API: https://docs.typesafe.ai/api.md   POST https://api.typesafe.ai/v1/systemone

    judge(state, questions, *, model, timeout, ...) -> {qid: answer} or None
    redact(obj, pairs)        case-insensitive replacement in every string of a nested value
    band(p)                   "yes" (p >= 0.7) | "no" (p <= 0.3) | "unsure"
    to_prolog(run_id, answers)  Prolog facts, atoms quoted safely

judge fails open: a timeout, an HTTP error, a bad reply or a missing key logs the error
and returns None. It never raises to the caller.

Transport (injectable, for tests): transport(url, headers, body_bytes, timeout)
returns (status_int, response_text). It may raise TimeoutError or OSError.
"""
import json
import os
import re
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone

URL = "https://api.typesafe.ai/v1/systemone"
DEFAULT_MODEL = "jev-1.14.0"
DEFAULT_TIMEOUT = 20.0
DEFAULT_LOG = os.path.expanduser("~/.claude/logs/s1.jsonl")
KEY_ENV = "TYPESAFE_API_KEY"
LOG_ENV = "S1_LOG"
LONG_CONTEXT_HEADER = "TypeSafe-Danger-Zone-Long-Context"  # docs.typesafe.ai/models.md


def urllib_transport(url, headers, body, timeout):
    req = urllib.request.Request(url, data=body, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, r.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", "replace")
    except urllib.error.URLError as e:
        if isinstance(e.reason, TimeoutError):
            raise e.reason
        raise OSError(str(e.reason))


def redact(obj, pairs):
    """Return a copy of obj with each (original, replacement) replaced, case-insensitively,
    in every string (values and dict keys). One pass, so a replacement is never rescanned.
    The match maps back to its pair by group, not by lower(), so case folding never fails.
    Two dict keys that become the same key raise ValueError (no value is dropped)."""
    pairs = sorted([(a, b) for a, b in pairs if a], key=lambda p: -len(p[0]))
    if not pairs:
        return obj
    rx = re.compile("|".join("(" + re.escape(a) + ")" for a, _ in pairs), re.IGNORECASE)

    def walk(o):
        if isinstance(o, str):
            return rx.sub(lambda m: pairs[m.lastindex - 1][1], o)
        if isinstance(o, dict):
            out = {}
            for k, v in o.items():
                k2 = walk(k)
                if k2 in out:
                    raise ValueError("redaction makes two keys the same")
                out[k2] = walk(v)
            return out
        if isinstance(o, (list, tuple)):
            return [walk(v) for v in o]
        return o

    return walk(obj)


def band(p):
    if p >= 0.7:
        return "yes"
    if p <= 0.3:
        return "no"
    return "unsure"


def _log(path, key, record):
    """Append one JSON line. The key is scrubbed from the line. Never raises."""
    try:
        line = json.dumps(record, ensure_ascii=False, default=str)
        if key:
            for k in {key, json.dumps(key)[1:-1]}:
                line = line.replace(k, "[KEY]")
        os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
        with open(path, "a", encoding="utf-8") as f:
            f.write(line + "\n")
    except Exception:
        pass


_CORE = ("time", "model", "questions", "state", "answers", "latency", "usage", "error")


def judge(state, questions, *, model=DEFAULT_MODEL, timeout=DEFAULT_TIMEOUT,
          redactions=None, key=None, log_path=None, transport=None, log_extra=None,
          long_context=False):
    """Ask Jev the questions about state. Returns {qid: answer}, or None on any failure.

    redactions: [(original, replacement), ...] applied to the state and to the question
    values (not the question ids) before the request, and so before the log.
    key: defaults to $TYPESAFE_API_KEY. log_path: defaults to $S1_LOG, then DEFAULT_LOG.
    log_extra: optional {field: value} added to the log line; it never replaces a core field.
    long_context: send the TypeSafe-Danger-Zone-Long-Context header (262k tokens, T30).
    """
    path = log_path or os.environ.get(LOG_ENV) or DEFAULT_LOG
    key = key or os.environ.get(KEY_ENV)
    pairs = redactions or []
    extra = dict(log_extra or {})
    try:
        state = redact(state, pairs)
        questions = {q: redact(v, pairs) for q, v in questions.items()}
    except Exception as e:  # malformed input: fail open
        _log(path, key, {"time": _now(), "model": model, "questions": [], "state": None,
                         "answers": None, "latency": 0, "usage": None, "error": f"input: {e}",
                         **{k: v for k, v in extra.items() if k not in _CORE}})
        return None
    rec = {"time": _now(), "model": model, "questions": list(questions), "state": state,
           "answers": None, "latency": 0.0, "usage": None, "error": None}
    rec.update({k: v for k, v in extra.items() if k not in rec})
    t0 = time.monotonic()
    try:
        if not key:
            raise RuntimeError(f"missing API key (${KEY_ENV})")
        body = json.dumps({"model": model, "state": state, "questions": questions}).encode()
        headers = {"Authorization": "Bearer " + key, "Content-Type": "application/json"}
        if long_context:
            headers[LONG_CONTEXT_HEADER] = "true"
        status, text = (transport or urllib_transport)(URL, headers, body, timeout)
        if status != 200:
            raise RuntimeError(f"HTTP {status}: {text[:300]}")
        data = json.loads(text)
        answers = data["answers"]
        if not isinstance(answers, dict):
            raise ValueError("answers is not an object")
        missing = [q for q in questions if answers.get(q) is None]
        if missing:
            rec["answers"] = answers
            raise ValueError("no answer for " + ", ".join(missing))
        rec["answers"] = answers
        rec["usage"] = data.get("usage")
        if data.get("model"):
            rec["model"] = data["model"]
        return answers
    except TimeoutError as e:
        rec["error"] = f"timeout: {e}"
    except Exception as e:
        rec["error"] = f"{type(e).__name__}: {e}"
    finally:
        rec["latency"] = round(time.monotonic() - t0, 4)
        _log(path, key, rec)
    return None


def _now():
    return datetime.now(timezone.utc).isoformat(timespec="milliseconds")


_PLAIN = re.compile(r"[a-z][a-zA-Z0-9_]*\Z")


def _atom(s):
    s = str(s)
    if _PLAIN.match(s):
        return s
    s = (s.replace("\\", "\\\\").replace("'", "\\'").replace("\n", "\\n")
         .replace("\r", "\\r").replace("\t", "\\t").replace("\0", "\\0\\"))
    return "'" + s + "'"


def to_prolog(run_id, answers):
    """One fact per answer: s1_answer(Run, Qid, Type, Value, Label).

    noul:   Value = P(yes),    Label = band(P)             s1_answer(run1, q1, noul, 0.93, yes).
    choice: Value = confidence, Label = the chosen option  s1_answer(run1, q2, choice, 0.7, calm).
    score:  Value = score,      Label = nearest level (int, half up)
    Run, Qid and Label atoms are quoted when they are not plain lowercase atoms.
    None and unknown answers are skipped.
    """
    out = []
    for qid, a in (answers or {}).items():
        if a is None:
            continue
        try:
            t = a.get("type")
            if t == "noul":
                value = _num(a["noul"])
                label = band(value)
            elif t == "choice":
                value, label = _num(a["confidence"]), _atom(a["choice"])
            elif t == "score":
                value = _num(a["score"])
                label = int(value + 0.5)
            else:
                continue
        except (AttributeError, KeyError, TypeError, ValueError) as e:
            why = (type(e).__name__ + " " + str(e)).replace("\n", " ").replace("\r", " ")
            out.append("% skipped " + str(qid).replace("\n", " ").replace("\r", " ")
                       + ": malformed answer (" + why[:80] + ")")
            continue
        out.append(f"s1_answer({_atom(run_id)}, {_atom(qid)}, {t}, {value!r}, {label}).")
    return "\n".join(out)


def _num(x):
    if isinstance(x, bool) or not isinstance(x, (int, float)):
        raise TypeError(f"not a number: {x!r}")
    return x
