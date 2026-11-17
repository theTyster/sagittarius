#!/usr/bin/env python3
"""desk.py -- the Desk: Ty's responses ("letters") to hub items, their receipts, drafts, and their
delivery into the Claude Code sessions that own the items.

The Desk page (`orbit-kb serve questions`) calls this script. It stores each letter the moment Ty
sends it (c8), shows where each letter is (c7), and the hook below tells the owning session at its
next prompt or stop, never another session and never inside a turn (c6). It types a one-line notice
into a tmux pane only when that session is idle and blocked on the answer (q1).

usage: desk.py [--hub DIR] COMMAND [ARGS]
  send --kind answer|diverge|requirement --item-json JSON --text-file F [--choice C]
                                  store a letter; prints {"id": LID}. Then wakes the owner (see wake)
  event LID applied|apply_failed [--detail TEXT]
                                  record a receipt from the page server (exit 2: unknown LID)
  status [--json]                 sessions, orphans, kb refs, recent closed asks, letters with
                                  their state, drafts and bad lines (JSON for the page)
  draft KEY [--text-file F] [--choice C] [--intent I] [--clear]
                                  save or clear one draft (KEY: up to 300 characters)
  letters [--id LID] [--json]     print the letters, or one letter in full
  hook                            the Claude Code hook (SessionStart, UserPromptSubmit, Stop):
                                  reads the hook JSON on stdin; never fails a session
  wake LID                        type a one-line notice into each owner's tmux pane, only when
                                  the owner is idle, blocked on that answer, and runs Claude
  hooks                           print the hooks block for a hub's .claude/settings.json

Item JSON (the item a letter is about):
  {"type": "ask", "id": "A-0002"}                              any ledger item
  {"type": "question", "slug": S, "kb": "specs/S", "q": "q3"}  a question of a spec KB
  {"type": "kb", "slug": S, "kb": "specs/S", "ref": "vote"}    a KB-level card

Owners: for an ask, the item's owner_session (whatever its status); for a question or kb card,
every open or waiting item with a kb ref to the slug. An owner is live when its session is active.

Files (HUB/flow/desk/, made on demand): letters.jsonl and events.jsonl (append-only, one JSON object
per line, flock + one write + fsync), drafts.json and sessions/NAME.json (replaced atomically),
desk.log (errors of the hook and the wake). flow/flow.db is read only, never written.

Environment
  HUB_SESSION         the session name (hook)
  TMUX_PANE           the session's tmux pane (hook; set by tmux)
  CLAUDE_PROJECT_DIR  the hook's fallback hub when its cwd is in no hub
  DESK_TMUX           the tmux program (default tmux)
  DESK_WAKE_COMMANDS  pane commands that count as Claude, comma list (default claude)

Exit codes: 0 ok, 1 bad input, 2 no hub or unknown letter.
"""
import argparse, datetime, errno, fcntl, json, os, re, secrets, sqlite3, subprocess, sys
from urllib.parse import quote

KINDS = ("answer", "diverge", "requirement")
EVENTS_PAGE = ("applied", "apply_failed")
SLUG = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")
ITEM_ID = re.compile(r"^[A-Z]-\d{4,}$")
SESSION_NAME = re.compile(r"^[a-z0-9][a-z0-9-]*$")
LETTER_ID = re.compile(r"^L-\d{8}T\d{6}Z-[0-9a-f]{6}$")
TS_FMT = "%Y-%m-%dT%H:%M:%SZ"
NOTICE_MAX = 1500
TEXT_MAX = 300  # per letter in a notice
KEY_MAX = 300
TMUX_TIMEOUT = 5
TAIL = ("An answer to a KB question is in the KB or in its answers.pending (run orbit-kb show open there). "
        "A divergence leaves the item open: it is Ty's own words. A requirement went to intake. "
        "Act on them at this stop, or say why not.")


class Bad(Exception):
    """Bad input: exit 1."""


