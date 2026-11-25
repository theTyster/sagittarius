"""The record that System 1 reads beside the conversation (scientific-method-overhaul c29, c34,
c36, c46). Python 3 standard library only. Used by hook.py and stop.py.

What it does:

- source_of(prompt): a prompt that starts with <cross-session-message, <task-notification or
  <agent-message was not written by the human (c34). No model is asked.
- fetch(env, payload): the active record, through `orbit s1-record --json` (c29). The command is
  $S1_ORBIT, else the hub's .claude/orbit-kb/bin/orbit, else `orbit` on the PATH. It gets
  S1_ORBIT_TIMEOUT seconds (default 0.5). A missing command, a failure, a timeout or a bad reply
  gives no record: the hook goes on with the state of 0.7.2 (c36: fail open, never block).
  With no ticket, the record is the goal and the hypotheses that the session stated (q24), kept
  in a small file for each session ($S1_SESSION_DIR, default ~/.claude/s1-session).
- clean(obj): only the fields of the contract leave the machine (c46). A field that the contract
  does not name is dropped here, whatever the command printed.
- attach(state, rec, questions, long_context): puts the record in the state as state["record"]
  and returns the log fields (record, record_sent, ...). A record that does not fit the context
  in use is cut: goal sentences first, then open questions, then predictions, then all of it.
- off(env, hub): the switch. S1_RECORD=0, or "s1_record": false under "modules" in the hub's
  .hub-template.json. Then nothing is fetched and the state has exactly the fields of 0.7.2.
- propose(rec, env, fact, note): one proposal of System 1, through `orbit propose --from system1`
  (c34). It is a proposal only: `orbit confirm-proposal P` makes it a record.

No function here raises to its caller.
"""
import hashlib
import json
import os
import re
import shlex
import shutil
import signal
import subprocess
import time

ORBIT_TIMEOUT = 0.5  # seconds for one call of orbit (c36: far under the 4 s of the model call)
HUB_MARK = ".hub-template.json"
SESSION_DIR = os.path.expanduser("~/.claude/s1-session")
TAGS = ("cross-session-message", "task-notification", "agent-message")  # e6: 133 of 147, 0 of 110
NOT_HUMAN = re.compile(r"^\s*<(" + "|".join(TAGS) + r")(?=[\s>/])", re.I)
HUMAN_ONLY = ("h_effort", "h_change_of_plan")  # q25: signals that only a human can give
MASKED = {"type": "noul", "noul": 0.5}  # the unsure band: the line leaves it out
MAX_STATED = 5  # hypotheses that a session stated: the newest are kept
TEXT_MAX = 4000  # one text of the record is cut at this many characters


def source_of(prompt):
    """The tag name when the prompt starts with a tag of a message that the human did not write
    (c34), else None. Code decides it: the model is not asked."""
    m = NOT_HUMAN.match(prompt) if isinstance(prompt, str) else None
    return m.group(1).lower() if m else None


def mask(answers, source):
    """The answers with the signals that only a human can give (effort, change of plan) put in
    the unsure band, for a message that the human did not write (q25). Other answers stay: a
    result that differs from what was expected is still a divergence. A copy."""
    if not source or not isinstance(answers, dict):
        return answers
    out = dict(answers)
    for qid in HUMAN_ONLY:
        if qid in out:
            out[qid] = dict(MASKED)
    return out


def compose(line, front=(), back=()):
    """The line with parts added: front parts after "System 1: ", back parts at the end. A line
    of a hook that failed ("no view") gets only the front parts (the source of the message, which
    code decides); a line of another form is not changed."""
    head = "System 1: "
    front, back = [p for p in front if p], [p for p in back if p]
    if not (front or back) or not isinstance(line, str) or not line.startswith(head):
        return line
    if line.startswith(head + "no view"):  # a hook that failed still says whose message it was
        back = []
        if not front:
            return line
    return head + "; ".join(front + [line[len(head):]] + back)


def source_part(source):
    return f"not from the human ({source})" if source else None


def project_dir(env, payload):
    """The project dir of the session: $CLAUDE_PROJECT_DIR, else the cwd of the hook input."""
    for d in (env.get("CLAUDE_PROJECT_DIR"), payload.get("cwd") if isinstance(payload, dict) else None):
        if isinstance(d, str) and d and os.path.isdir(d):
            return os.path.abspath(d)
    return None


