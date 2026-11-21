#!/usr/bin/env python3
"""desk.py -- the Desk: Ty's responses ("letters") to hub items, their receipts, drafts, and their
delivery into the Claude Code sessions that own the items.

One Desk page (`orbit-kb serve desk`) serves every mindhole on this machine (c16). A mindhole joins
it with `join`; the Desk keeps the list in its own state dir. The page calls this script. It stores
each letter the moment Ty sends it (c8), shows where each letter is (c7), and the hook below gives
each letter to its one recipient session at its next prompt or stop, never to another session and
never inside a turn (c6). It types one line into a tmux pane only when that session is idle and
blocked on the answer (q1). Drafts stay in the Desk's own state dir, outside every mindhole: no
agent reads them, and a letter enters the receiving mindhole only when Ty sends it (q10).

usage: desk.py [--hub DIR] COMMAND [ARGS]
  send --kind KIND --item-json JSON --to SESSION --about TEXT --text-file F [--choice C]
                                  store a letter for one session; prints {"id": LID}. Then wakes
                                  the recipient (see wake). KIND: answer, diverge, requirement, note (a note on a ledger item, c32), fix
                                  (a fix of an orphan or a gap), notice (a short notice)
  render --to SESSION --about TEXT --text-file F [--json]
                                  print the exact text the session gets for such a letter (the
                                  page shows it in the review). --json: {"to", "about", "delivered",
                                  "wake"}. The text is printed exactly, with no newline added
  wake-text --about TEXT          print the exact line that a wake types (no newline added)
  event LID applied|apply_failed [--detail TEXT]
                                  record a receipt from the page server (exit 2: unknown LID)
  status [--json]                 sessions, orphans, kb refs and handoffs, recent closed asks,
                                  letters with their state, and bad lines (JSON for the page)
  letters [--id LID] [--json]     print the letters, or one letter in full
  hook                            the Claude Code hook (SessionStart, UserPromptSubmit, Stop):
                                  reads the hook JSON on stdin; never fails a session
  wake LID                        type the wake line into the recipient's tmux pane, only when the
                                  recipient is idle, blocked on that answer, and runs Claude
  hooks                           print the hooks block for a hub's .claude/settings.json
  The commands below need no hub, or find it themselves:
  draft KEY [--text-file F] [--choice C] [--intent I] [--clear]
                                  save or clear one draft (KEY: up to 300 characters)
  drafts [--json]                 print every draft. --json: {"drafts": {KEY: {"text", "choice",
                                  "intent", "at"}}, "bad_lines": {"count", "lines"}}
  join [--hub DIR] [--name NAME]  add a mindhole to the Desk (NAME: default the hub dir's name;
                                  a-z, 0-9 and -). Again for the same dir: changes its name.
                                  Says if the hub's .claude/settings.json has the desk hooks
  leave [--hub DIR | --name NAME] remove a mindhole from the Desk
  mindholes [--json]              print the mindholes of the Desk
  service [--hub DIR] [--orbit-kb PATH] [--port N] [--write]
                                  print a systemd user unit that runs the Desk page (default:
                                  the hub's .claude/orbit-kb/bin/orbit-kb, port 8737). --write
                                  writes it to the user unit dir and prints the systemctl command
                                  to enable it; it never runs systemctl

Item JSON (the item a letter is about):
  {"type": "ask", "id": "A-0002"}                              any ledger item
  {"type": "question", "slug": S, "kb": "specs/S", "q": "q3"}  a question of a spec KB
  {"type": "kb", "slug": S, "kb": "specs/S", "ref": "vote"}    a KB-level card
  {"type": "fix", "what": W, "ids": [ID, ...]}                 a fix or notice about the hub (kinds
                                                               fix and notice only; ids optional)
  "kb" is a path relative to the hub, or the absolute path of a KB outside the hub; "slug" is the
  KB dir's name. W: a-z and -, up to 40 characters; ids: up to 50, each one line of up to 100.

The recipient: each letter names one session (`to`, a session or alias of the hub, stored as the
session name). Only that session gets it. A letter stored before `to` existed goes to the owners of
its item: for an ask, the item's owner_session (whatever its status); for a question or kb card,
every open or waiting item with a kb ref to the slug. A recipient is live when its session is active.

What a session gets: for each letter, exactly
  Letter from Ty (the Desk), about ABOUT:
  TEXT
with the whole text, never cut, and no other line. Several letters in one notice are joined by one
empty line. A notice holds whole letters up to NOTICE_MAX characters (always at least one); the
rest come at the next stop or prompt. A letter stored before `about` existed uses its item's name.
The wake line is exactly
  Desk: Ty sent a letter about ABOUT. It is stored; read the Desk notice of this prompt.

Receipts in status: state is sent, seen, applied or apply_failed. late_unseen is true when the
letter was sent 24 hours or more before the ledger clock and no session has seen it.

Files in the hub (HUB/flow/desk/, made on demand): letters.jsonl and events.jsonl (append-only, one
JSON object per line, flock + one write + fsync), sessions/NAME.json (replaced atomically), desk.log
(errors of the hook and the wake). flow/flow.db is read only, never written. An old
HUB/flow/desk/drafts.json is not read any more.
Files in the Desk's state dir (DESK_STATE): drafts.json and mindholes.json ({"mindholes": [{"name",
"path", "joined_at"}]}), each replaced atomically under a flock (drafts.lock, mindholes.lock).
The unit file: XDG_CONFIG_HOME/systemd/user/desk.service.

Environment
  HUB_SESSION         the session name (hook)
  TMUX_PANE           the session's tmux pane (hook; set by tmux)
  CLAUDE_PROJECT_DIR  the hook's fallback hub when its cwd is in no hub
  DESK_STATE          the Desk's state dir (default XDG_STATE_HOME/desk)
  XDG_STATE_HOME      default ~/.local/state
  XDG_CONFIG_HOME     default ~/.config (for service --write)
  DESK_TMUX           the tmux program (default tmux)
  DESK_WAKE_COMMANDS  pane commands that count as Claude, comma list (default claude)

The toast: the mod desk-toast (beside this script; Sagittarius install.py links it to
~/.claude/skills/desk-toast, so every session loads it) shows in each session that runs it `📨 <session name> saw:` and the first 60 characters of a letter,
a few seconds after the letter's seen event. "saw" means that the hook gave the letter to the agent.
It does not mean that the agent acted on it: a Ctrl+C, a crash or a compaction right after the hook
still gives the toast. The mod only reads the files above; it writes nothing.

Exit codes: 0 ok, 1 bad input, 2 no hub, an unknown letter or mindhole, or a broken Desk store.
"""
import argparse, datetime, errno, fcntl, json, os, re, secrets, sqlite3, subprocess, sys
from urllib.parse import quote