class NoHub(Exception):
    """No hub or an unknown letter: exit 2."""


def now_ts():
    return datetime.datetime.now(datetime.timezone.utc).strftime(TS_FMT)


# ---- paths ----

def find_hub(start):
    d = os.path.abspath(start)
    while True:
        if os.path.isfile(os.path.join(d, "flow", "flow.db")):
            return d
        up = os.path.dirname(d)
        if up == d:
            return None
        d = up


def hub_of(arg):
    if arg:
        if not os.path.isfile(os.path.join(arg, "flow", "flow.db")):
            raise NoHub(f"no hub: {arg} has no flow/flow.db")
        return os.path.abspath(arg)
    h = find_hub(os.getcwd())
    if h is None:
        raise NoHub(f"no hub: no flow/flow.db in {os.getcwd()} or above; pass --hub DIR")
    return h


def desk_dir(hub):
    return os.path.join(hub, "flow", "desk")


def fsync_dir(d):
    try:
        fd = os.open(d, os.O_RDONLY)
    except OSError:
        return
    try:
        os.fsync(fd)
    except OSError:
        pass
    finally:
        os.close(fd)


def ensure_dir(d):
    if not os.path.isdir(d):
        os.makedirs(d, exist_ok=True)
        fsync_dir(os.path.dirname(d))


# ---- files ----

def append_line(path, obj):
    """One JSON line, on disk before return: O_APPEND, flock, one write, fsync."""
    ensure_dir(os.path.dirname(path))
    created = not os.path.exists(path)
    data = (json.dumps(obj, ensure_ascii=False, sort_keys=True) + "\n").encode("utf-8")
    fd = os.open(path, os.O_RDWR | os.O_APPEND | os.O_CREAT, 0o644)
    try:
        fcntl.flock(fd, fcntl.LOCK_EX)
        size = os.fstat(fd).st_size
        if size and os.pread(fd, 1, size - 1) != b"\n":
            data = b"\n" + data  # a torn last line stays a bad line of its own
        n = os.write(fd, data)
        while n < len(data):
            n += os.write(fd, data[n:])
        os.fsync(fd)
    finally:
        try:
            fcntl.flock(fd, fcntl.LOCK_UN)
        finally:
            os.close(fd)
    if created:
        fsync_dir(os.path.dirname(path))


def read_jsonl(path, bad, need):
    """The objects of a JSONL file, with their line numbers. A bad line is skipped and noted."""
    out = []
    try:
        fd = os.open(path, os.O_RDONLY)
    except FileNotFoundError:
        return out
    try:
        fcntl.flock(fd, fcntl.LOCK_SH)
        chunks = []
        while True:
            b = os.read(fd, 1 << 16)
            if not b:
                break
            chunks.append(b)
    finally:
        os.close(fd)
    name = os.path.basename(path)
    for n, raw in enumerate(b"".join(chunks).split(b"\n"), 1):
        if not raw.strip():
            continue
        text = raw.decode("utf-8", "replace")
        try:
            obj = json.loads(text)
            ok = isinstance(obj, dict) and all(isinstance(obj.get(k), str) for k in need)
        except ValueError:
            ok = False
        if not ok:
            bad.append({"file": name, "line": n, "text": text[:80]})
            continue
        out.append(obj)
    return out


def write_atomic(path, obj):
    ensure_dir(os.path.dirname(path))
    tmp = f"{path}.tmp.{os.getpid()}"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, sort_keys=True, indent=1)
        f.write("\n")
        f.flush()
        os.fsync(f.fileno())
    os.replace(tmp, path)
    fsync_dir(os.path.dirname(path))


def read_json(path, bad, default):
    try:
        with open(path, encoding="utf-8") as f:
            obj = json.load(f)
        if isinstance(obj, dict):
            return obj
        raise ValueError("not an object")
    except FileNotFoundError:
        return default
    except (OSError, ValueError) as e:
        bad.append({"file": os.path.basename(path), "line": 0,
                    "text": str(e)[:80]})
        return default