def hub_of(pdir):
    """The hub that holds pdir (the folder with .hub-template.json, pdir or one above it), or None."""
    d = pdir
    while d:
        if os.path.isfile(os.path.join(d, HUB_MARK)):
            return d
        up = os.path.dirname(d)
        if up == d:
            break
        d = up
    return None


def off(env, hub):
    """Why the record is off, or None when it is on. S1_RECORD=0 (also off, false, no), or
    "s1_record": false under "modules" of the hub's .hub-template.json."""
    v = env.get("S1_RECORD")
    if isinstance(v, str) and v.strip().lower() in ("0", "off", "false", "no"):
        return "S1_RECORD"
    if hub:
        try:
            with open(os.path.join(hub, HUB_MARK), encoding="utf-8") as f:
                mods = json.load(f).get("modules")
            if isinstance(mods, dict) and mods.get("s1_record") is False:
                return "hub"
        except (OSError, ValueError, AttributeError):
            pass
    return None


def orbit_command(env, hub):
    """(argv prefix, how) of the orbit command, or (None, None). how: env | hub | path."""
    v = env.get("S1_ORBIT")
    if isinstance(v, str) and v.strip():
        try:
            return shlex.split(v), "env"
        except ValueError:
            return None, None
    if hub:
        p = os.path.join(hub, ".claude", "orbit-kb", "bin", "orbit")
        if os.path.isfile(p) and os.access(p, os.X_OK):
            return [p], "hub"
    p = shutil.which("orbit", path=env.get("PATH") or "")
    return ([p], "path") if p else (None, None)


def budget(env):
    try:
        t = float(env.get("S1_ORBIT_TIMEOUT", ORBIT_TIMEOUT))
        return t if t > 0 else ORBIT_TIMEOUT
    except (TypeError, ValueError):
        return ORBIT_TIMEOUT


def run_orbit(argv, env, cwd, timeout):
    """(stdout, None) or (None, why). The child runs in its own session, and the whole group is
    killed at the timeout, so a slow command never outlives its budget. Never raises."""
    child_env = dict(env)
    child_env.setdefault("PATH", os.environ.get("PATH", "/usr/bin:/bin"))
    try:
        p = subprocess.Popen(argv, env=child_env, cwd=cwd if cwd and os.path.isdir(cwd) else None,
                             stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                             stderr=subprocess.DEVNULL, start_new_session=True, close_fds=True)
    except (OSError, ValueError):
        return None, "orbit missing"
    try:
        out, _ = p.communicate(timeout=max(timeout, 0.01))
    except subprocess.TimeoutExpired:
        try:
            os.killpg(p.pid, signal.SIGKILL)
        except OSError:
            pass
        try:
            p.communicate(timeout=0.2)
        except Exception:
            pass
        return None, "orbit timeout"
    except Exception:
        return None, "orbit failed"
    if p.returncode != 0:
        return None, "orbit failed"
    return out.decode("utf-8", "replace"), None


def _text(x):
    return x[:TEXT_MAX] if isinstance(x, str) else None


def _items(xs, fields):
    """The list xs with only the named string fields of each item; an item with no id or no text
    is dropped."""
    out = []
    for x in xs if isinstance(xs, list) else []:
        if not isinstance(x, dict) or not isinstance(x.get("id"), str) or not isinstance(x.get("text"), str):
            continue
        out.append({k: _text(x[k]) if isinstance(x.get(k), str) else None for k in fields})
    return out


def clean(obj):
    """The record with only the fields of the contract (c46): ticket, goal {id, author, text},
    hypotheses [{id, author, state, text, defeating_case, predictions [{id, text}]}], questions
    [{id, text}], goal_sentences [{id, text}]. Raises ValueError when obj is not an object."""
    if not isinstance(obj, dict):
        raise ValueError("the record is not an object")
    g = obj.get("goal")
    goal = None
    if isinstance(g, dict) and isinstance(g.get("text"), str):
        goal = {"id": _text(g.get("id")), "author": _text(g.get("author")), "text": _text(g["text"])}
    hyps = []
    for h in obj.get("hypotheses") if isinstance(obj.get("hypotheses"), list) else []:
        if not isinstance(h, dict) or not isinstance(h.get("id"), str) or not isinstance(h.get("text"), str):
            continue
        hyps.append({"id": _text(h["id"]), "author": _text(h.get("author")), "state": _text(h.get("state")),
                     "text": _text(h["text"]), "defeating_case": _text(h.get("defeating_case")),
                     "predictions": _items(h.get("predictions"), ("id", "text"))})
    return {"ticket": obj.get("ticket") if isinstance(obj.get("ticket"), str) else None,
            "goal": goal, "hypotheses": hyps,
            "questions": _items(obj.get("questions"), ("id", "text")),
            "goal_sentences": _items(obj.get("goal_sentences"), ("id", "text"))}


