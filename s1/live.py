#!/usr/bin/env python3
"""A live view of what the System 1 hook saw, for a pane, a corner, a toast or any other display.
Python 3 standard library only; no network; reads the S1 log (s1/hook.py writes it).

    python3 s1/live.py --format pane|corner|toast|json [--session ID | --stdin] [--log FILE]
                       [--turns N] [--no-color] [--width N]

The session is --session; or, with --stdin, the session_id of JSON on stdin (as Claude Code sends to
a status line command); else the newest session in the log. Stdin is never read without --stdin.

    pane    the newest message in full: each signal as a bar, each part of the message with what the
            System 1 model said about it, and the history of the session as sparklines
    corner  three short lines: the signals that fired, the model and its speed, the history
    toast   one line, only when the newest message fired a signal; else nothing
    json    the turns as data: {"session", "turns": [{time, model, latency, tokens, work, tool,
            signals: {...}, fired: [...], parts: [{text, react, p, doubts, faults, changes, asks,
            undecided, reverses}]}]}

A signal fires at 0.7 or more (jev.band). Fails quiet: on any error it prints nothing and exits 0."""
import argparse
import json
import os
import sys

DEFAULT_LOG = os.path.expanduser("~/.claude/logs/s1.jsonl")
TAIL = 4 * 1024 * 1024
YES, NO = 0.7, 0.3
SIGNALS = (("divergence", "h_divergence"), ("change of plan", "h_change_of_plan"), ("questions open", "h_questions"),
           ("effort", "h_effort"), ("reversal", "h_reversal"), ("proof asked", "h_proof"))
SHORT = {"divergence": "div", "change of plan": "plan", "questions open": "ques", "effort": "eff", "reversal": "rev", "proof asked": "proof"}
PART_KEYS = ("doubts", "faults", "changes", "asks", "undecided", "reverses")
BLOCKS = " ▁▂▃▄▅▆▇█"


def _lines(path):
    with open(path, "rb") as f:
        f.seek(0, os.SEEK_END)
        size = f.tell()
        f.seek(max(0, size - TAIL))
        data = f.read().decode("utf-8", "replace").splitlines()
    out = []
    for x in data[1:] if size > TAIL else data:
        try:
            d = json.loads(x)
        except ValueError:
            continue
        if isinstance(d, dict):
            out.append(d)
    return out


def _noul(a, k):
    v = a.get(k)
    p = v.get("noul") if isinstance(v, dict) else None
    return float(p) if isinstance(p, (int, float)) and not isinstance(p, bool) else None


def _choice(a, k):
    v = a.get(k)
    if not isinstance(v, dict) or not isinstance(v.get("choice"), str):
        return None, None
    p = (v.get("probabilities") or {}).get(v["choice"], v.get("confidence"))
    return v["choice"], (float(p) if isinstance(p, (int, float)) else None)


def turns(path, session=None):
    """(session, [turn]) oldest first. A turn is one message that the hook judged. With the fan-out
    on, the call line and the combined line that follows it are one turn."""
    recs = _lines(path)
    if session is None:
        ids = [r.get("session_id") for r in recs if r.get("session_id")]
        session = ids[-1] if ids else None
    out, call = [], None
    for r in recs:
        if r.get("session_id") != session or not isinstance(r.get("answers"), dict):
            if r.get("session_id") == session and (r.get("error") or r.get("skipped")):
                out.append({"time": r.get("time"), "error": str(r.get("error") or r.get("skipped"))[:120]})
            continue
        if not r.get("combined"):
            call = r
            if isinstance(r.get("parts"), int):  # the combined line follows and replaces this one
                out.append(_turn(r, r))
                continue
            out.append(_turn(r, r))
        else:
            t = _turn(r, call or r)
            if out and call is not None and out[-1].get("_call") is call:
                out[-1] = t
            else:
                out.append(t)
    for t in out:
        t.pop("_call", None)
    return session, out