def log(hub, msg):
    if not hub:
        return
    try:
        d = desk_dir(hub)
        ensure_dir(d)
        fd = os.open(os.path.join(d, "desk.log"), os.O_WRONLY | os.O_APPEND | os.O_CREAT, 0o644)
        try:
            os.write(fd, f"{now_ts()} {msg}".replace("\n", " ").encode("utf-8")[:2000] + b"\n")
        finally:
            os.close(fd)
    except OSError:
        pass


class Store:
    def __init__(self, hub):
        self.hub = hub
        self.dir = desk_dir(hub)
        self.bad = []

    def letters(self):
        return read_jsonl(os.path.join(self.dir, "letters.jsonl"), self.bad, ("id",))

    def events(self):
        return read_jsonl(os.path.join(self.dir, "events.jsonl"), self.bad, ("letter", "event"))

    def add_event(self, lid, event, session=None, detail=None):
        append_line(os.path.join(self.dir, "events.jsonl"),
                    {"at": now_ts(), "letter": lid, "event": event, "session": session, "detail": detail})

    def session_path(self, name):
        return os.path.join(self.dir, "sessions", name + ".json")

    def session_state(self, name):
        if not SESSION_NAME.match(name or ""):
            return None
        return read_json(self.session_path(name), self.bad, None)

    def drafts(self):
        return read_json(os.path.join(self.dir, "drafts.json"), self.bad, {})


# ---- the ledger (read only) ----

def connect(hub):
    p = os.path.join(hub, "flow", "flow.db")
    c = sqlite3.connect("file:" + quote(p) + "?mode=ro", uri=True, timeout=5)
    c.row_factory = sqlite3.Row
    c.execute("PRAGMA busy_timeout=5000")
    return c


def ref_slug(ref):
    """The spec KB slug of a kb ref: <slug>, a path ending in <slug>, or the old <slug>/kb."""
    parts = [p for p in ref.split("/") if p]
    if len(parts) == 2 and parts[1] == "kb":
        return parts[0]
    return parts[-1] if parts else ref


def kb_items(c):
    """Open or waiting items with kb refs: (slug, row)."""
    out = []
    for r in c.execute("SELECT i.id, i.kind, i.title, i.status, i.owner_session, r.ref FROM item i"
                       " JOIN item_ref r ON r.item_id = i.id WHERE r.kind = 'kb'"
                       " AND i.status IN ('open','waiting') ORDER BY i.id, r.ref"):
        out.append((ref_slug(r["ref"]), r))
    return out


def active_sessions(c):
    return {r[0] for r in c.execute("SELECT name FROM session WHERE status = 'active'")}


def owners(c, letter, kbi=None):
    it = letter.get("item") or {}
    if it.get("type") == "ask":
        r = c.execute("SELECT owner_session FROM item WHERE id = ?", (it.get("id"),)).fetchone()
        return [r[0]] if r and r[0] else []
    slug = it.get("slug")
    kbi = kb_items(c) if kbi is None else kbi
    return sorted({r["owner_session"] for s, r in kbi if s == slug and r["owner_session"]})


def blocked_on(c, letter, s, kbi=None):
    """The session s waits on this answer: the ask is waiting and s owns it, or s owns a waiting
    item with a kb ref to the slug."""
    it = letter.get("item") or {}
    if it.get("type") == "ask":
        r = c.execute("SELECT status, owner_session FROM item WHERE id = ?", (it.get("id"),)).fetchone()
        return bool(r and r["status"] == "waiting" and r["owner_session"] == s)
    kbi = kb_items(c) if kbi is None else kbi
    return any(sl == it.get("slug") and r["status"] == "waiting" and r["owner_session"] == s for sl, r in kbi)


def resolve_name(c, name):
    r = c.execute("SELECT name FROM session WHERE name = ?", (name,)).fetchone()
    if r is None:
        r = c.execute("SELECT name FROM session_alias WHERE alias = ?", (name,)).fetchone()
    return r[0] if r else name


