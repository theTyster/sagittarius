#!/usr/bin/env python3
"""desk.py -- the Desk: Ty's responses ("letters") to hub items, their receipts, drafts, and their
delivery into the Claude Code sessions that own the items.

One Desk page (`orbit-kb serve desk`) serves every mindhole on this machine (c16). A mindhole joins
it with `join`; the Desk keeps the list in its own state dir. The page calls this script. It stores
each letter the moment Ty sends it (c8), shows where each letter is (c7), and the hook below gives
each letter to its one recipient session at its next prompt or stop, never to another session and
never inside a turn (c6). A Stop gives every letter that waits, one notice after the other, also
when the turn already continues from a stop hook (desk-delivery c2). For a letter to an idle session
the Desk asks Ty whether to wake it; only his yes (`wake`) types one line into its tmux pane
(desk-delivery c5). Each notice asks the agent to confirm each letter by its id (`ack`). Each hook
settles the letters of the turn before it: acted on only when confirmed in that turn; else, at a
Stop too, given, not acted on, shown on the Desk and not given again (desk-delivery c7). Drafts stay
in the Desk's own state dir, outside every mindhole: no agent reads them, and a letter enters the
receiving mindhole only when Ty sends it (q10).

usage: desk.py [--hub DIR] COMMAND [ARGS]
  send --kind KIND --item-json JSON --to SESSION --about TEXT --text-file F [--choice C]
                                  store a letter for one session; prints {"id": LID}. It types
                                  nothing into any pane (only Ty's yes wakes, see wake). KIND: answer, diverge, requirement, note (a note on a ledger item, c32), fix
                                  (a fix of an orphan or a gap), notice (a short notice)
  render --to SESSION --about TEXT --text-file F [--id LID] [--json]
                                  print the exact notice the session gets for such a letter alone
                                  (the page shows it in the review): the lead line, the letter, its
                                  confirm line. Without --id the confirm line holds L-<the letter id>.
                                  --json: {"to", "about", "delivered", "wake"}. Printed exactly, with
                                  no newline added
  ack LID                         run by the agent that got the letter (HUB_SESSION), in the turn
                                  that got it: record an acked event. Only an acked letter is settled
                                  as acted on (exit 1: not given to this session in this turn)
  wake-text --about TEXT          print the exact line that a wake types (no newline added)
  event LID applied|apply_failed|dismissed [--detail TEXT]
                                  record a receipt from the page server (exit 2: unknown LID).
                                  dismissed: Ty acted on a letter that is given, not acted on
                                  (exit 1 for any other letter)
  status [--json]                 sessions, orphans, kb refs and handoffs, recent closed asks,
                                  letters with their state, and bad lines (JSON for the page)
  letters [--id LID] [--json]     print the letters, or one letter in full
  hook                            the Claude Code hook (SessionStart, UserPromptSubmit, Stop):
                                  reads the hook JSON on stdin; never fails a session
  wake LID                        Ty's yes on the Desk: type the wake line into the recipient's
                                  tmux pane, only when the recipient is live and idle, has not been
                                  given the letter, and its pane runs Claude. Prints {"woken":
                                  [SESSION...], "not": {SESSION: why}}; exit 0 either way
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

What a session gets: one lead line (Ty sent you a letter on the Desk ...), an empty line, then for
each letter exactly
  Letter from Ty (the Desk), about ABOUT:
  TEXT

  When you have done what this letter asks, confirm it to Ty with: python3 HUB/.claude/scripts/desk.py ack LID
with the whole text, never cut (one newline only before the confirm line when TEXT ends with one).
Several letters in one notice are joined by one empty line. A notice holds whole letters up to NOTICE_MAX characters (always at least one); the
rest come at the next stop or prompt. A letter stored before `about` existed uses its item's name.
The wake line is exactly
  Desk: Ty sent a letter about ABOUT. It is stored; read the Desk notice of this prompt.

Receipts in status: state is sent, seen, applied or apply_failed. late_unseen is true when the
letter was sent 24 hours or more before the ledger clock and no session has seen it. delivery is
sent (no session was given it), given (given; its turn has not ended yet), acted (the agent
confirmed it in the turn that got it), not_acted (that turn ended, by a Stop, Ctrl+C, a crash or a
compaction, with no confirmation), dismissed (not_acted, and Ty acted on it) or given_before (seen before the Desk kept track of turns). wake_ask lists each recipient that is live,
idle and not given the letter: {"session", "pane"} (pane: the Desk knows its tmux pane, so a yes can
wake it). Events: seen, woken, acted, not_acted (by the hook or wake), acked (by ack), applied,
apply_failed, dismissed (by the page).

Files in the hub (HUB/flow/desk/, made on demand): letters.jsonl and events.jsonl (append-only, one
JSON object per line, flock + one write + fsync), sessions/NAME.json (replaced atomically; "given":
the letters given in the current turn, not yet settled by a hook), desk.log
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
import argparse, datetime, errno, fcntl, json, os, re, secrets, shlex, sqlite3, subprocess, sys
from urllib.parse import quote

KINDS = ("answer", "diverge", "requirement", "fix", "notice", "note")
EVENTS_PAGE = ("applied", "apply_failed", "dismissed")
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
    """The one session named by `to`; for an old letter without `to`, the owners of its item. A letter that a
    desk agent takes (desk-agents c11, c14) goes to no session."""
    if letter.get("agent") or (letter.get("item") or {}).get("type") == "agent":
        return []
    to = letter_to(letter)
    return [to] if to else owners(c, letter, kbi)


def item_name(letter):
    it = letter.get("item") or {}
    if it.get("type") == "ask":
        return str(it.get("id"))
    if it.get("type") == "agent":
        return f"the desk agent {it.get('agent')}"
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


ID_PLACEHOLDER = "L-<the letter id>"  # render without --id: the id is made when Ty sends


def ack_command(hub, lid):
    """desk-delivery c7: the exact command that confirms one letter (run by the agent that got it)."""
    return "python3 " + shlex.quote(os.path.join(hub, ".claude", "scripts", "desk.py")) + " ack " + lid


def ack_line(hub, lid):
    return f"When you have done what this letter asks, confirm it to Ty with: {ack_command(hub, lid)}"


def letter_block(hub, letter, lid=None):
    """One letter as the session gets it: the letter (head and whole text), then its confirm line."""
    t = delivered_text(letter)
    return t + ("\n" if t.endswith("\n") else "\n\n") + ack_line(hub, lid or letter.get("id") or ID_PLACEHOLDER)


def lead_line(n):
    """desk-delivery c7: the first line of every notice. It says what the text is (letters from Ty,
    given between turns so that they do not interrupt) and that each wants a confirmation."""
    what = "a letter" if n == 1 else f"{n} letters"
    return (f"Ty sent you {what} on the Desk. The Desk gives letters between turns, so that they do not "
            "interrupt your work. Read each one, do what it asks now, and confirm each with the command under it.")


def notice_text(hub, blocks):
    return lead_line(len(blocks)) + "\n\n" + "\n\n".join(blocks)


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
              "fix": ("type", "what", "ids"), "agent": ("type", "agent")}
    t = it.get("type")
    if t not in shapes:
        raise Bad("item type must be ask, question, kb, fix or agent")
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
    if t == "agent":  # Ty's words to a desk agent (desk-agents c14)
        if not isinstance(it["agent"], str) or not AGENT_NAME.match(it["agent"]):
            raise Bad(f"item agent {it['agent']!r} is not the name of a desk agent")
        return it
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



# ---- headless desk agents (desk-agents c11 to c19, Ty r3 to r8, hy8) ----
# A letter about a spec KB that nobody holds (no live writer lock, no accepted handoff on it) starts a
# desk agent: `claude -p` with --output-format stream-json, run by a detached runner (desk.py agent-run),
# never in tmux. The runner holds the writer lock of the KB while claude runs, keeps each event of the run
# in flow/desk/agents/NAME.jsonl (the Desk shows them), and releases the lock when the run ends. One
# process per session (probe f13: claude does not refuse a second one): a letter for a running agent waits
# in its queue and the runner starts the next run (--resume) when the current one ends; a letter for a
# stopped or ended agent starts a new run at once. desk.py agent-stop ends the run (SIGTERM); agent-resume
# starts a new headless run of the same session. Desk agents are OFF until Ty turns them on: `desk.py agents on`
# (a flag in the Desk's state dir) or DESK_AGENTS=on; DESK_AGENTS=off wins. Off by default because a letter of any
# scratch hub (a test, a copy) would otherwise start a real, paid claude.

AGENT_LEASE = 30 * 60          # a writer lock older than this is lapsed (orbit-kb's lease)
AGENT_EVENTS_SHOWN = 40        # events of one agent in desk.py status
AGENT_TEXT_MAX = 600           # one event as the Desk shows it
AGENT_NAME = re.compile(r"^[a-z0-9][a-z0-9-]*-agent_\d{3,}$")
AGENT_CTRL = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]")   # a control byte (not tab, not newline)
AGENT_LIVE = ("starting", "running", "stopping")
RESUME_PROMPT = "Ty resumed you from the Desk. Go on with the work of your last letter, then end your turn."


def short_name(mindhole):
    """The name of the agents of a mindhole: sidequest-mindhole gives sidequest."""
    return mindhole[:-len("-mindhole")] if mindhole.endswith("-mindhole") and len(mindhole) > len("-mindhole") else mindhole


def agents_on_flag():
    return os.path.join(state_dir(), "agents-on")


def agents_on():
    e = os.environ.get("DESK_AGENTS")
    return e != "off" and (e == "on" or os.path.exists(agents_on_flag()))


def mindhole_of(hub):
    name = os.path.basename(hub)
    try:
        for x in read_mindholes(os.path.join(state_dir(), "mindholes.json")):
            if os.path.abspath(x["path"]) == os.path.abspath(hub):
                name = x["name"]
    except (NoHub, OSError):
        pass
    return short_name(name)


def agents_path(hub):
    return os.path.join(desk_dir(hub), "agents.json")


def agent_events_path(hub, name):
    return os.path.join(desk_dir(hub), "agents", name + ".jsonl")


def with_agents(hub, change):
    """Run change(obj) under the flock of agents.json; write obj back when change returns True (or (True, x)).
    Returns what change returned (x for a tuple)."""
    ensure_dir(desk_dir(hub))
    fd = os.open(os.path.join(desk_dir(hub), "agents.lock"), os.O_WRONLY | os.O_CREAT, 0o644)
    try:
        fcntl.flock(fd, fcntl.LOCK_EX)
        obj = read_json(agents_path(hub), [], {"next": 1, "agents": {}})
        if not isinstance(obj, dict) or not isinstance(obj.get("agents"), dict):
            obj = {"next": 1, "agents": {}}
        r = change(obj)
        if r is True or (isinstance(r, tuple) and r and r[0] is True):
            write_atomic(agents_path(hub), obj)
        return r[1] if isinstance(r, tuple) else r
    finally:
        os.close(fd)


def pid_alive(pid):
    if not isinstance(pid, int) or pid <= 0:
        return False
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    try:  # a zombie child of this process is not alive
        with open(f"/proc/{pid}/stat", encoding="utf-8") as f:
            return f.read().split(")")[-1].split()[0] != "Z"
    except OSError:
        return True


def letter_slug(letter):
    it = letter.get("item") or {}
    return it.get("slug") if it.get("type") in ("question", "kb") else None


def letter_kbdir(hub, letter):
    it = letter.get("item") or {}
    kb = it.get("kb") or f"specs/{it.get('slug')}"
    return kb if os.path.isabs(kb) else os.path.join(hub, kb)


def lock_of(kbdir):
    """(writer, seconds since its time) of the writer lock of a KB, or None."""
    try:
        with open(os.path.join(kbdir, "writer.lock"), encoding="utf-8") as f:
            parts = f.readline().split()
    except OSError:
        return None
    if len(parts) < 2:
        return None
    ts = ts_secs(parts[1])
    return parts[0], (None if ts is None else max(0.0, datetime.datetime.now(datetime.timezone.utc).timestamp() - ts))


def live_lock(kbdir):
    lk = lock_of(kbdir)
    return lk if lk and (lk[1] is None or lk[1] < AGENT_LEASE) else None


def take_lock(kbdir, sid):
    """Take the writer lock of the KB for the session sid when it is free, lapsed or already its own."""
    lk = live_lock(kbdir)
    if lk and lk[0] != sid:
        return False
    write_atomic_text(os.path.join(kbdir, "writer.lock"), f"{sid} {now_ts()}\n")
    return True


def release_lock(kbdir, sid):
    lk = lock_of(kbdir)
    if lk and lk[0] == sid:
        try:
            os.remove(os.path.join(kbdir, "writer.lock"))
        except OSError:
            pass


def write_atomic_text(path, text):
    tmp = f"{path}.{os.getpid()}.tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(text)
        f.flush()
        os.fsync(f.fileno())
    os.replace(tmp, path)


def kb_held(hub, slug, kbdir):
    """Who holds the KB: the writer of a live lock, else the receiver of an accepted handoff on it (the
    Desk's desk_holder), else None."""
    lk = live_lock(kbdir)
    if lk:
        return lk[0]
    try:
        c = connect(hub)
        try:
            for r in c.execute("SELECT r.ref, h.to_session FROM item i JOIN handoff h ON h.item_id = i.id"
                               " JOIN item_ref r ON r.item_id = i.id AND r.kind = 'kb'"
                               " WHERE i.status IN ('open','waiting') AND h.accepted_at IS NOT NULL"):
                if ref_slug(r[0]) == slug and r[1]:
                    return r[1]
        finally:
            c.close()
    except sqlite3.Error:
        pass
    return None


def kb_role(hub, slug):
    roles = []
    try:
        c = connect(hub)
        try:
            roles = [r["owner_session"] for s, r in kb_items(c) if s == slug and r["owner_session"] in ("review", "discovery", "build")]
        finally:
            c.close()
    except sqlite3.Error:
        pass
    return roles[-1] if roles else "discovery"


def recorded_session(kbdir):
    try:
        with open(os.path.join(kbdir, "kb.pl"), encoding="utf-8") as f:
            ids = re.findall(r"desk agent session ([0-9a-f-]{8,})", f.read())
    except OSError:
        return None
    return ids[-1] if ids else None


def transcript_exists(sid):
    import glob
    home = os.environ.get("HOME") or os.path.expanduser("~")
    return bool(glob.glob(os.path.join(home, ".claude", "projects", "*", sid + ".jsonl")))


def clean_text(text):
    return AGENT_CTRL.sub(" ", text or "")


def agent_prompt_of(letter):
    return f"Desk letter {letter['id']} from Ty, about {about_of(letter)}:\n{clean_text(letter.get('text'))}"


def role_prompt(role):
    home = os.environ.get("HOME") or os.path.expanduser("~")
    try:
        with open(os.path.join(home, ".claude", "sagittarius", "panes", role + ".md"), encoding="utf-8") as f:
            return f.read()
    except OSError:
        return f"Your role is the {role} pane of Sagittarius (PANES.md)."


def system_prompt(hub, name, role, slug):
    return (role_prompt(role) + "\n\n"
            + f"You are {name}, a desk agent of the mindhole at {hub}. You work on the spec KB specs/{slug} and on "
              "nothing else. You hold its writer lock while you run; write to it with orbit-kb as yourself. "
              "Each prompt is a letter from Ty (the Desk) or his words to you. Do what it asks, then end your turn: "
              "the Desk shows Ty what you do, and he may write to you, stop you or resume you there.")


def claude_prog():
    return os.environ.get("DESK_CLAUDE") or "claude"


def claude_found():
    import shutil
    return shutil.which(claude_prog()) is not None


def kb_note(hub, kbdir, sid, fact):
    """Write one fact to the KB as the agent (orbit-kb takes the writer lock for sid)."""
    k = os.path.join(hub, ".claude", "orbit-kb", "bin", "orbit-kb")
    env = dict(os.environ, ORBIT_KB_WRITER=sid)
    env.pop("HUB_SESSION", None)
    try:
        r = subprocess.run([k, "--dir", kbdir, "add", fact], capture_output=True, text=True, env=env, timeout=60)
    except (OSError, subprocess.SubprocessError) as e:
        return f"orbit-kb could not run: {e}"
    return None if r.returncode == 0 else (r.stderr.strip().splitlines() or ["orbit-kb add failed"])[0][:200]


def q_atom(s):
    return "'" + s.replace("\\", "\\\\").replace("'", "\\'") + "'"


def settle_dead(hub, o):
    """A run whose runner is gone (killed, crashed, a restart) is interrupted: the agent is stopped and its
    lock is released. Returns True when o changed."""
    changed = False
    for nm, a in o["agents"].items():
        if a.get("state") in AGENT_LIVE and not pid_alive(a.get("runner")) and \
                (ts_secs(now_ts()) or 0) - (ts_secs(a.get("since")) or 0) > 5:
            release_lock(a.get("kbdir") or "", a.get("session_id") or "")
            a.update(state="stopped", since=now_ts(), why="interrupted (its runner is gone)", claude=None, runner=None)
            changed = True
    return changed


def agent_plan(hub, letter):
    """None (the letter goes to its receiver, as before), or {"name", "act": new|queue|run} after the agent
    took what it needs (a name, the lock of its KB). Raises Bad for a letter to an unknown agent."""
    it = letter.get("item") or {}
    if it.get("type") == "agent":
        name = it.get("agent")
        out = {}

        def f(o):
            ch = settle_dead(hub, o)
            a = o["agents"].get(name)
            if not a:
                out["err"] = f"there is no desk agent {name}"
                return ch
            out["plan"] = {"name": name, "act": "queue" if a.get("state") in AGENT_LIVE else "run"}
            return ch
        with_agents(hub, f)
        if "err" in out:
            raise Bad(out["err"])
        return out["plan"]
    slug = letter_slug(letter)
    if not slug or not agents_on():
        return None
    kbdir = letter_kbdir(hub, letter)
    if not os.path.isfile(os.path.join(kbdir, "kb.pl")):
        return None
    out = {}

    def g(o):
        ch = settle_dead(hub, o)
        for nm, a in o["agents"].items():  # the KB has its agent: the letter goes to it (c3)
            if a.get("kbdir") == kbdir:
                out["plan"] = {"name": nm, "act": "queue" if a.get("state") in AGENT_LIVE else "run"}
                return ch
        who = kb_held(hub, slug, kbdir)
        if who:
            return ch
        if not claude_found():
            out["why"] = f"{claude_prog()} is not on the PATH"
            return ch
        n = int(o.get("next") or 1)
        role = kb_role(hub, slug)
        nm = f"{mindhole_of(hub)}-{role}-agent_{n:03d}"
        old = recorded_session(kbdir)
        resume = bool(old) and transcript_exists(old)
        import uuid
        sid = old if resume else str(uuid.uuid4())
        o["next"] = n + 1
        o["agents"][nm] = {"name": nm, "kb": slug, "kbdir": kbdir, "role": role, "session_id": sid, "state": "starting",
                           "started": now_ts(), "since": now_ts(), "runs": 0, "queue": [], "new_session": not resume,
                           "lost": old if (old and not resume) else None}
        out["plan"] = {"name": nm, "act": "new"}
        return True
    with_agents(hub, g)
    if out.get("why"):
        print(f"desk: no desk agent starts: {out['why']}; the letter keeps its receiver", file=sys.stderr)
    p = out.get("plan")
    if p and p["act"] == "new":
        a = with_agents(hub, lambda o: (False, dict(o["agents"][p["name"]])))
        facts = []
        if a.get("lost"):
            facts.append(f"note(r1, {q_atom('The transcript of the desk agent session ' + a['lost'] + ' was lost (' + now_ts() + '); ' + a['name'] + ' starts new and takes the KB.')})")
        facts.append(f"note(r1, {q_atom('desk agent session ' + a['session_id'] + ' (' + a['name'] + ', ' + now_ts() + ')')})")
        err = None
        for fact in facts:
            err = err or kb_note(hub, a["kbdir"], a["session_id"], fact)
        if err or not take_lock(a["kbdir"], a["session_id"]):
            def drop(o):
                o["agents"].pop(p["name"], None)
                return True
            with_agents(hub, drop)
            print(f"desk: no desk agent starts for {slug}: {err or 'its writer lock is held'}; the letter keeps its receiver", file=sys.stderr)
            return None
    return p


def spawn_runner(hub, name):
    me = os.path.abspath(__file__)
    env = dict(os.environ)
    env.pop("HUB_SESSION", None)
    subprocess.Popen([sys.executable, me, "--hub", hub, "agent-run", name], start_new_session=True, cwd=hub, env=env,
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, stdin=subprocess.DEVNULL, close_fds=True)


def agent_dispatch(hub, plan, prompt, lid=None):
    """Give the prompt to the agent: queue it behind the run that goes on, or start a run now."""
    name = plan["name"]
    out = {}

    def f(o):
        a = o["agents"].get(name)
        if not a:
            out["err"] = f"there is no desk agent {name}"
            return False
        a.setdefault("queue", []).append({"prompt": prompt, "letter": lid})
        if a.get("state") in AGENT_LIVE and pid_alive(a.get("runner")):
            out["queued"] = True
        elif a.get("state") == "starting" and plan.get("act") == "new":
            out["spawn"] = True
        else:
            a.update(state="starting", since=now_ts(), why=None)
            out["spawn"] = True
        return True
    with_agents(hub, f)
    if out.get("err"):
        raise Bad(out["err"])
    if out.get("spawn"):
        spawn_runner(hub, name)
    return "queued" if out.get("queued") else "started"


def summarize_event(ev):
    """(kind, text) of one stream-json event, or None."""
    t = ev.get("type")
    if t == "assistant":
        outs = []
        for c in ((ev.get("message") or {}).get("content") or []):
            if not isinstance(c, dict):
                continue
            if c.get("type") == "tool_use":
                inp = c.get("input") or {}
                arg = inp.get("command") or inp.get("file_path") or inp.get("pattern") or inp.get("description") or json.dumps(inp, ensure_ascii=False)
                outs.append(("tool", f"{c.get('name')}: {arg}"))
            elif c.get("type") == "text" and (c.get("text") or "").strip():
                outs.append(("text", c["text"]))
        return outs
    if t == "result":
        return [("result", str(ev.get("result") or ev.get("subtype") or ""))]
    return []


def agent_event(hub, name, kind, text):
    text = clean_text(text).strip()
    if len(text) > AGENT_TEXT_MAX:
        text = text[:AGENT_TEXT_MAX - 1] + "…"
    ensure_dir(os.path.join(desk_dir(hub), "agents"))
    append_line(agent_events_path(hub, name), {"at": now_ts(), "kind": kind, "text": text})
    return text


def cmd_agent_run(hub, a):
    """The runner of one desk agent: one claude -p at a time, run after run while its queue has prompts."""
    name = a.name
    me = os.getpid()
    while True:
        job = {}

        def take(o):
            ag = o["agents"].get(name)
            if not ag:
                return False
            r = ag.get("runner")
            if r and r != me and pid_alive(r):
                job["other"] = True   # one runner (one process) per session
                return False
            q = ag.get("queue") or []
            if not q:
                ag.update(state="stopped" if ag.get("state") == "stopping" else ("ended" if ag.get("runs") else ag.get("state")),
                          runner=None, claude=None, since=now_ts())
                return True
            job.update(q.pop(0), agent=dict(ag))
            ag.update(state="running", runner=me, since=now_ts(), runs=int(ag.get("runs") or 0) + 1)
            return True
        with_agents(hub, take)
        if job.get("other") or "prompt" not in job:
            return
        ag = job["agent"]
        sid, kbdir = ag["session_id"], ag["kbdir"]
        if not take_lock(kbdir, sid):
            lk = lock_of(kbdir)
            agent_event(hub, name, "error", f"the writer lock of {ag['kb']} is held by {lk[0] if lk else '?'}: this run does not start")
            with_agents(hub, lambda o: (o["agents"][name].update(state="stopped", runner=None, since=now_ts(),
                                                                  why="its KB is held by another writer"), True)[1])
            return
        first = bool(ag.get("new_session")) and int(ag.get("runs") or 0) == 0
        mode = os.environ.get("DESK_AGENT_PERMISSION_MODE") or "auto"
        args = [claude_prog(), "-p", "--name", name, "--permission-mode", mode, "--output-format", "stream-json",
                "--verbose", "--append-system-prompt", system_prompt(hub, name, ag["role"], ag["kb"]),
                "--session-id" if first else "--resume", sid, job["prompt"]]
        env = dict(os.environ, ORBIT_KB_WRITER=sid, DESK_AGENT=name)
        env.pop("HUB_SESSION", None)
        agent_event(hub, name, "start", ("Started" if first else "Resumed") + f" with: {job['prompt']}")
        if job.get("letter"):
            try:
                Store(hub).add_event(job["letter"], "seen", name)
            except OSError:
                pass
        try:
            p = subprocess.Popen(args, cwd=hub, env=env, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                 stderr=subprocess.DEVNULL, start_new_session=True, text=True, encoding="utf-8", errors="replace")
        except OSError as e:
            agent_event(hub, name, "error", f"{claude_prog()} did not start: {e}")
            release_lock(kbdir, sid)
            with_agents(hub, lambda o: (o["agents"][name].update(state="stopped", runner=None, since=now_ts(), why=str(e)), True)[1])
            return
        with_agents(hub, lambda o: (o["agents"][name].update(claude=p.pid), True)[1])
        for line in p.stdout:
            try:
                ev = json.loads(line)
            except ValueError:
                continue
            if not isinstance(ev, dict):
                continue
            for kind, text in summarize_event(ev):
                t = agent_event(hub, name, kind, text)
                if kind in ("text", "tool", "result"):
                    with_agents(hub, lambda o, t=t, k=kind: (o["agents"][name].update(last=t, last_kind=k, last_at=now_ts()), True)[1])
        rc = p.wait()
        release_lock(kbdir, sid)
        agent_event(hub, name, "end", f"the run ended (exit {rc})")
        if job.get("letter"):
            try:
                st = Store(hub)
                acked = any(e["event"] == "acked" and e["letter"] == job["letter"] for e in st.events())
                st.add_event(job["letter"], "acted" if (acked or rc == 0) else "not_acted", name,
                             None if (acked or rc == 0) else f"the run of {name} ended with exit {rc}")
            except OSError:
                pass

        def done(o):
            g = o["agents"][name]
            g.update(claude=None, ended=now_ts())
            return True
        with_agents(hub, done)


def cmd_agent_stop(hub, a):
    out = {}

    def f(o):
        settle_dead(hub, o)
        g = o["agents"].get(a.name)
        if not g:
            out["err"] = f"there is no desk agent {a.name}"
            return False
        if g.get("state") not in AGENT_LIVE:
            out["msg"] = f"{a.name} is not running ({g.get('state')})"
            return True
        out["dropped"] = len(g.get("queue") or [])
        g.update(state="stopping", since=now_ts(), queue=[])
        out["pid"] = g.get("claude")
        return True
    with_agents(hub, f)
    if out.get("err"):
        raise NoHub(out["err"])
    if out.get("msg"):
        print(out["msg"])
        return
    pid = out.get("pid")
    if pid and pid_alive(pid):
        try:
            os.killpg(pid, 15)
        except OSError:
            try:
                os.kill(pid, 15)
            except OSError:
                pass
    if out.get("dropped"):
        agent_event(hub, a.name, "stop", f"stopped by Ty; {out['dropped']} waiting message(s) dropped")
    else:
        agent_event(hub, a.name, "stop", "stopped by Ty")
    print(f"stopping {a.name}")


def cmd_agent_resume(hub, a):
    g = with_agents(hub, lambda o: (settle_dead(hub, o), dict(o["agents"].get(a.name) or {})))
    if not g:
        raise NoHub(f"there is no desk agent {a.name}")
    if g.get("state") in AGENT_LIVE:
        raise Bad(f"{a.name} is running: stop it first")
    agent_dispatch(hub, {"name": a.name, "act": "run"}, RESUME_PROMPT)
    print(f"resumed {a.name}")


def cmd_agents(hub, a):
    if a.switch == "on":
        ensure_dir(state_dir())
        open(agents_on_flag(), "w").close()
        print("desk agents are on: a letter about a spec KB that nobody holds starts claude -p"
              + (" (but DESK_AGENTS=off in this environment)" if os.environ.get("DESK_AGENTS") == "off" else ""))
        return
    if a.switch == "off":
        try:
            os.remove(agents_on_flag())
        except OSError:
            pass
        print("desk agents are off: a letter about a KB that nobody holds keeps its receiver")
        return
    print(json.dumps({"on": agents_on(), "agents": agents_view(hub)}, ensure_ascii=False, indent=1))


def agents_view(hub):
    """The desk agents of the hub as the Desk shows them (desk.py status)."""
    o = with_agents(hub, lambda o: (settle_dead(hub, o), json.loads(json.dumps(o))))
    out = []
    for nm, g in sorted(o["agents"].items(), key=lambda kv: kv[1].get("started") or ""):
        evs = read_jsonl(agent_events_path(hub, nm), [], ("kind",))
        live = g.get("state") in AGENT_LIVE
        out.append({"name": nm, "kb": g.get("kb"), "kbdir": g.get("kbdir"), "role": g.get("role"), "state": g.get("state"),
                    "running": live, "since": g.get("since"), "started": g.get("started"), "ended": g.get("ended"),
                    "session_id": g.get("session_id"), "why": g.get("why"), "last": g.get("last"),
                    "queued": len(g.get("queue") or []), "events": evs[-AGENT_EVENTS_SHOWN:],
                    "resume_command": None if live else f"cd {shlex.quote(hub)} && claude --resume {g.get('session_id')}"})
    return out


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
    plan = agent_plan(hub, letter)  # desk-agents c11, c14: a desk agent takes it (it holds the KB first)
    if plan:
        letter["agent"] = plan["name"]
    append_line(os.path.join(desk_dir(hub), "letters.jsonl"), letter)  # stored before we return (c8)
    print(json.dumps({"id": lid, **({"agent": plan["name"]} if plan else {})}))
    sys.stdout.flush()
    if plan:
        try:
            agent_dispatch(hub, plan, agent_prompt_of(letter) if it["type"] != "agent" else clean_text(text), lid)
        except (Bad, OSError) as e:
            log(hub, f"agent: {plan['name']} did not take {lid}: {e!r}")
            print(f"desk: the desk agent {plan['name']} did not take the letter: {e}", file=sys.stderr)
    # desk-delivery c5: no wake here. The Desk asks Ty for each letter to an idle session (wake_ask).


def cmd_render(hub, a):
    about = check_about(a.about)
    text = check_text(read_text(a.text_file))
    c = connect(hub)
    try:
        to = check_to(c, a.to)
    finally:
        c.close()
    if a.id is not None and not LETTER_ID.match(a.id):
        raise Bad(f"--id {a.id!r} is not a letter id")
    out = notice_text(hub, [letter_block(hub, {"about": about, "text": text}, a.id)])
    if a.json:
        print(json.dumps({"to": to, "about": about, "delivered": out, "wake": wake_text(about)}, ensure_ascii=False))
    else:
        sys.stdout.write(out)


def cmd_wake_text(hub, a):
    sys.stdout.write(wake_text(check_about(a.about)))


def cmd_event(hub, a):
    store = Store(hub)
    find_letter(store, a.lid)
    if a.event == "dismissed" and delivery_of([e for e in store.events() if e["letter"] == a.lid]) != "not_acted":
        raise Bad(f"{a.lid} is not given, not acted on: only such a letter can be dismissed")
    store.add_event(a.lid, a.event, None, a.detail)
    print(json.dumps({"letter": a.lid, "event": a.event}))


def ts_secs(ts):
    try:
        return datetime.datetime.strptime(ts, TS_FMT).replace(tzinfo=datetime.timezone.utc).timestamp()
    except (TypeError, ValueError):
        return None


def delivery_of(ev, tracked=True):
    """desk-delivery c6: where a letter is, from its events (in file order): sent, given, acted,
    not_acted or dismissed. A letter that a turn did not act on stays not_acted until Ty dismisses it."""
    kinds = [e["event"] for e in ev]
    if "not_acted" in kinds:
        return "dismissed" if "dismissed" in kinds else "not_acted"
    if "acted" in kinds:
        return "acted"
    if "seen" not in kinds:
        return "sent"
    # a seen letter that no session's given list holds and no turn settled was given before the Desk
    # kept track of turns: it is not "given, its turn has not ended" for ever (review H-0184, finding 2)
    return "given" if tracked else "given_before"


def idle_pane(st):
    """The session's state says idle; the tmux pane it was in, or None."""
    return bool(st) and st.get("state") == "idle", (st or {}).get("tmux_pane") or None


def letter_views(c, store, letters, events, now):
    kbi = kb_items(c)
    live = active_sessions(c)
    states = {}
    now_s = ts_secs(now)
    given_now = set()  # the letters that some session was given and whose turn has not been settled
    try:
        for fn in os.listdir(os.path.join(store.dir, "sessions")):
            if fn.endswith(".json"):
                stx = store.session_state(fn[:-5])
                given_now.update(x for x in ((stx or {}).get("given") or []) if isinstance(x, str))
    except OSError:
        pass
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
        acted = [{"session": e.get("session"), "at": e.get("at")} for _, e in ev if e["event"] == "acted"]
        not_acted = [{"session": e.get("session"), "at": e.get("at"), "detail": e.get("detail")}
                     for _, e in ev if e["event"] == "not_acted"]
        given_to = {e.get("session") for _, e in ev if e["event"] == "seen"}
        wake_ask = []
        for s in lv:  # desk-delivery c5: the Desk asks Ty whether to wake each idle recipient
            if s in given_to or not SESSION_NAME.match(s):
                continue
            if s not in states:
                states[s] = store.session_state(s)
            idle, pane = idle_pane(states[s])
            if idle:
                wake_ask.append({"session": s, "pane": bool(pane)})
        closed = None
        it = x.get("item") or {}
        if it.get("type") == "ask":
            r = c.execute("SELECT status FROM item WHERE id = ?", (it.get("id"),)).fetchone()
            closed = None if r is None else r[0] not in ("open", "waiting")
        state = "applied" if last_ok else "apply_failed" if last_bad else "seen" if seen else "sent"
        at_s = ts_secs(x.get("at"))
        late = bool(not seen and at_s is not None and now_s is not None and now_s - at_s >= LATE_SECONDS)
        out.append(dict({"to": None, "about": None}, **x, owners=own, live_owners=lv, no_live_owner=not lv,
                        late_unseen=late, seen=seen, woken=woken, acted=acted, not_acted=not_acted,
                        delivery=delivery_of([e for _, e in ev], x["id"] in given_now), wake_ask=wake_ask,
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
        # kb-migrations c9: a spec KB whose items (summaries aside) are all closed is frozen; the Desk
        # shows no migration step of it (the words of its checks)
        kb_closed = sorted({ref_slug(r[0]) for r in c.execute(
            "SELECT DISTINCT r.ref FROM item_ref r JOIN item i ON i.id = r.item_id WHERE r.kind = 'kb'"
            " AND i.kind <> 'summary'")}
            - {ref_slug(r[0]) for r in c.execute(
                "SELECT DISTINCT r.ref FROM item_ref r JOIN item i ON i.id = r.item_id WHERE r.kind = 'kb'"
                " AND i.kind <> 'summary' AND i.status IN ('open','waiting')")})
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
            "agents": agents_view(hub), "agents_on": agents_on(),
            "kb_refs": kb_refs, "kb_closed": kb_closed, "kb_handoffs": kb_handoffs, "closed_recent": closed, "letters": lv,
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

def notice(hub, letters):
    """The notice text and the letters it holds: the lead line, then whole letters, each with its
    confirm line, joined by one empty line, up to NOTICE_MAX characters of letters, and at least one.
    The rest wait for the next stop or prompt."""
    parts, held, size = [], [], 0
    for x in letters:
        t = letter_block(hub, x)
        add = len(t) + (2 if parts else 0)
        if held and size + add > NOTICE_MAX:
            break
        parts.append(t)
        held.append(x)
        size += add
    return notice_text(hub, parts), held


def write_state(store, name, state, ev, data, given=()):
    write_atomic(store.session_path(name), {"name": name, "session_id": data.get("session_id"), "state": state,
                                            "at": now_ts(), "tmux_pane": os.environ.get("TMUX_PANE") or None,
                                            "cwd": data.get("cwd"), "event": ev, "given": list(given)})


def settle(store, name, prev, ev, data):
    """desk-delivery c7 (supersedes c6): the turn before this hook has ended; settle each letter it
    was given. A letter that the agent confirmed by its id in that turn (desk.py ack) is acted on;
    any other is not acted on, whether the turn ended by a Stop, Ctrl+C, a crash or a compaction.
    The context of a session start lives into the first prompt's turn, so that prompt carries the
    letters on. Returns those carried."""
    given = [x for x in ((prev or {}).get("given") or []) if isinstance(x, str)]
    if not given:
        return []
    if ev == "UserPromptSubmit" and (prev or {}).get("event") == "SessionStart":
        return given
    acked = {e["letter"] for e in store.events() if e["event"] == "acked" and e.get("session") == name}
    how = ("Stop" if ev == "Stop" else f"SessionStart ({data.get('source')})" if ev == "SessionStart"
           and isinstance(data.get("source"), str) else f"{ev} with no Stop of the turn before it")
    for lid in given:
        verdict, detail = ("acted", None) if lid in acked else ("not_acted", f"{how}; no ack of the letter in its turn")
        try:
            store.add_event(lid, verdict, name, detail)
        except OSError as e:
            log(store.hub, f"hook: {verdict} {lid} for {name} not recorded: {e!r}")
    return []


def cmd_ack(hub, a):
    """desk-delivery c7: the agent confirms that it acted on a letter it was given in this turn."""
    store = Store(hub)
    if not LETTER_ID.match(a.lid or ""):
        raise Bad(f"{a.lid!r} is not a letter id such as L-20261120T114714Z-a342ac")
    find_letter(store, a.lid)
    name = os.environ.get("HUB_SESSION")
    if not name:
        raise Bad("HUB_SESSION is not set: only the session that got the letter can confirm it")
    c = connect(hub)
    try:
        name = resolve_name(c, name)
    finally:
        c.close()
    st = store.session_state(name) if SESSION_NAME.match(name) else None
    if a.lid not in ((st or {}).get("given") or []):
        ev = [e for e in store.events() if e["letter"] == a.lid and e.get("session") == name]
        if any(e["event"] in ("acted", "not_acted") for e in ev):
            raise Bad(f"{a.lid} was given to {name} in an earlier turn, which ended; it cannot be confirmed now"
                      " (Ty sees it on the Desk)")
        raise Bad(f"{a.lid} was not given to {name} in this turn")
    store.add_event(a.lid, "acked", name)
    print(f"confirmed {a.lid} for {name}: Ty sees it as acted on when this turn ends")


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
        # desk-delivery c2: a Stop gives the next notice also when stop_hook_active is true. Each
        # letter is given once (its seen event), so the turn cannot go on for ever.
        carried = settle(store, name, store.session_state(name), ev, data)
        text, held = notice(hub, todo) if todo else ("", [])
        state = "busy" if ev == "UserPromptSubmit" or (stop and todo) else "idle"
        write_state(store, name, state, ev, data, carried + [x["id"] for x in held])
        if not todo:
            return
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
    """Ty's yes on the Desk (desk-delivery c5): type the wake line into each live recipient's pane when
    it is idle, runs Claude and has not been given the letter, blocked on the item or not. The line is
    a prompt: its UserPromptSubmit hook gives the letter, and the Stop of that turn the rest (c2).
    Never into a busy pane (c4). Returns (woken sessions, {session: why not})."""
    store = Store(hub)
    lid = letter["id"]
    events = store.events()
    done = {(e["event"], e.get("session")) for e in events if e["letter"] == lid}
    cmds = {x.strip() for x in (os.environ.get("DESK_WAKE_COMMANDS") or "claude").split(",") if x.strip()}
    c = connect(hub)
    try:
        own = recipients(c, letter)
        live = active_sessions(c)
    finally:
        c.close()
    woken, nots = [], {}
    if not own:
        print(f"desk: wake {lid}: no recipient", file=sys.stderr)
    for s in own:
        why = None
        st = store.session_state(s) if SESSION_NAME.match(s) else None
        if s not in live:
            why = "not live"
        elif ("seen", s) in done:
            why = "already given the letter"
        elif not st or st.get("state") != "idle" or not st.get("tmux_pane"):
            why = "not idle in a known pane" if st else "no session state"
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
        if why is not None:
            nots[s] = why
        print(f"desk: wake {lid} {s}: " + ("woken" if why is None else why), file=sys.stderr)
    return woken, nots


def cmd_wake(hub, a):
    woken, nots = wake(hub, find_letter(Store(hub), a.lid))
    print(json.dumps({"woken": woken, "not": nots}))


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
    s.add_argument("--id")
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
    s = sub.add_parser("ack")
    s.add_argument("lid")
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
    s = sub.add_parser("agent-run")
    s.add_argument("name")
    s = sub.add_parser("agent-stop")
    s.add_argument("name")
    s = sub.add_parser("agent-resume")
    s.add_argument("name")
    s = sub.add_parser("agents")
    s.add_argument("switch", nargs="?", choices=("on", "off"))
    s = sub.add_parser("service")
    s.add_argument("--hub", dest="sub_hub")
    s.add_argument("--orbit-kb")
    s.add_argument("--port", type=int, default=DEFAULT_PORT)
    s.add_argument("--write", action="store_true")
    return p


COMMANDS = {"send": cmd_send, "render": cmd_render, "wake-text": cmd_wake_text, "event": cmd_event,
            "status": cmd_status, "draft": cmd_draft, "ack": cmd_ack, "drafts": cmd_drafts, "letters": cmd_letters,
            "wake": cmd_wake, "hooks": cmd_hooks, "join": cmd_join, "leave": cmd_leave,
            "mindholes": cmd_mindholes, "service": cmd_service, "agent-run": cmd_agent_run,
            "agent-stop": cmd_agent_stop, "agent-resume": cmd_agent_resume, "agents": cmd_agents}
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