def _turn(r, call):
    a = r["answers"]
    work, wp = _choice(a, "h_work")
    tool, tp = _choice(a, "h_language")
    sig = {name: _noul(a, qid) for name, qid in SIGNALS if _noul(a, qid) is not None}
    texts = r.get("part_text") or ((call.get("state") or {}).get("sentences") if isinstance(call.get("state"), dict) else None) or []
    parts = []
    for k, text in enumerate(texts):
        if f"react@{k}" not in a:
            break
        c, cp = _choice(a, f"react@{k}")
        p = {"text": text, "react": c, "p": cp}
        p.update({name: _noul(a, f"{name}@{k}") for name in PART_KEYS})
        parts.append(p)
    usage = call.get("usage") or {}
    return {"_call": call, "time": r.get("time"), "model": call.get("model"), "latency": call.get("latency"),
            "tokens": usage.get("input_tokens"), "work": work, "work_p": wp, "tool": tool, "tool_p": tp,
            "signals": sig, "fired": [n for n, p in sig.items() if p >= YES], "parts": parts}


class Paint:
    def __init__(self, on):
        self.on = on

    def __call__(self, text, code):
        return f"\033[{code}m{text}\033[0m" if self.on else text


def _bar(p, width=10):
    n = int(round(p * width))
    return "█" * n + "░" * (width - n)


def _tone(p):
    return "1;31" if p >= YES else "33" if p > NO else "2"


def _spark(vals):
    return "".join(BLOCKS[min(8, int(round((v or 0) * 8)))] for v in vals)


def _clip(s, n):
    s = " ".join(str(s).split())
    return s if len(s) <= n else s[:max(0, n - 1)] + "…"


def _why(t, name):
    """The part that carries a signal: (number, text), or None."""
    key = {"divergence": ("doubts", "faults"), "change of plan": ("changes",), "questions open": ("asks", "undecided"), "reversal": ("reverses",)}.get(name)
    best = None
    for i, p in enumerate(t["parts"]):
        v = max([p.get(k) or 0 for k in key]) if key else 0
        if v >= YES and (best is None or v > best[0]):
            best = (v, i + 1, p["text"])
    return best and best[1:]


def pane(session, ts, color=True, width=100, history=30):
    c = Paint(color)
    good = [t for t in ts if "signals" in t]
    if not good:
        return c("SYSTEM 1", "1") + "  no judged message in this session yet" + (f"  (last: {ts[-1]['error']})" if ts else "")
    t = good[-1]
    head = [c("SYSTEM 1", "1;36"), t.get("model") or "?"]
    if t.get("latency") is not None:
        head.append(f"{t['latency']:.2f}s")
    if t.get("tokens"):
        head.append(f"{t['tokens']:,} tok")
    if t["parts"]:
        head.append(f"{len(t['parts'])} part{'s' if len(t['parts']) != 1 else ''}")
    head.append(f"turn {len(good)}")
    out = ["  ·  ".join(head)]
    line = []
    if t["work"]:
        line.append(f"work {c(t['work'], '1')} {t['work_p']:.2f}")
    if t["tool"]:
        line.append(f"tool {c(t['tool'], '1')} {t['tool_p']:.2f}")
    if line:
        out.append("  ".join(line))
    out.append("")
    for name, _ in SIGNALS:
        p = t["signals"].get(name)
        if p is None:
            continue
        mark = c(" ◀ FIRED", "1;31") if p >= YES else ""
        why = _why(t, name) if p >= YES else None
        tail = f"  part {why[0]}: “{_clip(why[1], max(10, width - 52))}”" if why else ""
        out.append(f"  {name:<15}{c(_bar(p), _tone(p))} {p:.2f}{mark}{tail}")
    if t["parts"]:
        out.append("")
        out.append(c("  #  the part does       doubt fault chng  asks undec  rev   text", "2"))
        for i, p in enumerate(t["parts"]):
            cells = " ".join(c(f"{(p.get(k) or 0):5.2f}", _tone(p.get(k) or 0)) for k in PART_KEYS)
            out.append(f" {i + 1:>2}  {(p['react'] or '?'):<16}{(p['p'] or 0):.2f} {cells}  {_clip(p['text'], max(12, width - 66))}")
    hist = good[-history:]
    if len(hist) > 1:
        out.append("")
        out.append(c(f"  history, last {len(hist)} messages (oldest first)", "2"))
        for name, _ in SIGNALS:
            vals = [h["signals"].get(name) for h in hist]
            fired = sum((v or 0) >= YES for v in vals)
            out.append(f"  {name:<15}{_spark(vals)}  fired {fired}")
        lat = [h["latency"] for h in hist if h.get("latency") is not None]
        tok = [h["tokens"] for h in hist if h.get("tokens")]
        if lat:
            out.append(c(f"  latency mean {sum(lat) / len(lat):.2f}s, max {max(lat):.2f}s" + (f"  ·  tokens sum {sum(tok):,} (about ${sum(tok) * 0.042 / 1e6:.4f})" if tok else ""), "2"))
    errs = sum("error" in x for x in ts)
    if errs:
        out.append(c(f"  {errs} call{'s' if errs != 1 else ''} with no view in this session", "33"))
    return "\n".join(out)