KINDS = ("answer", "diverge", "requirement", "fix", "notice", "note")
EVENTS_PAGE = ("applied", "apply_failed")
SLUG = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")
ITEM_ID = re.compile(r"^[A-Z]-\d{4,}$")
SESSION_NAME = re.compile(r"^[a-z0-9][a-z0-9-]*$")
FIX_WHAT = re.compile(r"^[a-z][a-z-]*$")
FIX_WHAT_MAX = 40
FIX_IDS_MAX = 50
FIX_ID_LEN = 100
FIX_KINDS = ("fix", "notice")
LETTER_ID = re.compile(r"^L-\d{8}T\d{6}Z-[0-9a-f]{6}$")
TS_FMT = "%Y-%m-%dT%H:%M:%SZ"
NOTICE_MAX = 1500  # a notice holds whole letters up to this size, and at least one
KEY_MAX = 300
ABOUT_MAX = 300
TMUX_TIMEOUT = 5
LATE_SECONDS = 24 * 3600  # a sent letter not seen after this is late (q9)
DEFAULT_PORT = 8737


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


def xdg(var, *default):
    v = os.environ.get(var)
    return v if v and os.path.isabs(v) else os.path.join(os.path.expanduser("~"), *default)


def state_dir():
    """The Desk's own state dir, outside every mindhole: DESK_STATE, else XDG_STATE_HOME/desk."""
    d = os.environ.get("DESK_STATE")
    return os.path.abspath(d) if d else os.path.join(xdg("XDG_STATE_HOME", ".local", "state"), "desk")


def drafts_dir():
    return state_dir()


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


# ---- the ledger (read only) ----