def sent(record):
    """The names of the records in a record as it is sent (the log field record_sent, c46)."""
    if not isinstance(record, dict):
        return []
    out = []
    if record.get("goal"):
        out.append(f"goal:{record['goal'].get('id')}")
    for h in record.get("hypotheses", []):
        out.append(f"hypothesis:{h.get('id')}")
        out.extend(f"claim:{c.get('id')}" for c in h.get("predictions", []))
    out.extend(f"question:{q.get('id')}" for q in record.get("questions", []))
    out.extend(f"goal_sentence:{s.get('id')}" for s in record.get("goal_sentences", []))
    return out


def empty(record):
    return not (record.get("goal") or record.get("hypotheses") or record.get("questions")
                or record.get("goal_sentences"))


# --- what the session stated (q24): a small file for each session ---

def _safe(sid):
    return sid if isinstance(sid, str) and re.fullmatch(r"[A-Za-z0-9_.-]{1,128}", sid) else None


def session_path(env, session_id):
    sid = _safe(session_id)
    if not sid:
        return None
    return os.path.join(os.path.expanduser(env.get("S1_SESSION_DIR") or SESSION_DIR), sid + ".json")


def load_session(env, session_id):
    """The state file of the session: {"goal", "hypotheses", "pairs", "stop"}; {} when none."""
    p = session_path(env, session_id)
    if not p:
        return {}
    try:
        with open(p, encoding="utf-8") as f:
            d = json.load(f)
        return d if isinstance(d, dict) else {}
    except (OSError, ValueError):
        return {}


def save_session(env, session_id, data):
    """Write the state file of the session (one rename). Returns True when it was written."""
    p = session_path(env, session_id)
    if not p:
        return False
    try:
        os.makedirs(os.path.dirname(p), mode=0o700, exist_ok=True)
        tmp = f"{p}.{os.getpid()}.tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False)
        os.replace(tmp, p)
        return True
    except OSError:
        return False


def short_id(prefix, text):
    """An id for a record that System 1 proposes: the prefix and 8 hex digits of the text's sha256."""
    return prefix + hashlib.sha256(text.encode("utf-8")).hexdigest()[:8]


def state_goal(env, session_id, text, author="human"):
    """The session stated a goal (q24): it replaces the goal that the session stated before."""
    d = load_session(env, session_id)
    d["goal"] = {"id": short_id("s1_g", text), "author": author, "text": text[:TEXT_MAX]}
    return save_session(env, session_id, d)


def state_hypothesis(env, session_id, text, author="human"):
    """The session stated a hypothesis (q24): kept with the others, at most MAX_STATED."""
    d = load_session(env, session_id)
    hs = [h for h in d.get("hypotheses", []) if isinstance(h, dict) and h.get("text") != text]
    hs.append({"id": short_id("s1_h", text), "author": author, "state": "proposed",
               "text": text[:TEXT_MAX], "defeating_case": None, "predictions": []})
    d["hypotheses"] = hs[-MAX_STATED:]
    return save_session(env, session_id, d)


def stated(env, session_id):
    """The goal and the hypotheses that the session stated, as a record, or None."""
    d = load_session(env, session_id)
    try:
        rec = clean({"ticket": None, "goal": d.get("goal"), "hypotheses": d.get("hypotheses")})
    except ValueError:
        return None
    return None if empty(rec) else rec


# --- the fetch ---