def corner(session, ts, color=True, history=20):
    c = Paint(color)
    good = [t for t in ts if "signals" in t]
    if not good:
        return c("S1", "1;36") + " no view yet"
    t = good[-1]
    first = c("S1 ", "1;36") + (" ".join(c(f"{SHORT[n]} {t['signals'][n]:.2f}", "1;31") for n in t["fired"]) or c("quiet", "2"))
    second = " ".join(x for x in (t["work"], f"{t['latency']:.2f}s" if t.get("latency") is not None else "", f"{len(t['parts'])}p" if t["parts"] else "") if x)
    hist = good[-history:]
    third = "div " + _spark([h["signals"].get("divergence") for h in hist]) + " eff " + _spark([h["signals"].get("effort") for h in hist])
    return "\n".join((first, c(second, "2"), c(third, "2")))


def toast(session, ts):
    good = [t for t in ts if "signals" in t]
    if not good or not good[-1]["fired"] or (ts and ts[-1] is not good[-1]):
        return ""
    t = good[-1]
    name = t["fired"][0]
    why = _why(t, name)
    more = f" (+{len(t['fired']) - 1} more)" if len(t["fired"]) > 1 else ""
    return f"System 1: {name} {t['signals'][name]:.2f}{more}" + (f" · “{_clip(why[1], 60)}”" if why else "")


def main(argv=None):
    try:
        ap = argparse.ArgumentParser()
        ap.add_argument("--format", default="pane", choices=("pane", "corner", "toast", "json"))
        ap.add_argument("--session")
        ap.add_argument("--stdin", action="store_true", help="read {\"session_id\": ...} from stdin, as a status line command gets it")
        ap.add_argument("--log", default=os.environ.get("S1_LOG") or DEFAULT_LOG)
        ap.add_argument("--turns", type=int, default=30)
        ap.add_argument("--no-color", action="store_true")
        ap.add_argument("--width", type=int, default=100)
        a = ap.parse_args(argv)
        session = a.session
        if session is None and a.stdin:
            try:
                session = json.loads(sys.stdin.read() or "{}").get("session_id")
            except (ValueError, AttributeError):
                session = None
        session, ts = turns(os.path.expanduser(a.log), session)
        color = not a.no_color and not os.environ.get("NO_COLOR")
        if a.format == "json":
            out = json.dumps({"session": session, "turns": ts[-a.turns:]}, ensure_ascii=False)
        elif a.format == "pane":
            out = pane(session, ts, color, a.width, a.turns)
        elif a.format == "corner":
            out = corner(session, ts, color, a.turns)
        else:
            out = toast(session, ts)
        if out:
            sys.stdout.write(out + "\n")
    except Exception:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