def connect(hub):
    p = os.path.join(hub, "flow", "flow.db")
    c = sqlite3.connect("file:" + quote(p) + "?mode=ro", uri=True, timeout=5)
    c.row_factory = sqlite3.Row
    c.execute("PRAGMA busy_timeout=5000")
    return c


def ref_slug(ref):
    """The spec KB slug of a kb ref: <slug>, a path ending in <slug>, or the old <slug>/kb. A ref to a
    KB outside the hub (/abs/path or ~/path) stays whole."""
    if ref.startswith(("/", "~")):
        return ref
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


def known_session(c, name):
    """The session name of a session or alias of the hub, else None."""
    r = c.execute("SELECT name FROM session WHERE name = ?", (name,)).fetchone()
    if r is None:
        r = c.execute("SELECT name FROM session_alias WHERE alias = ?", (name,)).fetchone()
    return r[0] if r else None


def resolve_name(c, name):
    return known_session(c, name) or name


def letter_to(letter):
    t = letter.get("to")
    return t if isinstance(t, str) and t else None


def recipients(c, letter, kbi=None):
    """The one session named by `to`; for an old letter without `to`, the owners of its item."""
    to = letter_to(letter)
    return [to] if to else owners(c, letter, kbi)


def item_name(letter):
    it = letter.get("item") or {}
    if it.get("type") == "ask":
        return str(it.get("id"))
    if it.get("type") == "fix":
        ids = [str(x) for x in it.get("ids") or []]
        return (f"fix {it.get('what')}" + (" " + ", ".join(ids) if ids else ""))[:200]
    where = it.get("kb") or f"specs/{it.get('slug')}"
    return f"{where} {it.get('q') if it.get('type') == 'question' else it.get('ref')}"


def about_of(letter):
    a = letter.get("about")
    return a if isinstance(a, str) and a else item_name(letter)


def delivered_text(letter):
    """Exactly what the recipient session gets for one letter: one head line and the whole text."""
    return f"Letter from Ty (the Desk), about {about_of(letter)}:\n{letter.get('text') or ''}"


def wake_text(about):
    """Exactly the line that a wake types into the recipient's pane (then Enter)."""
    return f"Desk: Ty sent a letter about {about}. It is stored; read the Desk notice of this prompt."


# ---- validation ----

def check_kb_path(v, what):
    """A KB dir: a path relative to the hub, or an absolute path (a KB outside the hub). No .. parts."""
    if not isinstance(v, str) or not v.strip() or ".." in v.split("/") or "\n" in v:
        raise Bad(f"item {what} must be a path relative to the hub or an absolute path, with no .. part")
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
    shapes = {"ask": ("type", "id"), "question": ("type", "slug", "kb", "q"), "kb": ("type", "slug", "kb", "ref"),
              "fix": ("type", "what", "ids")}
    t = it.get("type")
    if t not in shapes:
        raise Bad("item type must be ask, question, kb or fix")
    if t == "fix":
        if set(it) not in ({"type", "what"}, set(shapes[t])):
            raise Bad("a fix item has the keys type, what and (optional) ids")
        if not isinstance(it["what"], str) or len(it["what"]) > FIX_WHAT_MAX or not FIX_WHAT.match(it["what"]):
            raise Bad(f"item what {it['what']!r} must be a-z and - (starting with a letter), up to {FIX_WHAT_MAX} characters")
        ids = it.get("ids", [])
        if not isinstance(ids, list) or len(ids) > FIX_IDS_MAX:
            raise Bad(f"item ids must be a list of up to {FIX_IDS_MAX} ids")
        for x in ids:
            check_short(x, "ids", FIX_ID_LEN)
        return it
    if set(it) != set(shapes[t]):
        raise Bad(f"a {t} item has exactly the keys {', '.join(shapes[t])}")
    if t == "ask":
        if not isinstance(it["id"], str) or not ITEM_ID.match(it["id"]):
            raise Bad(f"item id {it['id']!r} is not a ledger id such as A-0002")
    else:
        if not isinstance(it["slug"], str) or not SLUG.match(it["slug"]):
            raise Bad(f"item slug {it['slug']!r} is not a slug")
        check_kb_path(it["kb"], "kb")
        check_short(it["q"] if t == "question" else it["ref"], "q" if t == "question" else "ref")
    return it