def item_name(letter):
    it = letter.get("item") or {}
    if it.get("type") == "ask":
        return str(it.get("id"))
    where = it.get("kb") or f"specs/{it.get('slug')}"
    return f"{where} {it.get('q') if it.get('type') == 'question' else it.get('ref')}"


# ---- validation ----

def check_rel(v, what):
    if not isinstance(v, str) or not v.strip() or v.startswith("/") or ".." in v.split("/") or "\n" in v:
        raise Bad(f"item {what} must be a path relative to the hub")
    return v


def check_short(v, what, n=200):
    if not isinstance(v, str) or not v.strip() or len(v) > n or "\n" in v:
        raise Bad(f"item {what} must be one line of 1 to {n} characters")
    return v


def check_item(raw):
    try:
        it = json.loads(raw)
    except ValueError as e:
        raise Bad(f"--item-json is not JSON: {e}")
    if not isinstance(it, dict):
        raise Bad("--item-json must be an object")
    shapes = {"ask": ("type", "id"), "question": ("type", "slug", "kb", "q"), "kb": ("type", "slug", "kb", "ref")}
    t = it.get("type")
    if t not in shapes:
        raise Bad("item type must be ask, question or kb")
    if set(it) != set(shapes[t]):
        raise Bad(f"a {t} item has exactly the keys {', '.join(shapes[t])}")
    if t == "ask":
        if not isinstance(it["id"], str) or not ITEM_ID.match(it["id"]):
            raise Bad(f"item id {it['id']!r} is not a ledger id such as A-0002")
    else:
        if not isinstance(it["slug"], str) or not SLUG.match(it["slug"]):
            raise Bad(f"item slug {it['slug']!r} is not a slug")
        check_rel(it["kb"], "kb")
        check_short(it["q"] if t == "question" else it["ref"], "q" if t == "question" else "ref")
    return it


def read_text(path):
    try:
        if path == "-":
            return sys.stdin.read()
        with open(path, encoding="utf-8") as f:
            return f.read()
    except (OSError, UnicodeDecodeError) as e:
        raise Bad(f"cannot read {path}: {e}")


def find_letter(store, lid):
    for x in store.letters():
        if x.get("id") == lid:
            return x
    raise NoHub(f"no letter {lid}")


# ---- commands ----

def cmd_send(hub, a):
    if a.kind not in KINDS:
        raise Bad(f"--kind must be one of {', '.join(KINDS)}")
    it = check_item(a.item_json)
    text = read_text(a.text_file)
    choice = a.choice if a.choice else None
    if not text.strip() and not (a.kind == "answer" and choice):
        raise Bad("the text is empty (only an answer with a choice may have no text)")
    t = datetime.datetime.now(datetime.timezone.utc)
    lid = f"L-{t.strftime('%Y%m%dT%H%M%SZ')}-{secrets.token_hex(3)}"
    letter = {"id": lid, "at": t.strftime(TS_FMT), "kind": a.kind, "item": it, "text": text,
              "choice": choice, "by": "human"}
    append_line(os.path.join(desk_dir(hub), "letters.jsonl"), letter)  # stored before we return (c8)
    print(json.dumps({"id": lid}))
    sys.stdout.flush()
    try:
        wake(hub, letter)
    except Exception as e:  # best effort: the letter is stored
        print(f"desk: wake {lid} failed: {e}", file=sys.stderr)
        log(hub, f"wake {lid} failed: {e!r}")


def cmd_event(hub, a):
    store = Store(hub)
    find_letter(store, a.lid)
    store.add_event(a.lid, a.event, None, a.detail)
    print(json.dumps({"letter": a.lid, "event": a.event}))