def fetch(env, payload):
    """The record for this event. Returns a dict:
        record   the cleaned record, or None
        source   ticket | session | goals | none | off
        why      why there is no record (source none or off), else None
        expected True in a hub, or when $S1_ORBIT is set: the line then says "no record"
        took     seconds spent in the orbit command (0.0 when none ran)
        hub, kb_dir, cmd, how   for propose()
    Never raises."""
    rec = {"record": None, "source": "none", "why": "no orbit command", "expected": False,
           "took": 0.0, "hub": None, "kb_dir": None, "cmd": None, "how": None}
    try:
        pdir = project_dir(env, payload)
        hub = hub_of(pdir) if pdir else None
        rec["hub"] = hub
        why = off(env, hub)
        if why:
            rec.update(source="off", why=why)
            return rec
        sid = payload.get("session_id") if isinstance(payload, dict) else None
        cmd, how = orbit_command(env, hub)
        rec.update(cmd=cmd, how=how, expected=bool(hub) or how == "env")
        got = None
        if cmd:
            argv = list(cmd) + ["s1-record"]
            if hub:
                argv += ["--hub", hub]
            if env.get("HUB_SESSION"):
                argv += ["--session", env["HUB_SESSION"]]
            argv.append("--json")
            t0 = time.monotonic()
            out, why = run_orbit(argv, env, hub or pdir, budget(env))
            rec["took"] = round(time.monotonic() - t0, 4)
            if out is None:
                rec["why"] = why
            else:
                try:
                    got = clean(json.loads(out))
                    rec["why"] = None
                except ValueError:
                    rec["why"] = "bad record"
        if got and got["ticket"]:
            if hub and os.path.isdir(os.path.join(hub, "specs", got["ticket"])):
                rec["kb_dir"] = os.path.join(hub, "specs", got["ticket"])
            rec.update(record=got, source="ticket", why=None)
            return rec
        said = stated(env, sid)
        if said:
            if got:
                said["goal_sentences"] = got["goal_sentences"]
            rec.update(record=said, source="session", why=None)
        elif got and not empty(got):
            rec.update(record=got, source="goals", why=None)
        elif got:
            rec["why"] = "no ticket"
    except Exception as e:  # fail open: the state of 0.7.2
        rec.update(record=None, source="none", why=f"error: {type(e).__name__}")
    return rec


def attach(state, rec, questions, long_context=False, limits=(96000, 786000)):
    """Put the record in the state (state["record"]) when there is one, cut to the context in
    use, and return the log fields. limits: (the default context, the long context) in
    characters, as hook.CONTEXT_CHARS and hook.LONG_CONTEXT_CHARS."""
    lx = {"record": rec.get("source", "none")}
    if rec.get("why"):
        lx["record_why"] = rec["why"]
    if rec.get("took"):
        lx["record_latency"] = rec["took"]
    record = rec.get("record")
    if not record:
        return lx
    longest = max((len(json.dumps(v)) for v in (questions or {}).values()), default=0)
    limit = limits[1] if long_context else limits[0]
    record = json.loads(json.dumps(record))  # a copy: the cuts below do not change rec
    cut = []

    def fits():
        return len(json.dumps(dict(state, record=record))) + longest <= limit

    if not fits():
        record["goal_sentences"] = []
        cut.append("goal_sentences")
    if not fits():
        record["questions"] = []
        cut.append("questions")
    if not fits():
        for h in record["hypotheses"]:
            h["predictions"] = []
        cut.append("predictions")
    if not fits():
        lx.update(record="none", record_why="too large for the context", record_cut=cut + ["all"])
        rec["attached"] = None
        return lx
    state["record"] = record
    rec["attached"] = record
    lx["record_sent"] = sent(record)
    if record.get("ticket"):
        lx["record_ticket"] = record["ticket"]
    if cut:
        lx["record_cut"] = cut
    return lx


def marker(rec):
    """The part that the line gets when a record was expected and none was sent (k29), else None."""
    if not rec or rec.get("source") == "off" or not rec.get("expected") or rec.get("attached"):
        return None
    why = rec.get("why")
    return f"no record ({why})" if why else "no record"


def quote(text):
    """A Prolog quoted atom of the text."""
    return "'" + str(text).replace("\\", "\\\\").replace("'", "\\'").replace("\n", " ").replace("\r", " ") + "'"


def propose(rec, env, fact, note=None, timeout=None):
    """One proposal of System 1 through orbit (c34): `orbit propose --from system1 FACT
    [--note TEXT] [--dir KB]`. True when the command took it. A missing command, no KB of a
    ticket, a failure or a timeout gives False (fail open). Never raises."""
    try:
        cmd, kb = rec.get("cmd"), rec.get("kb_dir")
        if not cmd or not kb:
            return False
        argv = list(cmd) + ["propose", "--from", "system1", fact]
        if note:
            argv += ["--note", note]
        argv += ["--dir", kb]
        out, _why = run_orbit(argv, env, rec.get("hub"), budget(env) if timeout is None else timeout)
        return out is not None
    except Exception:
        return False