def check_about(v):
    if not isinstance(v, str) or not v.strip() or len(v) > ABOUT_MAX or any(ord(ch) < 32 or ord(ch) == 127 for ch in v):
        raise Bad(f"--about must be one line of 1 to {ABOUT_MAX} characters")
    return v


def check_to(c, name):
    s = known_session(c, name or "")
    if s is None:
        raise Bad(f"--to {name!r} is not a session or alias of this hub")
    return s


def check_text(text):
    if not text.strip():
        raise Bad("the text is empty: the session gets only the text, so write the answer (and any choice) in it")
    return text


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
    if it["type"] == "fix" and a.kind not in FIX_KINDS:
        raise Bad(f"a fix item goes only with --kind {' or '.join(FIX_KINDS)}")
    # The Desk (serve desk) always gives --to and --about. Without them (serve questions --hub, the page
    # of round 1) the letter has neither, and the hook gives it to the item's owners (the old rule).
    about = check_about(a.about) if a.about is not None else None
    text = check_text(read_text(a.text_file))
    c = connect(hub)
    try:
        to = check_to(c, a.to) if a.to is not None else None
    finally:
        c.close()
    choice = a.choice if a.choice else None
    t = datetime.datetime.now(datetime.timezone.utc)
    lid = f"L-{t.strftime('%Y%m%dT%H%M%SZ')}-{secrets.token_hex(3)}"
    letter = {"id": lid, "at": t.strftime(TS_FMT), "kind": a.kind, "item": it, "text": text,
              "choice": choice, "by": "human", **({"to": to} if to else {}), **({"about": about} if about else {})}
    append_line(os.path.join(desk_dir(hub), "letters.jsonl"), letter)  # stored before we return (c8)
    print(json.dumps({"id": lid}))
    sys.stdout.flush()
    try:
        wake(hub, letter)
    except Exception as e:  # best effort: the letter is stored
        print(f"desk: wake {lid} failed: {e}", file=sys.stderr)
        log(hub, f"wake {lid} failed: {e!r}")


def cmd_render(hub, a):
    about = check_about(a.about)
    text = check_text(read_text(a.text_file))
    c = connect(hub)
    try:
        to = check_to(c, a.to)
    finally:
        c.close()
    out = delivered_text({"about": about, "text": text})
    if a.json:
        print(json.dumps({"to": to, "about": about, "delivered": out, "wake": wake_text(about)}, ensure_ascii=False))
    else:
        sys.stdout.write(out)


def cmd_wake_text(hub, a):
    sys.stdout.write(wake_text(check_about(a.about)))


def cmd_event(hub, a):
    store = Store(hub)
    find_letter(store, a.lid)
    store.add_event(a.lid, a.event, None, a.detail)
    print(json.dumps({"letter": a.lid, "event": a.event}))


def ts_secs(ts):
    try:
        return datetime.datetime.strptime(ts, TS_FMT).replace(tzinfo=datetime.timezone.utc).timestamp()
    except (TypeError, ValueError):
        return None


def letter_views(c, store, letters, events, now):
    kbi = kb_items(c)
    live = active_sessions(c)
    now_s = ts_secs(now)
    by = {}
    for i, e in enumerate(events):
        by.setdefault(e["letter"], []).append((i, e))
    out = []
    for x in reversed(letters):
        ev = by.get(x["id"], [])
        own = recipients(c, x, kbi)
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
        at_s = ts_secs(x.get("at"))
        late = bool(not seen and at_s is not None and now_s is not None and now_s - at_s >= LATE_SECONDS)
        out.append(dict({"to": None, "about": None}, **x, owners=own, live_owners=lv, no_live_owner=not lv,
                        late_unseen=late, seen=seen, woken=woken,
                        applied={"at": last_ok[1].get("at"), "detail": last_ok[1].get("detail")} if last_ok else None,
                        apply_failed={"at": last_bad[1].get("at"), "detail": last_bad[1].get("detail")} if last_bad else None,
                        item_closed=closed, state=state))
    return out


def rows(c, sql, params=()):
    return [dict(r) for r in c.execute(sql, params)]