def letter_views(c, store, letters, events):
    kbi = kb_items(c)
    live = active_sessions(c)
    by = {}
    for i, e in enumerate(events):
        by.setdefault(e["letter"], []).append((i, e))
    out = []
    for x in reversed(letters):
        ev = by.get(x["id"], [])
        own = owners(c, x, kbi)
        lv = [s for s in own if s in live]
        applied = [(i, e) for i, e in ev if e["event"] == "applied"]
        failed = [(i, e) for i, e in ev if e["event"] == "apply_failed"]
        last_ok = applied[-1] if applied else None
        last_bad = failed[-1] if failed and (not applied or failed[-1][0] > applied[-1][0]) else None
        seen = [{"session": e.get("session"), "at": e.get("at")} for _, e in ev if e["event"] == "seen"]
        woken = [{"session": e.get("session"), "at": e.get("at")} for _, e in ev if e["event"] == "woken"]
        closed = None
        it = x.get("item") or {}
        if it.get("type") == "ask":
            r = c.execute("SELECT status FROM item WHERE id = ?", (it.get("id"),)).fetchone()
            closed = None if r is None else r[0] not in ("open", "waiting")
        state = "applied" if last_ok else "apply_failed" if last_bad else "seen" if seen else "sent"
        out.append(dict(x, owners=own, live_owners=lv, no_live_owner=not lv, seen=seen, woken=woken,
                        applied={"at": last_ok[1].get("at"), "detail": last_ok[1].get("detail")} if last_ok else None,
                        apply_failed={"at": last_bad[1].get("at"), "detail": last_bad[1].get("detail")} if last_bad else None,
                        item_closed=closed, state=state))
    return out


def rows(c, sql, params=()):
    return [dict(r) for r in c.execute(sql, params)]


def status_obj(hub):
    store = Store(hub)
    letters, events, drafts = store.letters(), store.events(), store.drafts()
    c = connect(hub)
    try:
        now = c.execute("SELECT now FROM clock").fetchone()[0]
        sessions = []
        for s in rows(c, "SELECT name, role, status FROM session ORDER BY name"):
            st = store.session_state(s["name"]) or {}
            inbox = rows(c, "SELECT id, kind, title, status, unaccepted, age_days, idle_days FROM v_inbox"
                            " WHERE session = ? ORDER BY id", (s["name"],))
            for r in inbox:
                r["unaccepted"] = bool(r["unaccepted"])
            sessions.append(dict(s, state=st.get("state"), state_at=st.get("at"), tmux_pane=st.get("tmux_pane"),
                                 inbox=inbox))
        unowned = rows(c, "SELECT o.id, o.kind, o.title, o.owner_session, o.age_days FROM v_open o"
                          " WHERE o.owner_session IS NULL OR o.owner_session NOT IN"
                          " (SELECT name FROM session WHERE status = 'active') ORDER BY o.id")
        unaccepted = rows(c, "SELECT o.id, o.title, h.from_session AS \"from\", h.to_session AS \"to\", o.age_days"
                             " FROM v_open o JOIN handoff h ON h.item_id = o.id WHERE h.accepted_at IS NULL ORDER BY o.id")
        kb_refs = {}
        for slug, r in kb_items(c):
            lst = kb_refs.setdefault(slug, [])
            row = {k: r[k] for k in ("id", "kind", "title", "status", "owner_session")}
            if row not in lst:
                lst.append(row)
        closed = rows(c, """SELECT i.id, i.title, i.status, i.close_reason, i.closed_at, i.owner_session,
  e.by, e.by_session, e.note FROM item i, clock
  LEFT JOIN event e ON e.seq = (SELECT MAX(seq) FROM event x WHERE x.item_id = i.id AND x.verb = 'closed')
  WHERE i.kind = 'ask' AND i.closed_at IS NOT NULL
    AND i.closed_at >= strftime('%Y-%m-%dT%H:%M:%SZ', clock.now, '-7 days')
  ORDER BY i.closed_at DESC, i.id""")
        lv = letter_views(c, store, letters, events)
    finally:
        c.close()
    return {"now": now, "sessions": sessions, "orphans": {"unowned": unowned, "unaccepted": unaccepted},
            "kb_refs": kb_refs, "closed_recent": closed, "letters": lv, "drafts": drafts,
            "bad_lines": {"count": len(store.bad), "lines": store.bad}}


