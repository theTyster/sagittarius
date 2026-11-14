#!/usr/bin/env python3
"""System 1 inspection tool. Python 3 standard library only. Reads; never calls the network.

Shows what the System 1 model (Jev) was sent, how it was asked, and what it answered, from the log
that jev.py writes ($S1_LOG, else ~/.claude/logs/s1.jsonl). It writes a file only when you pass --html.

    python3 s1/s1inspect.py [--hub PATH] [--log FILE] [--session ID] [--since ISO] [--last N]
                          [--errors] [--questions FILE] [--projects DIR]
                          [--json | --html FILE | --summary]

The log keeps the question ids, not their text. The text comes from the questions.json of this
checkout (or --questions). The tool says so when that set may differ from what was sent.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))

import argparse  # noqa: E402
import html  # noqa: E402
import json  # noqa: E402
import re  # noqa: E402
import statistics  # noqa: E402
from datetime import datetime, timezone  # noqa: E402

sys.path.insert(0, HERE)
import hook  # noqa: E402
import jev  # noqa: E402

DEFAULT_PROJECTS = os.path.expanduser("~/.claude/projects")
SIGNALS = (("h_divergence", "divergence"), ("h_change_of_plan", "change of plan"),
           ("h_effort", "effort"), ("h_questions", "questions not settled"), ("h_proof", "proof asked"))
SCHEMA = "s1-inspect/1"


# ---------------------------------------------------------------- reading

def read_log(path):
    """[(index, record)] of the JSON lines of the log that are objects. Bad lines are counted, not shown."""
    out, bad = [], 0
    with open(path, encoding="utf-8", errors="replace") as f:
        for i, line in enumerate(f):
            line = line.strip()
            if not line:
                continue
            try:
                d = json.loads(line)
            except ValueError:
                bad += 1
                continue
            if isinstance(d, dict):
                out.append((i, d))
            else:
                bad += 1
    return out, bad


def project_dirname(cwd):
    """The folder name that Claude Code uses under ~/.claude/projects: the cwd with `/` and `.` as `-`."""
    return re.sub(r"[/.]", "-", cwd)


def project_dirnames(cwd):
    """The strict name, and a looser one (every character that is not a letter or digit is `-`)."""
    return {project_dirname(cwd), re.sub(r"[^A-Za-z0-9]", "-", cwd)}


def hub_sessions(hub, projects):
    """(set of session ids, list of project dirs that exist) for the hub folder `hub`."""
    hub = os.path.abspath(os.path.expanduser(hub))
    dirs = [os.path.join(projects, n) for n in sorted(project_dirnames(hub))
            if os.path.isdir(os.path.join(projects, n))]
    sids = set()
    for d in dirs:
        for name in os.listdir(d):
            if name.endswith(".jsonl"):
                sids.add(name[:-len(".jsonl")])
    return sids, dirs


UNKNOWN_HUB = "(other folders)"  # a session outside every MindHole, or whose folder is not known
HUB_MARK = ".hub-template.json"  # a MindHole: the folder that holds it (s1-inspect c4b, Ty: list only MindHoles)
_HUBMAP_CACHE = {}


def _transcript_cwd(path):
    """The first `cwd` that a transcript line carries, or None."""
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            for n, line in enumerate(f):
                if n > 200:
                    break
                if '"cwd"' not in line:
                    continue
                try:
                    d = json.loads(line)
                except ValueError:
                    continue
                if isinstance(d, dict) and isinstance(d.get("cwd"), str) and d["cwd"]:
                    return d["cwd"]
    except OSError:
        pass
    return None


def mindhole_of(cwd, _cache={}):
    """The MindHole that holds folder cwd (cwd itself or a parent with .hub-template.json), or None."""
    if cwd not in _cache:
        d, found = os.path.abspath(cwd), None
        while True:
            if os.path.isfile(os.path.join(d, HUB_MARK)):
                found = d
                break
            up = os.path.dirname(d)
            if up == d:
                break
            d = up
        _cache[cwd] = found
    return _cache[cwd]


def hub_map(projects):
    """{session id: its MindHole (mindhole_of the session's cwd)} for every transcript under the projects dir;
    a session outside every MindHole is absent, so it shows as UNKNOWN_HUB.
    Cached while no project folder changes (same names and mtimes); a session whose transcript has no cwd is absent."""
    projects = os.path.abspath(os.path.expanduser(projects))
    try:
        names = sorted(n for n in os.listdir(projects) if os.path.isdir(os.path.join(projects, n)))
        sig = tuple((n, os.stat(os.path.join(projects, n)).st_mtime_ns) for n in names)
    except OSError:
        return {}
    hit = _HUBMAP_CACHE.get(projects)
    if hit and hit[0] == sig:
        return hit[1]
    out = {}
    for n in names:
        d = os.path.join(projects, n)
        try:
            files = sorted(os.listdir(d))
        except OSError:
            continue
        for fn in files:
            if fn.endswith(".jsonl"):
                cwd = _transcript_cwd(os.path.join(d, fn))
                hub = mindhole_of(cwd) if cwd else None
                if hub:
                    out[fn[:-len(".jsonl")]] = hub
    _HUBMAP_CACHE[projects] = (sig, out)
    return out


def hub_labels(hubs):
    """{hub: label}: the folder name, or as many parent folders as it takes to tell hubs apart."""
    parts = {h: [x for x in h.rstrip("/").split("/") if x] for h in hubs if h != UNKNOWN_HUB}
    out = {UNKNOWN_HUB: UNKNOWN_HUB} if UNKNOWN_HUB in hubs else {}
    for h, ps in parts.items():
        n = 1
        while n < len(ps) and any(o != h and qs[-n:] == ps[-n:] for o, qs in parts.items()):
            n += 1
        out[h] = "/".join(ps[-n:]) or h
    return out


def hub_name(path):
    return UNKNOWN_HUB if path in (None, UNKNOWN_HUB) else (os.path.basename(path.rstrip("/")) or path)


def parse_time(s):
    try:
        d = datetime.fromisoformat(str(s).replace("Z", "+00:00"))
    except ValueError:
        return None
    return d if d.tzinfo else d.replace(tzinfo=timezone.utc)


def questions_sha(questions):
    return jev.questions_sha(questions) if hasattr(jev, "questions_sha") else None


def load_questions(path):
    """(dict or None, error text or None)."""
    try:
        with open(path, encoding="utf-8") as f:
            q = json.load(f)
        if not isinstance(q, dict):
            raise ValueError("not an object")
        return q, None
    except (OSError, ValueError) as e:
        return None, f"{type(e).__name__}: {e}"


# ---------------------------------------------------------------- one judgment

def _short(sid):
    return sid[:8] if isinstance(sid, str) else None


def _text(x):
    return x if isinstance(x, str) else json.dumps(x, ensure_ascii=False)


def saw(rec):
    """What it saw: {"message": {...}, "recent": [{role, text, chars}]} or None (no state in the line)."""
    st = rec.get("state")
    if not isinstance(st, dict):
        return None
    msg = _text(st.get("message", ""))
    recent = []
    for r in st.get("recent") or []:
        if isinstance(r, dict):
            t = _text(r.get("text", ""))
            recent.append({"role": r.get("role"), "text": t, "chars": len(t)})
        else:
            t = _text(r)
            recent.append({"role": None, "text": t, "chars": len(t)})
    return {"message": {"text": msg, "chars": len(msg)}, "recent": recent}


def asked(rec, questions, qerr, qpath, checkout_version):
    """How it was asked: the question text from the checkout's set, the request body shape, and notes
    about whether that set may differ from what was sent."""
    ids = [q for q in (rec.get("questions") or []) if isinstance(q, str)]
    notes = []
    qs = {}
    missing = []
    for q in ids:
        if questions is not None and q in questions:
            qs[q] = questions[q]
        else:
            qs[q] = None
            missing.append(q)
    if qerr:
        notes.append(f"The question file {qpath} could not be read ({qerr}). No question text is shown.")
    if missing and not qerr:
        notes.append("The log names questions that the question file does not have: " + ", ".join(missing)
                     + ". The set that was sent differs from the file.")
    extra = [q for q in (questions or {}) if q not in ids] if (ids and questions) else []
    if extra:
        notes.append("The question file has questions that this call did not send: " + ", ".join(extra) + ".")
    v = rec.get("sagittarius")
    if v and checkout_version and v != checkout_version:
        notes.append(f"The line is from Sagittarius {v}; this checkout is {checkout_version}. "
                     "The question text may have changed between them.")
    elif not v and ids:
        notes.append("The line has no Sagittarius version.")
    logged = rec.get("questions_sha")
    here = questions_sha(questions) if questions is not None else None
    if logged and here:
        status = "same" if logged == here else "differs"
        if status == "differs":
            notes.append("The hash of the questions that were sent differs from the hash of the question file."
                         " The text shown is NOT what was sent.")
    else:
        status = "unknown"
        if ids and not qerr and not logged:
            notes.append("The line has no questions_sha, so the tool cannot tell for certain that the question "
                         "file is what was sent.")
    body = None
    if ids:
        body = {"model": rec.get("model"), "state": rec.get("state"), "questions": qs}
    return {"question_ids": ids, "questions": qs, "missing_from_file": missing, "questions_file": qpath,
            "questions_sha_logged": logged, "questions_sha_file": here, "match": status,
            "notes": notes, "request_body": body}


def _answer(q, a, question):
    """One answer, shown: type, value, probabilities, and its band or choice (as hook.py reads it)."""
    if not isinstance(a, dict):
        return {"type": None, "malformed": True, "raw": a}
    out = {"type": a.get("type")}
    try:
        if a.get("type") == "noul":
            p = float(a["noul"])
            out.update(value=p, band=jev.band(p))
        elif a.get("type") == "choice":
            c = a["choice"]
            probs = a.get("probabilities") if isinstance(a.get("probabilities"), dict) else None
            p = float(probs[c] if probs and c in probs else a["confidence"])
            out.update(choice=c, p=p, confidence=a.get("confidence"), probabilities=probs,
                       band="shown" if p >= hook.CHOICE_MIN else "unsure")
        else:
            out["raw"] = a
    except (KeyError, TypeError, ValueError) as e:
        out.update(malformed=True, raw=a, reason=f"{type(e).__name__}: {e}")
    if "probabilities" in a and "probabilities" not in out:
        out["probabilities"] = a["probabilities"]
    return out


_SKIP_VIEW = (("no API key", "no API key"), ("timeout", "timeout"), ("questions", "no question set"),
              ("stdin", "bad input"), ("bad answers", "bad answers"), ("no answers", "no answer"))


def skip_hint(reason):
    """The line the agent got after the hook skipped, by the hook's own wording."""
    r = reason or ""
    for start, why in _SKIP_VIEW:
        if r.startswith(start):
            return hook.no_view(why)
    return hook.no_view("error")


def answered(rec, questions):
    """What it answered, and the exact line that the agent received."""
    ans = rec.get("answers")
    out = {"answers": None, "hint": None, "hint_note": None, "error": rec.get("error"),
           "skipped": rec.get("skipped")}
    if rec.get("skipped"):
        out["hint"] = skip_hint(rec["skipped"])
        out["hint_note"] = "The hook skipped this prompt; the line is the hook's wording for that reason."
        return out
    if isinstance(ans, dict):
        out["answers"] = {q: _answer(q, a, (questions or {}).get(q)) for q, a in ans.items()}
    if rec.get("error") or not isinstance(ans, dict):
        out["hint"] = hook.no_view("no answer")
        out["hint_note"] = ("The call failed, so the hook printed a no-view line. The reason in the line comes "
                            "from the hook's next log line (a skip line), which may differ.")
        return out
    if questions is None:
        out["hint_note"] = "Not recomputed: no question file."
        return out
    try:
        out["hint"] = hook.format_answers(ans, questions)
        out["hint_note"] = ("Recomputed with hook.format_answers and the question file; "
                            "only the choice names are read from the file.")
    except Exception as e:
        out["hint_note"] = f"Not recomputed: {type(e).__name__}: {e}"
    return out


def signals_fired(rec):
    ans = rec.get("answers")
    out = []
    if not isinstance(ans, dict):
        return out
    for qid, name in SIGNALS:
        a = ans.get(qid)
        try:
            if isinstance(a, dict) and a.get("type") == "noul" and jev.band(float(a["noul"])) == "yes":
                out.append(name)
        except (KeyError, TypeError, ValueError):
            pass
    return out


def judgment(index, rec, questions, qerr, qpath, checkout_version):
    """One judgment object (the --json shape)."""
    if rec.get("skipped"):
        kind = "skip"
    elif "cal" in rec or "case" in rec:
        kind = "calibration"
    else:
        kind = "call"
    usage = rec.get("usage")
    return {
        "schema": SCHEMA, "kind": kind, "line": index + 1, "time": rec.get("time"),
        "session_id": rec.get("session_id"), "session_short": _short(rec.get("session_id")),
        "model": rec.get("model"), "latency": rec.get("latency"), "usage": usage,
        "sagittarius": rec.get("sagittarius"), "trimmed": bool(rec.get("trimmed")),
        "long_context": bool(rec.get("long_context")), "failed": bool(rec.get("error")) or kind == "skip",
        "calibration_case": rec.get("case"),
        "signals": signals_fired(rec),
        "saw": saw(rec),
        "asked": asked(rec, questions, qerr, qpath, checkout_version) if kind != "skip" else None,
        "answered": answered(rec, questions),
    }


# ---------------------------------------------------------------- selection

def select(log, args_hub=None, projects=DEFAULT_PROJECTS, session=None, since=None, last=None, errors=False,
           pick=None):
    """The (index, record) pairs chosen, newest first. Returns (pairs, info).
    `pick` is the hub picker's choice: a hub folder, or UNKNOWN_HUB (None: every hub)."""
    info = {"hub_dirs": []}
    keep = list(log)
    hm = hub_map(projects)
    info["hubs"] = sorted({hm.get(r.get("session_id")) or UNKNOWN_HUB for _, r in keep},
                          key=lambda h: (h == UNKNOWN_HUB, hub_name(h).lower(), h))
    info["hub_of"] = hm
    if pick:
        keep = [(i, r) for i, r in keep if (hm.get(r.get("session_id")) or UNKNOWN_HUB) == pick]
    if args_hub:
        sids, dirs = hub_sessions(args_hub, projects)
        info["hub_dirs"] = dirs
        keep = [(i, r) for i, r in keep if r.get("session_id") in sids]
    if session:
        keep = [(i, r) for i, r in keep if isinstance(r.get("session_id"), str)
                and r["session_id"].startswith(session)]
    if since:
        t0 = parse_time(since)
        if t0 is None:
            raise ValueError(f"--since: not an ISO time: {since!r}")
        keep = [(i, r) for i, r in keep if (parse_time(r.get("time")) or datetime.min.replace(tzinfo=timezone.utc)) >= t0]
    if errors:
        keep = [(i, r) for i, r in keep if r.get("error") or r.get("skipped")]
    floor = datetime.min.replace(tzinfo=timezone.utc)
    keep.sort(key=lambda p: (parse_time(p[1].get("time")) or floor, p[0]), reverse=True)
    if last is not None:
        keep = keep[:max(last, 0)]
    return keep, info


# ---------------------------------------------------------------- summary

def summarize(judgments):
    calls = [j for j in judgments if j["kind"] != "skip"]
    errs = [j for j in calls if j["answered"]["error"] or j["answered"]["answers"] is None]
    lat = [j["latency"] for j in calls if isinstance(j["latency"], (int, float)) and not isinstance(j["latency"], bool)]
    per = {}
    for j in calls:
        for qid, a in (j["answered"]["answers"] or {}).items():
            d = per.setdefault(qid, {"type": a.get("type"), "n": 0, "counts": {}})
            d["n"] += 1
            if a.get("malformed"):
                key = "malformed"
            elif a.get("type") == "noul":
                key = a["band"]
            elif a.get("type") == "choice":
                key = a["choice"] if a["band"] == "shown" else "unsure"
            else:
                key = "other"
            d["counts"][key] = d["counts"].get(key, 0) + 1
    fired = {}
    for j in calls:
        for s in j["signals"]:
            fired[s] = fired.get(s, 0) + 1
    return {"schema": SCHEMA, "judgments": len(judgments), "calls": len(calls),
            "skip_lines": len(judgments) - len(calls), "failed_calls": len(errs),
            "error_rate": (len(errs) / len(calls)) if calls else None,
            "latency_median": statistics.median(lat) if lat else None,
            "signals_fired": fired, "questions": per}


# ---------------------------------------------------------------- text view

def _fmt_p(x):
    return f"{x:.2f}" if isinstance(x, (int, float)) else str(x)


def _indent(text, pad="      "):
    return "\n".join(pad + ln for ln in text.split("\n"))


def render_text(judgments, info=None):
    out = []
    for j in judgments:
        flags = [f for f, on in (("trimmed", j["trimmed"]), ("long_context", j["long_context"])) if on]
        u = j["usage"]
        tok = "-" if not isinstance(u, dict) else ", ".join(f"{k}={v}" for k, v in u.items())
        lat = j["latency"]
        out.append("=" * 78)
        if j["kind"] == "skip":
            out.append(f"{j['time']}  session {j['session_short']}  HOOK SKIP  Sagittarius {j['sagittarius']}")
            out.append(f"  skipped: {j['answered']['skipped']}")
            out.append(f"  the agent got: {j['answered']['hint']}")
            continue
        label = "CALIBRATION CALL" if j["kind"] == "calibration" else "call"
        out.append(f"{j['time']}  session {j['session_short']}  {label}  model {j['model']}  "
                   f"latency {_fmt_p(lat)}s  tokens {tok}  Sagittarius {j['sagittarius']}"
                   + (f"  [{', '.join(flags)}]" if flags else ""))
        s = j["saw"]
        out.append("  WHAT IT SAW")
        if s is None:
            out.append("    (no state in this line)")
        else:
            for r in s["recent"]:
                out.append(f"    recent {r['role']} ({r['chars']} chars):")
                out.append(_indent(r["text"]))
            out.append(f"    message ({s['message']['chars']} chars):")
            out.append(_indent(s["message"]["text"]))
        a = j["asked"]
        out.append("  HOW IT WAS ASKED")
        for n in a["notes"]:
            out.append(f"    ! {n}")
        out.append(f"    match with the question file: {a['match']}"
                   + (f" (logged {a['questions_sha_logged']})" if a["questions_sha_logged"] else ""))
        for qid in a["question_ids"]:
            q = a["questions"][qid]
            if q is None:
                out.append(f"    {qid}: (text not in the question file)")
                continue
            out.append(f"    {qid} [{q.get('type')}]: {q.get('instructions')}")
            for c, t in (q.get("criteria") or {}).items():
                out.append(f"        {c}: {t}")
        if a["request_body"] is not None:
            b = a["request_body"]
            out.append("    request body: {model: %r, state: {message, recent[%d]}, questions: {%s}}"
                       % (b["model"], len((b["state"] or {}).get("recent") or []), ", ".join(a["question_ids"])))
            out.append("    (sent with Authorization and Content-Type headers; no key is shown or stored)")
        r = j["answered"]
        out.append("  WHAT IT ANSWERED")
        if r["error"]:
            out.append(f"    error: {r['error']}")
        for qid, x in (r["answers"] or {}).items():
            if x.get("malformed"):
                out.append(f"    {qid}: malformed ({x.get('reason', 'unknown type')})")
            elif x["type"] == "noul":
                out.append(f"    {qid}: P(yes)={_fmt_p(x['value'])} -> {x['band']}")
            elif x["type"] == "choice":
                pr = x.get("probabilities")
                ps = "  " + ", ".join(f"{k}={_fmt_p(v)}" for k, v in pr.items()) if pr else ""
                shown = "shown" if x["band"] == "shown" else f"unsure (below {hook.CHOICE_MIN})"
                out.append(f"    {qid}: {x['choice']} P={_fmt_p(x['p'])} -> {shown}{ps}")
            else:
                out.append(f"    {qid}: {x.get('type')}")
        out.append(f"    the agent got: {r['hint'] if r['hint'] else '(not known)'}")
        if r["hint_note"]:
            out.append(f"    ({r['hint_note']})")
    if not judgments:
        out.append("No judgments match.")
    return "\n".join(out)


def render_summary_text(s):
    out = [f"judgments: {s['judgments']}  calls: {s['calls']}  hook skip lines: {s['skip_lines']}",
           f"failed calls: {s['failed_calls']}  error rate: "
           + ("-" if s["error_rate"] is None else f"{s['error_rate']:.1%}")
           + "  median latency: " + ("-" if s["latency_median"] is None else f"{s['latency_median']:.2f}s"),
           "signals fired (yes band): " + (", ".join(f"{k} {v}" for k, v in s["signals_fired"].items()) or "none"),
           "", "per question (noul: yes / no / unsure; choice: chosen at P >= %s, else unsure):" % hook.CHOICE_MIN]
    for qid, d in s["questions"].items():
        c = ", ".join(f"{k} {v}" for k, v in sorted(d["counts"].items(), key=lambda kv: -kv[1]))
        out.append(f"  {qid} [{d['type']}] n={d['n']}: {c}")
    return "\n".join(out)


# ---------------------------------------------------------------- html view

CSS = """
:root{--bg:#fff;--fg:#1c1c1e;--mut:#6b6b73;--card:#f5f5f7;--bd:#d8d8de;--acc:#2456c9;--bad:#b3261e;--warn:#8a5a00;--code:#ececf1}
@media(prefers-color-scheme:dark){:root{--bg:#16161a;--fg:#e8e8ec;--mut:#9a9aa6;--card:#202026;--bd:#38383f;--acc:#7aa2ff;--bad:#ff8a80;--warn:#f0c060;--code:#2a2a32}}
body{background:var(--bg);color:var(--fg);font:15px/1.45 system-ui,sans-serif;margin:0 auto;max-width:1000px;padding:1rem}
h1{font-size:1.3rem} h2{font-size:1.05rem;margin:1.2rem 0 .4rem}
.sum{display:flex;flex-wrap:wrap;gap:.6rem}.sum div{background:var(--card);border:1px solid var(--bd);border-radius:6px;padding:.4rem .7rem}
.sum b{display:block;font-size:1.1rem}
table{border-collapse:collapse;width:100%}td,th{border:1px solid var(--bd);padding:.2rem .5rem;text-align:left;font-size:.9rem}
.j{background:var(--card);border:1px solid var(--bd);border-radius:6px;margin:.6rem 0;padding:.3rem .7rem}
.j>summary{cursor:pointer;font-weight:600}.j.fail>summary{color:var(--bad)}
.meta{color:var(--mut);font-weight:400;font-size:.85rem}
details.s{margin:.4rem 0 .4rem .8rem}details.s>summary{cursor:pointer;color:var(--acc);font-weight:600}
pre{background:var(--code);padding:.5rem;border-radius:4px;white-space:pre-wrap;word-break:break-word;max-height:24rem;overflow:auto;margin:.3rem 0}
.note{color:var(--warn)}.hint{font-family:ui-monospace,monospace;background:var(--code);padding:.1rem .4rem;border-radius:4px}
.tag{border:1px solid var(--bd);border-radius:10px;padding:0 .4rem;font-size:.75rem;margin-left:.3rem;color:var(--mut)}
.bar{display:flex;gap:.5rem;flex-wrap:wrap;margin:.5rem 0}.bar input{padding:.25rem;min-width:16rem}
button{background:var(--card);color:var(--fg);border:1px solid var(--bd);border-radius:4px;padding:.25rem .6rem;cursor:pointer}
"""

JS = """
const q=document.getElementById('q'),eo=document.getElementById('eo'),hs=document.getElementById('hubsel');
function f(){const t=q.value.toLowerCase(),h=hs.value;document.querySelectorAll('.j').forEach(d=>{
 const ok=(!t||d.textContent.toLowerCase().includes(t))&&(!eo.checked||d.classList.contains('fail'))
  &&(!h||d.dataset.hub===h);
 d.hidden=!ok;});}
q.addEventListener('input',f);eo.addEventListener('change',f);
// The picked hub lives in the URL (?hub=), so the live reload and a shared link keep it.
hs.addEventListener('change',function(){try{const u=new URL(location.href);
 if(hs.value)u.searchParams.set('hub',hs.value);else u.searchParams.delete('hub');
 if(document.getElementById('live')){location.href=u.href;return;}  // live page: the server redoes the summary
 history.replaceState(null,'',u.href);}catch(e){}f();});
try{const p=new URL(location.href).searchParams.get('hub');
 if(p&&[...hs.options].some(o=>o.value===p))hs.value=p;}catch(e){}
f();
function all(o){document.querySelectorAll('.j').forEach(d=>{if(!d.hidden)d.open=o;
 d.querySelectorAll('details.s').forEach(s=>s.open=o);});}
document.getElementById('ex').onclick=()=>all(true);document.getElementById('co').onclick=()=>all(false);
"""


def _e(x):
    return html.escape("" if x is None else str(x), quote=True)


def _pre(x):
    return f"<pre>{_e(x)}</pre>"


def render_html(judgments, summary, meta, hubs=None, picked=""):
    """`hubs`: every hub for the picker (default: those of the judgments); `picked`: the hub selected at load."""
    if hubs is None:
        hubs = sorted({j.get("hub") or UNKNOWN_HUB for j in judgments},
                      key=lambda h: (h == UNKNOWN_HUB, hub_name(h).lower(), h))
    labels = hub_labels(hubs)
    h = ["<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\">",
         "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">",
         "<meta name=\"color-scheme\" content=\"light dark\"><title>System 1 inspection</title>",
         f"<style>{CSS}</style></head><body><h1>System 1 inspection</h1>"]
    h.append(f"<p class=\"meta\">{_e(meta)}</p>")
    er = "-" if summary["error_rate"] is None else f"{summary['error_rate']:.1%}"
    ml = "-" if summary["latency_median"] is None else f"{summary['latency_median']:.2f}s"
    cards = [("judgments", summary["judgments"]), ("calls", summary["calls"]),
             ("hook skip lines", summary["skip_lines"]), ("failed calls", summary["failed_calls"]),
             ("error rate", er), ("median latency", ml)]
    h.append("<div class=\"sum\">" + "".join(f"<div>{_e(k)}<b>{_e(v)}</b></div>" for k, v in cards) + "</div>")
    h.append("<h2>Signals fired (yes band)</h2><table><tr><th>signal</th><th>calls</th></tr>")
    for _, name in SIGNALS:
        h.append(f"<tr><td>{_e(name)}</td><td>{summary['signals_fired'].get(name, 0)}</td></tr>")
    h.append("</table><h2>Per question</h2><table><tr><th>question</th><th>type</th><th>n</th><th>counts</th></tr>")
    for qid, d in summary["questions"].items():
        c = ", ".join(f"{k} {v}" for k, v in sorted(d["counts"].items(), key=lambda kv: -kv[1]))
        h.append(f"<tr><td>{_e(qid)}</td><td>{_e(d['type'])}</td><td>{d['n']}</td><td>{_e(c)}</td></tr>")
    h.append("</table><h2>Judgments, newest first</h2><div class=\"bar\">"
             "<label>hub <select id=\"hubsel\" aria-label=\"hub\"><option value=\"\">all hubs</option>"
             + "".join(f"<option value=\"{_e(x)}\" title=\"{_e(x)}\"{' selected' if x == picked else ''}>{_e(labels[x])}</option>"
                       for x in hubs)
             + "</select></label>"
             "<input id=\"q\" placeholder=\"filter text\" aria-label=\"filter\">"
             "<label><input type=\"checkbox\" id=\"eo\"> failed only</label>"
             "<button id=\"ex\">expand all</button><button id=\"co\">collapse all</button></div>")
    for j in judgments:
        fail = " fail" if j["failed"] else ""
        if j["kind"] == "skip":
            h.append(f"<details class=\"j{fail}\" data-hub=\"{_e(j.get('hub') or UNKNOWN_HUB)}\"><summary>{_e(j['time'])} session {_e(j['session_short'])} "
                     f"hook skip<span class=\"meta\"> {_e(j['answered']['skipped'])}</span></summary>"
                     f"<p>The agent got: <span class=\"hint\">{_e(j['answered']['hint'])}</span></p></details>")
            continue
        u = j["usage"]
        tok = "-" if not isinstance(u, dict) else ", ".join(f"{k}={v}" for k, v in u.items())
        tags = "".join(f"<span class=\"tag\">{_e(t)}</span>" for t, on in
                       (("trimmed", j["trimmed"]), ("long_context", j["long_context"]),
                        ("calibration", j["kind"] == "calibration"), ("failed", j["failed"])) if on)
        lat = _fmt_p(j["latency"])
        h.append(f"<details class=\"j{fail}\" data-hub=\"{_e(j.get('hub') or UNKNOWN_HUB)}\"><summary>{_e(j['time'])} session {_e(j['session_short'])} "
                 f"<span class=\"meta\">{_e(j['model'])}, {_e(lat)}s, tokens {_e(tok)}, "
                 f"Sagittarius {_e(j['sagittarius'])}</span>{tags}</summary>")
        s = j["saw"]
        h.append("<details class=\"s\"><summary>Saw</summary>")
        if s is None:
            h.append("<p>No state in this line.</p>")
        else:
            for r in s["recent"]:
                h.append(f"<div>recent: {_e(r['role'])} <span class=\"meta\">{r['chars']} chars</span></div>{_pre(r['text'])}")
            h.append(f"<div>message <span class=\"meta\">{s['message']['chars']} chars</span></div>{_pre(s['message']['text'])}")
        h.append("</details>")
        a = j["asked"]
        h.append("<details class=\"s\"><summary>Asked</summary>")
        for n in a["notes"]:
            h.append(f"<p class=\"note\">{_e(n)}</p>")
        h.append(f"<p>Match with the question file: <b>{_e(a['match'])}</b>"
                 + (f" <span class=\"meta\">logged hash {_e(a['questions_sha_logged'])}</span>" if a["questions_sha_logged"] else "")
                 + "</p>")
        for qid in a["question_ids"]:
            q = a["questions"][qid]
            if q is None:
                h.append(f"<p><b>{_e(qid)}</b> (text not in the question file)</p>")
                continue
            crit = "".join(f"<li><b>{_e(c)}</b>: {_e(t)}</li>" for c, t in (q.get("criteria") or {}).items())
            h.append(f"<p><b>{_e(qid)}</b> <span class=\"meta\">{_e(q.get('type'))}</span><br>"
                     f"{_e(q.get('instructions'))}</p>" + (f"<ul>{crit}</ul>" if crit else ""))
        if a["request_body"] is not None:
            shape = {"model": a["request_body"]["model"], "state": a["request_body"]["state"],
                     "questions": a["request_body"]["questions"]}
            h.append("<details class=\"s\"><summary>Request body (no key, no headers)</summary>"
                     + _pre(json.dumps(shape, indent=1, ensure_ascii=False)) + "</details>")
        h.append("</details>")
        r = j["answered"]
        h.append("<details class=\"s\"><summary>Answered</summary>")
        if r["error"]:
            h.append(f"<p class=\"note\">error: {_e(r['error'])}</p>")
        rows = []
        for qid, x in (r["answers"] or {}).items():
            if x.get("malformed"):
                v = "malformed " + str(x.get("reason", ""))
            elif x["type"] == "noul":
                v = f"P(yes) {_fmt_p(x['value'])} -> {x['band']}"
            elif x["type"] == "choice":
                pr = x.get("probabilities")
                v = (f"{x['choice']} P={_fmt_p(x['p'])} -> "
                     + ("shown" if x["band"] == "shown" else "unsure")
                     + ("; " + ", ".join(f"{k} {_fmt_p(p)}" for k, p in pr.items()) if pr else ""))
            else:
                v = str(x.get("type"))
            rows.append(f"<tr><td>{_e(qid)}</td><td>{_e(v)}</td></tr>")
        if rows:
            h.append("<table>" + "".join(rows) + "</table>")
        h.append(f"<p>The agent got: <span class=\"hint\">{_e(r['hint'] or '(not known)')}</span></p>")
        if r["hint_note"]:
            h.append(f"<p class=\"meta\">{_e(r['hint_note'])}</p>")
        h.append("</details></details>")
    h.append(f"<script>{JS}</script></body></html>")
    return "\n".join(h)


# ---------------------------------------------------------------- main

def build(args, pick=None):
    """(judgments newest first, info) for parsed args. `pick`: one hub folder (the picker), None for every hub."""
    log, bad = read_log(args.log)
    pairs, info = select(log, args.hub, args.projects, args.session, args.since, args.last, args.errors, pick)
    qpath = args.questions
    questions, qerr = load_questions(qpath)
    ver = jev.sagittarius_version()
    js = [judgment(i, r, questions, qerr, qpath, ver) for i, r in pairs]
    for j, (_, r) in zip(js, pairs):
        j["hub"] = info["hub_of"].get(r.get("session_id"))
    info.update(bad_lines=bad, checkout_version=ver, questions_file=qpath, questions_error=qerr)
    return js, info


def parser():
    p = argparse.ArgumentParser(description="Show what System 1 was sent, how it was asked, and what it answered.")
    p.add_argument("--hub", help="only sessions of this hub folder (found in the projects dir)")
    p.add_argument("--log", default=os.environ.get(jev.LOG_ENV) or jev.DEFAULT_LOG)
    p.add_argument("--session", help="a session id or a prefix of one")
    p.add_argument("--since", help="ISO time; only judgments at or after it")
    p.add_argument("--last", type=int, help="only the newest N")
    p.add_argument("--errors", action="store_true", help="only failed calls and hook skip lines")
    p.add_argument("--questions", default=os.path.join(HERE, "questions.json"),
                   help="the question file (default: questions.json of this checkout)")
    p.add_argument("--projects", default=DEFAULT_PROJECTS, help="the Claude Code projects dir")
    p.add_argument("--json", action="store_true", help="one JSON object per judgment, one per line "
                   "(with --summary: one summary object)")
    v = p.add_mutually_exclusive_group()
    v.add_argument("--html", metavar="FILE", help="write one self-contained HTML report")
    v.add_argument("--summary", action="store_true", help="counts per question over the selection")
    v.add_argument("--serve", type=int, metavar="PORT", help="serve the HTML report on 127.0.0.1:PORT; the "
                   "page reloads by itself when the log changes (default selection: the newest 50)")
    return p


# ---------------------------------------------------------------- live server

# Polls /stamp; on a change, keeps the scroll position and which judgments are open, then reloads.
LIVE_JS = """
(function(){
  var KEY='s1inspect-live', last=null;
  function keyOf(d){var s=d.querySelector('summary');return s?s.textContent.slice(0,120):'';}
  try{var st=JSON.parse(sessionStorage.getItem(KEY)||'null');
    if(st){document.querySelectorAll('details').forEach(function(d){if(st.open.indexOf(keyOf(d))>=0)d.open=true;});
      window.scrollTo(0,st.y);}}catch(e){}
  function save(){var open=[];document.querySelectorAll('details[open]').forEach(function(d){open.push(keyOf(d));});
    try{sessionStorage.setItem(KEY,JSON.stringify({y:window.scrollY,open:open}));}catch(e){}}
  function poll(){fetch('/stamp',{cache:'no-store'}).then(function(r){return r.text();}).then(function(t){
      if(last!==null&&t!==last){save();location.reload();return;} last=t;
      var b=document.getElementById('live');if(b)b.textContent='live: watching the log';
    }).catch(function(){var b=document.getElementById('live');if(b)b.textContent='live: server stopped';});}
  poll();setInterval(poll,2000);
})();
"""


def _stamp(path):
    try:
        st = os.stat(path)
        return f"{st.st_mtime_ns}:{st.st_size}"
    except OSError:
        return "none"


def serve(args):
    """Serve the report on 127.0.0.1 only. Each page load reads the log again; the page polls /stamp."""
    import http.server
    import urllib.parse

    if args.last is None:
        args.last = 50

    class Handler(http.server.BaseHTTPRequestHandler):
        def _send(self, code, body, ctype):
            data = body.encode("utf-8")
            self.send_response(code)
            self.send_header("Content-Type", ctype)
            self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        def do_GET(self):
            url = urllib.parse.urlsplit(self.path)
            pick = (urllib.parse.parse_qs(url.query).get("hub") or [""])[0]
            if url.path == "/stamp":
                self._send(200, _stamp(args.log), "text/plain; charset=utf-8")
                return
            if url.path not in ("/", "/index.html"):
                self._send(404, "not found", "text/plain; charset=utf-8")
                return
            try:
                js, info = build(args, pick or None)
                meta = (f"log {args.log}; newest {args.last}; {len(js)} judgments; question file {args.questions}; "
                        f"checkout Sagittarius {info['checkout_version']}" + (f"; hub {args.hub}" if args.hub else "")
                        + (f"; picked hub {pick}" if pick else ""))
                page = render_html(js, summarize(js), meta, info["hubs"], pick)
            except (OSError, ValueError) as e:
                self._send(500, f"inspect: {e}", "text/plain; charset=utf-8")
                return
            live = (f"<p id=\"live\" class=\"meta\">live: connecting</p><script>{LIVE_JS}</script>")
            page = page.replace("</body></html>", live + "</body></html>", 1)
            self._send(200, page, "text/html; charset=utf-8")

        def log_message(self, *a):  # quiet
            pass

    httpd = http.server.ThreadingHTTPServer(("127.0.0.1", args.serve), Handler)
    print(f"serving http://127.0.0.1:{args.serve}/ (newest {args.last}; ctrl+c stops)", flush=True)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    return 0


def main(argv=None):
    args = parser().parse_args(argv)
    if args.serve is not None:
        return serve(args)
    try:
        js, info = build(args)
    except (OSError, ValueError) as e:
        print(f"inspect: {e}", file=sys.stderr)
        return 2
    if args.hub and not info["hub_dirs"]:
        print(f"inspect: no projects dir found for hub {args.hub} under {args.projects}", file=sys.stderr)
    if args.html:
        meta = (f"log {args.log}; {len(js)} judgments; question file {args.questions}; "
                f"checkout Sagittarius {info['checkout_version']}"
                + (f"; hub {args.hub}" if args.hub else ""))
        with open(args.html, "w", encoding="utf-8") as f:
            f.write(render_html(js, summarize(js), meta))
        print(f"wrote {args.html} ({len(js)} judgments)")
    elif args.summary:
        s = summarize(js)
        print(json.dumps(s, indent=1) if args.json else render_summary_text(s))
    elif args.json:
        for j in js:
            print(json.dumps(j, ensure_ascii=False))
    else:
        print(render_text(js, info))
    return 0


if __name__ == "__main__":
    sys.exit(main())