def status_obj(hub):
    store = Store(hub)
    letters, events = store.letters(), store.events()
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
                # c32: what a Ledger card shows: who handed it over, its KB refs, its newest note, when it opened
                h = c.execute("SELECT from_session FROM handoff WHERE item_id = ?", (r["id"],)).fetchone()
                r["from"] = h[0] if h else None
                r["kbs"] = [x[0] for x in c.execute("SELECT ref FROM item_ref WHERE item_id = ? AND kind = 'kb' ORDER BY ref", (r["id"],))]
                n = c.execute("SELECT note FROM event WHERE item_id = ? AND note IS NOT NULL AND note != '' ORDER BY seq DESC LIMIT 1",
                              (r["id"],)).fetchone()
                r["note"] = n[0] if n else None
                o = c.execute("SELECT opened_at, parked_until FROM item WHERE id = ?", (r["id"],)).fetchone()
                r["opened_at"] = o[0] if o else None
                # c36, c37: parked until the park ends (hubflow: a date D through that day; a time is its own end)
                pu = o[1] if o else None
                r["parked_until"] = pu
                r["parked"] = bool(pu) and (pu + "T24:00:00Z" if len(pu) == 10 else pu) > now
            sessions.append(dict(s, state=st.get("state"), state_at=st.get("at"), tmux_pane=st.get("tmux_pane"),
                                 session_id=st.get("session_id"), inbox=inbox))
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
        kb_handoffs = {}
        for r in rows(c, "SELECT r.ref, i.id, h.from_session AS \"from\", h.to_session AS \"to\", h.accepted_at,"
                         " i.opened_at FROM item i JOIN handoff h ON h.item_id = i.id"
                         " JOIN item_ref r ON r.item_id = i.id AND r.kind = 'kb'"
                         " WHERE i.status IN ('open','waiting') ORDER BY r.ref, i.id"):
            kb_handoffs.setdefault(r.pop("ref"), []).append(r)
        for lst in kb_handoffs.values():  # accepted first, oldest first; unaccepted last
            lst.sort(key=lambda r: (r["accepted_at"] is None, r["accepted_at"] or "", r["opened_at"] or "", r["id"]))
        closed = rows(c, """SELECT i.id, i.title, i.status, i.close_reason, i.closed_at, i.owner_session,
  e.by, e.by_session, e.note FROM item i, clock
  LEFT JOIN event e ON e.seq = (SELECT MAX(seq) FROM event x WHERE x.item_id = i.id AND x.verb = 'closed')
  WHERE i.kind = 'ask' AND i.closed_at IS NOT NULL
    AND i.closed_at >= strftime('%Y-%m-%dT%H:%M:%SZ', clock.now, '-7 days')
  ORDER BY i.closed_at DESC, i.id""")
        lv = letter_views(c, store, letters, events, now)
    finally:
        c.close()
    return {"now": now, "sessions": sessions, "orphans": {"unowned": unowned, "unaccepted": unaccepted},
            "kb_refs": kb_refs, "kb_handoffs": kb_handoffs, "closed_recent": closed, "letters": lv,
            "bad_lines": {"count": len(store.bad), "lines": store.bad},
            # c24: no letter reaches a session of this hub while an event has no desk hook
            "hooks_missing": (lambda m: list(HOOK_EVENTS) if m is None else m)(hooks_missing(hub, settings_files(hub)))}


def cmd_status(hub, a):
    s = status_obj(hub)
    if a.json:
        print(json.dumps(s, ensure_ascii=False, indent=1))
        return
    for x in s["sessions"]:
        print(f"session {x['name']} ({x['status']}): {x['state'] or 'no state'}, inbox {len(x['inbox'])}")
    for x in s["letters"]:
        loud = (" NO LIVE OWNER" if x["no_live_owner"] else "") + (" NOT SEEN AFTER A DAY" if x["late_unseen"] else "")
        to = f" to {x['to']}" if x.get("to") else ""
        print(f"{x['id']} {item_name(x)} {x['kind']}{to}: {x['state']}{loud}")
    if s["bad_lines"]["count"]:
        print(f"bad lines: {s['bad_lines']['count']}")


def cmd_draft(hub, a):
    if not a.key or len(a.key) > KEY_MAX or "\n" in a.key:
        raise Bad(f"a draft key is one line of 1 to {KEY_MAX} characters")
    d = drafts_dir()
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