def cmd_status(hub, a):
    s = status_obj(hub)
    if a.json:
        print(json.dumps(s, ensure_ascii=False, indent=1))
        return
    for x in s["sessions"]:
        print(f"session {x['name']} ({x['status']}): {x['state'] or 'no state'}, inbox {len(x['inbox'])}")
    for x in s["letters"]:
        loud = " NO LIVE OWNER" if x["no_live_owner"] else ""
        print(f"{x['id']} {item_name(x)} {x['kind']}: {x['state']}{loud}")
    if s["bad_lines"]["count"]:
        print(f"bad lines: {s['bad_lines']['count']}")


def cmd_draft(hub, a):
    if not a.key or len(a.key) > KEY_MAX or "\n" in a.key:
        raise Bad(f"a draft key is one line of 1 to {KEY_MAX} characters")
    d = desk_dir(hub)
    ensure_dir(d)
    path = os.path.join(d, "drafts.json")
    fd = os.open(os.path.join(d, "drafts.lock"), os.O_WRONLY | os.O_CREAT, 0o644)
    try:
        fcntl.flock(fd, fcntl.LOCK_EX)
        bad = []
        drafts = read_json(path, bad, {})
        if a.clear:
            drafts.pop(a.key, None)
        else:
            drafts[a.key] = {"text": read_text(a.text_file) if a.text_file else "", "choice": a.choice or None,
                             "intent": a.intent or None, "at": now_ts()}
        write_atomic(path, drafts)
    finally:
        os.close(fd)
    print(json.dumps({"key": a.key, "cleared" if a.clear else "saved": True}))


def cmd_letters(hub, a):
    store = Store(hub)
    if a.id:
        x = find_letter(store, a.id)
        if a.json:
            print(json.dumps(x, ensure_ascii=False, indent=1))
        else:
            print(f"{x['id']} {x.get('at')} {x.get('kind')} {item_name(x)}"
                  + (f" choice: {x['choice']}" if x.get("choice") else ""))
            print(x.get("text", ""))
        return
    ls = store.letters()
    if a.json:
        print(json.dumps(ls, ensure_ascii=False, indent=1))
        return
    for x in ls:
        first = (x.get("text") or "").strip().split("\n")[0]
        print(f"{x['id']} {x.get('at')} {x.get('kind')} {item_name(x)}: {first[:100]}")


# ---- the notice and the hook ----

def letter_line(x):
    head = f"{x.get('kind')}: {x['choice']}" if x.get("choice") else str(x.get("kind"))
    text = x.get("text") or ""
    line = f"- {item_name(x)} ({head})"
    if text.strip():
        if len(text) > TEXT_MAX:
            text = text[:TEXT_MAX] + f"… (cut; read it all: .claude/scripts/desk.py letters --id {x['id']})"
        line += ": " + json.dumps(text, ensure_ascii=False)
    return line


def notice(letters):
    """The notice text and the letters it holds (at least one; the rest wait for the next stop or prompt)."""
    lines, held = [], []
    for x in letters:
        ln = letter_line(x)
        if held and sum(len(s) + 1 for s in lines) + len(ln) + len(TAIL) + 200 > NOTICE_MAX:
            break
        lines.append(ln)
        held.append(x)
    head = (f"Desk: Ty sent {len(held)} response(s) for items you own. Each is stored in flow/desk/letters.jsonl.")
    rest = len(letters) - len(held)
    more = [f"({rest} more response(s) follow at the next stop or prompt; .claude/scripts/desk.py letters lists all.)"] if rest else []
    return "\n".join([head] + lines + more + [TAIL]), held


def write_state(store, name, state, ev, data):
    write_atomic(store.session_path(name), {"name": name, "session_id": data.get("session_id"), "state": state,
                                            "at": now_ts(), "tmux_pane": os.environ.get("TMUX_PANE") or None,
                                            "cwd": data.get("cwd"), "event": ev})