def cmd_drafts(hub, a):
    bad = []
    drafts = read_json(os.path.join(drafts_dir(), "drafts.json"), bad, {})
    if a.json:
        print(json.dumps({"drafts": drafts, "bad_lines": {"count": len(bad), "lines": bad}}, ensure_ascii=False, indent=1))
        return
    for k in sorted(drafts):
        v = drafts[k] if isinstance(drafts[k], dict) else {}
        first = (v.get("text") or "").strip().split("\n")[0]
        print(f"{k} {v.get('at')}: {first[:100]}")
    for b in bad:
        print(f"bad {b['file']}: {b['text']}")


def cmd_letters(hub, a):
    store = Store(hub)
    if a.id:
        x = find_letter(store, a.id)
        if a.json:
            print(json.dumps(x, ensure_ascii=False, indent=1))
        else:
            print(f"{x['id']} {x.get('at')} {x.get('kind')} {item_name(x)}"
                  + (f" to {x['to']}" if x.get("to") else "") + (f" choice: {x['choice']}" if x.get("choice") else ""))
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

def notice(letters):
    """The notice text and the letters it holds: whole letters joined by one empty line, up to
    NOTICE_MAX characters, and at least one. The rest wait for the next stop or prompt."""
    parts, held, size = [], [], 0
    for x in letters:
        t = delivered_text(x)
        add = len(t) + (2 if parts else 0)
        if held and size + add > NOTICE_MAX:
            break
        parts.append(t)
        held.append(x)
        size += add
    return "\n\n".join(parts), held


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
            todo = [x for x in store.letters() if x["id"] not in seen and name in recipients(c, x, kbi)]
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
    """Type the wake line into each live recipient's pane when it is idle, blocked on the answer, runs
    Claude, has not seen the letter and was not woken for it. Returns the sessions woken."""
    store = Store(hub)
    lid = letter["id"]
    events = store.events()
    done = {(e["event"], e.get("session")) for e in events if e["letter"] == lid}
    cmds = {x.strip() for x in (os.environ.get("DESK_WAKE_COMMANDS") or "claude").split(",") if x.strip()}
    c = connect(hub)
    try:
        kbi = kb_items(c)
        own = recipients(c, letter, kbi)
        live = active_sessions(c)
        blocked = {s: blocked_on(c, letter, s, kbi) for s in own}
    finally:
        c.close()
    woken = []
    if not own:
        print(f"desk: wake {lid}: no recipient", file=sys.stderr)
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
                line = wake_text(about_of(letter))
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


# ---- the mindholes of the Desk ----

HOOK_EVENTS = ("SessionStart", "UserPromptSubmit", "Stop")
DESK_HOOK = re.compile(r"desk\.py\b.*\bhook\b")


def settings_files(hub):
    """The Claude Code settings that a session in the hub reads: the hub's settings.json and
    settings.local.json, and the user's ~/.claude/settings.json. Read only: never written here."""
    home = os.environ.get("HOME") or os.path.expanduser("~")
    return [os.path.join(hub, ".claude", "settings.json"), os.path.join(hub, ".claude", "settings.local.json"),
            os.path.join(home, ".claude", "settings.json")]


def hooks_missing(hub, files=None):
    """The hook events that no readable settings file gives to desk.py hook, or None when no file can
    be read. files: the files to read (default: the hub's settings.json only, as join reports it)."""
    files = [os.path.join(hub, ".claude", "settings.json")] if files is None else files
    found, readable = set(), False
    for fn in files:
        try:
            with open(fn, encoding="utf-8") as f:
                st = json.load(f)
        except (OSError, ValueError):
            continue
        readable = True
        hooks = st.get("hooks") if isinstance(st, dict) else None
        hooks = hooks if isinstance(hooks, dict) else {}
        for ev in HOOK_EVENTS:
            cmds = [h.get("command") for g in (hooks.get(ev) or []) if isinstance(g, dict)
                    for h in (g.get("hooks") or []) if isinstance(h, dict)]
            if any(isinstance(x, str) and DESK_HOOK.search(x) for x in cmds):
                found.add(ev)
    if not readable:
        return None
    return [ev for ev in HOOK_EVENTS if ev not in found]