def hook_hub(arg, data):
    if arg:
        return os.path.abspath(arg) if os.path.isfile(os.path.join(arg, "flow", "flow.db")) else None
    cwd = data.get("cwd") if isinstance(data.get("cwd"), str) else None
    h = find_hub(cwd or os.getcwd())
    if h is None and os.environ.get("CLAUDE_PROJECT_DIR"):
        h = find_hub(os.environ["CLAUDE_PROJECT_DIR"])
    return h


def run_hook(hub_arg):
    hub = None
    try:
        raw = sys.stdin.read()
        data = json.loads(raw)
        if not isinstance(data, dict):
            return
        name = os.environ.get("HUB_SESSION")
        hub = hook_hub(hub_arg, data)
        if not name or not hub:
            return
        ev = data.get("hook_event_name")
        if ev not in ("SessionStart", "UserPromptSubmit", "Stop"):
            return
        c = connect(hub)
        try:
            name = resolve_name(c, name)
            if not SESSION_NAME.match(name):
                log(hub, f"hook: bad session name {name!r}")
                return
            store = Store(hub)
            seen = {e["letter"] for e in store.events() if e["event"] == "seen" and e.get("session") == name}
            kbi = kb_items(c)
            todo = [x for x in store.letters() if x["id"] not in seen and name in owners(c, x, kbi)]
        finally:
            c.close()
        stop = ev == "Stop"
        if stop and data.get("stop_hook_active") is True:
            todo = []  # already continuing from a stop hook: the letters wait
        state = "busy" if ev == "UserPromptSubmit" or (stop and todo) else "idle"
        write_state(store, name, state, ev, data)
        if not todo:
            return
        text, held = notice(todo)
        for x in held:
            try:
                store.add_event(x["id"], "seen", name)
            except OSError as e:
                log(hub, f"hook: seen {x['id']} for {name} not recorded: {e!r}")
        if stop:
            out = {"decision": "block", "reason": text}
        else:
            out = {"hookSpecificOutput": {"hookEventName": ev, "additionalContext": text}}
        sys.stdout.write(json.dumps(out, ensure_ascii=False) + "\n")
        sys.stdout.flush()
    except Exception as e:  # never fail a session
        log(hub, f"hook: {e!r}")


# ---- wake ----

def tmux(*args):
    prog = os.environ.get("DESK_TMUX") or "tmux"
    return subprocess.run([prog] + list(args), capture_output=True, text=True, timeout=TMUX_TIMEOUT)


def wake(hub, letter):
    """Type one line into each live owner's pane when it is idle, blocked on the answer, runs Claude,
    has not seen the letter and was not woken for it. Returns the sessions woken."""
    store = Store(hub)
    lid = letter["id"]
    events = store.events()
    done = {(e["event"], e.get("session")) for e in events if e["letter"] == lid}
    cmds = {x.strip() for x in (os.environ.get("DESK_WAKE_COMMANDS") or "claude").split(",") if x.strip()}
    c = connect(hub)
    try:
        kbi = kb_items(c)
        own = owners(c, letter, kbi)
        live = active_sessions(c)
        blocked = {s: blocked_on(c, letter, s, kbi) for s in own}
    finally:
        c.close()
    woken = []
    if not own:
        print(f"desk: wake {lid}: no owner", file=sys.stderr)
    for s in own:
        why = None
        st = store.session_state(s) if SESSION_NAME.match(s) else None
        if s not in live:
            why = "not live"
        elif ("woken", s) in done:
            why = "already woken"
        elif ("seen", s) in done:
            why = "already seen"
        elif not st or st.get("state") != "idle" or not st.get("tmux_pane"):
            why = "not idle in a known pane" if st else "no session state"
        elif not blocked[s]:
            why = "not blocked on this answer"
        if why is None:
            pane = st["tmux_pane"]
            try:
                p = tmux("display-message", "-p", "-t", pane, "#{pane_current_command}")
                cur = p.stdout.strip() if p.returncode == 0 else None
            except (OSError, subprocess.SubprocessError) as e:
                cur, why = None, f"tmux failed: {e}"
            if why is None and cur not in cmds:
                why = f"pane {pane} runs {cur!r}, not Claude"
            if why is None:
                again = store.session_state(s)
                if not again or again.get("state") != "idle" or again.get("tmux_pane") != pane:
                    why = "no longer idle"
            if why is None:
                line = (f"Desk: Ty sent a response for {item_name(letter)}. "
                        "It is stored; read the Desk notice of this prompt.")
                p1 = tmux("send-keys", "-t", pane, "-l", line)
                p2 = tmux("send-keys", "-t", pane, "Enter") if p1.returncode == 0 else p1
                if p1.returncode or p2.returncode:
                    why = f"tmux send-keys failed: {(p1.stderr or p2.stderr).strip()[:100]}"
                    log(hub, f"wake {lid} {s}: {why}")
                else:
                    store.add_event(lid, "woken", s, pane)
                    woken.append(s)
        print(f"desk: wake {lid} {s}: " + ("woken" if why is None else why), file=sys.stderr)
    return woken