def hooks_line(hub):
    m = hooks_missing(hub)
    if m is None:
        return "hooks: the hub has no readable .claude/settings.json; print the block with `desk.py hooks`, a human adds it"
    if not m:
        return "hooks: .claude/settings.json has the desk hooks (" + ", ".join(HOOK_EVENTS) + ")"
    return ("hooks: .claude/settings.json has no desk hook for " + ", ".join(m)
            + "; print the block with `desk.py hooks`, a human adds it")


def read_mindholes(path):
    bad = []
    obj = read_json(path, bad, {"mindholes": []})
    lst = obj.get("mindholes")
    if bad or not isinstance(lst, list) or not all(
            isinstance(x, dict) and isinstance(x.get("name"), str) and isinstance(x.get("path"), str) for x in lst):
        raise NoHub(f"{path} is broken; fix it or remove it ({bad[0]['text'] if bad else 'bad shape'})")
    return lst


def with_mindholes(change):
    """Run change(list) under the lock of mindholes.json and write the list back if it returns True."""
    d = state_dir()
    ensure_dir(d)
    path = os.path.join(d, "mindholes.json")
    fd = os.open(os.path.join(d, "mindholes.lock"), os.O_WRONLY | os.O_CREAT, 0o644)
    try:
        fcntl.flock(fd, fcntl.LOCK_EX)
        lst = read_mindholes(path)
        if change(lst):
            write_atomic(path, {"mindholes": lst})
    finally:
        os.close(fd)


def sub_hub(a):
    return getattr(a, "sub_hub", None) or a.hub


def cmd_join(hub, a):
    hub = hub_of(sub_hub(a))
    name = a.name if a.name is not None else os.path.basename(hub)
    if not SESSION_NAME.match(name) or len(name) > 64:
        raise Bad(f"mindhole name {name!r} must be 1 to 64 of a-z, 0-9 and -, starting with a letter or digit;"
                  " pass --name NAME")
    said = []

    def change(lst):
        clash = [x for x in lst if x["name"] == name and x["path"] != hub]
        if clash:
            raise Bad(f"the name {name} is taken by {clash[0]['path']}; pass another --name")
        mine = [x for x in lst if x["path"] == hub]
        if not mine:
            lst.append({"name": name, "path": hub, "joined_at": now_ts()})
            said.append(f"joined: mindhole {name} at {hub}")
            return True
        if mine[0]["name"] == name:
            said.append(f"already joined: mindhole {name} at {hub}")
            return False
        said.append(f"renamed: mindhole {mine[0]['name']} is now {name} at {hub}")
        mine[0]["name"] = name
        return True

    with_mindholes(change)
    print(said[0])
    print(hooks_line(hub))


def cmd_leave(hub, a):
    if a.name and sub_hub(a):
        raise Bad("pass --hub DIR or --name NAME, not both")
    if a.name:
        match = lambda x: x["name"] == a.name
        what = f"name {a.name}"
    else:
        path = os.path.abspath(sub_hub(a)) if sub_hub(a) else hub_of(None)
        match = lambda x: x["path"] == path
        what = f"path {path}"
    gone = []

    def change(lst):
        gone.extend(x for x in lst if match(x))
        lst[:] = [x for x in lst if not match(x)]
        return bool(gone)

    with_mindholes(change)
    if not gone:
        raise NoHub(f"no mindhole with the {what} has joined the Desk")
    print(f"left: mindhole {gone[0]['name']} at {gone[0]['path']}")


def cmd_mindholes(hub, a):
    lst = read_mindholes(os.path.join(state_dir(), "mindholes.json"))
    out = [dict(x, present=os.path.isfile(os.path.join(x["path"], "flow", "flow.db")),
                hooks=hooks_missing(x["path"]) == []) for x in sorted(lst, key=lambda x: x["name"])]
    if a.json:
        print(json.dumps({"mindholes": out}, ensure_ascii=False, indent=1))
        return
    for x in out:
        notes = ("" if x["present"] else " (no hub there)") + ("" if x["hooks"] else " (no desk hooks)")
        print(f"{x['name']} {x['path']}{notes}")


def unit_value(v):
    """One systemd unit value: % and $ escaped, quoted when it has a space or a quote."""
    v = v.replace("%", "%%").replace("$", "$$")
    if re.search(r"[\s\"'\\]", v):
        v = '"' + v.replace("\\", "\\\\").replace('"', '\\"') + '"'
    return v