def cmd_wake(hub, a):
    wake(hub, find_letter(Store(hub), a.lid))


def cmd_hooks(hub, a):
    cmd = [{"hooks": [{"type": "command", "command": "python3 \"$CLAUDE_PROJECT_DIR\"/.claude/scripts/desk.py hook",
                       "timeout": 10}]}]
    print(json.dumps({"hooks": {"SessionStart": cmd, "UserPromptSubmit": cmd, "Stop": cmd}}, indent=1))


# ---- main ----

def parser():
    p = argparse.ArgumentParser(prog="desk.py", description="The Desk: Ty's responses to hub items.")
    p.add_argument("--hub")
    sub = p.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("send")
    s.add_argument("--kind", required=True)
    s.add_argument("--item-json", required=True)
    s.add_argument("--text-file", required=True)
    s.add_argument("--choice")
    s = sub.add_parser("event")
    s.add_argument("lid")
    s.add_argument("event", choices=EVENTS_PAGE)
    s.add_argument("--detail")
    s = sub.add_parser("status")
    s.add_argument("--json", action="store_true")
    s = sub.add_parser("draft")
    s.add_argument("key")
    s.add_argument("--text-file")
    s.add_argument("--choice")
    s.add_argument("--intent")
    s.add_argument("--clear", action="store_true")
    s = sub.add_parser("letters")
    s.add_argument("--id")
    s.add_argument("--json", action="store_true")
    sub.add_parser("hook")
    s = sub.add_parser("wake")
    s.add_argument("lid")
    sub.add_parser("hooks")
    return p


COMMANDS = {"send": cmd_send, "event": cmd_event, "status": cmd_status, "draft": cmd_draft,
            "letters": cmd_letters, "wake": cmd_wake, "hooks": cmd_hooks}


def main():
    argv = sys.argv[1:]
    if "hook" in argv:  # the hook never fails a session, not even on bad arguments
        try:
            a = parser().parse_args(argv)
        except SystemExit:
            sys.exit(0)
        if a.cmd == "hook":
            run_hook(a.hub)
            sys.exit(0)
    a = parser().parse_args(argv)
    try:
        hub = None if a.cmd == "hooks" else hub_of(a.hub)
        COMMANDS[a.cmd](hub, a)
    except Bad as e:
        print(f"desk: {e}", file=sys.stderr)
        sys.exit(1)
    except NoHub as e:
        print(f"desk: {e}", file=sys.stderr)
        sys.exit(2)
    except sqlite3.Error as e:
        print(f"desk: the ledger cannot be read: {e}", file=sys.stderr)
        sys.exit(2)


if __name__ == "__main__":
    main()