def unit_text(exe, port, state):
    lines = ["[Unit]", "Description=The Desk: one page for every mindhole on this machine", "",
             "[Service]", f"ExecStart={unit_value(exe)} serve desk --port {port}"]
    if state:
        lines.append("Environment=" + unit_value("DESK_STATE=" + state))
    lines += ["Restart=on-failure", "", "[Install]", "WantedBy=default.target"]
    return "\n".join(lines) + "\n"


def cmd_service(hub, a):
    if not 1 <= a.port <= 65535:
        raise Bad("--port must be 1 to 65535")
    exe = os.path.abspath(os.path.expanduser(a.orbit_kb)) if a.orbit_kb else \
        os.path.join(hub_of(sub_hub(a)), ".claude", "orbit-kb", "bin", "orbit-kb")
    if not os.access(exe, os.X_OK):
        print(f"desk: warning: {exe} is not an executable file", file=sys.stderr)
    state = os.path.abspath(os.environ["DESK_STATE"]) if os.environ.get("DESK_STATE") else None
    text = unit_text(exe, a.port, state)
    if not a.write:
        sys.stdout.write(text)
        return
    path = os.path.join(xdg("XDG_CONFIG_HOME", ".config"), "systemd", "user", "desk.service")
    ensure_dir(os.path.dirname(path))
    tmp = f"{path}.tmp.{os.getpid()}"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(text)
        f.flush()
        os.fsync(f.fileno())
    os.replace(tmp, path)
    fsync_dir(os.path.dirname(path))
    print(f"wrote {path}")
    print("enable it (a human runs this): systemctl --user daemon-reload && systemctl --user enable --now desk.service")


# ---- main ----

def parser():
    p = argparse.ArgumentParser(prog="desk.py", description="The Desk: Ty's responses to hub items.")
    p.add_argument("--hub")
    sub = p.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("send")
    s.add_argument("--kind", required=True)
    s.add_argument("--item-json", required=True)
    s.add_argument("--to")
    s.add_argument("--about")
    s.add_argument("--text-file", required=True)
    s.add_argument("--choice")
    s = sub.add_parser("render")
    s.add_argument("--to", required=True)
    s.add_argument("--about", required=True)
    s.add_argument("--text-file", required=True)
    s.add_argument("--json", action="store_true")
    s = sub.add_parser("wake-text")
    s.add_argument("--about", required=True)
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
    s = sub.add_parser("drafts")
    s.add_argument("--json", action="store_true")
    s = sub.add_parser("letters")
    s.add_argument("--id")
    s.add_argument("--json", action="store_true")
    sub.add_parser("hook")
    s = sub.add_parser("wake")
    s.add_argument("lid")
    sub.add_parser("hooks")
    s = sub.add_parser("join")
    s.add_argument("--hub", dest="sub_hub")
    s.add_argument("--name")
    s = sub.add_parser("leave")
    s.add_argument("--hub", dest="sub_hub")
    s.add_argument("--name")
    s = sub.add_parser("mindholes")
    s.add_argument("--json", action="store_true")
    s = sub.add_parser("service")
    s.add_argument("--hub", dest="sub_hub")
    s.add_argument("--orbit-kb")
    s.add_argument("--port", type=int, default=DEFAULT_PORT)
    s.add_argument("--write", action="store_true")
    return p


COMMANDS = {"send": cmd_send, "render": cmd_render, "wake-text": cmd_wake_text, "event": cmd_event,
            "status": cmd_status, "draft": cmd_draft, "drafts": cmd_drafts, "letters": cmd_letters,
            "wake": cmd_wake, "hooks": cmd_hooks, "join": cmd_join, "leave": cmd_leave,
            "mindholes": cmd_mindholes, "service": cmd_service}
NO_HUB = ("hooks", "wake-text", "draft", "drafts", "join", "leave", "mindholes", "service")  # find it themselves


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
        hub = None if a.cmd in NO_HUB else hub_of(a.hub)
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
    except OSError as e:
        print(f"desk: {e}", file=sys.stderr)
        sys.exit(2)


if __name__ == "__main__":
    main()
